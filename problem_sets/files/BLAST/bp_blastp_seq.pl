#!/usr/bin/perl -w

=pod

=head1 NAME

 bp_blastp_seq.pl

=head1 SYNOPSIS

 bp_blastp_seq.pl --matrix BLOSUM62 --expect 5.0 protein_sequence_file

=head1 OPTIONS

    -hshort help
 --help include description
 -s/--matrix scoring matrix (BLOSUM45, BLOSUM62, BLOSUM80, PAM70, PAM30)
 -E/--expect E()-value threshold (default 5.0)
 --db database (human refseq by default)

=head1 DESCRIPTION

C compares the sequence (in FASTA format) in the
file specfied and compares that sequence to human refseq proteins
(default) at the NCBI BLASTP site, reporting the search parameter and
the high scoring sequences.

=head1 AUTHOR

William R. Pearson, wrp@virginia.edu

=cut

    use strict;
use Bio::SeqIO;
use Bio::Tools::Run::RemoteBlast;

use Pod::Usage;
use Getopt::Long;

my ($acc,$database,$expect,$matrix) = ('', 'GP/9606.9558/RefSeq_protein', 5.0, "");
use vars qw($help $shelp);

my %matrix_gaps = ( BLOSUM45 => "15 2",
		        BLOSUM62 => "11 1",
		        PAM70 => "10 1",
		        PAM30 => "9 1",
    );

pod2usage(1) unless @ARGV;

GetOptions("db:s"=>\$database,
	      "E:f" => \$expect,
	      "expect:f" => \$expect,
	      "s:s" => \$matrix,
	      "matrix:s" => \$matrix,
	      "h|?" => \$shelp,
	      "help" => \$help,
    );

pod2usage(1) if $shelp;
pod2usage(exitstatus => 0, verbose => 2) if $help;

my $file = shift @ARGV;

my $seqio = Bio::SeqIO->new(-file => $file,
			    -format => "fasta");

my $query_seq = $seqio->next_seq;

# then setup a blast search
my (@params, $remote_blast_object, $blast_file, $r, $rc);
my $sleep_time = 2;

@params = (-prog=>'blastp', -data=>$database, -expect=>$expect);

if ($matrix && $matrix_gaps{$matrix}) {
    $Bio::Tools::Run::RemoteBlast::HEADER{'MATRIX_NAME'} = $matrix;
    $Bio::Tools::Run::RemoteBlast::HEADER{'GAPCOSTS'} = $matrix_gaps{$matrix};
}

# (possibly select taxon)
# not used -- GP/9606.9558/RefSeq_protein does the correct select, and returns the correct database size
# $Bio::Tools::Run::RemoteBlast::HEADER{'ENTREZ_QUERY'} = 'txid9606 [ORGN]';
# E()-values and database sizes are often incorrect when ENTREZ_QUERY is used.

$remote_blast_object = Bio::Tools::Run::RemoteBlast->new(@params);

$r = $remote_blast_object->submit_blast($query_seq);

while ( my @rids = $remote_blast_object->each_rid ) {
    foreach my $rid ( @rids ) {
	$rc = $remote_blast_object->retrieve_blast($rid);
	if( !ref($rc) ) {    # $rc not a reference => error or job not yet finished
	    if( $rc < 0 ) { $remote_blast_object->remove_rid($rid);
			    print "Error return code for BlastID code $rid ... \n";}
	    sleep $sleep_time; if ($sleep_time < 120) {$sleep_time *= 2;}
	}
	else {
	    my $result = $rc->next_result();

	    my $filename = $result->query_name()."\.out";
	    $remote_blast_object->save_output($filename);
	    $remote_blast_object->remove_rid($rid);
# print description of search
	    print "#Query: Name: ", $result->query_name(), "; Length: ",$result->query_length() . "\n";
	    print "#Database: Name: \"$database\"; Entries: ". $result->database_entries() . "; Residues: " . $result->database_letters() . "\n";
	    print "#Parameters: ";
	    for my $param ( $result->available_parameters() ) {
		print "  $param: ". $result->get_parameter($param)."; ";
	    }
	    print "\n";
# print list of hits:
	    print "#Hits:\tACC     \tE()\tbits\tf_id\ta_len\tdescr\n";
	    while ( my $hit = $result->next_hit ) {
		my $hit_descr = $hit->description();
		# simplify concatenated descriptions
		if ($hit_descr =~ m/\001/) {($hit_descr) =  split(/\001/,$hit_descr);}
		# clean up SwissProt results
		$hit_descr =~ s/RecName: Full=//g;
		$hit_descr =~ s/AltName: Full=//g;
		my @hsps = ();
		# get HSPs
		while ( my $hsp = $hit->next_hsp ) {
		    push @hsps, {e_val=>$hsp->evalue(),
				        bits => $hsp->bits(),
				        f_id => $hsp->frac_identical(),
				        q_start => $hsp->start('query'),
				        q_end => $hsp->end('query'),
				        s_start => $hsp->start('sbjct'),
				        s_end => $hsp->end('sbjct'),
				        a_len => $hsp->end('query') - $hsp->start('query') + 1,
		    }
		}
		# clean up the target accession
		my $l_acc = $hit->name;
		$l_acc =~ s/ref\|//;
		$l_acc =~ s/\.\d+\|//;

		print $l_acc, "\t";
		for my $hsp_p ( @hsps ) {
		    printf("%.2g\t%.1f\t%.3f\t%d",$hsp_p->{e_val},$hsp_p->{bits}, $hsp_p->{f_id},
			   $hsp_p->{a_len});
		}
		print "\t$hit_descr\n";
	    }
	}
    }
}


__END__


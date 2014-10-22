#!/usr/bin/perl -w 

=pod

=head1 NAME

 merge_hits.pl

=head1 SYNOPSIS

 merge_hits.pl file1 file2 file3 ...

 merge_hits.pl gstt1_drome_hits.bp62 gstt1_drome_hits.vt80 gstt1_drome_hits.vt20

=head1 OPTIONS

    -h    short help
 --help   include description
 --expect show E()-value
 --all    show all scores (default)
 --bits   show bits
 --f_id   show fraction identical
 --a_len  show alignment length

=head1 DESCRIPTION

C takes a set of results files produced by the
C or C(bp_blastp.pl> scripts, and merges the results
in these files, so that they can be compared.  The C<*_hits.*> are
expected to contain lines containing an accession, E()-value, bit
score, fraction identical, and alignment length, ending with a
description: 

    #Hits:ACC    E()bitsf_ida_lendescr
    NP_0005522e-145409.01.000218glutathione S-transferase Mu 1 isoform 1 [Homo sapiens]

Results from each of the files are merged using the unique accession
(and ordered according to the results in the first file).

=head1 AUTHOR

William R. Pearson, wrp@virginia.edu

=cut

use strict;
use Pod::Usage;
use Getopt::Long;
use vars qw($file $fd %results @file_list $matrix @hit_list $shelp $help);
use vars qw($expect $a_len $f_id $bits $all);

($expect,$a_len,$f_id, $bits, $all) = ( 0, 0, 0, 0, 0);

pod2usage(1) unless @ARGV;
GetOptions("h|?" => \$shelp,
	      "help" => \$help,
	      "all" => \$all,
	      "expect" => \$expect,
	      "bits" => \$bits,
	      "a_len" => \$a_len,
	      "f_id" => \$f_id,
    );

pod2usage(1) if $shelp;
pod2usage(exitstatus => 0, verbose => 2) if $help;

my @res_fields = ();
if ($all) {
    @res_fields = qw( expect bits f_id a_len );
}
elsif ($expect || $bits || $f_id || $a_len) {
    if ($expect) { push @res_fields, "expect";}
    if ($bits) { push @res_fields, "bits";}
    if ($f_id) { push @res_fields, "f_id";}
    if ($a_len) { push @res_fields, "a_len";}
}
else {
    @res_fields = qw( expect bits f_id a_len );
}

for (my $i=0; $i < @ARGV; $i++) {

    $file = $ARGV[$i];

# open the file
    unless (open($fd,$file)) {
	warn "Cannot open $file\n";
	next;
    }

# extract the suffix
  ($matrix) = ($file =~ m/\w+\.(\w+)$/);
  push @file_list, $matrix;

    while (my $line = <$fd>) {
# skip over the comments
	next if ($line =~ /^#/);
	chomp($line);

# read in the accessions, other info
	my @data = split(/\t/,$line);
	my $acc = $data[0];
	if ($i == 0) { push @hit_list, $acc;}
	my %values = ();
	@values{qw(expect bits f_id a_len)} = @data[1..4];
	unless ($results{$acc}) {
	    $results{$acc} = {descr => $data[-1]};
	}
	$results{$acc}{$matrix} = \%values;
    }
}

#print Dumper(%results);

my $tab_fill = "\t" x scalar(@res_fields);
print "#\t\t".join($tab_fill,@file_list) . "\n";

for my $acc ( @hit_list) {
    print $acc;
    for $matrix ( @file_list ) {
	if ($results{$acc}{$matrix}) {
	    my $result_p = $results{$acc}{$matrix};
	    print "\t",join("\t",@$result_p{@res_fields});
	}
	else {
	    print $tab_fill;
	}
    }
    print "\t".$results{$acc}{descr} . "\n";
}

__END__


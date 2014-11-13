#!/usr/bin/env perl

use strict;
use warnings;

my $fasta_file = $ARGV[0] or die "usage: $0 fasta_file\n\n";


##################################
## Parse sequences from fasta file


my $acc = ""; ## sequence accession
my $sequence = "";
my @seq_lengths; # store list of sequence lengths

open (my $fh, $fasta_file) or die "Error, cannot open file: $fasta_file\n";
while (my $line = <$fh>) {
    chomp $line;

    if ($line =~ />(\S+)/) {
	# process last entry before new one:
	if ($acc ne "") {
	    my ($seq_length, $GC_content) = &process_seq($acc, $sequence);
	    push (@seq_lengths, $seq_length);
	}
	
	$acc = $1;
	$sequence = ""; # re-init, new seq
    }
    else {
	## grow the sequence entry
	$sequence .= $line;
    }
}

## get last one, since not encountering a '>' again...
my ($seq_length, $GC_content) = &process_seq($acc, $sequence);
push (@seq_lengths, length($sequence));


##################
## compute average

my $num_seqs = 0;
my $sum_length = 0;
foreach my $seq_len (@seq_lengths) {
    $num_seqs++;
    $sum_length += $seq_len;
}

print "\n\nAvg length of $num_seqs seqs: " . ($sum_length/$num_seqs) . "\n";

##############
## compute N50

@seq_lengths = sort {$a<=>$b} @seq_lengths; # sort by length
@seq_lengths = reverse(@seq_lengths); ## reorder descendingly

my $N50_value;
my $sum_ordered_len = 0;
for my $ordered_seq_len (@seq_lengths) {
    $sum_ordered_len += $ordered_seq_len;
    if ($sum_ordered_len >= $sum_length/2) { 
	## finding shortest contig that represents half the total seq data
	$N50_value = $ordered_seq_len;
	last;
    }
}

print "N50 value: $N50_value\n";


exit(0);

####
sub process_seq {
    my ($acc, $sequence) = @_;


    my $seq_length = length($sequence);

    my $num_GC_chars = &get_GC_count($sequence);

    my $percent_GC_content = $num_GC_chars / $seq_length;

    print join("\t", $acc, "len=$seq_length", "\%GC=" . sprintf("%.2f", $percent_GC_content)) . "\n";
    
    return($seq_length, $GC_content);
    
}


####
sub get_GC_count {
    my ($sequence) = @_;

    my $GC_count = 0;
    while ($sequence =~ /[GC]/ig) {
	$GC_count++;
    }

    return($GC_count);
}


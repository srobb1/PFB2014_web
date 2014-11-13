#!/usr/bin/env perl

use strict;
use warnings;

my $fasta_file = $ARGV[0] or die "usage: $0 fasta_file\n\n";

my $acc = "";
my $sequence = "";

open (my $fh, $fasta_file) or die "Error, cannot open file: $fasta_file\n";
while (my $line = <$fh>) {
    chomp $line;

    if ($line =~ />(\S+)/) {
	# process last one:
	&process_seq($acc, $sequence);

	$acc = $1;
	$sequence = ""; # re-init, new seq
    }
    else {
	$sequence .= $line;
    }
}

## get last one
&process_seq($acc, $sequence);

exit(0);

####
sub process_seq {
    my ($acc, $sequence) = @_;

    print "$acc\t$sequence\n";
    
    ## Do this part:

    


}


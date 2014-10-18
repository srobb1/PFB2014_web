#!/usr/bin/perl
use warnings;
use strict;

my @micro;

foreach my $i (0..5000) {
    foreach my $j (0..3000) {
	$micro[$i][$j] = int rand(10);
    }
}
#generate reference
my $ref = \@micro;
# call function to calculate average
my $ave = table_average($ref);
print "Average of table = $ave\n";

sub table_average {
    my $ref = shift;
    my $total = 0;
    my $count = 0;
    foreach my $i_ref (@{$ref}) {
	foreach my $j ( @{$i_ref} ) {
	    $total += $j;
	    $count++;
	}
    }
    return $total/$count;
}

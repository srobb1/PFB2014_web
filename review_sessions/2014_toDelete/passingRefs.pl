#!/usr/bin/perl
use warnings;
use strict;

# initialize array to store all our data
my @micro;

#let's make a big rectangle of random numbers
foreach my $i (0..5000) { # first dimension
    foreach my $j (0..3000) { #second dimension
	$micro[$i][$j] = int rand(10); #random number 0-9
    }
}
#generate reference so we can pass a single scalar into the sub
my $ref = \@micro;

# call function to calculate average
# reutrns the average
my $ave = table_average($ref);

print "Average of table = $ave\n";

########################################################
sub table_average {
    my $ref = shift; # reference to array of arrays
    my $total = 0;
    my $count = 0;
    foreach my $i_ref (@{$ref}) { # get each of the refs in the first
                                  # dimension that point to the arrays
                                  # in the second dimension
	foreach my $j ( @{$i_ref} ) { # dereference the second dimension
                                      # array ref to get the array 
                                      # with all the values (-> $j)
	    $total += $j;
	    $count++;
	}
    }
    return $total/$count;
}

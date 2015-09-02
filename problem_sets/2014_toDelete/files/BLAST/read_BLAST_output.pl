#!/urb/bin/perl
use warnings;
use strict;

my $base_name = shift @ARGV;
my @matrices = @ARGV;
my %types;
foreach my $matrix (@matrices){
    my $file_name = ($base_name.$matrix);
    open ($MATRIX_in,'<',$filen_name);
    while ($line = <$MATRIX_in>){
	if ($line =~ />/){
	    next;
	}
	my @info = split (/\t/,$line)


    }

}




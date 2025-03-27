#!/usr/bin/perl
use strict;
use warnings;

sub usage {
    print "$0 <file>\n";
    die;
}

@ARGV == 1 or usage();

open my $fh, '<', $ARGV[0] or usage();
my @lines = <$fh>;
close $fh;

while (@lines && $lines[-1] =~ /#define .*/) {
    pop @lines;
}

print @lines;

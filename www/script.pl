#!/usr/bin/env perl
use strict;
use warnings;
use CGI;
use Template;

my $file = "overview.txt";
open my $fh, '<', $file or die "Could not open '$file': $!";
my @lines = <$fh>;
close $fh;
chomp @lines;

my $tt = Template->new({
    INCLUDE_PATH => '.',
    INTERPOLATE  => 1,
}) or die Template->error();

my $vars = {
    overview => \@lines,
};

my $cgi = CGI->new;
print $cgi->header('text/html');
$tt->process('index.tt', $vars) or die $tt->error();

#!/usr/bin/env perl
use strict;
use warnings;
use Regexp::Common qw(whitespace);
use CGI;
use Template;
use Data::Dumper;

my $cgi = CGI->new;

sub to_title_case {
    my $str = shift;
    $str =~ s/_/ /g;
    $str = lc($str);
    $str =~ s/^(.)/\U$1/;
    return $str;
}

my @ov_lines = do { open my $fh, '<', 'overview.txt' or die $!; chomp(my @l = <$fh>); @l };

if ($cgi->param('path') eq ''
or  $cgi->param('path') eq '/') {

    my @toc_lines = do { open my $fh, '<', 'table_of_contents.txt' or die $!; chomp(my @l = <$fh>); @l };

    my $tt = Template->new({
        INCLUDE_PATH => '.',
        INTERPOLATE  => 1,
    }) or die Template->error();

    my $vars = {
        title => \&to_title_case,
        overview => \@ov_lines,
        toc => \@toc_lines,
    };

    print $cgi->header('text/html');
    $tt->process('index.tt', $vars) or die $tt->error();

} else {
    if ($cgi->param('path') !~ /^\w+(\.\w+)?$/) {
        die "Invalid filename";
    }
    my $filename = '../out/' . $cgi->param('path') . '.inc';
    my $content = do { local $/; open my $fh, '<', $filename or die $!; <$fh> };

    my $tt = Template->new({
        INCLUDE_PATH => '.',
        INTERPOLATE  => 1,
    }) or die Template->error();

    my $vars = {
        title => \&to_title_case,
        overview => \@ov_lines,
        content => $content,
    };

    print $cgi->header(-type => 'text/html', -charset => 'utf-8');
    $tt->process('page.tt', $vars) or die $tt->error();

}

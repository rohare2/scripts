#! /usr/bin/perl
# $Id: catxml.pl 2 2012-01-20 04:22:57Z rohare $
# $URL: file:///usr/local/svn/scripts/catxml.pl $
#
use XML::Simple;
use Data::Dumper;

my $file="/etc/nodeattr.xml";
defined $ARGV[0] && ($file = $ARGV[0]);
my $config = XMLin("$file");
print Dumper($config);

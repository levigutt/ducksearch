#!/usr/bin/perl -wl
use strict;
use lib './lib';
use DuckSearch;

my $phrase = shift or die "Missing search phrase.\n";

my $duck = DuckSearch->new(search => 'images', cache => '.vqdcache');
my @images = $duck->search($phrase);

print $images[rand @images]->{image};

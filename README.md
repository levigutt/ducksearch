# DUCKSEARCH

for making searches on duckduckgo.com programmatically

## SYNOPSIS

duckduckgo uses a key called `vqd` that is unique to the search phrase to
prevent simple scraping of results. this module queries the frontend for the
key, optionally caches it in a file for later, and uses it to fetch the search
results.

```perl
use DuckSearch;

my $duck = DuckSearch->new(search => 'images', cache => '.vqdcache');
my @images = $duck->search('owl');

print $images[rand @images]->{image};
```

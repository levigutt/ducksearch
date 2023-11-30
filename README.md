# DUCKSEARCH

for making searches on duckduckgo.com programmatically

## SYNOPSIS

duckduckgo uses a key called `vqd` that is unique to the search phrase to
prevent simple scraping of results. this module queries the frontend for the
key, optionally caches it in a file for later, and uses it to fetch the search
results.

```perl
use lib './lib';
use DuckSearch;

my $ddg = DuckSearch->new(  cache => '.vqdcache' # file for caching vqds
                         ,  safe  => 1           # 1 = STRICT, 0 = ON, -1 = OFF
                         );
my @sites = $ddg->web('duck');
my @pics  = $ddg->images('duck');
my @gifs  = $ddg->images('duck', 'gif');
my @news  = $ddg->news('duck');
```

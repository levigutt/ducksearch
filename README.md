# DUCKSEARCH

DuckDuckGo are unable to provide an API for their search engine, due to
licensing. this module does simple web scraping to simulate an API.

## SYNOPSIS

DuckDuckGo uses a key called `vqd` that is unique to the search phrase to
prevent scraping. this module queries the frontend for the key, optionally
caches it in a file for later, and uses it to fetch the search results.

```perl
use DuckSearch;

my $ddg = DuckSearch->new(  cache => '.vqdcache' # file for caching vqds
                         ,  safe  => 1           # 1 = STRICT, 0 = ON, -1 = OFF
                         );
my @sites = $ddg->web('duck');
my @pics  = $ddg->images('duck');
my @gifs  = $ddg->images('duck', 'gif');
my @news  = $ddg->news('duck');
```

## COMMAND LINE UTILITY

the repo bundles a binary (`bin/ddg`) for simple cli usage:

```sh
$ ddg -limit=3 ducks
https://www.ducks.org/hunting/waterfowl-id
https://animalcorner.org/animals/ducks/
https://en.wikipedia.org/wiki/Duck
```

### SWITCHES

- `-web` search for web sites (default behaviour)
- `-news` search for news articles
- `-images` search for images; returns url for the image file
- `-videos` search for videos; returns the playable url
- `-limit=x` limits the number of results
- `-shuffle` will shuffle put the results in random order
- `-unsafe` turns OFF safe mode
- `-strict` turns ON strict mode
- `-help` show help info

`-web`, `-news`, `-images`, `-videos` can be stacked to return more than one
type of result.

`-strict` takes precedence over `-unsafe`, when both are specified - not
specifying either sets `safe => 0` as default.

download random duck image:

```sh
ddg -images -shuffle -limit=1 duck | wget -i - -q
```

## DIAGNOSTICS

```
Could not open CACHE_FILE: ERROR
Could not write to CACHE_FILE: ERROR
```

specified cache file is not a file, current user doesn't have access, or file
is locked. error will contain more specifics.

```
Could not GET https://duckduckgo.com/?q=SEARCH_PHRASE: 500 Can't connect to duckduckgo.com:443 (Name or service not known)
```

no internet connection, or the duckduckgo server is down.

```
malformed JSON string, neither tag, array, object, number, string or atom, at character offset 0 (before "window.execDeep=func...") at lib/DuckSearch.pm line 109.
```

DuckDuckGo may reject requests if scraping is suspected. retrying or changing
the UserAgent may help.


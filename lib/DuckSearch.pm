package DuckSearch;

use LWP::UserAgent;
use JSON::XS;
use Data::Dumper qw<Dumper>;

use namespace::clean;

our $UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0";

sub new
{
    my $class = shift;
    my $self =  {  safe   => 1
                ,  cache  => ''
                ,  locale => 'en-US'
                ,  vqds   => {}
                ,  @_
                };
    bless $self, $class;
}

sub web
{
    my $self = shift;
    die "Missing search phrase\n" unless @_;
    map { { title => $_->{t}, url => $_->{u}, $_->%* } }
        $self->_search(shift, 'd.js');
}

sub images
{
    my $self = shift;
    die "Missing search phrase\n" unless @_;
    my ($phrase, $type) = @_;
    map { { url => $_->{image}, page => $_->{url}, $_->%* } }
        $self->_search($phrase, 'i.js', defined $type ? ",,,type:$type,," : ',,,,,');
}

sub videos
{
    my $self = shift;
    die "Missing search phrase\n" unless @_;
    map { { url => $_->{content}, $_->%* } }
        $self->_search(shift, 'v.js');
}

sub news
{
    my $self = shift;
    die "Missing search phrase\n" unless @_;
    $self->_search(shift, 'news.js');
}

sub cache
{
    my $self = shift;
    if( @_ )
    {
        ($self->{cache}) = @_;
        return $self;
    }
    $self->{cache};
}

sub safe
{
    my $self = shift;
    if( @_ )
    {
        ($self->{safe}) = @_;
        return $self;
    }
    $self->{safe};
}

sub locale
{
    my $self = shift;
    if( @_ )
    {
        ($self->{locale}) = @_;
        return $self;
    }
    $self->{locale};
}

sub _search
{
    my $self = shift;
    die "Missing search phrase\n" unless @_;
    my ($phrase, $area, $f) = @_;
    $area //= 'd.js';
    $f //= ',,,,,';

    my %params = (  o           => 'json'
                 ,  q           => $phrase
                 ,  vqd         => $self->_get_vqd($phrase)
                 ,  f           => $f
                 ,  p           => $self->{safe} // 1
                 ,  bing_market => $self->{locale} // 'en-US'
                 );
    my $query = "$area?" . join "&", map { "$_=$params{$_}" }
                                     keys %params;
    my $search_url = sprintf 'https://duckduckgo.com/%s', $query;
    my $ua = UserAgent->new();
    my $res = $ua->get($search_url);
    die sprintf("could not GET %s: %s\n", $search_url, $res->status_line)
        if $res->is_error;
    my $json = decode_json($res->decoded_content);
    $json->{results}->@*;
}

sub _get_vqd
{
    my $self = shift;
    die "Missing phrase for vqd\n" unless @_;
    my $phrase = shift;
    return $self->{vqds}{$phrase} if exists $self->{vqds}{$phrase};

    my $VAR1;
    # load dumped hash
    eval do {undef $/; open my $fh, $self->{cache}; <$fh>} if $self->{cache};
    unless (exists $VAR1->{$phrase})
    {
        my $ddg = sprintf(  "https://duckduckgo.com/?q=%s"
                         ,  $phrase
                         );
        my $ua = UserAgent->new();
        my $res = $ua->get($ddg);
        die sprintf("Could not GET %s: %s\n", $ddg, $res->status_line)
            if $res->is_error;
        my ($vqd) = $res->decoded_content =~ /vqd="([^"]+)"/;
        $self->{vqds}{$phrase} = $vqd;
        return $vqd unless $self->{cache};
        #save cache
        $VAR1->{$phrase} = $vqd;
        open my $fh, '>', $self->{cache} or die "Could not open $self->{cache}: $!\n";
        print $fh Dumper($VAR1) or die "Could not write to $self->{cache}: $!\n";
    }
    $self->{vqds} = { $VAR1->%*, $self->{vqds}->%* };
    $VAR1->{$phrase};
}

package UserAgent;
use base 'LWP::UserAgent';
sub _agent
{
    $DuckSearch::UserAgent;
}


1;

package DuckSearch;

use LWP::UserAgent;
use JSON::XS;
use Data::Dumper qw<Dumper>;

use namespace::clean;

sub new
{
    my $class = shift;
    my $self =  {  safe   => 1
                ,  cache  => ''
                ,  @_
                };
    bless $self, $class;
}

sub web
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    map { { title => $_->{t}, url => $_->{u}, $_->%* } }
        $self->_search(shift, 'd.js');
}

sub images
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    my ($phrase, $type) = @_;
    map { { url => $_->{image}, page => $_->{url}, $_->%* } }
        $self->_search($phrase, 'i.js', defined $type ? ",,,type:$type,," : ',,,,,');
}

sub videos
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    map { { url => $_->{content}, $_->%* } }
        $self->_search(shift, 'v.js');
}

sub news
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    $self->_search(shift, 'news.js');
}

sub _search
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    my ($phrase, $area, $f) = @_;
    $area //= 'd.js';
    $f //= ',,,,,';

    my $search_url = sprintf(  "https://duckduckgo.com/%s?o=json&q=%s&vqd=%s&f=%s&p=%d"
                            ,  $area
                            ,  $phrase
                            ,  $self->_get_vqd($phrase)
                            ,  $f
                            ,  $self->{safe}   // 1
                            );
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
    die "missing phrase for vqd\n" unless @_;
    my $phrase = shift;
    my $VAR1;
    # load dumped hash
    eval do {undef $/; open my $fh, $self->{cache}; <$fh>} if -e -f $self->{cache};
    unless (exists $VAR1->{$phrase})
    {
        my $ddg = sprintf(  "https://duckduckgo.com/?q=%s"
                         ,  $phrase
                         );
        my $ua = UserAgent->new();
        my $res = $ua->get($ddg);
        die sprintf("could not GET %s: %s\n", $ddg, $res->status_line)
            if $res->is_error;
        my ($vqd) = $res->decoded_content =~ /vqd="([^"]+)"/;
        return $vqd unless -e -f $self->{cache};
        #save cache
        $VAR1->{$phrase} = $vqd;
        open my $fh, '>', $self->{cache}
            or die "Could not save to cache: $!\n";
        print $fh Dumper($VAR1) or warn "could not write to $self->{cache}";
    }
    $self->{vqd} = $VAR1;
    $VAR1->{$phrase};
}

sub _get_f
{
    my $self = shift;
    sprintf(    ",,,%s,,"
           ,    defined $self->{type} ? "type:$self->{type}"
                                      : ''
           );
}

package UserAgent;
use base 'LWP::UserAgent';
sub _agent
{
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0";
}


1;

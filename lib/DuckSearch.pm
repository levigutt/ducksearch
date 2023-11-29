package DuckSearch;

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON qw<decode_json>;
use Data::Dumper qw<Dumper>;

use namespace::clean;


my %js = (  web    => 'd.js'
         ,  images => 'i.js'
         ,  videos => 'v.js'
         ,  news   => 'news.js'
         );

# lookup table to transform result so that all results have `title` and `url`
my %map = (  web    => sub { { title => $_->{t}, url => $_->{u}, $_->%* } }
          ,  images => sub { { url => $_->{image}, page => $_->{url}, $_->%* } }
          ,  videos => sub { { url => $_->{content}, $_->%* } }
          ,  news   => sub { $_ }
          );

sub new
{
    my $class = shift;
    my $self =  {  search => 'web'
                ,  type   => ''
                ,  safe   => 1
                ,  cache  => ''
                ,  @_
                };
    die "invalid search: $self->{search}\n"
        unless defined $js{$self->{search}};
    bless $self, $class;
}

sub search
{
    my $self = shift;
    die "missing search phrase\n" unless @_;
    my $phrase = shift;
    my $search_url = sprintf(  "https://ddg.gg/%s?o=json&q=%s&vqd=%s&f=%s&p=%d"
                            ,  $js{$self->{search} // 'web'}
                            ,  $phrase
                            ,  $self->_get_vqd($phrase)
                            ,  $self->_get_f
                            ,  $self->{safe}   // 1
                            );
    my $ua = Mojo::UserAgent->new(max_redirects => 3);
    $ua->transactor->name("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0");
    my $body   = $ua->get($search_url)->result->body;
    my $json   = decode_json($body);
    map { $map{$self->{search} // 'web'}->() } $json->{results}->@*;
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
        my $ddg = sprintf(  "https://ddg.gg/?q=%s"
                         ,  $phrase
                         );
        my $ua = Mojo::UserAgent->new(max_redirects => 3);
        $ua->transactor->name('Firefox');
        my ($vqd) = $ua->get($ddg)->result->dom('script')->first->all_text =~ /vqd="(.*?)",/;
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


1;

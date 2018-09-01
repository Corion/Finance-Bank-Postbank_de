package HAL::Resource;
use Moo;
use JSON 'decode_json';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Future;

use Carp qw(croak);

our $VERSION = '0.52';

=head1 NAME

HAL::Resource - wrap a HAL resource

=head1 SYNOPSIS

    my $ua = WWW::Mechanize->new();
    my $res = $ua->get('https://api.example.com/');
    my $r = HAL::Resource->new(
        ua => $ua,
        %{ decode_json( $res->decoded_content ) },
    );

=cut

has ua => (
    weaken => 1,
    is => 'ro',
);

has _links => (
    is => 'ro',
);

has _external => (
    is => 'ro',
);

has _embedded => (
    is => 'ro',
);

sub resource_url( $self, $name ) {
    my $l = $self->_links;
    if( exists $l->{$name} ) {
        $l->{$name}->{href}
    }
}

sub resources( $self ) {
    sort keys %{ $self->_links }
}

sub fetch_resource_future( $self, $name, %options ) {
    my $class = $options{ class } || ref $self;
    my $ua = $self->ua;
    my $url = $self->resource_url( $name )
        or croak "Couldn't find resource '$name' in " . join ",", sort keys %{$self->_links};
    Future->done( $ua->get( $url ))->then( sub( $res ) {
        Future->done( bless { ua => $ua, %{ decode_json( $res->content )} } => $class );
    });
}

sub fetch_resource( $self, $name, %options ) {
    $self->fetch_resource_future( $name, %options )->get
}

sub navigate_future( $self, %options ) {
    $options{ class } ||= ref $self;
    my $path = delete $options{ path } || [];
    my $resource = Future->done( $self );
    for my $item (@$path) {
        my $i = $item;
        $resource = $resource->then( sub( $r ) {
            $r->fetch_resource_future( $i, %options );
        });
    };
    $resource
}

sub navigate( $self, %options ) {
    $self->navigate_future( %options )->get
}

sub inflate_list( $self, $class, $list ) {
    my $ua = $self->ua;
    map {
        $class->new( ua => $ua, %$_ )
    } @{ $list };
}

1;

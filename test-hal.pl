#!perl -w
package HAL::Resource;
use Moo;
use JSON 'decode_json';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Future;

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
        or die "Couldn't find resource '$name'";
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

1;

package Postbank_de::Finanzstatus;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

has [ 'accountsPrivate', 'accountsBusiness',
      'amountBusiness',
      'amountPrivate',
      'brokerageable',
      'hash',
      'md5Hash',
      'messages',
      'name',
      'selectUser',
      'teaserUrl'.
      'totalAmount',
] => ( is => 'ro' );

sub available_messages( $self ) {
    my $mb = $self->fetch_resource( 'messagebox' );
    my $ua = $self->ua;
    map {
        Postbank_de::Message->new( ua => $ua, %$_ )
    } @{ $mb->_embedded->{notificationDTOList} };
}

1;

package Postbank_de::Account;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'productType',
      'bookingDate', 'balance', 'usedTan', 'messages', 'transactionId',
      'transactionType', 'purpose', 'transactionDetail',
      'referenceInitials', 'reference', 'valutaDate'
    ] => ( is => 'ro' );

sub transactions_future( $self ) {
    $self->fetch_resource_future( 'transactions' )
}
    
sub transactions( $self ) {
    $self->transactions_future->get
}
    
1;

package Postbank_de::Message;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

has [ 
 'productType',
 'notificationId',
 'iban',
 'deletionDate',
 'messages',
 'deleteable',
 'confirmationLimitDate',
 'receiptDate',
 'confirmationDate',
 'postalDispatchDate',
 'priority',
 'accountDescription',
 'type', # 'EBS', 'CAMPAIGN', 'SIGNAL', 'SETTLEMENT', ...
 'subject',
 'state', # 'NEW', 'READ'
] => ( is => 'ro' );

sub attachments_future( $self ) {
    $self->fetch_resource_future( 'attachements' )
}
    
sub attachments( $self ) {
    $self->attachments_future->get
}

sub confirm( $self ) {
    die "confirm() is not implemented yet";
    $self->ua->post( $self->resource_url( 'confirm' ))
}

1;

package main;
use strict;
use WWW::Mechanize;
use LWP::Protocol::https;
use JSON 'decode_json';
#use LWP::ConsoleLogger::Easy qw( debug_ua );
use HTTP::CookieJar::LWP;
use Data::Dumper;

my $ua = WWW::Mechanize->new(
    cookie_jar => HTTP::CookieJar::LWP->new(),
);

#my $logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);

# Do an initial fetch to set up cookies
$ua->get('https://meine.postbank.de');

$ua->get('https://meine.postbank.de/configuration.json');
my $config = decode_json( $ua->content );

my $loginUrl = $config->{loginUrl};
$loginUrl =~ s!%(\w+)%!$config->{$1}!ge;

# ::APIv1
$ua->add_header(
    'api-key' => $config->{apiKey},
    #'device-signature' => '494f423500225fd9',
    accept => 'application/hal+json',
    keep_alive => 1,
);

$ua->post(
    $loginUrl,
    content => 'dummy=value&password=11111&username=Petra.Pfiffig'
);
#print $ua->status;
#print $ua->content;

my $postbank = HAL::Resource->new(
    ua => $ua,
    %{ decode_json($ua->content)}
);

my $finanzstatus = $postbank->navigate(
    class => 'Postbank_de::Finanzstatus',
    path => ['banking_v1' => 'financialstatus']
);

my $messages = $finanzstatus->fetch_resource( 'messagebox' ); # messagebox->count
warn $_->notificationId, $_->subject for $finanzstatus->available_messages;
#warn Dumper $messages;
#warn Dumper $messages->{_embedded}->{notificationDTOList};

# if( exists $finanzstatus->{splash_page} ) {
#     show / retrieve splash page text
# }

for my $acc (@{ $finanzstatus->accountsPrivate }) {
    my $account = Postbank_de::Account->new( ua => $ua, %$acc );

    print $account->name || '',"\n";
    print $account->accountHolder || '',"\n";
    print $account->iban || '',"\n";
    print $account->amount, " ", $account->currency,"\n";
 
    if( $account->productType eq 'depot' ) {
        next;
    };
 
    my $tx = $account->fetch_resource( 'transactions' );
    print Dumper $tx->{_embedded}->{'transactionDTOList'};
};


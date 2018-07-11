#!perl -w
use strict;
use WWW::Mechanize;
use LWP::Protocol::https;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use HTTP::CookieJar::LWP;
use JSON 'decode_json';
use HAL::Tiny;

my $ua = WWW::Mechanize->new(
    #cookie_jar => HTTP::CookieJar::LWP->new(),
);

#my $logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);

$ua->add_header( 'api-key' => '494f423500225fd9',
    #'device-signature' => '494f423500225fd9',
    accept => 'application/hal+json',
    keep_alive => 1,
    
    );
#$ua->agent('Mozilla/5.0 (Windows NT 6.1; W…) Gecko/20100101 Firefox/61.0');

$ua->get('https://meine.postbank.de');
print $ua->cookie_jar->as_string;
$ua->post(
    'https://bankapi-public.postbank.de/bankapi-public/prod/v1/authentication/login',
    content => 'dummy=value&password=11111&username=Petra.Pfiffig'
);
#print $ua->status;
#print $ua->content;

my $resource = decode_json($ua->content);
#my $resource = HAL::Tiny->new( %$info );
use Data::Dumper;
#warn Dumper $resource->{_links};
# https://bankapi-public.postbank.de/bankapi-public/prod/v1/banking/accounts/giro/DE81100100101987654321/transactions?page=1&size=30

my $finanzstatus = nav_hal( $ua, 'banking_v1' => 'financialstatus' );

for my $account (@{ $finanzstatus->{accountsPrivate} }) {
    print $account->{name} || '',"\n";
    print $account->{accountHolder} || '',"\n";
    print $account->{iban} || '',"\n";
    print $account->{amount}, " ", $account->{currency},"\n";
 
    if( $account->{productType} eq 'depot' ) {
        next;
    };
 
    my $tx = get_hal( $ua, $account, 'transactions' );
    print Dumper $tx->{_embedded}->{'transactionDTOList'};
};

#warn Dumper $finanzstatus->{accountsPrivate}->[1];
#$ua->get( $resource->{_links}->{banking_v1}->{href} );
#print $ua->content;

sub get_hal {
    my( $ua, $resource, $name ) = @_;
    if( exists $resource->{_links}->{$name} ) {
        $ua->get( $resource->{_links}->{$name}->{href} );
    } else {
        die "Can't find '$name' in resource. Possible links :\n"
            . join( "\n", map { "    - $_" } sort keys %{ $resource->{_links} } );
    };
        $resource = decode_json($ua->content);
};

sub nav_hal {
    my( $ua, @path ) = @_;
    
    my $resource = decode_json($ua->content);
    my @taken;
    for my $item (@path) {
        $resource = get_hal( $ua, $resource, $item );
        push @taken, $item;
    };
    
    $resource
}
#!perl -w
package main;
use strict;
use WWW::Mechanize;
use LWP::Protocol::https;
use JSON 'decode_json';
#use LWP::ConsoleLogger::Easy qw( debug_ua );
use HTTP::CookieJar::LWP;
use Data::Dumper;
use Finance::Bank::Postbank_de::APIv1;

#my $logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);

my $api = Finance::Bank::Postbank_de::APIv1->new();
$api->configure_ua();

my $postbank = $api->login( 'Petra.Pfiffig', '11111' );

my $finanzstatus = $postbank->navigate(
    class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
    path => ['banking_v1' => 'financialstatus']
);

my $messages = $finanzstatus->fetch_resource( 'messagebox' ); # messagebox->count
warn $_->notificationId, $_->subject for $finanzstatus->available_messages;
#warn Dumper $messages;
#warn Dumper $messages->{_embedded}->{notificationDTOList};

# if( exists $finanzstatus->{splash_page} ) {
#     show / retrieve splash page text
# }

for my $account ($finanzstatus->get_accountsPrivate ) {

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


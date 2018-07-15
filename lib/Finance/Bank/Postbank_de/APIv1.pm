package Finance::Bank::Postbank_de::APIv1;
use Moo;
use JSON 'decode_json';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use HAL::Resource;
use Finance::Bank::Postbank_de::APIv1::Finanzstatus;
use Finance::Bank::Postbank_de::APIv1::Message;
use Finance::Bank::Postbank_de::APIv1::Account;

our $VERSION = '0.50';

=head1 NAME

Finance::Bank::Postbank_de::APIv1 - Postbank connection

=head1 SYNOPSIS

    my $api = Finance::Bank::Postbank_de::APIv1->new();
    $api->configure_ua();
    my $postbank = $api->login( 'Petra.Pfiffig', '11111' );

=cut

#my $logger;
has ua => (
    is => 'ro',
    default => sub( $class ) {
        my $ua = WWW::Mechanize->new(
            cookie_jar => HTTP::CookieJar::LWP->new(),
        );
#use LWP::ConsoleLogger::Easy qw( debug_ua );
#$logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);
        $ua
    }
);


has config => (
    is => 'rw',
);

sub fetch_config( $self ) {
    # Do an initial fetch to set up cookies
    my $ua = $self->ua;
    $ua->get('https://meine.postbank.de');
    $ua->get('https://meine.postbank.de/configuration.json');
    my $config = decode_json( $ua->content );
    $self->config( $config );
    $config
}

sub configure_ua( $self, $config = $self->fetch_config ) {
    # XXX add certificate validation headers here too
    my $ua = $self->ua;
    $ua->add_header(
        'api-key' => $config->{apiKey},
        #'device-signature' => '494f423500225fd9',
        accept => ['application/hal+json', '*/*'],
        keep_alive => 1,
    );
};

sub login_url( $self ) {
    my $config = $self->config;
    my $loginUrl = $config->{loginUrl};
    $loginUrl =~ s!%(\w+)%!$config->{$1}!ge;
    $loginUrl
}

sub login( $self, $username, $password ) {
    my $ua = $self->ua;
    my $loginUrl = $self->login_url();
    
    my $r = 
    $ua->post(
        $loginUrl,
        content => sprintf 'dummy=value&password=%s&username=%s', $password, $username
        
    );
    
    my $postbank = HAL::Resource->new(
        ua => $ua,
        %{ decode_json($ua->content)}
    );

};

1;

=head1 RESOURCE HIERARCHY

This is the hierarchy of the resources in the API:

    APIv1
        Finanzstatus
            Account
                Transaction
                Message
                    Attachment

=cut
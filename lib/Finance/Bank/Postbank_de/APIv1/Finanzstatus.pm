package Finance::Bank::Postbank_de::APIv1::Finanzstatus;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.01';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

    my $ua = WWW::Mechanize->new();
    my $res = $ua->get('https://api.example.com/');
    my $r = HAL::Resource->new(
        ua => $ua,
        %{ decode_json( $res->decoded_content ) },
    );

=cut

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
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::Message',
        $mb->_embedded->{notificationDTOList}
    );
}

sub get_accountsPrivate( $self ) {
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::Account',
        $self->accountsPrivate
    );
}

1;

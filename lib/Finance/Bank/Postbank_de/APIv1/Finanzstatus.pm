package Finance::Bank::Postbank_de::APIv1::Finanzstatus;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

use Finance::Bank::Postbank_de::APIv1::BusinessPartner;
use Finance::Bank::Postbank_de::APIv1::Message;

our $VERSION = '0.52';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

    my $finanzstatus = $postbank->navigate(
        class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
        path => ['banking_v1' => 'financialstatus']
    );

=cut

has [ 'businesspartners',
      'amount',
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

sub get_businesspartners( $self ) {
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::BusinessPartner',
        $self->businesspartners
    );
}

1;

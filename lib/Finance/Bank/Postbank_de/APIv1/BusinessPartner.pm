package Finance::Bank::Postbank_de::APIv1::BusinessPartner;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

use Finance::Bank::Postbank_de::APIv1::Account;

our $VERSION = '0.52';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::BusinessPartner - Postbank Businesspartner (Person)

=head1 SYNOPSIS

=cut

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'ownerType',
      'sapAmId',
      'relationshipCategory',
      'accounts',
    ] => ( is => 'ro' );

sub get_accounts( $self ) {
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::Account',
        $self->accounts
    );
}

1;


package Finance::Bank::Postbank_de::APIv1::Account;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.01';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

=cut

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


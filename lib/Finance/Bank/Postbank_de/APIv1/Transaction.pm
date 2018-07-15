package Finance::Bank::Postbank_de::APIv1::Transaction;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.50';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Transaction - Postbank Transaction

=head1 SYNOPSIS

=cut

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'productType',
      'bookingDate', 'balance', 'usedTan', 'messages', 'transactionId',
      'transactionType', 'purpose', 'transactionDetail',
      'referenceInitials', 'reference', 'valutaDate'
    ] => ( is => 'ro' );

sub transactions_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
    my $tx = $account->fetch_resource( 'transactions' );
    Future->done(
        $self->inflate_list( 'Finance::Bank::Postbank_de::APIv1::Transaction',
            $r->_embedded->{transactionDTOList}));
    });
}
    
sub transactions( $self ) {
    $self->transactions_future->get
}
    
1;


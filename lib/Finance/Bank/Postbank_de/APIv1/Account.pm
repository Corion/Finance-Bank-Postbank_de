package Finance::Bank::Postbank_de::APIv1::Account;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.50';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Account - Postbank Account

=head1 SYNOPSIS

=cut

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'productType',
    ] => ( is => 'ro' );

sub transactions_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        $self->inflate_list(
            'Finance::Bank::Postbank_de::APIv1::Transaction',
            $r->_embedded->{transactionDTOList}
        )
    });
}
    
sub transactions( $self ) {
    $self->transactions_future->get
}
    
1;


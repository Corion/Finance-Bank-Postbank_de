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

sub transactions_csv_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        my $tr = HAL::Resource->new( %$r );
        $self->ua->get( $tr->resource_url('transactions_csv' ));
        Future->done( $self->ua->content );
    });
}

sub transactions_csv( $self ) {
    $self->transactions_csv_future->get
}

sub transactions_xml_future( $self ) {
    $self->fetch_resource_future( 'transactions' )->then(sub( $r ) {
        my $tr = HAL::Resource->new( %$r );
        $self->ua->get( $tr->resource_url('transactions_xml' ));
        Future->done( $self->ua->content );
    });
}

sub transactions_xml( $self ) {
    $self->transactions_xml_future->get
}

1;


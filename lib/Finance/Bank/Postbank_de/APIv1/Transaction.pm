package Finance::Bank::Postbank_de::APIv1::Transaction;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.52';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Transaction - Postbank Transaction

=head1 SYNOPSIS

=cut

has [ 'accountHolder', 'name', 'iban', 'currency', 'amount',
      'productType',
      'bookingDate', 'balance', 'usedTan', 'messages', 'transactionId',
      'transactionType', 'purpose', 'transactionDetail',
      'referenceInitials', 'reference', 'valutaDate'
] => (
    is => 'ro',
);

1;


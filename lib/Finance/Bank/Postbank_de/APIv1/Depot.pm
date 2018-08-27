package Finance::Bank::Postbank_de::APIv1::Depot;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.52';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Depot - Postbank Depot

=head1 SYNOPSIS

=cut

has [ 'depotWinOrLoss',
      'depotId',
      'depotValue',
      'depotWinOrLossPercent',
      'messages',
      'groupedPositions',
      'date',
    ] => ( is => 'ro' );

has depotCurrency => (
    is => 'ro',
    default => 'EUR',
);
    
sub positions( $self ) {
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::Position',
        [
            map {
                @{ $_->{positions} }
            } @{ $self->groupedPositions }
        ]);
}

1;


package Finance::Bank::Postbank_de::APIv1::Message;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.52';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

=cut

has [ 
 'productType',
 'notificationId',
 'iban',
 'deletionDate',
 'messages',
 'deleteable',
 'confirmationLimitDate',
 'receiptDate',
 'confirmationDate',
 'postalDispatchDate',
 'priority',
 'accountDescription',
 'type', # 'EBS', 'CAMPAIGN', 'SIGNAL', 'SETTLEMENT', ...
 'subject',
 'state', # 'NEW', 'READ'
] => ( is => 'ro' );

sub attachments_future( $self ) {
    $self->fetch_resource_future( 'attachements' )
}
    
sub attachments( $self ) {
    $self->attachments_future->get
}

sub confirm( $self ) {
    die "confirm() is not implemented yet";
    $self->ua->post( $self->resource_url( 'confirm' ))
}

1;

package Finance::Bank::Postbank_de::Account;

use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(strftime);
use Finance::Bank::Postbank_de;
use base 'Class::Accessor';

use vars qw[ $VERSION ];

$VERSION = '0.07';

BEGIN {
  Finance::Bank::Postbank_de::Account->mk_accessors(qw( number balance balance_prev  ));
};

sub new {
  my $self = $_[0]->SUPER::new();
  my ($class,%args) = @_;

  if (exists $args{number} and exists $args{name}) {
    croak "If you specify both, 'name' and 'number', they must be equal"
      unless $args{number} eq $args{name};
  };

  $self->number($args{number} || $args{name});

  $self;
};

# name is an alias for number
sub name { shift->number(@_); };

sub parse_date {
  my ($self,$date) = @_;
  $date =~ /^(\d{2})\.(\d{2})\.(\d{4})$/
    or die "Unknown date format '$date'. A date must be in the format 'DD.MM.YYYY'\n";
  $3.$2.$1;
};

sub parse_amount {
  my ($self,$amount) = @_;
  die "String '$amount' does not look like a number"
    unless $amount =~ /^-?[0-9]{1,3}(?:\.\d{3})*,\d{2}$/;
  $amount =~ tr/.//d;
  $amount =~ s/,/./;
  $amount;
};

sub slurp_file {
  my ($self,$filename) = @_;
  local $/ = undef;
  local *F;
  open F, "< $filename"
    or croak "Couldn't read from file '$filename' : $!";
  <F>;
};

sub parse_statement {
  my ($self,%args) = @_;

  # If $self is just a string, we want to make a new class out of us
  $self = $self->new
    unless ref $self;
  my $filename = $args{file};
  my $raw_statement = $args{content};
  if ($filename) {
    $raw_statement = $self->slurp_file($filename);
  } elsif (! defined $raw_statement) {
    croak "Need an account number if I have to retrieve the statement online"
      unless $args{number};
    croak "Need a password if I have to retrieve the statement online"
      unless exists $args{password};
    my $login = $args{login} || $args{number};

    return Finance::Bank::Postbank_de->new( login => $login, password => $args{password} )->get_account_statement;
  };

  croak "Don't know what to do with empty content"
    unless $raw_statement;

  my @lines = split /\r?\n/, $raw_statement;
  croak "No valid account statement"
    unless $lines[0] eq 'Postbank Kontoauszug Girokonto';
  shift @lines;

  # PFIFFIG, PETRA  BLZ: 20010020  Kontonummer: 9999999999
  $lines[0] =~ /^(.*?)\s+BLZ:\s+(\d{8})\s+Kontonummer:\s+(\d+)$/
    or croak "No owner found in account statement ($lines[0])";
  $self->{name} = $1;
  $self->{blz} = $2;

  # Verify resp. set the account number from what we read
  my $num = $self->number;
  croak "Account statement for different account"
    unless (not defined $num) or ($num eq $3);
  $self->number($3)
    unless $num;
  shift @lines;

  shift @lines;
  $lines[0] =~ /^Kontostand\s+Datum\s+Betrag\s+EUR$/
    or croak "No summary found in account statement ($lines[0])";
  shift @lines;
  my ($balance_now,$balance_prev);
  for ($balance_now,$balance_prev) {
    if ($lines[0] =~ /^([0-9.]{10})\s+([0-9.,]+)$/) {
      $_ = [$self->parse_date($1),$self->parse_amount($2)];
    } else {
      die "Couldn't find a balance statement in ($lines[0])";
    };
    shift @lines;
  };
  shift @lines;

  $self->balance( $balance_now );
  $self->balance_prev( $balance_prev );

  # Now parse the lines for each cashflow :
  $lines[0] =~ /^Datum\s+Wertstellung\s+Art\s+Verwendungszweck\s+Auftraggeber\s+Empfänger\s+Betrag\s+EUR$/
    or croak "Couldn't find start of transactions ($lines[0])";
  shift @lines;
  my (@fields) = qw[tradedate valuedate type comment receiver sender amount];
  my (%convert) = (
    tradedate => \&parse_date,
    valuedate => \&parse_date,
    amount => \&parse_amount,
  );

  my @transactions;
  my $line;
  for $line (@lines) {
    next if $line =~ /^\s*$/;
    my (@row) = split /\t/, $line;
    scalar @row == scalar @fields
      or die "Malformed cashflow ($line)";

    my (%rec);
    @rec{@fields} = @row;
    for (keys %convert) {
      $rec{$_} = $convert{$_}->($self,$rec{$_});
    };

    push @transactions, \%rec;
  };

  # Filter the transactions
  $self->{transactions} = \@transactions;

  $self
};

sub transactions {
  my ($self,%args) = @_;

  my ($start_date,$end_date);
  if (exists $args{on}) {

    croak "Options 'since'+'upto' and 'on' are incompatible"
      if (exists $args{since} and exists $args{upto});
    croak "Options 'since' and 'on' are incompatible"
      if (exists $args{since});
    croak "Options 'upto' and 'on' are incompatible"
      if (exists $args{upto});
    $args{on} = strftime('%Y%m%d',localtime())
      if ($args{on} eq 'today');
    $args{on} =~ /^\d{8}$/ or croak "Argument {on => '$args{on}'} dosen't look like a date to me.";

    $start_date = $args{on} -1;
    $end_date = $args{on};
  } else {
    $start_date = $args{since} || "00000000";
    $end_date = $args{upto} || "99999999";
    $start_date =~ /^\d{8}$/ or croak "Argument {since => '$start_date'} dosen't look like a date to me.";
    $end_date =~ /^\d{8}$/ or croak "Argument {upto => '$end_date'} dosen't look like a date to me.";
    $start_date < $end_date or croak "The 'since' argument must be less than the 'upto' argument";
  };

  # Filter the transactions
  grep { $_->{tradedate} > $start_date and $_->{tradedate} <= $end_date } @{$self->{transactions}};
};

sub value_dates {
  my ($self) = @_;
  my %dates;
  $dates{$_->{valuedate}} = 1 for $self->transactions();
  sort keys %dates;
};

sub trade_dates {
  my ($self) = @_;
  my %dates;
  $dates{$_->{tradedate}} = 1 for $self->transactions();
  sort keys %dates;
};

1;
__END__
=head1 NAME

Finance::Bank::Postbank_de::Account - Postbank bank account class

=head1 SYNOPSIS

=begin example

  use strict;
  use Finance::Bank::Postbank_de;
  my $account = Finance::Bank::Postbank_de::Account->parse_statement(
                number => '9999999999',
                password => '11111',
              );
  # Retrieve account data :
  my $retrieved_statement = $account->parse_statement();
  print "Statement date : ",$retrieved_statement->balance->[0],"\n";
  print "Balance : ",$retrieved_statement->balance->[1]," EUR\n";

  # Output CSV for the transactions
  for my $row ($retrieved_statement->transactions) {
    print join( ";", map { $row->{$_} } (qw( date valuedate type comment receiver sender amount ))),"\n";
  };

  $account->close_session;

=end example

=head1 DESCRIPTION

This module provides a rudimentary interface to the Postbank online banking system at
https://banking.postbank.de/. You will need either Crypt::SSLeay or IO::Socket::SSL
installed for HTTPS support to work with LWP.

The interface was cooked up by me without taking a look at the other Finance::Bank
modules. If you have any proposals for a change, they are welcome !

=head1 WARNING

This is code for online banking, and that means your money, and that means BE CAREFUL. You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself that I am not doing anything untoward with your banking data. This software is useful to me, but is provided under NO GUARANTEE, explicit or implied.

=head1 WARNUNG

Dieser Code beschaeftigt sich mit Online Banking, das heisst, hier geht es um Dein Geld und das bedeutet SEI VORSICHTIG ! Ich gehe
davon aus, dass Du den Quellcode persoenlich anschaust, um Dich zu vergewissern, dass ich nichts unrechtes mit Deinen Bankdaten
anfange. Diese Software finde ich persoenlich nuetzlich, aber ich stelle sie OHNE JEDE GARANTIE zur Verfuegung, weder eine
ausdrueckliche noch eine implizierte Garantie.

=head1 METHODS

=head2 new

Creates a new object. It takes three named parameters :

=over 4

=item number => '9999999999'

This is the number of the account. If you don't know it (for example, you
are reading in an account statement from disk), leave it undef.

=back

=head2 $account->parse_statement %ARGS

Parses an account statement and returns it as a hash reference. The account statement
can be passed in via two named parameters. If no parameter is given, the current statement
is fetched via the website through a call to C<get_account_statement> (is this so?).

Parameters :

=over 4

=item file => $filename

Parses the file C<$filename> instead of downloading data from the web.

=item content => $string

Parses the content of C<$string>  instead of downloading data from the web.

=back

=head2 $account->transactions %ARGS

Delivers you all transactions within a statement. The transactions may be filtered
by date by specifying the parameters 'since', 'upto' or 'on'. The values are, as always,
8-digit strings denoting YYYYMMDD dates.

Parameters :

=over 4

=item since => $date

Removes all transactions that happened on or before $date. $date must
be in the format YYYYMMDD. If the line is missing, C<since =E<gt> '00000000'>
is assumed.

=item upto => $date

Removes all transactions that happened after $date. $date must
be in the format YYYYMMDD. If the line is missing, C<upto =E<gt> '99999999'>
is assumed.

=item on => $date

Removes all transactions that happened on a date that is not C<eq> to $date. $date must
be in the format YYYYMMDD. $date may also be the special string 'today', which will
be converted to a YYYYMMDD string corresponding to todays date.

=back

=head2 $account->value_dates

C<value_dates> is a convenience method that returns all value dates on the account statement.

=cut

=head2 $account->trade_dates

C<trade_dates> is a convenience method that returns all trade dates on the account statement.

=cut

=head2 Converting a daily download to a sequence

=begin example

  #!/usr/bin/perl -w
  use strict;

  use Finance::Bank::Postbank_de::Account;
  use Tie::File;
  use List::Sliding::Changes qw(find_new_elements);
  use FindBin;
  use MIME::Lite;

  my $filename = "$FindBin::Bin/statement.txt";
  tie my @statement, 'Tie::File', $filename
    or die "Couldn't tie to '$filename' : $!";

  my @transactions;

  # See what has happened since we last polled
  my $retrieved_statement = Finance::Bank::Postbank_de::Account->parse_statement(
                         number => '9999999999',
                         password => '11111',
                );

  # Output CSV for the transactions
  for my $row (reverse @{$retrieved_statement->transactions()}) {
    push @transactions, join( ";", map { $row->{$_} } (qw( tradedate valuedate type comment receiver sender amount )));
  };

  # Find out what we did not already communicate
  my (@new) = find_new_elements(\@statement,\@transactions);
  if (@new) {
    my ($body) = "<html><body><table>";
    my ($date,$balance) = @{$retrieved_statement->balance};
    $body .= "<b>Balance ($date) :</b> $balance<br>";
    $body .= "<tr><th>";
    $body .= join( "</th><th>", qw( tradedate valuedate type comment receiver sender amount )). "</th></tr>";
    for my $line (@{[@new]}) {
      $line =~ s!;!</td><td>!g;
      $body .= "<tr><td>$line</td></tr>\n";
    };
    $body .= "</body></html>";
    MIME::Lite->new(
                    From     =>'update.pl',
                    To       =>'you',
                    Subject  =>"Account update $date",
                    Type     =>'text/html',
                    Encoding =>'base64',
                    Data     => $body,
                    )->send;
  };

  # And update our log with what we have seen
  push @statement, @new;

=end example

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<Finance::Bank::Postbank_de>.

#!/usr/bin/perl -w
use strict;

use vars qw(@accessors);

BEGIN { @accessors = qw( name number balance balance_prev )};

use Test::More tests => 12 + scalar @accessors * 2;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new( number => '9999999999' );
can_ok($account, qw(
  new
  parse_date
  parse_amount
  slurp_file
  parse_statement
  trade_dates
  value_dates
  ), @accessors );

sub test_scalar_accessor {
  my ($name,$newval) = @_;

  # Check our accessor methods
  my $oldval = $account->$name();
  $account->$name($newval);
  is($account->$name(),$newval,"Setting new value via accessor $name");
  $account->$name($oldval);
  is($account->$name(),$oldval,"Resetting new value via accessor $name");
};

for (@accessors) {
  test_scalar_accessor($_,"0999999999")
};

# also check that ->name and ->number are aequivalent :

$account->number("12345");
is($account->name,"12345","Setting number");
$account->name("54321");
is($account->number,"54321","Setting name");

$account = Finance::Bank::Postbank_de::Account->new( name => 12345 );
is($account->name,"12345","Constructor accepts 'name' argument");
is($account->number,"12345","Constructor accepts 'name' argument");

$account = Finance::Bank::Postbank_de::Account->new( number => 12345 );
is($account->name,"12345","Constructor accepts 'number' argument");
is($account->number,"12345","Constructor accepts 'number' argument");

$account = Finance::Bank::Postbank_de::Account->new( number => 12345, name => "12345" );
is($account->name,"12345","Constructor accepts 'number' argument");
is($account->number,"12345","Constructor accepts 'number' argument");

eval { $account = Finance::Bank::Postbank_de::Account->new( number => 12345, name => "67890" ); };
like($@,qr"^If you specify both, 'name' and 'number', they must be equal","Constructor checks that name and number are 'eq'ual");
eval { $account = Finance::Bank::Postbank_de::Account->new( number => 12345, name => "012345" ); };
like($@,qr"^If you specify both, 'name' and 'number', they must be equal","Constructor checks that name and number are 'eq'ual");

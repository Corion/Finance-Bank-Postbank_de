#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\Finance\Bank\Postbank_de.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module Finance::Bank::Postbank_de
  eval { require Finance::Bank::Postbank_de };
  skip "Need module Finance::Bank::Postbank_de to run this test", 1
    if $@;

  # Check for module strict
  eval { require strict };
  skip "Need module strict to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 220 lib/Finance/Bank/Postbank_de.pm

  use strict;
  use Finance::Bank::Postbank_de;
  my $account = Finance::Bank::Postbank_de->new(
                login => '9999999999',
                password => '11111',
                status => sub { shift;
                                print join(" ", @_),"\n"
                                  if ($_[0] eq "HTTP Code")
                                      and ($_[1] != 200)
                                  or ($_[0] ne "HTTP Code");

                              },
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
  
;

  }
};
is($@, '', "example from line 220");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};

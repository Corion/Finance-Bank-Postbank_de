#!/usr/bin/perl -w
use strict;
use File::Spec;
use FindBin;

use vars qw(@related_accounts);
BEGIN {
  @related_accounts = qw( 0999999999
                          9999999999 );
};

use Test::More tests => 5 + scalar @related_accounts *2;
use Test::MockObject;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",3 + + scalar @related_accounts *2
    unless LWP::Protocol::implementor('https');

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200)
                                #or $_[0] ne "HTTP Code";
                            },
                );

  # Get the login page:
  my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)",3;
    };
    skip "Banking is unavailable due to maintenance", 3
      if $account->maintenance;
    $account->agent(undef);

    my @fetched_accounts = sort $account->account_numbers;
    is_deeply(\@fetched_accounts,\@related_accounts,"Retrieve account numbers");

    for (reverse @fetched_accounts) {
      isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_");
    };
    for (sort @fetched_accounts) {
      isa_ok($account->get_account_statement(account_number => $_),'Finance::Bank::Postbank_de::Account', "Account $_");
    };

    ok($account->close_session(),"Close session");
    is($account->agent(),undef,"Agent was discarded");
  };
};

# Now also test for cases where we only have a single giro account :
# We "simply" fake the whole way that account_numbers uses to get
# at the actual account numbers for a login
{
  my $girofile = File::Spec->catfile($FindBin::Bin,'giroselection.html');
  local *F;
  open F, "<$girofile"
    or die "Couldn't open file '$girofile' : $!";
  undef $/;
  my $content = <F>;
  close F;
  
  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200)
                                #or $_[0] ne "HTTP Code";
                            },
                );
  
  no warnings 'once';                
  local *Finance::Bank::Postbank_de::select_function = sub {};
  my $agent = Test::MockObject->new()->set_always('current_form',HTML::Form->parse($content,'https://banking.postbank.de'));
  $account->agent($agent);
  is_deeply([$account->account_numbers],["9999999999"],"Single account number works");
};
#!/usr/bin/perl -w
use strict;
use FindBin;

use Test::More tests => 9;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",2
    unless LWP::Protocol::implementor('https');

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => 'xxxxx',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );

  # Get the login page:
  my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 8;
    };
    skip "Banking is unavailable due to maintenance", 8
      if $account->maintenance;
    $account->agent(undef);
    $account->new_session();
    ok($account->error_page(),"We got an error page");
    ok($account->access_denied(),"Access denied for wrong password");
    is($account->close_session(),'Never logged in',"Session is silently discarded if never logged in");
    is($account->agent(),undef,"agent was discarded");

    $account = Finance::Bank::Postbank_de->new(
                    #login => '99999999999', # One nine too many
                    login => '999999999', # One nine too few
                    password => '11111',
                    status => sub {
                                shift;
                                diag join " ",@_
                                  if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                              },
                  );

    $account->new_session();
    ok($account->error_page(),"We got an error page");
    ok($account->access_denied(),"Access denied for wrong account");
    is($account->close_session(),'Never logged in',"Session is silently discarded if never logged in");
    is($account->agent(),undef,"agent was discarded");
  };
};
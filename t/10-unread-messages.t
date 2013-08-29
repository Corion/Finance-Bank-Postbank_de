#!/usr/bin/perl -w
use strict;
use FindBin;
use Finance::Bank::Postbank_de;

use Test::More tests => 1;


# Check that we have SSL installed :
SKIP: {

  skip "Need SSL capability to access the website", 2
    unless LWP::Protocol::implementor('https');

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => '11111',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );
  # Get the login page:
  my $status= $account->new_session();

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      diag $account->agent->title;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 7;
    };
    skip "Banking is unavailable due to maintenance", 9
      if $account->maintenance;
  };
    diag $account->unread_messages;
    is $account->unread_messages, 1, "We have one unread message";

};

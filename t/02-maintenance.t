#!/usr/bin/perl -w
use strict;
use FindBin;
use WWW::Mechanize;

use Test::More tests => 3;

BEGIN { use_ok("Finance::Bank::Postbank_de"); };

# Check that we have SSL installed :
SKIP: {
  skip "Need SSL capability to access the website",2
    unless LWP::Protocol::implementor('https');
  #skip "Tests disabled until I get an actual maintenance page",2;

  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => 'xxxxx',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );
  $account->agent( WWW::Mechanize->new());
  $account->agent->get( 'file:t/02-maintenance.html' );
  ok( $account->error_page, 'Error page gets detected');
  ok( $account->maintenance, 'Maintenance mode gets detected')
    or diag $account->agent->content;
};

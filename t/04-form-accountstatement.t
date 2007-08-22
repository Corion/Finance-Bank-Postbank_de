#!/usr/bin/perl -w
use strict;
use FindBin;

require 't/test_form.pm';

use vars qw(@fields);
BEGIN {
  @fields = qw(konto zeitraum tage action);
};
use Test::More tests => 8;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {

  skip "Need SSL capability to access the website", 3 + scalar @fields
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
  my $status = $account->get_login_page(&Finance::Bank::Postbank_de::LOGIN);

  # Check that we got a wellformed page back
  SKIP: {
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      diag $account->agent->title;
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 7;
    };
    skip "Banking is unavailable due to maintenance", 9
      if $account->maintenance;
    $account->agent(undef);

    $status = $account->new_session();
    $status = $account->select_function("accountstatement");
    unless ($status == 200) {
      diag $account->agent->res->as_string;
      skip "Couldn't get to account statement (LWP: $status)",5;
    };

    form_ok( $account->agent, kontoumsatzUmsatzForm => @fields );
    ok($account->close_session(),"Closed session");
    is($account->agent(),undef,"agent was discarded");

    my $canned_statement = do {local $/ = undef;
                               local *F;
                               my $acctname = "$FindBin::Bin/accountstatement.txt";
                               open F, "< $acctname"
                                 or die "Couldn't read $acctname : $!";
                               <F>};

    eval { require File::Temp; File::Temp->import(); };
    SKIP: {
      skip "Need File::Temp to test download capabilities",4
        if $@;
      my ($fh,$tempname) = File::Temp::tempfile();
      close $fh;
      my $statement = $account->get_account_statement(file => $tempname);
      is($statement->iban, 'DE31200100209999999999', "Got the correct IBAN");

      my $downloaded_statement = do {local $/ = undef;
                                     local *F;
                                     open F, "< $tempname"
                                       or die "Couldn't read $tempname : $!";
                                     <F>};
      for ($downloaded_statement,$canned_statement) {
        s/\r\n/\n/g;
        s/\t/        /g;
        s/\s*$//mg;
        # Strip out all date references ...
        s/^\d{2}\.\d{2}\.\d{4}\s+\d{2}\.\d{2}\.\d{4}\s+//gm;
        s/^\d{2}\.\d{2}\.\d{4}//gm;
      };
      is_deeply([ split /\n/, $downloaded_statement ],[ split /\n/, $canned_statement ],"Download to file works");
      ok($account->close_session(),"Closed session");
      is($account->agent(),undef,"agent was discarded");

      unlink $tempname
       or diag "Couldn't remove tempfile $tempname : $!";
    };
  };
};

#!/usr/bin/perl -w
use strict;
use FindBin;

use vars qw(@fields);
BEGIN {
  @fields = qw(GIROSELECTION CHOICE SUBMIT);
};
use Test::More tests => 7 + scalar @fields;

use_ok("Finance::Bank::Postbank_de");

# Check that we have SSL installed :
SKIP: {

  skip "Need SSL capability to access the website", 6 + scalar @fields
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
      skip "Didn't get a connection to ".&Finance::Bank::Postbank_de::LOGIN."(LWP: $status)", 9;
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

    # Check that the expected form fields are available :
    my $field;
    for $field (@fields) {
      unless (defined $account->agent->current_form->find_input($field)) {
        diag $account->agent->current_form->inputs;
      };
      ok(defined $account->agent->current_form->find_input($field),"ACCOUNTSTATEMENT form has field '$field'");
    };
    ok($account->close_session(),"Closed session");
    is($account->agent(),undef,"agent was discarded");

    my $canned_statement = do {local $/ = undef;
                               local *F;
                               my $acctname = "$FindBin::Bin/accountstatement.txt";
                               open F, "< $acctname"
                                 or die "Couldn't read $acctname : $!";
                               <F>};

    my $statement = $account->get_account_statement();
    my $retrieved_statement = $account->agent->content;

    # Be careful with accountstatement.txt if your editor converts tabs to spaces!!!
    for ($retrieved_statement,$canned_statement) {
      s/\r\n/\n/g;
      s/\s*$//;
      # Strip out all date references ...
      s/^\d{2}\.\d{2}\.\d{4}\s+\d{2}\.\d{2}\.\d{4}\s+//gm;
      s/^\d{2}\.\d{2}\.\d{4}//gm;
    };
    is($retrieved_statement,$canned_statement,"Download to memory works");

    eval { require File::Temp; File::Temp->import(); };
    SKIP: {
      skip "Need File::Temp to test download capabilities",1
        if $@;
      my ($fh,$tempname) = File::Temp::tempfile();
      close $fh;
      $account->get_account_statement(file => $tempname);

      my $downloaded_statement = do {local $/ = undef;
                                     local *F;
                                     open F, "< $tempname"
                                       or die "Couldn't read $tempname : $!";
                                     <F>};
      for ($downloaded_statement,$canned_statement) {
        s/\r\n/\n/g;
        s/\s*$//;
        # Strip out all date references ...
        s/^\d{2}\.\d{2}\.\d{4}\s+\d{2}\.\d{2}\.\d{4}\s+//gm;
        s/^\d{2}\.\d{2}\.\d{4}//gm;
      };
      is($downloaded_statement,$canned_statement,"Download to file works");
      ok($account->close_session(),"Closed session");
      is($account->agent(),undef,"agent was discarded");

      unlink $tempname
        or diag "Couldn't remove tempfile $tempname : $!";
    };
  };
};
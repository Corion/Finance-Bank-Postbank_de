#!/usr/bin/perl -w
use strict;
use Test::More tests => 10;
use FindBin;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );
my $account_2 = Finance::Bank::Postbank_de::Account->new(
                number => '666666',
              );
my $account_3 = Finance::Bank::Postbank_de::Account->new(
                number => undef,
              );

my $acctname = "$FindBin::Bin/accountstatement.txt";
my $canned_statement = do {local $/ = undef;
                           local *F;
                           open F, "< $acctname"
                             or die "Couldn't read $acctname : $!";
                           <F>};

# Check that the parameter passing works :
{
  my ($get_called,$open_called);
  no warnings 'redefine';
  local *Finance::Bank::Postbank_de::Account::slurp_file = sub { die "slurp file called\n" };
  local *Finance::Bank::Postbank_de::Account::get_statement = sub { die "get called\n" };

  eval { $account->parse_statement( file => 'a/test/file') };
  is($@,"slurp file called\n","Passing file parameter");
};

# Check that the account number gets verified / set from the account data :
eval { $account_2->parse_statement( file => $acctname ) };
like( $@, "/^Account statement for different account/", "Existing account number gets verified");
$account_3->parse_statement( file => $acctname );
is($account_3->number, "9999999999", "Empty account number gets filled");

# Check error messages for invalid content :
eval { $account->parse_statement( content => '' ) };
like($@,"/^Don't know what to do with empty content/","Passing no parameter");
eval { $account->parse_statement( content => 'foo' ) };
like($@,"/^No valid account statement/","Passing bogus content");
eval { $account->parse_statement( content => "Postbank Kontoauszug Girokonto\nfoo" ) };
like($@,"/^No owner found in account statement \\(foo\\)/","Passing other bogus content");
eval { $account->parse_statement( content => "Postbank Kontoauszug Girokonto\nFOO, BAR BLZ: 66666666 Kontonummer: 9999999999\n\nfoo" )};
like($@,"/^No summary found in account statement \\(foo\\)/","Passing no summary in content");

my $expected_statement = { name => "PFIFFIG, PETRA",
                       blz => "20010020",
                       number => "9999999999",
                       balance => ["20030111","2500.00"],
                       balance_prev => ["20030102","347.36"],
                       transactions => [
                         { tradedate => "20030111", valuedate => "20030111", type => "GUTSCHRIFT",
                           comment => "KINDERGELD                 KINDERGELD-NR 234568/133",
                           receiver => "ARBEITSAMT BONN", sender => '', amount => "154.00", },
                         { tradedate => "20030111", valuedate => "20030111", type => "ÜBERWEISUNG",
                           comment => "FINANZKASSE 3991234        STEUERNUMMER 007 03434     EST-VERANLAGUNG 99",
                           receiver => "FINANZAMT KÖLN-SÜD", sender => '', amount => -328.75, },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "RECHNUNG 03121999          BUCHUNGSKONTO 9876543210",
                           receiver => "TELEFON AG KÖLN", sender => '', amount => "-125.80", },
                         { tradedate => "20030104", valuedate => "20030104", type => "SCHECK",
                           comment => "",
                           receiver => "EC1037406000003", sender => '', amount => "-511.20", },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "TEILNEHMERNUMMER 123456789 RUNDFUNK VON 1099 BIS 1299",
                           receiver => "GEZ KÖLN", sender => '', amount => -84.75, },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "STROMKOSTEN                KD-NR 1462347              JAHRESABRECHNUNG",
                           receiver => "STADTWERKE MUSTERSTADT", sender => '', amount => -580.06, },
                         { tradedate => "20030104", valuedate => "20030104", type => "INH.SCHECK",
                           comment => "",
                           receiver => "2000123456789", sender => '', amount => "-100.00", },
                         { tradedate => "20030104", valuedate => "20030104", type => "SCHECKEINR",
                           comment => "EINGANG VORBEHALTEN",
                           receiver => "GUTBUCHUNG 12345", sender => '', amount => "1830.00", },
                         { tradedate => "20030104", valuedate => "20030104", type => "DAUER ÜBERW",
                           comment => "DA 100001",
                           receiver => "", sender => 'MUSTERMANN, HANS', amount => "-31.50", },
                         { tradedate => "20030104", valuedate => "20030104", type => "GUTSCHRIFT",
                           comment => "BEZÜGE                     PERSONALNUMMER 700600170/01",
                           receiver => "ARBEITGEBER U. CO", sender => '', amount => "2780.70", },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "MIETE 600,00 EUR           NEBENKOSTEN 250,00 EUR     OBJEKT 22/328              MUSTERPFAD 567, MUSTERSTADT",
                           receiver => "EIGENHEIM KG", sender => '', amount => "-850.00", },
                       ],
                     };

my $statement = $account->parse_statement(content => $canned_statement);
is_deeply($statement,$expected_statement, "Parsing from memory works");

$account->parse_statement(file => $acctname);
is_deeply($statement,$expected_statement, "Parsing from file works");
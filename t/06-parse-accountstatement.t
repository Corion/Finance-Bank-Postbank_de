#!/usr/bin/perl -w
use strict;
use Test::More tests => 16;
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

my @acctnames = ("$FindBin::Bin/accountstatement.txt","$FindBin::Bin/accountstatement-negative.txt");
my $canned_statement = do {local $/ = undef;
                           local *F;
                           open F, "< $acctnames[0]"
                             or die "Couldn't read $acctnames[0] : $!";
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
eval { $account_2->parse_statement( file => $acctnames[0] ) };
like( $@, "/^Wrong/mixed account kontonummer: Got '9999999999', expected '666666'/", "Existing account number gets verified");
$account_3->parse_statement( file => $acctnames[0] );
is($account_3->number, "9999999999", "Empty account number gets filled");

# Check error messages for invalid content :
eval { $account->parse_statement( content => '' ) };
like($@,"/^Don't know what to do with empty content/","Passing no parameter");
eval { $account->parse_statement( content => 'foo' ) };
like($@,"/^No valid account statement: 'foo'/","Passing bogus content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\nfoo" ) };
like($@,"/^Expected an empty line/","Passing other bogus content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nFOO, BAR BLZ: 66666666 Kontonummer: 9999999999\n\nfoo" )};
like($@,"/^Field 'Name' not found in account statement/","Passing no Name in content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nName: Test User\nfoo" )};
like($@,"/^Field 'BLZ' not found in account statement/","Passing no BLZ in content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nName: Test User\nBLZ: 666\nfoo" )};
like($@,"/^Field 'Kontonummer' not found in account statement/","Passing no Kontonummer in content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nName: Test User\nBLZ: 666\nKontonummer: 9999999999\nfoo" )};
like($@,"/^Field 'IBAN' not found in account statement/","Passing no IBAN in content");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nName: Test User\nBLZ: 666\nKontonummer: 9999999999\nIBAN: IBAN DE31 2001 0020 9999 9999 99\nfoo" )};
like($@,"/^Expected an empty line after the information, got 'foo' at /","Passing no empty line after summary");
eval { $account->parse_statement( content => "Kontoumsätze Postbank Girokonto\n\nName: Test User\nBLZ: 666\nKontonummer: 9999999999\nIBAN: IBAN DE31 2001 0020 9999 9999 99\n\nfoo" )};
like($@,"/^No summary found in account statement \\(foo\\) for balance at /","Passing no summary in content");

my @expected_statements = ({ name => "PETRA PFIFFIG",
                       blz => "20010020",
                       number => "9999999999",
                       iban => "DE31200100209999999999",
		       account_type => 'Girokonto',
                       balance => ["????????","5314.05"],
                       transactions_future => ['????????',-11.33],
                       transactions => [
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "111111/1000000000/37050198 FINANZKASSE 3991234 STEUERNUMMER 00703434",
                           receiver => "Finanzkasse K\xf6ln-S\xfcd", sender => 'PETRA PFIFFIG', amount => "-328.75",
			   running_total => '5.314,05' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "111111/3299999999/20010020 ÜBERTRAG AUF SPARCARD 3299999999",
                           receiver => "Petra Pfiffig", sender => 'PETRA PFIFFIG', amount => "-228.61",
			   running_total => '5.642,80' },
                         { tradedate => "20041117", valuedate => "20041117", type => "Gutschrift",
                           comment => "BEZÜGE PERS.NR. 70600170/01 ARBEITGEBER U. CO",
                           receiver => "PETRA PFIFFIG", sender => 'Petra Pfiffig', amount => "2780.70", 
			   running_total => '5.871,41' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "DA 1000001",
                           receiver => "Verlagshaus Scribere GmbH", sender => 'PETRA PFIFFIG', amount => "-31.50",
			   running_total => '3.090,71' },
                         { tradedate => "20041117", valuedate => "20041117", type => "Scheckeinreichung",
                           comment => "EINGANG VORBEHALTEN GUTBUCHUNG 12345",
                           receiver => "PETRA PFIFFIG", sender => 'Ein Fremder', amount => "1830.00",
			   running_total => '3.122,21' },
                         { tradedate => "20041116", valuedate => "20041116", type => "Lastschrift",
                           comment => "MIETE 600+250 EUR OBJ22/328 SCHULSTR.7, 12345 MEINHEIM",
                           receiver => "Eigenheim KG", sender => 'PETRA PFIFFIG', amount => "-850.00", 
			   running_total => '1.292,21' },
                         { tradedate => "20041116", valuedate => "20041116", type => "Inh. Scheck",
                           comment => "",
                           receiver => "2000123456789", sender => 'PETRA PFIFFIG', amount => "-75.00",
			   running_total => '2.142,21' },
                         { tradedate => "20041114", valuedate => "20041114", type => "Lastschrift",
                           comment => "TEILNEHMERNR 1234567 RUNDFUNK 0103-1203",
                           receiver => "GEZ", sender => 'PETRA PFIFFIG', amount => -84.75,
			   running_total => '2.217,21' },
                         { tradedate => "20041112", valuedate => "20041112", type => "Lastschrift",
                           comment => "RECHNUNG 03121999",
                           receiver => "Telefon AG K\xf6ln", sender => 'PETRA PFIFFIG', amount => "-125.80", 
			   running_total => '2.301,96' },
                         { tradedate => "20041110", valuedate => "20041110", type => "Lastschrift",
                           comment => "STROMKOSTEN KD.NR.1462347 JAHRESABRECHNUNG",
                           receiver => "Stadtwerke Musterstadt", sender => 'PETRA PFIFFIG', amount => -580.06,
			   running_total => '2.427,76' },
                         { tradedate => "20041110", valuedate => "20041110", type => "Gutschrift",
                           comment => "KINDERGELD KINDERGELD-NR. 1462347",
                           receiver => "PETRA PFIFFIG", sender => 'Arbeitsamt Bonn', amount => "154.00", 
			   running_total => '3.007,82' },
                       ],
                     },
{ name => "PETRA PFIFFIG",
                       blz => "20010020",
                       number => "9999999999",
                       iban => "DE31200100209999999999",
		       account_type => 'Girokonto',
                       balance => ["????????","5314.05"],
                       transactions_future => ['????????',-11.33],
                       transactions => [
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "111111/1000000000/37050198 Finanzkasse 3991234 Steuernummer 00703434",
                           receiver => "Finanzkasse K\xf6ln-S\xfcd", sender => 'PETRA PFIFFIG', amount => "-328.75",
			   running_total => '5.314,05' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "111111/3299999999/20010020 Übertrag auf SparCard 3299999999",
                           receiver => "Petra Pfiffig", sender => 'PETRA PFIFFIG', amount => "-228.61",
			   running_total => '5.642,80' },
                         { tradedate => "20041117", valuedate => "20041117", type => "Gutschrift",
                           comment => "Bez\xfcge Pers.Nr. 70600170/01 Arbeitgeber u. Co",
                           receiver => "PETRA PFIFFIG", sender => 'Petra Pfiffig', amount => "2780.70", 
			   running_total => '5.871,41' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "DA 1000001",
                           receiver => "Verlagshaus Scribere GmbH", sender => 'PETRA PFIFFIG', amount => "-31.50",
			   running_total => '3.090,71' },
                         { tradedate => "20041117", valuedate => "20041117", type => "Scheckeinreichung",
                           comment => "Eingang vorbehalten Gutbuchung 12345",
                           receiver => "PETRA PFIFFIG", sender => 'Ein Fremder', amount => "1830.00",
			   running_total => '3.122,21' },
                         { tradedate => "20041116", valuedate => "20041116", type => "Lastschrift",
                           comment => "Miete 600+250 EUR Obj22/328 Schulstr.7, 12345 Meinheim",
                           receiver => "Eigenheim KG", sender => 'PETRA PFIFFIG', amount => "-850.00", 
			   running_total => '1.292,21' },
                         { tradedate => "20041116", valuedate => "20041116", type => "Inh. Scheck",
                           comment => "",
                           receiver => "2000123456789", sender => 'PETRA PFIFFIG', amount => "-75.00",
			   running_total => '2.142,21' },
                         { tradedate => "20041114", valuedate => "20041114", type => "Lastschrift",
                           comment => "Teilnehmernr 1234567 Rundfunk 0103-1203",
                           receiver => "GEZ", sender => 'PETRA PFIFFIG', amount => -84.75,
			   running_total => '2.217,21' },
                         { tradedate => "20041112", valuedate => "20041112", type => "Lastschrift",
                           comment => "Rechnung 03121999",
                           receiver => "Telefon AG K\xf6ln", sender => 'PETRA PFIFFIG', amount => "-125.80", 
			   running_total => '2.301,96' },
                         { tradedate => "20041110", valuedate => "20041110", type => "Lastschrift",
                           comment => "Stromkosten Kd.Nr.1462347 Jahresabrechnung",
                           receiver => "Stadtwerke Musterstadt", sender => 'PETRA PFIFFIG', amount => -580.06,
			   running_total => '2.427,76' },
                         { tradedate => "20041110", valuedate => "20041110", type => "Gutschrift",
                           comment => "Kindergeld Kindergeld-Nr. 1462347",
                           receiver => "PETRA PFIFFIG", sender => 'Arbeitsamt Bonn', amount => "154.00", 
			   running_total => '3.007,82' },
                       ],
                     });

# Reinitialize the account
$account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
           );
my $statement = $account->parse_statement(content => $canned_statement);
is_deeply($statement,$expected_statements[0], "Parsing from memory works");

$account->parse_statement(file => $acctnames[0]);
is_deeply($statement,$expected_statements[0], "Parsing from file works");

$account->parse_statement(file => $acctnames[1]);
is_deeply($statement,$expected_statements[1], "Parsing from file works for negative accounts");

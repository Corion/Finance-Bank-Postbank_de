#!/usr/bin/perl -w
use strict;
use FindBin;

use vars qw($statement @test_dates);
BEGIN {
  @test_dates = qw{ 1.1.1999 01/01/1999 1/01/1999 1999011 foo foo1 19990101foo };
};
use Test::More tests => 24 + scalar @test_dates * 2;

use_ok("Finance::Bank::Postbank_de::Account");

my $account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );

my $acctname = "$FindBin::Bin/accountstatement.txt";
my $canned_statement = do {local $/ = undef;
                           local *F;
                           open F, "< $acctname"
                             or die "Couldn't read $acctname : $!";
                           <F>};

my $expected_transactions_0 = [];

my $expected_transactions_1 = [
                         { tradedate => "20041110", valuedate => "20041110", type => "Gutschrift",
                           comment => "Kindergeld Kindergeld-Nr. 1462347",
                           receiver => "PETRA PFIFFIG", sender => 'Arbeitsamt Bonn', amount => "154.00", 
			   running_total => '3.007,82' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "111111/1000000000/37050198 Finanzkasse 3991234 Steuernummer 00703434",
                           receiver => "Finanzkasse K\xf6ln-S\xfcd", sender => 'PETRA PFIFFIG', amount => "-328.75",
			   running_total => '5.314,05' },
                       ];

=for later
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

=cut

my $expected_transactions_2 = [
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
                       ];
                       
my $expected_transactions_3 = [
                         { tradedate => "20041112", valuedate => "20041112", type => "Lastschrift",
                           comment => "Rechnung 03121999",
                           receiver => "Telefon AG K\xf6ln", sender => 'PETRA PFIFFIG', amount => "-125.80", 
			   running_total => '2.301,96' },
                         #{ tradedate => "20030104", valuedate => "20030104", type => "SCHECK",
                         #  comment => "",
                         #  receiver => "EC1037406000003", sender => '', amount => "-511.20", },
                         { tradedate => "20041114", valuedate => "20041114", type => "Lastschrift",
                           comment => "Teilnehmernr 1234567 Rundfunk 0103-1203",
                           receiver => "GEZ", sender => 'PETRA PFIFFIG', amount => -84.75,
			   running_total => '2.217,21' },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "STROMKOSTEN                KD-NR 1462347              JAHRESABRECHNUNG",
                           receiver => "STADTWERKE MUSTERSTADT", sender => '', amount => -580.06, },
                         { tradedate => "20030104", valuedate => "20030104", type => "INH.SCHECK",
                           comment => "",
                           receiver => "2000123456789", sender => '', amount => "-100.00", },
                         { tradedate => "20041117", valuedate => "20041117", type => "Scheckeinreichung",
                           comment => "Eingang vorbehalten Gutbuchung 12345",
                           receiver => "PETRA PFIFFIG", sender => 'Ein Fremder', amount => "1830.00",
			   running_total => '3.122,21' },
                         { tradedate => "20041117", valuedate => "20041117", type => "\xdcberweisung",
                           comment => "DA 1000001",
                           receiver => "Verlagshaus Scribere GmbH", sender => 'PETRA PFIFFIG', amount => "-31.50",
			   running_total => '3.090,71' },
                         { tradedate => "20030104", valuedate => "20030104", type => "GUTSCHRIFT",
                           comment => "BEZÜGE                     PERSONALNUMMER 700600170/01",
                           receiver => "ARBEITGEBER U. CO", sender => '', amount => "2780.70", },
                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
                           comment => "MIETE 600,00 EUR           NEBENKOSTEN 250,00 EUR     OBJEKT 22/328              MUSTERPFAD 567, MUSTERSTADT",
                           receiver => "EIGENHEIM KG", sender => '', amount => "-850.00", },
];

my @transactions;                     
$account->parse_statement(content => $canned_statement);

@transactions = $account->transactions();
is_deeply(\@transactions,$expected_transactions_2, "All transactions");

@transactions = $account->transactions(since => "20041118");
is_deeply(\@transactions,$expected_transactions_0, "Capping transactions at 20041118");
@transactions = $account->transactions(since => "20041117");
is_deeply(\@transactions,$expected_transactions_0, "Capping transactions at 20041117");
@transactions = $account->transactions(since => "20040117");
is_deeply(\@transactions,$expected_transactions_1, "Capping transactions at 20040117");
@transactions = $account->transactions(since => "20030104");
is_deeply(\@transactions,$expected_transactions_1, "Capping transactions at 20030104");
@transactions = $account->transactions(since => "20030103");
is_deeply(\@transactions,$expected_transactions_2, "Capping transactions at 20030103");
@transactions = $account->transactions(since => "");
is_deeply(\@transactions,$expected_transactions_2, "Capping transactions at empty string");
@transactions = $account->transactions(since => undef);
is_deeply(\@transactions,$expected_transactions_2, "Capping transactions at undef");
@transactions = $account->transactions(upto => "");
is_deeply(\@transactions,$expected_transactions_2, "Capping transactions at empty string");
@transactions = $account->transactions(upto => undef);
is_deeply(\@transactions,$expected_transactions_2, "Capping transactions at undef");

@transactions = $account->transactions(on => "20041112");
is_deeply(\@transactions,$expected_transactions_3, "Transactions today for 20041112");
@transactions = $account->transactions(on => "20041110");
is_deeply(\@transactions, [
                         { tradedate => "20041110", valuedate => "20041110", type => "Gutschrift",
                           comment => "Kindergeld Kindergeld-Nr. 1462347",
                           receiver => "PETRA PFIFFIG", sender => 'Arbeitsamt Bonn', amount => "154.00", 
			   running_total => '3.007,82' },
                          ],
                      "Transactions on 20041110");

@transactions = $account->transactions(on => "20041112");
is_deeply(\@transactions,[], "Getting transactions for 20041112");

@transactions = $account->transactions(on => "20041112");
is_deeply(\@transactions,$expected_transactions_3, "Getting transactions for 20041112");

@transactions = $account->transactions(on => "20041111");
is_deeply(\@transactions,$expected_transactions_1, "Getting transactions for 20041111");

@transactions = $account->transactions(on => "today");
is_deeply(\@transactions,[], "Getting transactions for 'today'");

eval { @transactions =$account->transactions(since => "20030111", on => "20030111", upto => "20030111");};
like($@,qr/^Options 'since'\+'upto' and 'on' are incompatible/, "Options 'since'+'upto' and 'on' are incompatible");

eval { @transactions = $account->transactions(on => "20030111", upto => "20030111"); };
like($@,qr/^Options 'upto' and 'on' are incompatible/, "Options 'upto' and 'on' are incompatible");

eval { @transactions = $account->transactions(since => "20030111", on => "20030111" );};
like($@,qr/^Options 'since' and 'on' are incompatible/, "Options 'since' and 'on' are incompatible");

eval { @transactions = $account->transactions(since => "20030111", upto => "20030111" );};
like($@,qr/^The 'since' argument must be less than the 'upto' argument/, "Since < upto");

eval { @transactions = $account->transactions(since => "20030112", upto => "20030111" );};
like($@,qr/^The 'since' argument must be less than the 'upto' argument/, "Since < upto");


# Now check our error handling
my $date;
for $date (@test_dates) {
  eval { $account->transactions( since => $date )};
  like $@,"/^Argument \\{since => '$date'\\} dosen't look like a date to me\\./","Bogus start date ($date)";
  eval { $account->transactions( upto => $date )};
  like $@,"/^Argument \\{upto => '$date'\\} dosen't look like a date to me\\./","Bogus end date ($date)";
};

# Now check that we can list the transaction dates contained in the 
# account statement

$account = Finance::Bank::Postbank_de::Account->new(
                number => '9999999999',
              );
$account->parse_statement(content => $canned_statement);
my @dates = $account->value_dates;
is_deeply(\@dates,[ "20041110", "20041112", "20041114", "20041116", "20041117" ],"Extracting account value dates");

@dates = $account->trade_dates;
is_deeply(\@dates,[ "20041110", "20041112", "20041114", "20041116", "20041117" ],"Extracting account trade dates");


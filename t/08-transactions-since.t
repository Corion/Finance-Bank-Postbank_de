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
                         { tradedate => "20030111", valuedate => "20030111", type => "GUTSCHRIFT",
                           comment => "KINDERGELD                 KINDERGELD-NR 234568/133",
                           receiver => "ARBEITSAMT BONN", sender => '', amount => "154.00", },
                         { tradedate => "20030111", valuedate => "20030111", type => "ÜBERWEISUNG",
                           comment => "FINANZKASSE 3991234        STEUERNUMMER 007 03434     EST-VERANLAGUNG 99",
                           receiver => "FINANZAMT KÖLN-SÜD", sender => '', amount => -328.75, },
                       ];

my $expected_transactions_2 = [
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
                       ];
                       
my $expected_transactions_3 = [                         { tradedate => "20030104", valuedate => "20030104", type => "LASTSCHRIFT",
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
];

my @transactions;                     
$account->parse_statement(content => $canned_statement);

@transactions = $account->transactions();
is_deeply(\@transactions,$expected_transactions_2, "All transactions");

@transactions = $account->transactions(since => "20030112");
is_deeply(\@transactions,$expected_transactions_0, "Capping transactions at 20030112");
@transactions = $account->transactions(since => "20030111");
is_deeply(\@transactions,$expected_transactions_0, "Capping transactions at 20030111");
@transactions = $account->transactions(since => "20030105");
is_deeply(\@transactions,$expected_transactions_1, "Capping transactions at 20030105");
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

@transactions = $account->transactions(on => "20030104");
is_deeply(\@transactions,$expected_transactions_3, "Transactions today for 20030104");
@transactions =$account->transactions(on => "20030111");
is_deeply(\@transactions,[{ tradedate => "20030111", valuedate => "20030111", type => "GUTSCHRIFT",
                       comment => "KINDERGELD                 KINDERGELD-NR 234568/133",
                       receiver => "ARBEITSAMT BONN", sender => '', amount => "154.00", },
                     { tradedate => "20030111", valuedate => "20030111", type => "ÜBERWEISUNG",
                       comment => "FINANZKASSE 3991234        STEUERNUMMER 007 03434     EST-VERANLAGUNG 99",
                       receiver => "FINANZAMT KÖLN-SÜD", sender => '', amount => -328.75, }],
                      "Transactions on 20030111");

@transactions =$account->transactions(on => "20030112");
is_deeply(\@transactions,[], "Getting transactions for 20030112");

@transactions =$account->transactions(on => "20030104");
is_deeply(\@transactions,$expected_transactions_3, "Getting transactions for 20030104");

@transactions =$account->transactions(on => "20030111");
is_deeply(\@transactions,$expected_transactions_1, "Getting transactions for 20030111");

@transactions =$account->transactions(on => "today");
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
is_deeply(\@dates,[ "20030104","20030111" ],"Extracting account value dates");

@dates = $account->trade_dates;
is_deeply(\@dates,[ "20030104","20030111" ],"Extracting account trade dates");
package Finance::Bank::Postbank_de;

use strict;
use warnings;
use Carp;
use base 'Class::Accessor';

use WWW::Mechanize;
use Finance::Bank::Postbank_de::Account;

use vars qw[ $VERSION ];

$VERSION = '0.07';

BEGIN {
  Finance::Bank::Postbank_de->mk_accessors(qw( agent ));
};

use constant LOGIN => 'https://banking.postbank.de/anfang.jsp';
use vars qw(%functions);
BEGIN {
  %functions = (
    quit => qr/Banking\s+beenden/,
    accountstatement => qr/Kontoauszug/,
  );
};

sub new {
  my ($class,%args) = @_;

  croak "Login/Account number must be specified"
    unless $args{login};
  croak "Password/PIN must be specified"
    unless $args{password};
  my $logger = $args{status} || sub {};

  my $self = {
    agent => undef,
    login => $args{login},
    password => $args{password},
    logger => $logger,
  };
  bless $self, $class;

  $self->log("New $class created");
  $self;
};

sub log { $_[0]->{logger}->(@_); };
sub log_httpresult { $_[0]->log("HTTP Code",$_[0]->agent->status,$_[0]->agent->res->as_string) };

sub new_session {
  # Reset our user agent
  my ($self) = @_;

  $self->close_session()
    if ($self->agent);

  my $result = $self->get_login_page(LOGIN);
  if($result == 200) {
    if ($self->maintenance) {
      $self->log("Status","Banking is unavailable due to maintenance");
      die "Banking unavailable due to maintenance";
    };
    my $agent = $self->agent();
    my $function = 'ACCOUNTBALANCE';
    $self->log("Logging into function $function");
    $agent->current_form->value('Kontonummer',$self->{login});
    $agent->current_form->value('PIN',$self->{password});
    $agent->current_form->value('FUNCTION',$function);
    $agent->click('LOGIN');
    $self->log_httpresult();
    $result = $agent->status;
  };
  $result;
};

sub get_login_page {
  my ($self,$url) = @_;
  $self->log("Connecting to $url");
  $self->agent(WWW::Mechanize->new());

  my $agent = $self->agent();
  $agent->get(LOGIN);
  $self->log_httpresult();
  $agent->status;
};

sub error_page {
  # Check if an error page is shown (a page with much red on it)
  my ($self) = @_;
  $self->agent->content =~ /<tr valign="top" bgcolor="#FF0033">/sm;
};

sub maintenance {
  my ($self) = @_;
  $self->error_page and
  $self->agent->content =~ /derzeit steht das Internet Banking aufgrund von Wartungsarbeiten leider nicht zur Verf&uuml;gung.\s*<br>\s*In K&uuml;rze wird das Internet Banking wieder wie gewohnt erreichbar sein./gsm;
};

sub access_denied {
  my ($self) = @_;
  my $content = $self->agent->content;

  $self->error_page and
  (  $content =~ /Die eingegebene Kontonummer ist unvollst&auml;ndig oder falsch\..*\(2051\)/gsm
  or $content =~ /Die eingegebene PIN ist falsch\. Bitte geben Sie die richtige PIN ein\.\s*\(10011\)/gsm
  or $content =~ /Die von Ihnen eingegebene Kontonummer ist ung&uuml;ltig und entspricht keiner Postbank-Kontonummer.\s*\(3040\)/gsm );
};

sub session_timed_out {
  my ($self) = @_;
  $self->agent->content =~ /Die Sitzungsdaten sind ung&uuml;ltig, bitte f&uuml;hren Sie einen erneuten Login durch.\s+\(27000\)/;
};

sub select_function {
  my ($self,$function) = @_;
  carp "Unknown account function '$function'"
    unless exists $functions{$function};

  $self->new_session unless $self->agent;

  $self->agent->follow($functions{$function});
  if ($self->session_timed_out) {
    $self->log("Session timed out");
    $self->agent(undef);
    $self->new_session();
    $self->agent->follow($functions{$function});
  };
  $self->log_httpresult();
  $self->agent->status;
};

sub close_session {
  my ($self) = @_;
  my $result;
  if (not $self->access_denied) {
    $self->log("Closing session");
    $self->select_function('quit');
    $result = $self->agent->res->as_string =~ /Online-Banking\s+beendet/sm;
  } else {
    $result = 'Never logged in';
  };
  $self->agent(undef);
  $result;
};

sub account_numbers {
  my ($self,%args) = @_;
  $self->log("Getting related account numbers");
  $self->select_function("accountstatement");

  #local *F;
  #open F, ">", "giroselection.html"
  #  or die "uhoh : $!";
  #print F $self->agent->content;
  #close F;
  my $giro_input = $self->agent->current_form->find_input('GIROSELECTION');
  if (defined $giro_input) {
    if ($giro_input->type eq 'hidden') {
      ($giro_input->value())
    } else {
      $giro_input->possible_values()
    };
  } else {
    return ();
  };
};

sub get_account_statement {
  my ($self,%args) = @_;

  $self->select_function("accountstatement");

  my $agent = $self->agent();

  if (exists $args{account_number}) {
    $self->log("Getting account statement for $args{account_number}");
    $agent->current_form->value('GIROSELECTION', delete $args{account_number});
  } else {
    $self->log("Getting account statement (default or only one there)");
  };

  $agent->current_form->value('CHOICE','COMPLETE');
  $agent->click('SUBMIT');
  $self->log("Downloading print version");
  $agent->form(3);
  $agent->click('DOWNLOAD');

  $self->log_httpresult();

  if ($args{file}) {
    $self->log("Saving to $args{file}");
    local *F;
    open F, "> $args{file}"
      or croak "Couldn't create '$args{file}' : $!";
    print F $agent->content
      or croak "Couldn't write to '$args{file}' : $!";
    close F
      or croak "Couldn't close '$args{file}' : $!";;
  };

  if ($agent->status == 200) {
    return Finance::Bank::Postbank_de::Account->parse_statement(content => $agent->content);
  } else {
    return wantarray ? () : undef;
  };
};

1;
__END__

=head1 NAME

Finance::Bank::Postbank_de - Check your Postbank.de bank account from Perl

=head1 SYNOPSIS

=for example begin

  use strict;
  use Finance::Bank::Postbank_de;
  my $account = Finance::Bank::Postbank_de->new(
                login => '9999999999',
                password => '11111',
                status => sub { shift;
                                print join(" ", @_),"\n"
                                  if ($_[0] eq "HTTP Code")
                                      and ($_[1] != 200)
                                  or ($_[0] ne "HTTP Code");

                              },
              );
  # Retrieve account data :
  my $retrieved_statement = $account->get_account_statement();
  print "Statement date : ",$retrieved_statement->balance->[0],"\n";
  print "Balance : ",$retrieved_statement->balance->[1]," EUR\n";

  # Output CSV for the transactions
  for my $row ($retrieved_statement->transactions) {
    print join( ";", map { $row->{$_} } (qw( tradedate valuedate type comment receiver sender amount ))),"\n";
  };

  $account->close_session;
  # See Finance::Bank::Postbank_de::Account for
  # a simpler example

=for example end

=for example_testing
  isa_ok($account,"Finance::Bank::Postbank_de");
  isa_ok($retrieved_statement,"Finance::Bank::Postbank_de::Account");
  $::_STDOUT_ =~ s!^Statement date : \d{8}\n!!m;
  my $expected = <<EOX;
New Finance::Bank::Postbank_de created
Connecting to https://banking.postbank.de/anfang.jsp
Logging into function ACCOUNTBALANCE
Getting account statement (default or only one there)
Downloading print version
Balance : 2500.00 EUR
20030520;20030520;GUTSCHRIFT;KINDERGELD                 KINDERGELD-NR 234568/133;ARBEITSAMT BONN;;154.00
20030520;20030520;ÜBERWEISUNG;FINANZKASSE 3991234        STEUERNUMMER 007 03434     EST-VERANLAGUNG 99;FINANZAMT KÖLN-SÜD;;-328.75
20030513;20030513;LASTSCHRIFT;RECHNUNG 03121999          BUCHUNGSKONTO 9876543210;TELEFON AG KÖLN;;-125.80
20030513;20030513;SCHECK;;EC1037406000003;;-511.20
20030513;20030513;LASTSCHRIFT;TEILNEHMERNUMMER 123456789 RUNDFUNK VON 1099 BIS 1299;GEZ KÖLN;;-84.75
20030513;20030513;LASTSCHRIFT;STROMKOSTEN                KD-NR 1462347              JAHRESABRECHNUNG;STADTWERKE MUSTERSTADT;;-580.06
20030513;20030513;INH.SCHECK;;2000123456789;;-100.00
20030513;20030513;SCHECKEINR;EINGANG VORBEHALTEN;GUTBUCHUNG 12345;;1830.00
20030513;20030513;DAUER ÜBERW;DA 100001;;MUSTERMANN, HANS;-31.50
20030513;20030513;GUTSCHRIFT;BEZÜGE                     PERSONALNUMMER 700600170/01;ARBEITGEBER U. CO;;2780.70
20030513;20030513;LASTSCHRIFT;MIETE 600,00 EUR           NEBENKOSTEN 250,00 EUR     OBJEKT 22/328              MUSTERPFAD 567, MUSTERSTADT;EIGENHEIM KG;;-850.00
Closing session
EOX
  $expected =~ s!\r\n!\n!gms;
  $::_STDOUT_ =~ s!\r\n!\n!gms;
  is($::_STDOUT_,'','Retrieving an account statement works');

=head1 DESCRIPTION

This module provides a rudimentary interface to the Postbank online banking system at
https://banking.postbank.de/. You will need either Crypt::SSLeay or IO::Socket::SSL
installed for HTTPS support to work with LWP.

The interface was cooked up by me without taking a look at the other Finance::Bank
modules. If you have any proposals for a change, they are welcome !

=head1 WARNING

This is code for online banking, and that means your money, and that means BE CAREFUL. You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself that I am not doing anything untoward with your banking data. This software is useful to me, but is provided under NO GUARANTEE, explicit or implied.

=head1 WARNUNG

Dieser Code beschaeftigt sich mit Online Banking, das heisst, hier geht es um Dein Geld und das bedeutet SEI VORSICHTIG ! Ich gehe
davon aus, dass Du den Quellcode persoenlich anschaust, um Dich zu vergewissern, dass ich nichts unrechtes mit Deinen Bankdaten
anfange. Diese Software finde ich persoenlich nuetzlich, aber ich stelle sie OHNE JEDE GARANTIE zur Verfuegung, weder eine
ausdrueckliche noch eine implizierte Garantie.

=head1 METHODS

=head2 new

Creates a new object. It takes three named parameters :

=over 4

=item login => '9999999999'

This is your account number.

=item password => '11111'

This is your PIN.

=item status => sub {}

This is an optional
parameter where you can specify a callback that will receive the messages the object
Finance::Bank::Postbank produces per session.

=back

=head2 $account->new_session

Closes the current session and logs in to the website using
the credentials given at construction time.

=head2 $account->close_session

Closes the session and invalidates it on the server.

=head2 $account->agent

Returns the C<WWW::Mechanize> object. You can retrieve the
content of the current page from there.

=head2 $account->select_function STRING

Selects a function. The two currently supported functions are C<accountstatement> and C<quit>.

=head2 $account->get_account_statement

Navigates to the print version of the account statement. The content can currently
be retrieved from the agent, but this will most likely change, as the print version
of the account statement is not a navigable page. The result of the function
is either undef or a Finance::Bank::Postbank_de::Account object.

=head2 session_timed_out

Returns true if our banking session timed out.

=head2 maintenance

Returns true if the banking interface is currently unavailable due to maintenance.

=head1 TODO:

  * Add even more runtime tests to validate the HTML
  * Streamline the site access to use even less bandwidth

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

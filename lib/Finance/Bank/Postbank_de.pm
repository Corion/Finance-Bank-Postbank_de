package Finance::Bank::Postbank_de;

use strict;
use warnings;
use Carp;
use base 'Class::Accessor';

use WWW::Mechanize;
use Finance::Bank::Postbank_de::Account;

use vars qw[ $VERSION ];

$VERSION = '0.23';

BEGIN {
  Finance::Bank::Postbank_de->mk_accessors(qw( agent login password ));
};

#use constant LOGIN => 'https://banking.postbank.de/app/welcome.do?prevNote=1';
use constant LOGIN => 'https://banking.postbank.de/app/welcome.do';

use vars qw(%functions);
BEGIN {
  %functions = (
    quit		=> qr'^Banking beenden$',
    accountstatement	=> qr'^Kontoums.*?tze$',
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
  my ($self) = @_;

  # Reset our user agent
  $self->close_session()
    if ($self->agent);

  my $result = $self->get_login_page(LOGIN);
  if($result == 200) {
    if ($self->maintenance) {
      $self->log("Status","Banking is unavailable due to maintenance");
      die "Banking unavailable due to maintenance";
    };
    my $agent = $self->agent();
    $agent->form("loginForm");
    eval {
      $agent->current_form->value( accountNumber => $self->login );
      #$agent->current_form->value( PNINumber => $self->password );
      $agent->current_form->value( pinNumber => $self->password );
    };
    if ($@) {
      warn $agent->content;
      croak $@;
    };
    $agent->submit;
    $self->log_httpresult();
    $result = $agent->status;

    if ($self->is_security_advice) {
      $self->skip_security_advice;
    };

  };
  $result;
};

sub get_login_page {
  my ($self,$url) = @_;
  $self->log("Connecting to $url");
  $self->agent(WWW::Mechanize->new( autocheck => 1, keep_alive => 1 ));

  my $agent = $self->agent();
  $agent->add_header("If-SSL-Cert-Subject" => qr'/C=DE/ST=NRW/L=Bonn/O=Deutsche Postbank AG/OU=Postbank Systems AG/OU=Terms of use at www\.verisign\.com/rpa \(c\)00');

  $agent->get(LOGIN);
  $self->log_httpresult();
  #warn $agent->res->header('Client-SSL-Cert-Subject');
  $agent->status;
};

sub is_security_advice {
  my ($self) = @_;
  $self->agent->content() =~ /\bZum\s+Finanzstatus\b/;
};

sub skip_security_advice {
  my ($self) = @_;
  $self->log('Skipping security advice page');
  $self->agent->follow(qr/\bZum\s+Finanzstatus\b/);
  # $self->agent->content() =~ /Sicherheitshinweis/;
};

sub error_page {
  # Check if an error page is shown (a page with much red on it)
  my ($self) = @_;
     $self->agent->content =~ m!<h3 class="h3Error">Es ist ein Fehler aufgetreten</h3>!sm
  or $self->maintenance;
};

sub error_message {
  my ($self) = @_;
  die "No error condition detected in:\n" . $self->agent->content
    unless $self->error_page;
  $self->agent->content =~ m!<p class="errorText">(.*?)</p>!sm
    or die "No error message found in:\n" . $self->agent->content;
  $1
};

sub maintenance {
  my ($self) = @_;
  #$self->error_page and
  $self->agent->content =~ m!Sehr geehrter <span lang="en">Online-Banking</span>\s+Nutzer,\s+wegen einer hohen Auslastung kommt es derzeit im Online-Banking zu\s*l&auml;ngeren Wartezeiten.!sm
  or $self->agent->content =~ m!&nbsp;Wartung\b!;
};

sub access_denied {
  my ($self) = @_;
  if ($self->error_page) {
    my $message = $self->error_message;

    return (
         $message =~ m!^Die Kontonummer ist nicht f�r das Internet Online-Banking freigeschaltet. Bitte verwenden Sie zur Freischaltung den Link "Online-Banking freischalten"\.<br />\s*$!sm
      or $message =~ m!^Sie haben zu viele Zeichen in das Feld eingegeben.<br />\s*$!sm
     #   $message =~ m!^\s*.*?\(anmeldung.login.accountNumber.ktonr-n-vorh.error\)<br />\s*$!sm
     #or $message =~ m!^\s*.*?\(anmeldung.login.accountNumber.checkMaxLen.error\)<br />\s*$!sm
    )
  } else {
    return;
  };
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

  $self->log( "Activating $functions{$function}" );
  $self->agent->follow_link( text_regex => $functions{$function})
    or do {
    };
  if ($self->session_timed_out) {
    $self->log("Session timed out");
    $self->agent(undef);
    $self->new_session();
    $self->agent->follow_link( text => $functions{$function});
  };
  $self->log_httpresult();
  $self->agent->status;
};

sub close_session {
  my ($self) = @_;
  my $result;
  if (not ($self->access_denied or $self->maintenance)) {
    $self->log("Closing session");
    $self->select_function('quit');
    $result = $self->agent->res->as_string =~ m!<p class="pHeadlineLeft"><span lang="en">Online-Banking</span> beendet</p>!sm
      #or warn $self->agent->content;
  } else {
    $result = 'Never logged in';
  };
  $self->agent(undef);
  $result;
};

sub account_numbers {
  my ($self,%args) = @_;
  $self->{account_numbers} ||= do {
    my @numbers;

    $self->log("Getting related account numbers");
    $self->select_function("accountstatement");
    $self->agent->form("kontoumsatzUmsatzForm");
    my $f = $self->agent->current_form;

    my $giro_input;
    if ($f) {
      $giro_input = $f->find_input('konto');
    };

    if (defined $giro_input) {
      if ($giro_input->type eq 'hidden') {
        @numbers = $giro_input->value();
        $self->log("Only one related account number found: @numbers");
      } else {
        @numbers = $giro_input->possible_values();
        $self->log( scalar(@numbers) . " related account numbers found: @numbers");
      }
    } else {
      # Find the single account number
      my $c = $self->agent->content;
      @numbers = ($c =~ /\?konto=(\d+)/g);
      if (! @numbers) {
        warn "No account number found!";
        warn $_ for ($c =~ /(konto)/imsg);
        $self->log("No related account numbers found");
      };
    };

    # Discard credit card numbers:
    @numbers = grep { /^\d{9,10}$/ } @numbers;
    \@numbers
  };
  @{ $self->{account_numbers} };
};

sub get_account_statement {
  my ($self,%args) = @_;

  $self->select_function("accountstatement");

  my $agent = $self->agent();

  $self->agent->form("kontoumsatzUmsatzForm");
  if (exists $args{account_number}) {
    $self->log("Getting account statement for $args{account_number}");
    $agent->current_form->param( konto => [ delete $args{account_number}]);
  } else {
    my @accounts = $agent->current_form->value('konto');
    $self->log("Getting account statement via default (@accounts)");
  };

  $agent->current_form->value('zeitraum','tage');
  $agent->current_form->param('tage',['90']);
  $self->log("Downloading text version");
  $agent->click('action');

  if ($agent->find_link(text_regex => qr'Download Kontoums.*?tze')) {
    $agent->follow_link(text_regex => qr'Download Kontoums.*?tze');
    $self->log_httpresult();
  } else {
    # keine Umsaetze
    $self->log("No transactions found");
    return ();
  };

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
    my $result = $agent->content;
    #warn $result;
    $agent->back;
    return Finance::Bank::Postbank_de::Account->parse_statement(content => $result);
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
  require Crypt::SSLeay; # It's a prerequisite
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
  $::_STDOUT_ =~ s!^Skipping security advice page\n!!m;
  my $expected = <<EOX;
New Finance::Bank::Postbank_de created
Connecting to https://banking.postbank.de/app/welcome.do
Activating (?-xism:^Kontoums.*?tze\$)
Getting account statement via default (9999999999)
Downloading text version
Statement date : ????????
Balance : 5314.05 EUR
.berweisung;111111/1000000000/37050198 FINANZKASSE 3991234 STEUERNUMMER 00703434;Finanzkasse K.ln-S.d;PETRA PFIFFIG;-328.75
.berweisung;111111/3299999999/20010020 .BERTRAG AUF SPARCARD 3299999999;Petra Pfiffig;PETRA PFIFFIG;-228.61
Gutschrift;BEZ.GE PERS.NR. 70600170/01 ARBEITGEBER U. CO;PETRA PFIFFIG;Petra Pfiffig;2780.70
.berweisung;DA 1000001;Verlagshaus Scribere GmbH;PETRA PFIFFIG;-31.50
Scheckeinreichung;EINGANG VORBEHALTEN GUTBUCHUNG 12345;PETRA PFIFFIG;Ein Fremder;1830.00
Lastschrift;MIETE 600+250 EUR OBJ22/328 SCHULSTR.7, 12345 MEINHEIM;Eigenheim KG;PETRA PFIFFIG;-850.00
Inh. Scheck;;2000123456789;PETRA PFIFFIG;-75.00
Lastschrift;TEILNEHMERNR 1234567 RUNDFUNK 0103-1203;GEZ;PETRA PFIFFIG;-84.75
Lastschrift;RECHNUNG 03121999;Telefon AG K�ln;PETRA PFIFFIG;-125.80
Lastschrift;STROMKOSTEN KD.NR.1462347 JAHRESABRECHNUNG;Stadtwerke Musterstadt;PETRA PFIFFIG;-580.06
Gutschrift;KINDERGELD KINDERGELD-NR. 1462347;PETRA PFIFFIG;Arbeitsamt Bonn;154.00
Closing session
Activating (?-xism:^Banking beenden\$)
EOX
  for ($::_STDOUT_,$expected) {
    s!\r\n!\n!gsm;
    s![\x80-\xff]!.!gsm;
    # Strip out all date references ...
    s/^\d{8};\d{8};//gm;
  };
  my @got = split /\n/, $::_STDOUT_;
  my @expected = split /\n/, $expected;
  is_deeply(\@got,\@expected,'Retrieving an account statement works')
    or do {
      diag "--- Got";
      diag $::_STDOUT_;
      diag "--- Expected";
      diag $expected;
    };

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

=head2 C<< $session->account_numbers >>

Returns the account numbers. Only numeric account numbers
are returned - the credit card account numbers are not
returned.

=head2 $account->select_function STRING

Selects a function. The currently supported functions are

	accountstatement
	quit

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

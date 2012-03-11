use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval {
  require 'LWP';
  # If we don't have LWP, it will be in the prerequisites of WWW::Mechanize anyway ...

  die "You don't seem to have SSL capability built into LWP.
Edit Makefile.PL if you want to install the module anyway"
    unless LWP::Protocol::implementor('https');
};

WriteMakefile(
    'NAME'    => 'Finance::Bank::Postbank_de',
    'VERSION_FROM'  => 'lib/Finance/Bank/Postbank_de.pm', # finds $VERSION
    'PREREQ_PM'    => { 'WWW::Mechanize' => 1.30,
                        'Test::More' => 0,
                        'Test::MockObject' => 0,
                        'Class::Accessor' => 0,
                        'MIME::Lite' => 3.00,
                        'List::Sliding::Changes' => 0.02,
                        'Encode' => 0, # for decoding the content and dealing with umlauts
                      }, # e.g., Module::Name => 1.1
    MIN_PERL_VERSION => 5.8, # 5.8 for Encode, 5.6 for the syntax
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Finance/Bank/Postbank_de.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),

    clean => { FILES => 'Finance-Bank-Postbank_de-*' },
);

# Now check whether we can create the synopsis inline tests
use vars qw($have_test_inline);
BEGIN {
  eval { require Test::Inline;
         $have_test_inline = $Test::Inline::VERSION ge '2.0'; };
  undef $@;
  if ($have_test_inline) {
    print "Good - you have Test::Inline\n";
  } else {
    print "Test::Inline is nice for testing the examples, but not necessary\n"
  };
};
BEGIN {
  eval { require List::Sliding::Changes };
  print "List::Sliding::Changes is nice for testing the examples, but not necessary\n"
   if $@;
};

if ($have_test_inline) {
    print "Generating embedded test files\n";
    require Test::Inline;
    my $Tests = Test::Inline->new(
          verbose  => 1,
          output   => 't',
    );
    $Tests->add_class('Finance::Bank::Postbank_de', recursive => 1 );
    $Tests->save();
};


use strict;

use vars qw( @modules );

BEGIN { @modules = qw(
  Finance::Bank::Postbank_de
  Finance::Bank::Postbank_de::Account
)};

use Test::More tests => scalar @modules;

sub test_module_pod {
  my $modulename;

  for $modulename (@_) {
    # We assume that we live in the t/ directory, and that our main module lives below t/../lib/
    my @modulepath = (File::Spec->splitpath($FindBin::Bin));
    pop @modulepath;
    push @modulepath, "lib",split /::/, $modulename;
    my $constructed_module_name = File::Spec->catfile(@modulepath) . ".pm";

    pop @modulepath;
    pod_ok($constructed_module_name);
  };
};

SKIP: {
  eval { require FindBin; FindBin->import() };
  skip "Need FindBin to check the Pod",scalar @modules if $@;
  eval { require File::Spec; File::SpecBase->import() };
  skip "Need File::Spec to check the Pod",scalar @modules if $@;
  eval { require Test::Pod; Test::Pod->import() };
  skip "Need Test::Pod to check the Pod",scalar @modules if $@;

  test_module_pod($_) for @modules;

  # make warnings.pm happy
  $FindBin::Bin eq $FindBin::Bin or 1;
};
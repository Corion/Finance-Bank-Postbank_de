sub form_ok {
  my ($mech, $name, @fields) = @_;
  my $result = 1;
  my $testname = "Form '$name' matches description";

  my @forms = $mech->forms();
  if (scalar(grep({ ($_->attr('name')||"") eq $name } @forms)) != 1) {
    diag $mech->content;
    diag "Form $name doesn't exist";
    diag $_->dump for @forms;
    return ok(0,$testname);
  };
  $mech->form_name($name);

  # Check that the expected form fields are available :
  my $field;
  for $field (@fields) {
    if (! defined $mech->current_form->find_input($field)) {
      undef $result;
      diag "Form field '$field' was not found in '$name'";
    };
  };
  
  diag $mech->current_form->dump
    unless $result;
  return ok($result, $testname);
};

1;

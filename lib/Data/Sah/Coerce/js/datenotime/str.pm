package Data::Sah::Coerce::js::datenotime::str;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::js::date::str';

1;
# ABSTRACT: Coerce datenotime from string

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This will simply use JavaScript's C<Date.parse()>, but will throw an error when
date is invalid.

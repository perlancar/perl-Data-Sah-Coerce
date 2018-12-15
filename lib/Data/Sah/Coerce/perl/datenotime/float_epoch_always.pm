package Data::Sah::Coerce::perl::datenotime::float_epoch_always;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::date::float_epoch_always';

1;
# ABSTRACT: Coerce datenotime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD",
this coercion rule precludes the
L<str_iso8601|Data::Sah::Coerce::perl::date::str_iso8601> coercion rule.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::datenotime::float_epoch>

L<Data::Sah::Coerce::perl::datenotime::str_iso8601>

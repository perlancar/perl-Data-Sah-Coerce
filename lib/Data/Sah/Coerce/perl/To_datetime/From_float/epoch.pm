package Data::Sah::Coerce::perl::To_datetime::From_float::epoch;

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::To_date::From_float::epoch';

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: Coerce datetime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD", we
only do this coercion if data is a number between 10^8 and 2^31.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_datetime::From_float::epoch_always>

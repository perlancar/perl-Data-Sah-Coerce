package Data::Sah::Coerce::perl::To_datenotime::From_float::Epoch;

# AUTHOR
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::To_date::From_float::Epoch';

1;
# ABSTRACT: Coerce datenotime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD", we
only do this coercion if data is a number between 10^8 and 2^31.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_datenotime::From_float::EpochAlways>

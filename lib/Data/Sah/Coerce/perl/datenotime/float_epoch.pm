package Data::Sah::Coerce::perl::datenotime::float_epoch;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::date::float_epoch';

1;
# ABSTRACT: Coerce datenotime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD", we
only do this coercion if data is a number between 10^8 and 2^31.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::datenotime::float_epoch_always>

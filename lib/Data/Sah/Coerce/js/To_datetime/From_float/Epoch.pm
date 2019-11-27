package Data::Sah::Coerce::js::To_datetime::From_float::Epoch;

# AUTHOR
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::js::To_date::From_float::Epoch';

1;
# ABSTRACT: Coerce datetime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with integer that contains "YYYY", "YYYYMM", or "YYYYMMDD",
we only do this coercion if data is an integer between 10^8 and 2^31.

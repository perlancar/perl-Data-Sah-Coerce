package Data::Sah::Coerce::js::To_datetime::From_str::DateParse;

# AUTHOR
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::js::To_date::From_str::DateParse';

1;
# ABSTRACT: Coerce datetime from string

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This will simply use JavaScript's C<Date.parse()>, but will throw an error when
date is invalid.

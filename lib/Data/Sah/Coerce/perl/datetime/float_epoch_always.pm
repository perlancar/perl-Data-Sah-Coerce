package Data::Sah::Coerce::perl::datetime::float_epoch_always;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::date::float_epoch_always';

no warnings 'redefine';
sub meta {
    +{
        v => 4,
        prio => 50,
        precludes => ['float_epoch'],
    };
}


1;
# ABSTRACT: Coerce datetime from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::datetime::float_epoch>

L<Data::Sah::Coerce::perl::datetime::str_iso8601>

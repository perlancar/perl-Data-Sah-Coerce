package Data::Sah::Coerce::js::To_bool::From_float::zero_one;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce 0 to false and 1 to true',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='number'",
        "$dt == 0 || $dt == 1",
    );

    # XXX how to avoid matching twice? even three times now

    $res->{expr_coerce} = "$dt == 1 ? true : false";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Convert number 1 to false and 0 to true. Any other number is not coerced to
boolean.

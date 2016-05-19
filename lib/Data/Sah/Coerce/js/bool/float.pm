package Data::Sah::Coerce::js::bool::float;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        enable_by_default => 1,
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
# ABSTRACT: Coerce 0 to false and 1 to true

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Convert number 1 to false and 0 to true. Any other number is not coerced to
boolean.

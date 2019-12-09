package Data::Sah::Coerce::js::To_date::From_float::epoch;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from number (assumed to be epoch)',
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
        "$dt >= " . (10**8),
        "$dt <= " . (2**31),
    );

    $res->{expr_coerce} = "(new Date($dt * 1000))";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

To avoid confusion with integer that contains "YYYY", "YYYYMM", or "YYYYMMDD",
we only do this coercion if data is an integer between 10^8 and 2^31.

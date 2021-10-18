package Data::Sah::Coerce::js::To_date::From_obj::date;

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from Date object',
        might_fail => 1, # we return error when date is invalid
        prio => 50,
    };
}

# AUTHORITY
# DATE
# DIST
# VERSION

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "($dt instanceof Date)",
    );

    $res->{expr_coerce} = "isNaN($dt) ? ['Invalid date', $dt] : [null, $dt]";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This is basically just to throw an error when date is invalid.

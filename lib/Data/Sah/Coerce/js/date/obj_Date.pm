package Data::Sah::Coerce::js::date::obj_Date;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        enable_by_default => 1,
        might_die => 1, # we throw exception date is invalid
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "($dt instanceof Date)",
    );

    $res->{expr_coerce} = "isNaN($dt) ? (throw new Error('Invalid date')) : $dt";

    $res;
}

1;
# ABSTRACT: Coerce date from Date object

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This is basically just to throw an error when date is invalid.

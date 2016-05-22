package Data::Sah::Coerce::js::duration::float_secs;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "(typeof($dt)=='number' || typeof($dt)=='string' && $dt.match(/^[0-9]+(?:\\.[0-9]+)?\$/))",
        "parseFloat($dt) >= 0", # we don't allow negative duration
        "!isNaN(parseFloat($dt))",
        "isFinite(parseFloat($dt))", # we don't allow infinite duration
    );

    $res->{expr_coerce} = "parseFloat($dt)";

    $res;
}

1;
# ABSTRACT: Coerce duration from number (assumed to be number of seconds)

=for Pod::Coverage ^(meta|coerce)$

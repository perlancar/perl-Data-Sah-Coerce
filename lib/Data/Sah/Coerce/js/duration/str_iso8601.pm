package Data::Sah::Coerce::js::duration::str_iso8601;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        enable_by_default => 1,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to};

    my $res = {};

    my $re_num = '[0-9]+(?:\\.[0-9]+)?';
    # js doesn't support /x flag, nor \A and \z. oh my
    #                                     #1=Y           #2=M(on)       #3=W           #4=D               #5=H           #6=M(in)       #7=S
    my $expr_re_match = "$dt.match(/^P(?:($re_num)Y)?(?:($re_num)M)?(?:($re_num)W)?(?:($re_num)D)?(?:T(?:($re_num)H)?(?:($re_num)M)?(?:($re_num)S)?)?\$/)";
    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        $expr_re_match,
    );

    # XXX i need a trick to avoid doing regex match twice

    # approximation
    $res->{expr_coerce} = "(function(_m) { _m = $expr_re_match; return ((_m[1]||0)*365.25*86400 + (_m[2]||0)*30.4375*86400 + (_m[3]||0)*7*86400 + (_m[4]||0)*86400 + (_m[5]||0)*3600 + (_m[6]||0)*60 + (_m[7]||0)) })()";

    $res;
}

1;
# ABSTRACT: Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

The format is:

 PnYnMnWnDTnHnMnS

Examples: "P1Y2M" (equals to "P14M", 14 months), "P1DT13M" (1 day, 13 minutes).

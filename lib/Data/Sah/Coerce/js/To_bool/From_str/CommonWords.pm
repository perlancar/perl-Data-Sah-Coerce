package Data::Sah::Coerce::js::To_bool::From_str::CommonWords;

# AUTHOR
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce from common true/false words (e.g. "true","yes","on" for true, and "false","no","off" to false)',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    my $re      = '/^(yes|no|true|false|on|off|1|0)$/i';
    my $re_true = '/^(yes|true|on|1)$/i';

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        "$dt.match($re)",
    );

    # XXX how to avoid matching twice? even three times now

    $res->{expr_coerce} = "(function(_m) { _m = $dt.match($re); return _m[1].match($re_true) ? true : false })()";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Convert some strings like "true", "yes", "on", "1" (matched case-insensitively)
to boolean true.

Convert "false", "no", "off", "0" (matched case-insensitively) to boolean false.

All other strings are not coerced to boolean.

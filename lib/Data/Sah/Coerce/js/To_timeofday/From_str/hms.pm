package Data::Sah::Coerce::js::To_timeofday::From_str::hms;

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
        summary => 'Coerce timeofday from string of the form hh:mm:ss',
        might_fail => 1, # we throw exception h:m:s is invalid
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        "($dt).match(/^([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2}(?:\\.[0-9]{1,9})?))?\$/)",
    );

    # note: (function(a,b,c){...})() is a trick to simulate lexical variables
    $res->{expr_coerce} = join(
        "",
        "(function (_m) { ",
        "  _m = ($dt).match(/^([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2}(?:\\.[0-9]{1,9})?))?\$/); ", # assume always match, because of expr_match
        "  _m[1] = parseInt(_m[1]);   if (_m[1] >= 24) { return ['Invalid hour '+_m[1]+', must be between 0-23'] } ",
        "  _m[2] = parseInt(_m[2]);   if (_m[2] >= 60) { return ['Invalid minute '+_m[2]+', must be between 0-59'] } ",
        "  _m[3] = _m[3] ? parseFloat(_m[3]) : 0; if (_m[3] >= 60) { return ['Invalid second '+_m[3]+', must be between 0-60'] } ",
        "  return [null, _m[1]*3600 + _m[2]*60 + _m[3]] ",
        "})()",
    );
    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

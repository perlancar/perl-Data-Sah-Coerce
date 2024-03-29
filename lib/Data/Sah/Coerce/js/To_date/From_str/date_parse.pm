package Data::Sah::Coerce::js::To_date::From_str::date_parse;

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
        summary => 'Coerce date from string using Date.parse()',
        might_fail => 1, # we throw exception date is invalid
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
    );

    # note: (function(a,b,c){...})() is a trick to simulate lexical variables
    $res->{expr_coerce} = "(function (_m) { _m = new Date($dt); if (isNaN(_m)) { return ['Invalid date', _m] } else { return [null, _m] } })()";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This will simply use JavaScript's C<Date.parse()>, but will throw an error when
date is invalid.

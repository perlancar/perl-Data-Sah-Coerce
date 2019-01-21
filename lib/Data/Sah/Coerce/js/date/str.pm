package Data::Sah::Coerce::js::date::str;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
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
    $res->{expr_coerce} = "(function (_m) { _m = new Date($dt); if (isNaN(_m)) { return ['Invalid date'] } else { return [null, _m] } })()";

    $res;
}

1;
# ABSTRACT: Coerce date from string

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This will simply use JavaScript's C<Date.parse()>, but will throw an error when
date is invalid.

package Data::Sah::Coerce::perl::bool::str;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "1",
    );

    $res->{expr_coerce} = "$dt =~ /\\A(yes|true|on)\\z/i ? 1 : $dt =~ /\\A(no|false|off|0)\\z/i ? '' : $dt";

    $res;
}

1;
# ABSTRACT: Convert "yes","true",etc to "1", and "no","false",etc to ""

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This is an optional rule (not enabled by default) that converts "true", "yes",
"on" (matched case-insensitively) to "1" and "false", "no", "off", "0" (matched
case-insensitively) to "". All other strings are left untouched.

This rule is not enabled because it is incompatible with Perl's notion of
true/false. Perl regards all non-empty string that isn't "0" (including "no",
"false", "off") as true.
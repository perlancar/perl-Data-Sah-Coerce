package Data::Sah::Coerce::perl::To_bool::From_str::common_words;

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
        summary => 'Convert common true/false words (e.g. "yes","true","on","1" to "1", and "no","false","off","0" to "")',
        prio => 50,
        args => {
            # mostly for testing of args
            ci => {
                schema => 'bool*',
                default => 1,
            },
        },
    };
}

sub coerce {
    my %cargs = @_;

    my $dt = $cargs{data_term};
    my $gen_args = $cargs{args} // {};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "1",
    );

    my $modifier = ($gen_args->{ci} // 1) ? "i" : "";
    $res->{expr_coerce} = "$dt =~ /\\A(yes|true|on)\\z/$modifier ? 1 : $dt =~ /\\A(no|false|off|0)\\z/$modifier ? '' : $dt";

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This coercion rule converts "true", "yes", "on" (matched case-insensitively) to
"1"; and "false", "no", "off", "0" (matched case-insensitively) to "". All other
strings are left untouched.

B<Note that this rule is incompatible with Perl's notion of true/false.> Perl
regards all non-empty string that isn't "0" (including "no", "false", "off") as
true. But this might be useful in CLI's or other places.

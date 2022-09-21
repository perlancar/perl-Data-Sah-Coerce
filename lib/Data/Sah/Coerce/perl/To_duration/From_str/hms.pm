package Data::Sah::Coerce::perl::To_duration::From_str::hms;

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
        summary => 'Coerce duration from string in the form of hh:mm:ss (or hh:mm)',
        might_fail => 1, # we match any (hh:mm:ss string, so the conversion might fail on invalid value)
        prio => 40, # higher than From_str::human
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2})(\\.[0-9]{1,9})?)?\\z/",
    );

    my $code_check = qq(if (\$1 > 23) { ["Invalid hour '\$1', must be between 0-23"] } elsif (\$2 > 59) { ["Invalid minute '\$2', must be between 0-59"] } elsif (defined \$3 && \$3 > 59) { ["Invalid second '\$3', must be between 0-59"] });

    if ($coerce_to eq 'float(secs)') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, \$1*3600 + \$2*60 + (defined \$3 ? \$3 : 0) + (defined \$4 ? \$4 : 0)] } });
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = qq(do { $code_check else { [undef, DateTime::Duration->new(hours => \$1, minutes => \$2, seconds => (defined \$3 ? \$3 : 0), nanoseconds => (defined \$4 ? \$4 * 1e9 : 0))] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use 'float(secs)' or 'DateTime::Duration'";
    }

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Duration can be coerced into one of: C<float(secs)> (number of seconds) or
C<DateTime::Duration> (L<DateTime::Duration> object).

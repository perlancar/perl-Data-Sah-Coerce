package Data::Sah::Coerce::perl::To_timeofday::From_str::HMS;

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
        summary => 'Coerce timeofday from string in the form of hh:mm:ss',
        might_fail => 1, # we match any (hh:mm:ss string, so the conversion might fail on invalid value)
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'str_hms';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2})(\.[0-9]{1,9})?)?\\z/",
    );

    my $code_check = qq(if (\$1 > 23) { ["Invalid hour '\$1', must be between 0-23"] } elsif (\$2 > 59) { ["Invalid minute '\$2', must be between 0-59"] } elsif (defined \$3 && \$3 > 59) { ["Invalid second '\$3', must be between 0-59"] });

    if ($coerce_to eq 'float') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, \$1*3600 + \$2*60 + (defined \$3 ? \$3 : 0) + (defined \$4 ? \$4 : 0)] } });
    } elsif ($coerce_to eq 'str_hms') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, defined(\$4) && \$4 > 0 ? sprintf("%02d:%02d:%s%.11g", \$1, \$2, (!defined(\$3) || \$3 < 10 ? "0":""), (defined \$3 ? \$3:0)+\$4) : sprintf("%02d:%02d:%02d", \$1, \$2, (defined \$3 ? \$3 : 0))] } });
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        $res->{modules}{"Date::TimeOfDay"} //= 0.002;
        $res->{expr_coerce} = qq([undef, Date::TimeOfDay->new(hour=>\$1, minute=>\$2, second=>(defined \$3 ? \$3 : 0), nanosecond=>(defined \$4 ? \$4*1e9 : 0))]);
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float, str_hms, or Date::TimeOfDay";
    }

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Timeofday can be coerced into one of: C<float> (seconds after midnight, e.g.
86399 is 23:59:59), C<str_hms> (string in the form of hh:mm:ss), or
C<Date::TimeOfDay> (an instance of L<Date::TimeOfDay> class).

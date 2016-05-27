package Data::Sah::Coerce::perl::duration::obj_DateTimeDuration;

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
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;

    $res->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('DateTime::Duration')",
    );

    if ($coerce_to eq 'float(secs)') {
        # approximation
        $res->{expr_coerce} = "($dt\->years * 365.25*86400 + $dt\->months * 30.4375*86400 + $dt\->weeks * 7*86400 + $dt\->days * 86400 + $dt\->hours * 3600 + $dt\->minutes * 60 + $dt\->seconds)";
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{expr_coerce} = $dt;
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from DateTime object

=for Pod::Coverage ^(meta|coerce)$

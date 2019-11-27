package Data::Sah::Coerce::perl::To_duration::From_float::Seconds;

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
        summary => 'Coerce duration from float (assumed to be number of seconds)',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\A[0-9]+(?:\.[0-9]+)\\z/",
    );

    if ($coerce_to eq 'float(secs)') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{'DateTime::Duration'} //= 0;
        $res->{expr_coerce} = "DateTime::Duration->new(seconds => $dt)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

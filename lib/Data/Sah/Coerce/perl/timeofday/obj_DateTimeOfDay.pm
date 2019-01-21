package Data::Sah::Coerce::perl::timeofday::obj_DateTimeOfDay;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'str_hms';

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;

    $res->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('Date::TimeOfDay')",
    );

    if ($coerce_to eq 'float') {
        $res->{expr_coerce} = "$dt\->float";
    } elsif ($coerce_to eq 'str_hms') {
        $res->{expr_coerce} = "$dt\->hms";
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        $res->{expr_coerce} = $dt;
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float, str_hms, or Date::TimeOfDay";
    }

    $res;
}

1;
# ABSTRACT: Coerce timeofday from Date::TimeOfDay object

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

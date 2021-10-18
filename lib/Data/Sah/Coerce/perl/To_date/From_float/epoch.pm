package Data::Sah::Coerce::perl::To_date::From_float::epoch;

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
        summary => 'Coerce date from number (assumed to be epoch)',
        prio => 50,
        precludes => [qr/\AFrom_float::epoch(.*)\z/],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\A[0-9]{8,10}(?:\.[0-9]+)?\\z/",
        "$dt >= 10**8",
        "$dt <= 2**31",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{DateTime} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt)";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{'Time::Moment'} //= 0;
        $res->{expr_coerce} = "Time::Moment->from_epoch($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT:

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This rule coerces date from a number that is assumed to be a Unix epoch. To
avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD", we
only do this coercion if data is a number between 10^8 and 2^31.

Hence, this rule has a Y2038 problem :-).


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_date::From_float::epoch_always>

package Data::Sah::Coerce::perl::To_date::From_obj::time_moment;

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
        summary => 'Coerce date from Time::Moment object',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;

    $res->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('Time::Moment')",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = "$dt\->epoch";
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{'DateTime'} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt\->epoch, time_zone => sprintf('%s%04d', $dt\->offset >= 0 ? '+':'-', abs(int($dt\->offset / 60)*100) + abs(int($dt\->offset % 60))))";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{expr_coerce} = $dt;
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

This rule coerces date from a L<Time::Moment> object. If C<coerce_to> is
"Time::Moment" that this rule does not do anything. Otherwise, it converts the
Time::Moment object to epoch (if C<coerce_to>="float(epoch)") or L<DateTime>
object (if C<coerce_to>="DateTime").

package Data::Sah::Coerce::perl::To_date::From_float::epoch_always_local;

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
        summary => 'Coerce date from number (all range assumed to be epoch) (local time zone)',
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
        "$dt =~ /\\A[0-9]+(?:\.[0-9]+)?\\z/",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{DateTime} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt, time_zone=>'local')";
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

This rule coerces date from number (which assumed to be epoch). If data is a
number and C<coerce_to> is "float(epoch)" (the default), then this rule does
nothing. If C<coerce_to> is "DateTime" or "Time::Moment" then this rule
instantiates the appropriate date object using the epoch value.

Additionally, this rule sets time zone to local.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_date::From_float::epoch_always>

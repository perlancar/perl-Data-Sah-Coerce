package Data::Sah::Coerce::perl::date::float_epoch_always;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
        precludes => ['float_epoch', 'str_iso8601'],
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
# ABSTRACT: Coerce date from number (assumed to be epoch)

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

This rule coerces date from number (which assumed to be epoch). If data is a
number and C<coerce_to> is "float(epoch)" (the default), then this rule does
nothing. If C<coerce_to> is "DateTime" or "Time::Moment" then this rule
instantiates the appropriate date object using the epoch value.

To avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD",
this coercion rule precludes the
L<str_iso8601|Data::Sah::Coerce::perl::date::str_iso8601> coercion rule.


=head1 SEE ALSO

L<Data::Sah::Coerce::perl::date::float_epoch>

L<Data::Sah::Coerce::perl::date::str_iso8601>

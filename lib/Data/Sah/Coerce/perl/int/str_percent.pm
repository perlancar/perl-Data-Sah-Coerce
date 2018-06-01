package Data::Sah::Coerce::perl::int::str_percent;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 0,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([+-]?\\d+)%\\z/",
    );

    $res->{expr_coerce} = "\$1/100";
    $res;
}

1;
# ABSTRACT: Coerce int from percent string (e.g. "100%")

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

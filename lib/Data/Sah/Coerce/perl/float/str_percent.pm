package Data::Sah::Coerce::perl::float::str_percent;

# DATE
# DIST
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

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([+-]?\\d+(?:\\.\\d*)?)%\\z/",
    );

    $res->{expr_coerce} = "\$1/100";
    $res;
}

1;
# ABSTRACT: Coerce float from percent string (e.g. "100.5%")

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

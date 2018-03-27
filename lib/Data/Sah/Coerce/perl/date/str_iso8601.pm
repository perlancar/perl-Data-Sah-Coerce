package Data::Sah::Coerce::perl::date::str_iso8601;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 1,
        might_die => 1, # we match any (YYYY-MM-DD... string, so the conversion to date might fail on invalid dates)
        prio => 50,
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
        #            1=Y        2=M        3=D          4="T" 5=h        6=m        7=s       8="Z"
        "$dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?:([T ])([0-9]{2}):([0-9]{2}):([0-9]{2})(Z?))?\\z/",
    );

    $res->{modules}{"Time::Local"} //= 0;

    my $code_epoch = '$4 ? ($8 ? Time::Local::timegm($7, $6, $5, $3, $2-1, $1-1900) : Time::Local::timelocal($7, $6, $5, $3, $2-1, $1-1900)) : Time::Local::timelocal(0, 0, 0, $3, $2-1, $1-1900)';
    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = $code_epoch;
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{"DateTime"} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $code_epoch, time_zone => \$8 ? 'UTC' : 'local')";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{"Time::Moment"} //= 0;
        $res->{expr_coerce} = "Time::Moment->from_epoch($code_epoch)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from (a subset of) ISO8601 string

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

Currently only the following formats are accepted:

 "YYYY-MM-DD"            ; # date (local time), e.g.: 2016-05-13
 "YYYY-MM-DDThh:mm:ss"   ; # date+time (local time), e.g.: 2016-05-13T22:42:00
 "YYYY-MM-DDThh:mm:ssZ"  ; # date+time (UTC), e.g.: 2016-05-13T22:42:00Z

 "YYYY-MM-DD hh:mm:ss"   ; # date+time (local time), MySQL format, e.g.: 2016-05-13 22:42:00
 "YYYY-MM-DD hh:mm:ssZ"  ; # date+time (UTC), MySQL format, e.g.: 2016-05-13 22:42:00Z

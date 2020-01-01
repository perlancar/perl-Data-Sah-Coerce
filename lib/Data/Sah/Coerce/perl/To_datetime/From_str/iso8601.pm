package Data::Sah::Coerce::perl::To_datetime::From_str::iso8601;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce datetime from (a subset of) ISO8601 string',
        might_fail => 1, # we match any (YYYY-MM-DD... string, so the conversion to date might fail on invalid dates)
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
        "$dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})([T ])([0-9]{2}):([0-9]{2}):([0-9]{2})(Z?)\\z/",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{modules}{"Time::Local"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = \$8 ? Time::Local::timegm(\$7, \$6, \$5, \$3, \$2-1, \$1-1900) : Time::Local::timelocal(\$7, \$6, \$5, \$3, \$2-1, \$1-1900) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{"DateTime"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = DateTime->new(year=>\$1, month=>\$2, day=>\$3, hour=>\$5, minute=>\$6, second=>\$7, time_zone => \$8 ? 'UTC' : 'local') };      my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{"Time::Moment"} //= 0;
        # XXX set offset=>... when $8 is not Z
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = Time::Moment->new(year=>\$1, month=>\$2, day=>\$3, hour=>\$5, minute=>\$6, second=>\$7, offset=>0) };                                    my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, \$time] } });
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

Currently only the following formats are accepted:

 "YYYY-MM-DDThh:mm:ss"   ; # date+time (local time), e.g.: 2016-05-13T22:42:00
 "YYYY-MM-DDThh:mm:ssZ"  ; # date+time (UTC), e.g.: 2016-05-13T22:42:00Z

 "YYYY-MM-DD hh:mm:ss"   ; # date+time (local time), MySQL format, e.g.: 2016-05-13 22:42:00
 "YYYY-MM-DD hh:mm:ssZ"  ; # date+time (UTC), MySQL format, e.g.: 2016-05-13 22:42:00Z

Note that if you set C<coerce_to> to C<float(epoch)>, you should not use dates
earlier than Unix epoch (Jan 1, 1970).

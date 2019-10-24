package Data::Sah::Coerce::perl::duration::str_human;

# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        might_fail => 1, # we feed most string to Time::Duration::Parse::AsHash which might croak when fed invalid string
        prio => 60,
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
        "$dt =~ /\\d.*[a-z]/",
    );

    $res->{modules}{"Time::Duration::Parse::AsHash"} //= 0;
    if ($coerce_to eq 'float(secs)') {
        # approximation
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, (\$p->{years}||0) * 365.25*86400 + (\$p->{months}||0) * 30.4375*86400 + (\$p->{weeks}||0) * 7*86400 + (\$p->{days}||0) * 86400 + (\$p->{hours}||0) * 3600 + (\$p->{minutes}||0) * 60 + (\$p->{seconds}||0)] } });
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, DateTime::Duration->new( (years=>\$p->{years}) x !!defined(\$p->{years}), (months=>\$p->{months}) x !!defined(\$p->{months}), (weeks=>\$p->{weeks}) x !!defined(\$p->{weeks}), (days=>\$p->{days}) x !!defined(\$p->{days}), (hours=>\$p->{hours}) x !!defined(\$p->{hours}), (minutes=>\$p->{minutes}) x !!defined(\$p->{minutes}), (seconds=>\$p->{seconds}) x !!defined(\$p->{seconds}))] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT: Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")

=for Pod::Coverage ^(meta|coerce)$

=head1 DESCRIPTION

The human notation is parsed using L<Time::Duration::Parse::AsHash>.

package Data::Sah::CoerceJS;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::Any::IfLOG '$log';

use Data::Sah::Util::JS qw(get_nodejs_path);

use Exporter qw(import);
our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

my $rule_modules_cache;
sub _list_rule_modules {
    return $rule_modules_cache if $rule_modules_cache;
    require PERLANCAR::Module::List;
    my $prefix = "Data::Sah::Coerce::js::";
    my $mods = PERLANCAR::Module::List::list_modules(
        $prefix, {list_modules=>1, recurse=>1},
    );
    $rule_modules_cache = $mods;
    $mods;
}

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate Perl code to execute JavaScript coercer',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
`Data::Sah`.

_
    args => {
        type => {
            schema => 'str*', # XXX sah::typename
            req => 1,
            pos => 0,
        },
        coerce_to => {
            schema => 'str*',
        },
        coerce_from => {
            schema => ['array*', of=>'str*'],
        },
        dont_coerce_from => {
            schema => ['array*', of=>'str*'],
        },
        source => {
            summary => 'If set to true, will return coercer source code string'.
                ' instead of compiled code',
            schema => 'bool',
        },
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $type = $args{type};

    my $all_mods = _list_rule_modules();

    my $typen = $type; $typen =~ s/::/__/g;
    my $prefix = "Data::Sah::Coerce::js::$typen\::";
    my @rules;
    for my $mod (keys %$all_mods) {
        next unless $mod =~ /\A\Q$prefix\E(.+)/;
        push @rules, $1;
    }
    my %explicitly_included_rules;
    for my $rule (@{ $args{coerce_from} // [] }) {
        push @rules, $rule unless grep {$rule eq $_} @rules;
        $explicitly_included_rules{$rule}++;
    }
    if ($args{dont_coerce_from} && @{ $args{dont_coerce_from} }) {
        my @frules;
        for my $rule (@rules) {
            next if grep {$rule eq $_} @{ $args{dont_coerce_from} };
            push @frules, $rule;
        }
        @rules = @frules;
    }
    @rules = sort @rules;

    return sub { $_[0] } unless @rules;

    my @res;
    for my $rule (@rules) {
        my $mod = "$prefix$rule";
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        next unless $explicitly_included_rules{$rule} ||
            &{"$mod\::meta"}->{enable_by_default};
        my $res = &{"$mod\::coerce"}(
            data_term => 'data',
            coerce_to => $args{coerce_to},
        );
        push @res, $res;
    }
    last unless @rules;

    my $expr;
    for my $i (reverse 0..$#res) {
        my $res = $res[$i];
        if ($i == $#res) {
            $expr = "$res->{expr_match} ? $res->{expr_coerce} : data";
        } else {
            $expr = "$res->{expr_match} ? $res->{expr_coerce} : ($expr)";
        }
    }

    my $coercer = join(
        "",
        "function (data) {\n",
        "    if (data === undefined || data === null) return null;\n",
        "    return ($expr);\n",
        "}",
    );
    if ($Log_Coercer_Code) {
        $log->tracef("Coercer code (gen args: %s): %s", \%args, $coercer);
    }

    return $coercer if $args{source};

    state $nodejs_path = get_nodejs_path();
    die "Can't find node.js in PATH" unless $nodejs_path;

    sub {
        require File::Temp;
        require JSON::MaybeXS;
        #require String::ShellQuote;

        my $data = shift;

        state $json = JSON::MaybeXS->new->allow_nonref;

        # code to be sent to nodejs
        my $src = "var coercer = $coercer;\n\n".
            "console.log(JSON.stringify(coercer(".
                $json->encode($data).")))";

        my ($jsh, $jsfn) = File::Temp::tempfile();
        print $jsh $src;
        close($jsh) or die "Can't write JS code to file $jsfn: $!";

        my $cmd = "$nodejs_path $jsfn";
        my $out = `$cmd`;
        $json->decode($out);
    };
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Data::Sah::CoerceJS qw(gen_coercer);

 # use as you would use Data::Sah::Coerce


=head1 DESCRIPTION

This module is just like L<Data::Sah::Coerce> except that it uses JavaScript
coercion rule modules.


=head1 VARIABLES

=head2 $Log_Coercer_Code => bool (default: from ENV or 0)

If set to true, will log the generated coercer code (currently using L<Log::Any>
at trace level). To see the log message, e.g. to the screen, you can use
something like:

 % TRACE=1 perl -MLog::Any::Adapter=Screen -MData::Sah::CoerceJS=gen_coercer \
     -E'my $c = gen_coercer(...)'


=head1 ENVIRONMENT

=head2 LOG_SAH_COERCER_CODE => bool

Set default for C<$Log_Coercer_Code>.


=head1 SEE ALSO

L<Data::Sah::Coerce>

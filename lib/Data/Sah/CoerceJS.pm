package Data::Sah::CoerceJS;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Data::Sah::CoerceCommon;
use Nodejs::Util qw(get_nodejs_path);

use Exporter qw(import);
our @EXPORT_OK = qw(gen_coercer);

our %SPEC;

our $Log_Coercer_Code = $ENV{LOG_SAH_COERCER_CODE} // 0;

$SPEC{gen_coercer} = {
    v => 1.1,
    summary => 'Generate coercer code',
    description => <<'_',

This is mostly for testing. Normally the coercion rules will be used from
`Data::Sah`.

_
    args => {
        %Data::Sah::CoerceCommon::gen_coercer_args,
    },
    result_naked => 1,
};
sub gen_coercer {
    my %args = @_;

    my $rt = $args{return_type} // 'val';
    my $rt_sv = $rt eq 'str+val';

    my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
        %args,
        compiler=>'js',
        data_term=>'data',
    );

    my $code;
    if (@$rules) {
        my $expr;
        for my $i (reverse 0..$#{$rules}) {
            my $rule = $rules->[$i];
            if ($i == $#{$rules}) {
                if ($rt_sv) {
                    $expr = "($rule->{expr_match}) ? [\"$rule->{name}\", $rule->{expr_coerce}] : [null, data]";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : data";
                }
            } else {
                if ($rt_sv) {
                    $expr = "($rule->{expr_match}) ? [\"$rule->{name}\", $rule->{expr_coerce}] : ($expr)";
                } else {
                    $expr = "($rule->{expr_match}) ? ($rule->{expr_coerce}) : ($expr)";
                }
            }
        }

        $code = join(
            "",
            "function (data) {\n",
            ($rt_sv ?
                 "    if (data === undefined || data === null) return [null, null];\n" :
                 "    if (data === undefined || data === null) return null;\n"
             ),
            "    return ($expr);\n",
            "}",
        );
    } else {
        if ($rt_sv) {
            $code = 'function (data) { return [null, data] }';
        } else {
            $code = 'function (data) { return data }';
        }
    }

    if ($Log_Coercer_Code) {
        $log->tracef("Coercer code (gen args: %s): %s", \%args, $code);
    }

    return $code if $args{source};

    state $nodejs_path = get_nodejs_path();
    die "Can't find node.js in PATH" unless $nodejs_path;

    sub {
        require File::Temp;
        require JSON::MaybeXS;
        #require String::ShellQuote;

        my $data = shift;

        state $json = JSON::MaybeXS->new->allow_nonref;

        # code to be sent to nodejs
        my $src = "var coercer = $code;\n\n".
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

L<App::SahUtils>, including L<coerce-with-sah> to conveniently test coercion
from the command-line.

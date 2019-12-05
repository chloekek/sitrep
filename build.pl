use strict;
use warnings;

use List::Util qw(uniqstr);
use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

my $sitrepd = Snowflake::Rule->new(
    name         => 'sitrepd',
    dependencies => [],
    sources      => {
        # TODO: Only include source files here, not readmes.
        'src' => ['on_disk', 'src'],
        'snowflake-build' => bash_strict(<<'BASH'),
            shopt -s globstar

            # ldc wants us to prefix each linker flag with ‘-L’,
            # so that is what we do.
            ldc_linker_flags=()
            for linker_flag in $(pkg-config --libs libzmq); do
                ldc_linker_flags+=("-L" "$linker_flag")
            done

            # Compile the source files and link them with the libraries.
            ldc2 \
                -of snowflake-output \
                "${ldc_linker_flags[@]}" \
                src/**/*.d
BASH
    },
);

my $mind_map = Snowflake::Rule->new(
    name         => 'Mind map',
    dependencies => [],
    sources      => {
        'mind_map.gv.m4' => ['on_disk', 'doc/mind_map.gv'],
        'snowflake-build' => bash_strict(<<'BASH'),
            mkdir snowflake-output
            m4 --prefix-builtins mind_map.gv.m4 > mind_map.gv
            sfdp -Tsvg -osnowflake-output/mind_map.svg mind_map.gv
BASH
    },
);

my %artifacts = (
    mind_map => $mind_map,
    sitrepd => $sitrepd,
);

%artifacts;

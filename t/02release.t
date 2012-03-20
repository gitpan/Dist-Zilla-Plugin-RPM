#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    use File::Which qw(which);

    if (!which('rpmbuild')) {
        plan skip_all => q{rpmbuild not installed, this module isn't very interesting without it};
        exit(0);
    }
}

use Test::DZil qw(Builder simple_ini);

local $ENV{DZIL_PLUGIN_RPM_TEST} = 1;

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'RPM'
                ),
            },
        },
    );
    $tzil->release;

    ok(
        grep({ /test: would have executed rpmbuild -ba/ } @{ $tzil->log_messages }),
        "basic rpmbuild execution",
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ['RPM' => {
                        sign => 1
                    }],
                ),
            },
        },
    );
    $tzil->release;

    ok(
        grep({ /test: would have executed rpmbuild -ba --sign/ } @{ $tzil->log_messages }),
        "sign option",
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ['RPM' => {
                        ignore_build_deps => 1
                    }],
                ),
            },
        },
    );
    $tzil->release;

    ok(
        grep({ /test: would have executed rpmbuild -ba --nodeps/ } @{ $tzil->log_messages }),
        "ignore_build_deps option",
    );
}

done_testing;


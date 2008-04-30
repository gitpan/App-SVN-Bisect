#!/usr/bin/perl
use Module::Build;
Module::Build->new(
    requires           => {
        perl           => '5.8.0',
        # required modules that ship with perl-5.8.0
        # Carp         => 0,
        # Getopt::Long => 0,
        # File::Spec   => 0,

        IO::All        => 0,
        YAML           => 0,
    },
    module_name        => 'App::SVN::Bisect',
    license            => 'artistic_2',
    script_files       => [qw(svn-bisect)],
    create_makefile_pl => 'traditional',
    dist_author        => 'Mark Glines <mark@glines.org>',
    dist_version_from  => 'lib/App/SVN/Bisect.pm',
    dist_abstract      => 'tool to perform binary searches on SVN checkouts',
)->create_build_script;

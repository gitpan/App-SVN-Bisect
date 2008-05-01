use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
use App::SVN::Bisect;
use File::Spec::Functions;

my $tests;
BEGIN { $tests = 0; };
plan tests => $tests;

my $tempdir = tempdir( CLEANUP => 1 );
chdir($tempdir);
mkdir(".svn");

package test;
use Test::More;
our @ISA = qw(App::SVN::Bisect);
sub run {
    my ($self, $cmd) = @_;
    $$self{cmds} = [] unless exists $$self{cmds};
    push(@{$$self{cmds}}, $cmd);
    return $$self{rvs}{$cmd} if exists $$self{rvs}{$cmd};
    return '';
}

sub stdout {
    my ($self, @lines) = @_;
    my $text = join("", @lines);
    @lines = split(/[\r\n]+/, $text);
    $$self{stdout} = [] unless exists $$self{stdout};
    push(@{$$self{stdout}}, @lines);
}

sub verbose { &stdout }

package main;

my $test_responses = {
    "svn info" => <<EOF,
Blah: foo
Revision: 17
Last Changed Rev: 16
Bar: baz
EOF
    "svn log -q -rHEAD:PREV" => <<EOF,
------------------------------------------------------------------------
r31 | foo | 2008-05-01 04:34:41 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r24 | bar | 2008-05-01 04:01:17 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r18 | baz | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r16 | quux | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r15 | bing | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
EOF
    "svn log -q -r0:31" => <<EOF,
------------------------------------------------------------------------
r31 | foo | 2008-05-01 04:34:41 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r24 | bar | 2008-05-01 04:01:17 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r18 | baz | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r16 | quux | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r15 | bing | 2008-05-01 03:08:32 -0700 (Thu, 01 May 2008)
------------------------------------------------------------------------
r12 | bing | 2008-04-01 03:08:32 -0700 (Thu, 01 Apr 2008)
------------------------------------------------------------------------
r8 | bob | 2008-04-01 03:08:31 -0700 (Thu, 01 Apr 2008)
------------------------------------------------------------------------
r1 | bob | 2008-04-01 03:08:30 -0700 (Thu, 01 Apr 2008)
------------------------------------------------------------------------
EOF
};

# so, the initial revspace is: (1 8 12 15 16 18 24 31)

# test default args
my $bisect = test->new(Action => "start", Min => 0, Max => undef);
ok(defined($bisect), "new() returns an object");
is(ref($bisect), "test", "new() blesses object into specified class");
ok(!-f catfile(".svn", "bisect.yaml"), "metadata file not created yet");
BEGIN { $tests += 3; };

# run the "start" method
$$bisect{rvs} = $test_responses;
$bisect->do_something_intelligent();
ok(-f catfile(".svn", "bisect.yaml"), "metadata file created");
is($$bisect{config}{max}, 31, "biggest svn revision was autodetected");
is($$bisect{config}{min}, 0 , "minimum is 0 by default");
is($$bisect{config}{orig},16, "Last Changed Rev: is preferred over Revision:");
is($$bisect{config}{cur}, 15, "first step: test r15");
is(scalar @{$$bisect{stdout}}, 1, "1 line written");
like($$bisect{stdout}[0], qr/Choosing r15/, "Choosing r15");
BEGIN { $tests += 7; };

# if I keep running "after", the result should be 1
$bisect = test->new(Action => "after", Min => 0, Max => undef);
$$bisect{rvs} = $test_responses;
$bisect->do_something_intelligent();
is($$bisect{config}{cur}, 8, "next step: test r8");
is(scalar @{$$bisect{stdout}}, 1, "1 line written");
like($$bisect{stdout}[0], qr/Choosing r8/, "Choosing r8");
BEGIN { $tests += 3; };

$bisect = test->new(Action => "after", Min => 0, Max => undef);
$$bisect{rvs} = $test_responses;
$bisect->do_something_intelligent();
is($$bisect{config}{cur}, 1, "next step: test r1");
is(scalar @{$$bisect{stdout}}, 1, "1 line written");
like($$bisect{stdout}[0], qr/Choosing r1/, "Choosing r1");
BEGIN { $tests += 3; };

# test the "reset" method
ok(-f catfile(".svn", "bisect.yaml"), "metadata file still exists");
$bisect = test->new(Action => "reset", Min => 0, Max => undef);
$$bisect{rvs} = $test_responses;
$bisect->do_something_intelligent();
ok(!defined $$bisect{stdout}, "no output");
ok(!-f catfile(".svn", "bisect.yaml"), "metadata file removed");
BEGIN { $tests += 3; };

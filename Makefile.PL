
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Build an RPM from your Dist::Zilla release",
  "AUTHOR" => "Stephen Clouse <stephenclouse\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::DZil" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-RPM",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::Plugin::RPM",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Dist::Zilla" => 0,
    "Dist::Zilla::App" => 0,
    "File::Temp" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Path::Class" => 0,
    "Text::Template" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




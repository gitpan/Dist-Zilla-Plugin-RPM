package Dist::Zilla::Plugin::RPM;
# ABSTRACT: Build an RPM from your Dist::Zilla release

use Moose;
use Moose::Autobox;
use namespace::autoclean;

our $VERSION = '0.001'; # VERSION

with 'Dist::Zilla::Role::Releaser',
     'Dist::Zilla::Role::FilePruner';

has spec_file => (
    is      => 'ro',
    isa     => 'Str',
    default => 'build/dist.spec',
);

has sign => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

use Carp;
use File::Temp ();
use Text::Template ();

sub prune_files {
    my($self) = @_;
    my $spec = $self->spec_file;
    for my $file ($self->zilla->files->flatten) {
        if ($file->name eq $self->spec_file) {
            $self->zilla->prune_file($file);
        }
    }
    return;
}

sub release {
    my($self,$archive) = @_;

    my $t = Text::Template->new(
        TYPE       => 'FILE',
        SOURCE     => $self->spec_file,
        DELIMITERS => [ '<%', '%>' ],
    ) || $self->log_fatal($Text::Template::ERROR);
    my $spec = $t->fill_in(
        HASH => {
            zilla   => \($self->zilla),
            archive => \$archive,
        },
    ) || $self->log_fatal($Text::Template::ERROR);
    my $tmp = File::Temp->new();
    $tmp->print($spec);
    $tmp->flush;

    my $sourcedir = qx/rpm --eval '%{_sourcedir}'/
        or $self->log_fatal(q{couldn't determine RPM sourcedir});
    $sourcedir =~ s/[\r\n]+$//;
    $sourcedir .= '/';
    system('cp',$archive,$sourcedir)
        && $self->log_fatal('cp failed');

    my @cmd = qw/rpmbuild -ba/;
    push @cmd, qw/--sign/ if $self->sign;
    push @cmd, $tmp->filename;

    system(@cmd) && $self->log_fatal('rpmbuild failed');

    return;
}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::RPM - Build an RPM from your Dist::Zilla release

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your dist.ini:

    [RPM]
    spec_file = build/dist.spec
    sign = 1

=head1 DESCRIPTION

This plugin is a Releaser for Dist::Zilla that builds an RPM of your
distribution.

=head1 ATTRIBUTES

=over

=item spec_file

The spec file to use to build the RPM.  The default is "build/dist.spec".

The spec file is run through L<Text::Template|Text::Template> before calling
rpmbuild, so you can substitute values from Dist::Zilla into the final output.
The template uses <% %> tags (like L<Mason|Mason>) as delimiters to avoid
conflict with standard spec file markup.

Two variables are available in the template:

=over

=item $zilla

The main Dist::Zilla object

=item $archive

The filename of the release tarball

=back

=item sign

If set to a true value, rpmbuild will be called with the --sign option.

=back

=head1 SAMPLE SPEC FILE TEMPLATE

    Name: <% $zilla->name %>
    Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
    Release: 1
    
    Summary: <% $zilla->abstract %>
    Copyright: <% $zilla->license->holder %>
    Group: Applications/CPAN
    BuildArch: noarch
    URL: <% $zilla->license->url %>
    Vendor: <% $zilla->license->holder %>
    Source: <% $archive %>
    
    BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
    
    %description
    <% $zilla->abstract %>
    
    %prep
    %setup -q
    
    %build
    perl Makefile.PL
    make test
    
    %install
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    make install DESTDIR=%{buildroot}
    find %{buildroot} | sed -e 's#/home/sclouse/devel/CCI-Schema-MORE##' > %{_tmppath}/filelist    
    
    %clean
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    
    %files -f %{_tmppath}/filelist
    %defattr(-,root,root)

=head1 SEE ALSO

L<Dist::Zilla|Dist::Zilla>

=head1 AUTHOR

Stephen Clouse <stephenclouse@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Stephen Clouse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


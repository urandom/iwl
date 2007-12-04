#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Static;

use strict;

use base 'IWL::RPC';

use IWL::Response;
use IWL::Config '%IWLConfig';

use Locale::TextDomain qw(org.bloka.iwl);

use constant MAX_DEPTH => 64;

=head1 NAME

IWL::Static - a Static file handler

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::RPC> -> L<IWL::Static>

=head1 DESCRIPTION

IWL::Static provides a simple method for serving static content to a server

=head1 CONSTRUCTOR

IWL::Static->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values. See L<IWL::RPC> for supported parameters

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(%args);

    $self->__init;

    return $self;
}

=head1 METHODS

=over 4

=item B<addPath> (B<PATH> => B<RECURSIVE>, ...)

Adds a path for static content to the list of known paths

Parameters: B<PATH> - a path, can be either a path to a directory, or a file, or a list of those, B<RECURSIVE> - if the path is a directory, whether to to add all of its children

I<Note:> An initial list of known paths is obtained from a colon (':') separated list of paths in the I<STATIC_PATHS> config parameter of L<IWL::Config>, as well as the installation paths for IWL's own static content

=cut

sub addPath {
    my ($self, %path) = @_;

    foreach my $path (keys %path) {
        next unless -f $path || -d $path;

        $path =~ s{/+}{/}g;
        $path .= '/' if -d $path && substr($path, -1) ne '/';
        $self->{_staticPaths}{$path} = 1;
        next if -f $path;
        $self->__recursiveScan($path, 0) if $path{$path};
    }
    return $self;
}

=item B<handleRequest> (B<%OPTIONS>)

Handles static file requests by checking whether the user script is invoked with a request for certain file, and if the file exists in one of the predefined static paths, its contents are sent back to the server

Parameters: B<%OPTIONS> - a hash of options. The following key-pairs are recognised:

=over 8

=item B<header>

An optional header hashref, which will overwrite the default header parameters

=item B<mimeType>

An optional string or coderef. If the value is a string, it will be used as the content's mime type. If the value is a coderef, it will be called with the path as its parameter, and its return value will be used as a mime type for the content

=back

=cut

sub handleRequest {
    my ($self, %options) = @_;
    my %form = $self->getParams;
    my $path = $form{IWLStaticPath};
    return unless $path;

    $path =~ s{/+}{/}g;
    require File::Spec;
    unless ($self->{_staticPaths}{$path}) {
        my (undef, $directory, undef) = File::Spec->splitpath($path);
        return $self->_pushError(
            __x("The path '{PATH}' does not belong in the predefined list of static paths.", PATH => $path))
          unless $self->{_staticPaths}{$directory};
    }

    local *DATA;
    open DATA, $path or return $self->_pushError($!);
    local $/;
    my $content = <DATA>;
    close DATA;
    my $modtime = (stat $path)[9];
    my $mime = ref $options{mimeType} eq 'CODE' ? $options{mimeType}->($path) : ($options{mimeType} || $self->__getMime($path));
    my $header = {
        'Content-type'   => $mime,
        'Content-length' => length($content),
        'Last-Modified'  => time2str($modtime),
        'ETag'           => $modtime + (-s $path),
    };
    $header->{$_} = $options{header}{$_} foreach keys %{$options{header} || {}};

    IWL::Response->new->send(header => $header, content => $content);

    return $self;
}

# Internal
#
sub __init {
    my $self = shift;

    $self->{_staticPaths} = {};

    my @path = @IWLConfig{qw(JS_DIR SKIN_DIR IMAGE_DIR ICON_DIR)};
    push @path, (split ':', $IWLConfig{STATIC_PATHS}) if $IWLConfig{STATIC_PATHS};
    $self->addPath({map {$_ => 1} @path});
}

sub __recursiveScan {
    my ($self, $path, $count) = @_;
    return if $count++ == MAX_DEPTH;

    local *DIR;
    opendir DIR, $path
      or $self->_pushError(
        __x("Cannot open directory {PATH}: {ERR}", PATH => $path, ERR => $!)
      );
    my @children = grep { !/^\./ && -d $path . '/' . $_ } readdir DIR;
    closedir DIR;

    foreach (@children) {
        my $child = $path . '/' . $_;
        $child =~ s{/+}{/}g;
        $child .= '/' if substr($child, -1) ne '/';
        next if $self->{_staticPaths}{$child};
        $self->{_staticPaths}{$child} = 1;
        $self->__recursiveScan($child, $count);
    }
}

sub __getMime {
    my ($self, $path) = @_;
    return (substr $path, -4  eq '.css')   ? 'text/css; charset=utf-8'
         : (substr $path, -5  eq '.html')  ? 'text/html; charset=utf-8'
         : (substr $path, -4  eq '.xml')   ? 'text/xml; charset=utf-8'
         : (substr $path, -3  eq '.js')    ? 'text/javascript; charset=utf-8'
         : (substr $path, -4  eq '.jpg')   ? 'image/jpeg'
         : (substr $path, -4 eq '.gif')    ? 'image/gif'
         : (substr $path, -4 eq '.tif')    ? 'image/tiff'
         : (substr $path, -4 eq '.png')    ? 'image/png'
         : (substr $path, -5 eq '.json')   ? 'application/json'
         : (substr $path, -6 eq '.xhtml')  ? 'application/xhtml+xml'
         : 'application/octet-stream';
}

## From HTTP::Date ##
sub time2str (;$) {
    my $time = shift;
    $time = time unless defined $time;
    my @DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	    $DoW[$wday],
	    $mday, $MoY[$mon], $year+1900,
	    $hour, $min, $sec);
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

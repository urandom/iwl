#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Static;

use strict;

use base 'IWL::RPC';

use IWL::Response;
use IWL::Config '%IWLConfig';

use File::Spec;
use Locale::TextDomain qw(org.bloka.iwl);

use constant MAX_DEPTH => 64;

=head1 NAME

IWL::Static - a Static file handler

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::RPC> -> L<IWL::Static>

=head1 DESCRIPTION

IWL::Static provides a simple method for serving static content to a server

=head1 SYNOPSIS

In order to serve static content through I<IWL::Static>, a few steps must be taken.

To use I<IWL::Static> static internally, either the I<STATIC_URI_SCRIPT>, or I<STATIC_LABEL> configuration options must be set in your iwl.conf file. The I<STATIC_URI_SCRIPT> option points to the script, which will serve the static content. The I<DOCUMENT_ROOT> option should also be set, unless the files to be served use relative URIs (the IWL static files use absolute URIs). If the user wants to include more URIs, along with the default IWL ones, the I<STATIC_URIS> option must also be set.

The Perl script, which is referenced by I<STATIC_URI_SCRIPT>, will have the following code in its most simplest form:
 
 #! /usr/bin/perl
 use IWL::Static;

 IWL::Static->new->handleRequest;

This simple script will fetch all required content, which is inside the I<STATIC_URIS>, as well as the default IWL static content, and will send it to the server with the appropriate header.

If the I<STATIC_LABEL> option is set to a true value, the static content files will be labeled with a unique GET parameter, and the web server will be responsible for serving them.

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

=item B<addURI> (B<URI> => B<RECURSIVE>, ...)

Adds a URI for static content to the list of known URIs

Parameters: B<URI> - a URI, can be either a URI to a directory, or a file, or a list of those, B<RECURSIVE> - if the URI is a directory, whether to to add all of its children

I<Note:> An initial list of known URIs is obtained from a colon (':') separated list of URIs in the I<STATIC_URIS> config parameter of L<IWL::Config>, as well as the installation URIs for IWL's own static content

=cut

sub addURI {
    my ($self, %uri) = @_;

    foreach my $uri (keys %uri) {
        my $recursive = $uri{$uri};
        $uri = File::Spec->join($IWLConfig{DOCUMENT_ROOT}, $uri)
          if substr($uri, 0, 1) eq '/' && $IWLConfig{DOCUMENT_ROOT};
        next unless -f $uri || -d $uri;

        $uri =~ s{/+}{/}g;
        $uri .= '/' if -d $uri && substr($uri, -1) ne '/';
        $self->{_staticURIs}{$uri} = 1;
        next if -f $uri;
        $self->__recursiveScan($uri, 0) if $recursive;
    }
    return $self;
}

=item B<handleRequest> (B<%OPTIONS>)

Handles static file requests by checking whether the user script is invoked with a request for certain file, and if the file exists in one of the predefined static URIs, its contents are sent back to the server

Parameters: B<%OPTIONS> - a hash of options. The following key-pairs are recognised:

=over 8

=item B<header>

An optional header hashref, or coderef, which will overwrite the default header parameters. If the parameter is a coderef, it should return a hashref which will be used for overriding. It will receive the content URI and its estimated MIME Type as its two parameters.

=item B<mimeType>

An optional string or coderef. If the value is a string, it will be used as the content's mime type. If the value is a coderef, it will be called with the URI as its parameter, and its return value will be used as a mime type for the content

=back

=cut

sub handleRequest {
    my ($self, %options) = @_;
    my %form = $self->getParams;
    my $uri = $form{IWLStaticURI};
    my $etag;
    return unless $uri;

    ($etag, $uri) = $self->__getETag($uri);

    unless ($self->{_staticURIs}{$uri}) {
        my (undef, $directory, undef) = File::Spec->splitpath($uri);
        return $self->_pushError(
            __x("The URI '{URI}' does not belong in the predefined list of static URIs.", URI => $uri))
          unless $self->{_staticURIs}{$directory};
    }

    local *DATA;
    open DATA, $uri or return $self->_pushError($!);
    local $/;
    my $content = <DATA>;
    close DATA;
    my @stat = stat $uri;
    my ($inode, $clength, $modtime) = @stat[1,7,9];
    my $mime = ref $options{mimeType} eq 'CODE' ? $options{mimeType}->($uri) : ($options{mimeType} || $self->__getMime($uri));
    my $header = {
        'Content-type'   => $mime,
        'Content-length' => $clength,
        'Last-Modified'  => time2str($modtime),
        'ETag'           => qq|"$etag"|,
    };
    $options{header} = $options{header}->($uri, $mime) if ref $options{header} eq 'CODE';
    $header->{$_} = $options{header}{$_} foreach keys %{
        ref $options{header} eq 'CODE'
              ? $options{header}->($uri, $mime)
              : $options{header} || {}
    };

    IWL::Response->new->send(header => $header, content => $content);

    return $self;
}

=item B<addRequest> (B<URI>)

Changes the B<URI> into a static request, if the I<STATIC_URI_SCRIPT> option is set in the %IWLConfig. It does not change the B<URI> otherwise.
This method is used by L<IWL::Widget>s, which use static content, such as an L<IWL::Image>.

Parameters: B<URI> - a URI, or a list of URIs, which will be handled by the static uri handler script

=cut

sub addRequest {
    my ($self, $script, $label) = (shift, $IWLConfig{STATIC_URI_SCRIPT}, $IWLConfig{STATIC_LABEL});
    return @_ unless $script || $label;
    if ($script) {
        $_ = $script . '?IWLStaticURI=' . $_ foreach @_;
    } else {
        foreach (@_) {
            my $tag = $self->__getETag($_);
            next unless $tag;
            if (index($_, '?') > -1) {
                $_ .= '&' . $tag;
            } else {
                $_ .= '?' . $tag;
            }
        }
    }
    return @_;
}

# Internal
#
sub __init {
    my $self = shift;

    $self->{_staticURIs} = {};

    my @uri = @IWLConfig{qw(JS_DIR SKIN_DIR IMAGE_DIR ICON_DIR)};
    push @uri, (split ':', $IWLConfig{STATIC_URIS}) if $IWLConfig{STATIC_URIS};
    $self->addURI(map {$_ => 1} @uri);
}

sub __getETag {
    my ($self, $uri) = @_;
    $uri = File::Spec->join($IWLConfig{DOCUMENT_ROOT}, $uri)
      if substr($uri, 0, 1) eq '/' && $IWLConfig{DOCUMENT_ROOT};

    $uri =~ s{/+}{/}g;

    my @stat = stat $uri;
    my ($inode, $clength, $modtime) = @stat[1,7,9];
    my $etag = $inode ? sprintf('%x-%x-%x', $inode, $clength, $modtime) : '';
    return wantarray ? ($etag, $uri) : $etag;
}

sub __recursiveScan {
    my ($self, $uri, $count) = @_;
    return if $count++ == MAX_DEPTH;

    local *DIR;
    opendir DIR, $uri
      or $self->_pushError(
        __x("Cannot open directory {URI}: {ERR}", URI => $uri, ERR => $!)
      );
    my @children = grep { !/^\./ && -d $uri . '/' . $_ } readdir DIR;
    closedir DIR;

    foreach (@children) {
        my $child = $uri . '/' . $_;
        $child =~ s{/+}{/}g;
        $child .= '/' if substr($child, -1) ne '/';
        next if $self->{_staticURIs}{$child};
        $self->{_staticURIs}{$child} = 1;
        $self->__recursiveScan($child, $count);
    }
}

sub __getMime {
    my ($self, $uri) = @_;
    return (substr($uri, -4) eq '.css')    ? 'text/css; charset=utf-8'
         : (substr($uri, -5) eq '.html')   ? 'text/html; charset=utf-8'
         : (substr($uri, -4) eq '.xml')    ? 'text/xml; charset=utf-8'
         : (substr($uri, -3) eq '.js')     ? 'text/javascript; charset=utf-8'
         : (substr($uri, -4) eq '.jpg')    ? 'image/jpeg'
         : (substr($uri, -4) eq '.gif')    ? 'image/gif'
         : (substr($uri, -4) eq '.tif')    ? 'image/tiff'
         : (substr($uri, -4) eq '.png')    ? 'image/png'
         : (substr($uri, -5) eq '.json')   ? 'application/json'
         : (substr($uri, -6) eq '.xhtml')  ? 'application/xhtml+xml'
         : (substr($uri, -4) eq '.swf')    ? 'application/x-shockwave-flash'
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

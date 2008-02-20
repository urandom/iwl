#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page::Link;

use strict;

use base 'IWL::Object';

=head1 NAME

IWL::Page::Link - a link object

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Page::Link>

=head1 DESCRIPTION

The link object provides the B<<link>> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Page::Link->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<link>> markup would have.

IWL::Page::Link->newLinkToCSS (B<URL>, [B<MEDIA>, B<%ARGS>])

A wrapper constructor that creates a link to an external CSS file

Parameters: B<URL> - the url of the css file, B<MEDIA> - the media of the link

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag}  = "link";
    $self->{_noChildren} = 1;
    foreach (keys %args) {
	if ($_ eq 'href') {
	    $self->setHref($args{$_});
	} else {
	    $self->setAttribute($_ => $args{$_});
	}
    }

    return $self;
}

sub newLinkToCSS {
    my ($self, $url, $media, %args) = @_;
    return unless $url;
    require IWL::Static;
    return IWL::Page::Link->new(
        rel   => 'stylesheet',
        type  => 'text/css',
        href  => IWL::Static->addRequest($url),
        media => $media || 'screen',
	%args,
    );
}

=item B<setHref> (B<URL>)

Sets the href attribute for the link 

Parameters: B<URL> - the url for the link

=cut

sub setHref {
    my ($self, $url) = @_;

    return $self->setAttribute(href => $url, 'uri');
}

=item B<getHref>

Gets the href attribute for the link

=cut

sub getHref {
    return shift->getAttribute('href', 1);
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

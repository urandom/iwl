#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Style;

use strict;

use base qw(IWL::Object);

use IWL::Text;

=head1 NAME

IWL::Style - a stylesheet object

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Style>

=head1 DESCRIPTION

The style object provides the B<<style type="text/css">> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Style->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<style>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag} = "style";
    $self->setAttribute(type => 'text/css');
    $self->setAttribute($_ => $args{$_}) foreach (keys %args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setMedia> (B<MEDIA>)

Adds a "media='B<MEDIA>'" attribute to B<<style>>.

Parameter: B<MEDIA> - the media target

=cut

sub setMedia {
    my ($self, $source) = @_;

    return $self->setAttribute(media => $source);
}

=item B<getMedia>

Returns the media type of the style

=cut

sub getMedia {
    return shift->getAttribute('media');
}

=item B<appendStyleImport> (B<FILE>)

Imports stylesheets from a file.

Parameter: B<FILE> - the css file, or an array reference of files, if both I<STATIC_URI_SCRIPT> and I<STATIC_UNION> options are set.

=cut

sub appendStyleImport {
    my ($self, $style) = @_;
    require IWL::Static;

    my $import = IWL::Text->new('@import "'
        . ref $style eq 'ARRAY'
            ? IWL::Static->addMultipleRequest($style, 'text/css')
            : IWL::Static->addRequest($style)
        . '";' . "\n");

    return $self->appendChild($import);
}

=item B<appendStyle> (B<STYLE>)

Appends a stylesheet string to the current style.

Parameter: B<STYLE> - the css string

=cut

sub appendStyle {
    my ($self, $style) = @_;

    require IWL::Text;
    my $import = IWL::Text->new($style);

    return $self->appendChild($import);
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

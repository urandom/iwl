#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Canvas;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Canvas - a canvas widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Canvas>

=head1 DESCRIPTION

The canvas widget provides a canvas element for rendering dynamic bitmap images

=head1 CONSTRUCTOR

IWL::Canvas->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "canvas";

    $self->requiredConditionalJs('IE', 'dist/excanvas.js');
    return $self;
}

=head1 METHODS

=over 4

=item B<setWidth> (B<WIDTH>)

Sets the width of the canvas

Parameter: B<WIDTH> - the width to use

=cut

sub setWidth {
    my ($self, $width) = @_;

    return $self->setAttribute(width => $width);
}

=item B<setHeight> (B<HEIGHT>)

Sets the height of the canvas

Parameter: B<HEIGHT> - the height to use

=cut

sub setHeight {
    my ($self, $height) = @_;

    return $self->setAttribute(height => $height);
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

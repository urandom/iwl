#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Canvas;

use strict;

use base 'IWL::Widget';

use IWL::Script;
use IWL::String 'randomize';

use Locale::TextDomain qw(org.bloka.iwl);

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

my $no_context = N__ "No context has been given";

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new;

    $self->{_tag} = 'canvas';
    $self->{_defaultClass} = 'canvas';
    $args{id} ||= randomize('canvas');

    $self->{__drawing} = [];
    $self->requiredJs('dist/prototype.js', 'dist/excanvas.js');
    $self->_constructorArguments(%args);

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

=item B<setDimensions> (B<WIDTH>, B<HEIGHT>)

Sets the width and height of the canvas

Parameters: B<WIDTH> - the width of the canvas, B<HEIGHT> - the height of the canvas

=cut

sub setDimensions {
    return shift->setWidth(shift)->setHeight(shift);
}

=head2 Drawing Methods

The names of the following methods reflect the reference names of methods and properties of the HTML5 Canvas element

=item B<getContext> (B<TYPE>, [B<NAME>])

Gets the canvas drawing context for a given type

Parameters:  B<TYPE> - the type of the context. Example: "2d", B<NAME> - optional name for the desired context

=cut

sub getContext {
    my ($self, $type) = (shift, shift);
    my $name = shift || 'ctx';
    $self->{__currentContext} = $name;
    push @{$self->{__drawing}}, "var $name = canvas.getContext('$type')";

    return $self;
}

=head3 Context properties

All context properties can optionally receive the current context name as their last parameter

=item B<fillStyle> (B<COLOR>)

Sets the color for fill operations

Parameters: B<COLOR> - the fill color. Can be one of the following:

=over 8

=item I<#RRGGBB>

A string, representing a hex RGB color

=item I<Red>, I<Green>, I<Blue>

An array, where every element represents a value between 0 - 255

=item I<Red>, I<Green>, I<Blue>, I<Alpha>

Same as above, but the I<Alpha> is a float number between 0 - 1

=back

=cut

sub fillStyle {
    my $self = shift;
    my $color = (@_ == 1) ? shift 
      : (@_ == 3) ? "rgb(" . (join ',', (shift, shift, shift)) .")"
      : (@_ == 4) ? "rgba(" . (join ',', (shift, shift, shift, shift)) .")" : undef;
    return $self->_pushError(__x("Invalid color: '{COLOR}'", COLOR => (join ',', @_))) unless $color;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.fillStyle = '$color'";
    return $self;
}

=item B<globalAlpha> (B<VALUE>)

Sets the global alpha value of the canvas' context

Parameters: B<VALUE> - a float, between 0 - 1, indicating the global alpha values

=cut

sub globalAlpha {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.globalAlpha = $value";
    return $self;
}

=item B<globalCompositeOperation> (B<TYPE>)

Determines the way the canvas is drawn relative to any background content.

Parameters: B<TYPE> - a string type, can be one of the following:

=over 8

=item B<copy>

Displays the source image instead of the destination image.

=item B<darker>

Display the sum of the source image and destination image, with color values approaching 0 as a limit.

=item B<destination-atop>

Display the destination image wherever both images are opaque. Display the source image wherever the source image is opaque but the destination image is transparent.

=item B<destination-in>
	
Display the destination image wherever both the destination image and source image are opaque. Display transparency elsewhere.

=item B<destination-out>

Display the destination image wherever the destination image is opaque and the source image is transparent. Display transparency elsewhere.

=item B<destination-over>

Display the destination image wherever the destination image is opaque. Display the source image elsewhere.

=item B<lighter>

Display the sum of the source image and destination image, with color values approaching 1 as a limit.

=item B<source-atop>

Display the source image wherever both images are opaque. Display the destination image wherever the destination image is opaque but the source image is transparent. Display transparency elsewhere.

=item B<source-in>

Display the source image wherever both the source image and destination image are opaque. Display transparency elsewhere.

=item B<source-out>

Display the source image wherever the source image is opaque and the destination image is transparent. Display transparency elsewhere.

=item B<source-over>

Display the source image wherever the source image is opaque. Display the destination image elsewhere. I<Default>

=item B<xor>

Exclusive OR of the source and destination images. Works only with black and white images and is not recommended for color images.

=back

=cut

sub globalCompositeOperation {
    my ($self, $type, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.globalCompositeOperation = '$type'";
    return $self;
}

=item B<lineCap> (B<TYPE>)

Sets the end style of drawn lines

Parameters: B<TYPE> - a string type, can be one of the following:

=over 8

=item B<butt>

Flat end, perpendicular to the line. I<Default>

=item B<round>

Round end

=item B<square>

Square end

=back

=cut

sub lineCap {
    my ($self, $type, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.lineCap = '$type'";
    return $self;
}

=item B<lineJoin> (B<TYPE>)

Sets the join style between lines

Parameters: B<TYPE> - a string type, can be one of the following:

=over 8

=item B<round>

Round joins 

=item B<bevel>

Beveled joins

=item B<miter>

Miter joins. I<Default>

=back

=cut

sub lineJoin {
    my ($self, $type, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.lineJoin = '$type'";
    return $self;
}

=item B<lineWidth> (B<VALUE>)

Sets the width of drawn lines

Parameters: B<VALUE> - a float, greater than 0, which determines the width of the drawn line, in units of the coordinate space

=cut

sub lineWidth {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.lineWidth = $value";
    return $self;
}

=item B<miterLimit> (B<VALUE>)

Sets the miter limit, which specifies how the canvas draws the juncture between connected line segments

Parameters: B<VALUE> - a float value

=cut

sub miterLimit {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.miterLimit = $value";
    return $self;
}

=item B<shadowBlur> (B<VALUE>)

Sets the width that a shadow can cover.

Parameters: B<VALUE> - a positive float value, in units of coordinate space

=cut

sub shadowBlur {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.shadowBlur = $value";
    return $self;
}

=item B<shadowColor> (B<COLOR>)

Sets the color for shadows

Parameters: B<COLOR> - the shadow color. Can be one of the following:

=over 8

=item I<#RRGGBB>

A string, representing a hex RGB color

=item I<Red>, I<Green>, I<Blue>

An array, where every element represents a value between 0 - 255

=item I<Red>, I<Green>, I<Blue>, I<Alpha>

Same as above, but the I<Alpha> is a float number between 0 - 1

=back

=cut

sub shadowColor {
    my $self = shift;
    my $color = (@_ == 1) ? shift 
      : (@_ == 3) ? "rgb(" . (join ',', (shift, shift, shift)) .")"
      : (@_ == 4) ? "rgba(" . (join ',', (shift, shift, shift, shift)) .")" : undef;
    return $self->_pushError(__x("Invalid color: '{COLOR}'", COLOR => (join ',', @_))) unless $color;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.shadowColor = '$color'";
    return $self;
}

=item B<shadowOffsetX> (B<VALUE>)

Sets the X offset of a shadow

Parameters: B<VALUE> - the X offset of the shadow, in units of coordinate space

=cut

sub shadowOffsetX {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.shadowOffsetX = $value";
    return $self;
}

=item B<shadowOffsetY> (B<VALUE>)

Sets the Y offset of a shadow

Parameters: B<VALUE> - the Y offset of the shadow, in units of coordinate space

=cut

sub shadowOffsetY {
    my ($self, $value, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.shadowOffsetY = $value";
    return $self;
}

=item B<strokeStyle> (B<COLOR>)

Sets the color for stroke operations

Parameters: B<COLOR> - the shadow color. Can be one of the following:

=over 8

=item I<#RRGGBB>

A string, representing a hex RGB color

=item I<Red>, I<Green>, I<Blue>

An array, where every element represents a value between 0 - 255

=item I<Red>, I<Green>, I<Blue>, I<Alpha>

Same as above, but the I<Alpha> is a float number between 0 - 1

=back

=cut

sub strokeStyle {
    my $self = shift;
    my $color = (@_ == 1) ? shift 
      : (@_ == 3) ? "rgb(" . (join ',', (shift, shift, shift)) .")"
      : (@_ == 4) ? "rgba(" . (join ',', (shift, shift, shift, shift)) .")" : undef;
    return $self->_pushError(__x("Invalid color: '{COLOR}'", COLOR => (join ',', @_))) unless $color;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.strokeStyle = '$color'";
    return $self;
}

=head3 Context methods

All context methods can optionally receive the current context name as their last parameter

=item B<fillRect> (B<X>, B<Y>, B<WIDTH>, B<HEIGHT>)

Paints a rectangular area

Parameters: B<X> - the X coordinate of a point of the rectangular area; B<Y> - the Y coordinate; B<WIDTH> - the width of the rectangular area; B<HEIGHT> - the height

=cut

sub fillRect {
    my ($self, $x, $y, $width, $height, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.fillRect($x, $y, $width, $height)";
    return $self;
}

=item B<strokeRect> (B<X>, B<Y>, B<WIDTH>, B<HEIGHT>)

Paints a rectangular outline

Parameters: B<X> - the X coordinate of a point of the rectangular outline; B<Y> - the Y coordinate; B<WIDTH> - the width of the rectangular outline; B<HEIGHT> - the height

=cut

sub strokeRect {
    my ($self, $x, $y, $width, $height, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.strokeRect($x, $y, $width, $height)";
    return $self;
}

=item B<clearRect> (B<X>, B<Y>, B<WIDTH>, B<HEIGHT>)

Clears a rectangular area and makes it fully transparent

Parameters: B<X> - the X coordinate of a point of the rectangular area; B<Y> - the Y coordinate; B<WIDTH> - the width of the rectangular area; B<HEIGHT> - the height

=cut

sub clearRect {
    my ($self, $x, $y, $width, $height, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.clearRect($x, $y, $width, $height)";
    return $self;
}

=item B<beginPath>

Creates a new path in the canvas

=cut

sub beginPath {
    my $self = shift;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.beginPath()";
    return $self;
}

=item B<stroke>

Strokes the current path

=cut

sub stroke {
    my $self = shift;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.stroke()";
    return $self;
}

=item B<fill>

Fills the current path

=cut

sub fill {
    my $self = shift;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.fill()";
    return $self;
}

=item B<closePath>

Closes the current path

=cut

sub closePath {
    my $self = shift;
    my $name = shift || $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.closePath()";
    return $self;
}

=item B<moveTo> (B<X>, B<Y>)

Moves the path position to the given point

Parameters: B<X> - the X coordinate of the point, B<Y> - the Y coordinate of the point

=cut

sub moveTo {
    my ($self, $x, $y, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.moveTo($x, $y)";
    return $self;
}

=item B<lineTo> (B<X>, B<Y>)

Creates a new line from the current path position to the given point

Parameters: B<X> - the X coordinate of the point, B<Y> - the Y coordinate of the point

=cut

sub lineTo {
    my ($self, $x, $y, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.lineTo($x, $y)";
    return $self;
}

=item B<arc> (B<X>, B<Y>, B<RADIUS>, B<START_ANGLE>, B<END_ANGLE>, B<CLOCKWISE>)

Creates a new arc from the current path position.

Parameters: B<X> - the X coordinate of the center of the arc, B<Y> - the Y coordinate of the center of the arc, B<RADIUS> - the radius of the arc, B<START_ANGLE> - the starting angle, measured in radians, B<END_ANGLE> - the ending angle, measured in radians, B<CLOCKWISE> - boolean, if true, the arc will be drawn in a clockwise direction

=cut

sub arc {
    my ($self, $x, $y, $radius, $start_angle, $end_angle, $clockwise, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    
    $clockwise = !(!$clockwise) ? 'true' : 'false';
    push @{$self->{__drawing}}, "$name.arc($x, $y, $radius, $start_angle, $end_angle, $clockwise)";
    return $self;
}

=item B<arcTo> (B<X1>, B<Y1>, B<X2>, B<Y2>, B<RADIUS>)

Creates a new arc from the current path position, using a radius and tangent points

Parameters: B<X1> - the X coordinate of the end point of a line between the current position and (B<X1>, B<Y1>), B<Y1> - the Y coordinate of that end point, B<X2> - the X coordinate of the end point of a line between (B<X1>, B<Y1>) and (B<X2>, B<Y2>), B<Y2> - the Y coordinate of that end point, B<RADIUS> - the radius of the arc

=cut

sub arcTo {
    my ($self, $x1, $y1, $x2, $y2, $radius, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    
    push @{$self->{__drawing}}, "$name.arcTo($x1, $y1, $x2, $y2, $radius)";
    return $self;
}

=item B<rect> (B<X>, B<Y>, B<WIDTH>, B<HEIGHT>)

Creates a new rectangle to the path

Parameters: B<X> - the X coordinate of a point of the rectangle; B<Y> - the Y coordinate; B<WIDTH> - the width of the rectangle; B<HEIGHT> - the height

=cut

sub rect {
    my ($self, $x, $y, $width, $height, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.rect($x, $y, $width, $height)";
    return $self;
}

=item B<quadraticCurveTo> (B<CPX>, B<CPY>, B<X>, B<Y>)

Creates a new quadratic curve from the current path position

Parameters: B<CPX> - the X coordinate of the control point of the curve, B<CPY> - the Y coordinate of the control point of the curve, B<X> - the X coordinate of the end point of the curve, B<Y> - the Y coordinate of the end point of the curve

=cut

sub quadraticCurveTo {
    my ($self, $cpx, $cpy, $x, $y, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.quadraticCurveTo($cpx, $cpy, $x, $y)";
    return $self;
}

=item B<bezierCurveTo> (B<CP1X>, B<CP1Y>, B<CP2X>, B<CP2Y>, B<X>, B<Y>)

Creates a new bezier curve from the current path position

Parameters: B<CP1X> - the X coordinate of the first control point of the curve, B<CP1Y> - the Y coordinate of the first control point of the curve, B<CP2X> - the X coordinate of the second control point of the curve, B<CP2Y> - the Y coordinate of the second control point of the curve, B<X> - the X coordinate of the end point of the curve, B<Y> - the Y coordinate of the end point of the curve

=cut

sub bezierCurveTo {
    my ($self, $cp1x, $cp1y, $cp2x, $cp2y, $x, $y, $name) = @_;
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    push @{$self->{__drawing}}, "$name.bezierCurveTo($cp1x, $cp1y, $cp2x, $cp2y, $x, $y)";
    return $self;
}

=item B<drawImage> (B<IMAGE>, B<X>, B<Y>, [B<WIDTH>, B<HEIGHT>, B<DX>, B<DY>, B<DWIDTH>, B<DHEIGHT>])

Draws an image

Parameters: B<IMAGE> - The image to draw, this can be an L<IWL::Image> or L<IWL::Canvas>, or an image/canvas ID, B<X> - the X coordinate where the image should be placed, B<Y> - the Y coordinate, B<WIDTH> - the desired width of the image, B<HEIGHT> - the desired height. If the following parameters are specified, the previous four parameters describe what portion of the image should be used, and the next four parameters describe the position and size of the slice when set on the canvas

=cut

sub drawImage {
    my ($self, $image, $x, $y) = (shift, shift, shift, shift);
    my ($width, $height, $dx, $dy, $dwidth, $dheight, $name) =
        @_ == 1 ? ((undef) x 6, shift)
      : @_ == 2 || @_ == 3 ? (shift, shift, (undef) x 4, shift)
      : @_ == 6 || @_ == 7 ? @_ : ();
    $name ||= $self->{__currentContext};
    return $self->_pushError(__ $no_context) unless $name;
    if (UNIVERSAL::isa($image, 'IWL::Image') || UNIVERSAL::isa($image, 'IWL::Canvas')) {
        $image = $image->getId;
    }
    my $optional = '';
    $optional .= $_ ? ',' . $_ : '' foreach ($width, $height, $dx, $dy, $dwidth, $dheight);

    push @{$self->{__drawing}}, "$name.drawImage(\$('$image'), $x, $y" . $optional . ")";
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id = $self->getId;

    return $self->_pushFatalError(__ $no_context) unless $self->{__currentContext};
    $self->_appendInitScript("var canvas = \$('$id')", @{$self->{__drawing}});
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

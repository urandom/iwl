#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::SubmitImage;

use strict;

use base 'IWL::Input';

=head1 NAME

IWL::SubmitImage - an image used as a submit button

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::SubmitImage

=head1 DESCRIPTION

The SubmitImage widget functions as a widget, which when pressed, activates the submit of the form

=head1 CONSTRUCTOR

IWL::SubmitImage->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->setAttribute(type => 'image');
    $self->setClass('image');

    return $self;
}

=head1 METHODS

=over 4

=item B<set> (B<SRC>)

Set sets the given source for the image widget.

Parameters: B<SRC> - the source for the image

=cut

sub set {
    my ($self, $src) = @_;

    return $self->setAttribute(src => $src, 'uri');
}

=item B<setAlt> (B<TEXT>)

Sets the alternative text of the image

Parameters: B<TEXT> - the text to be set

=cut

sub setAlt {
    my ($self, $text) = @_;

    return $self->setAttribute(alt => $text);
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

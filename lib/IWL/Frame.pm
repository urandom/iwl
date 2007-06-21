#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Frame;

use strict;

use base 'IWL::Container';

=head1 NAME

IWL::Frame - a frame object

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Frame

=head1 DESCRIPTION

The frame is a container for grouping logically similar widgets. It is B<NOT> the html frame object, but rather, the fieldset one.

=head1 CONSTRUCTOR

IWL::Frame->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "fieldset";

    return $self;
}

=head1 METHODS

=over 4

=item B<setLabel> (B<TEXT>)

Sets the label of the frame.

Parameter: B<TEXT> - the text for the label

=cut

sub setLabel {
    my ($self, $text) = @_;
    if (!$self->{__legend}) {
        $self->{__legend} = IWL::Widget->new;
        $self->{__legend}->{_tag}  = "legend";
    }
    my $text_obj = IWL::Text->new($text);

    $self->{__legend}->setChild($text_obj);
    return $self;
}

=item B<getLabel>

Returns the frame's label text

=cut

sub getLabel {
    my $self = shift;
    return $self->{__legend} ? $self->{__legend}->firstChild->getContent : '';
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    $self->prependChild($self->{__legend});
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

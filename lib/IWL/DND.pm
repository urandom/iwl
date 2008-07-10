#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::DND;

use strict;

use IWL::JSON qw(toJSON);

=head1 NAME

IWL::DND - a Perl interface to Javascript Drag & Drop

=head1 DESCRIPTION

The DND helper class is an abstract class, inherited by L<IWL::Widget>, which provides configuration for Drag & Drop functionality.

=head1 SIGNALS

In JavaScript, the following signals are prefixed. Example: I<'iwl:SIGNAL_NAME'>

The following signals are emitted by the drag source

=over 4

=item B<drag_begin>

Fires when a draggable widget begins its movement. Receives the draggable object as a second parameter

=item B<drag_motion>

Fires during the motion of a draggable widget. Receives the draggable object as a second parameter

=item B<drag_end>

Fires when a draggable widget ends its movement. Receives the draggable object as a second parameter

=back

The following signals are emitted by the drag destination

=over 4

=item B<drag_hover>

Fires when an acceptable draggable widget is hovering over a draggable destination. Receives the draggable widget and droppable widget as second and third parameter

=item B<drag_drop>

Fires when an acceptable draggable widget is dropped over a draggable destination. Receives the draggable widget and droppable widget as second and third parameter

=back

=head1 METHODS

=over 4

=item B<setDragSource> ([B<OPTIONS>])

Registers an L<IWL::Widget> as a drag source.

Parameters:  B<OPTIONS> - a hash reference of options:

=over 8

=item B<outline>

If true, an outline of the widget will be moved, instead of the widget itself

=item B<view>

If a helper widget it given, it will be moved on drag, instead of the actual widget

=item B<revert>

If true, the actual widget will be returned to its original position, when dropped

=item B<handle>

An L<IWL::Widget> or an I<ID> of a widget, which is a descendant of the draggable widget. The widget will move, only if the handle is dragged

=item B<snap>

A 2-element array of integers, specifying the amount, in pixels, for snapping

=item B<zindex>

An integer, defining the I<CSS> z-index of the widget during a drag.

=item B<constraint>

If set to either I<horizontal> or I<vertical>, it will constraint the drag in only that direction

=item B<ghosting>

If true, a copy of the object will be dragged, while the original object stays in place

=back

=cut

sub setDragSource {
    my ($self, %options) = @_;

    $self->require(js => ['dist/effects.js', 'dist/dragdrop.js', 'dnd.js'])
        unless $self->{__initDrag};

    $self->{__initDrag} = 1;
    $self->{__dragOptions} = \%options;

    return $self;
}

=item B<unsetDragSource>

Unsets the L<IWL::Widget> as a drag source

=cut

sub unsetDragSource {
    my $self = shift;

    $self->unrequire(js => ['dist/effects.js', 'dist/dragdrop.js', 'dnd.js']);
    delete $self->{__initDrag};
    return $self;
}

=item B<setDragDest> ([B<OPTIONS>])

Registers the L<IWL::Widget> as a drag destination (drop)

Parameters:  B<OPTIONS> - a hash reference of options:

=over 8

=item B<accept>

A I<CSS> class, or an array of such classes, which belong to elements, that will be accepted by the destination

=item B<containment>

If set to an L<IWL::Widget>, or an I<ID>, the destination will only accept the target, if the target is either the containment widget, or a child of that widget.

=item B<hoverclass>

If specificed, the I<CSS> class will be added to the destination, while an accepted target is on dragged on it

=back

=cut

sub setDragDest {
    my ($self, %options) = @_;

    $self->require(js => ['dist/effects.js', 'dist/dragdrop.js', 'dnd.js'])
        unless $self->{__initDrop};

    $self->{__initDrop} = 1;
    $self->{__dropOptions} = \%options;

    return $self;
}

=item B<unsetDragDest>

Unsets the L<IWL::Widget> as a drag destination

=cut

sub unsetDragDest {
    my $self = shift;

    $self->unrequire(js => ['dist/effects.js', 'dist/dragdrop.js', 'dnd.js']);
    delete $self->{__initDrop};
    return $self;
}

=item B<setDragData> (B<DATA>)

Associates the given data to the draggable source.

Parameters: B<DATA> - a string, or hash/array reference

=cut

sub setDragData {
    my ($self, $data) = @_;

    $self->{__dragData} = $data;

    return $self;
}

# Protected
#

sub _realize {
    my $self = shift;
    my $id = $self->getAttribute('id', 1);;

    return unless $id;
    my $dragOptions = $self->{__dragOptions} || {};
    my $dropOptions = $self->{__dropOptions} || {};
    my $environment = $self->getEnvironment;
    my @script;

    if ($self->{__initDrag}) {
        if ($dragOptions->{view}) {
            $dragOptions->{view}{environment} = $environment;
            $dragOptions->{view} = $dragOptions->{view}->getContent;
        }
        $dragOptions->{handle} = $dragOptions->{handle}->getId
            if UNIVERSAL::isa($dragOptions->{handle}, 'IWL::Widget');

        my $options = toJSON($dragOptions);
        push @script, "Element.setDragSource(document.getElementById('$id'), $options)";

        if (defined $self->{__dragData}) {
            my $data = toJSON($self->{__dragData});
            push @script, "Element.setDragData(document.getElementById('$id'), $data)";
        }
    }
    if ($self->{__initDrop}) {
        $dropOptions->{containment} = $dropOptions->{containment}->getId
            if $dropOptions->{containment};

        my $options = toJSON($dropOptions);
        push @script, "Element.setDragDest(document.getElementById('$id'), $options)";
    }

    $self->_appendInitScript(join ";\n", @script) if @script;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

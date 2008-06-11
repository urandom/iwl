#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Widget;

use strict;

use base qw(IWL::Object IWL::RPC::Request IWL::DND);
use IWL::Config qw(%IWLConfig);

=head1 NAME

IWL::Widget - the base widget object

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget>

=head1 DESCRIPTION

The Widget package provides basic methods that every widget inherits.

=head1 CONSTRUCTOR

IWL::Widget->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-value options.

=head1 SIGNALS

=over 4

=item B<click>

Fires when the pointing device button is clicked over an element. A click is defined as a mousedown and mouseup over the same screen location. The sequence of these events is:

  - mousedown
  - mouseup
  - click

=item B<dblclick>

Fires when the pointing device button is double clicked over an element

=item B<mousedown>

Fires when the pointing device button is pressed over an element

=item B<mouseup>

Fires when the pointing device button is released over an element

=item B<mouseover>

Fires when the pointing device is moved onto an element. Note that it is also fired when the pointing device enters the element, after leaving a child element

=item B<mousemove>

Fires when the pointing device is moved while it is over an element

=item B<mouseout>

Fires when the pointing device is moved away from an element. Note that it is also fired when the mouse goes over a child of the element

=item B<mouseenter>

Fires when the pointing device is moved onto an element. Unlike B<mouseover>, this signal is not fired again if the pointing device enters a child of the element.

=item B<mouseleave>

Fires when the pointing device is moved away from an element. Unlike B<mouseout>, this signal is not fired again if the pointing device leaves a child of the element.

=item B<mousewheel>

Fires when the pointing device's scroll wheel has been turned

=item B<keypress>

Fires when a key on the keyboard is "clicked". A keypress is defined as a keydown and keyup on the same key. The sequence of these events is:

  - keydown
  - keyup
  - keypress

=item B<keydown>

Fires when a key on the keyboard is pressed

=item B<keyup>

Fires when a key on the keyboard is released

=back

=head1 EVENTS

Every widget signal will also be emitted as an event, if it was registered. The event name is the widget's class, delimeted by a I<'-'>, and camelized signal name. Examples:

    IWL-Widget-click            signal name: 'click'
    IWL-NavBar-activatePath     signal name: 'activate_path'

Unless otherwise noted, the perl callback called by the event handler, will only receive the serialized signal event, under the I<eventData> key of the parameter hashref.

See L<IWL::RPC::handleEvent|IWL::RPC/handleEvent> for more information

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_signals} = {
        click     => 1,
        dblclick  => 1,
        mousedown => 1,
        mouseup   => 1,
        mouseover => 1,
        mousemove => 1,
        mouseout  => 1,
        keypress  => 1,
        keydown   => 1,
        keyup     => 1,
    };

    # The style hash
    $self->{_style} = {};

    # Selectable
    $self->{__selectable} = 1;

    $self->_constructorArguments(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<signalConnect> (B<SIGNAL>, B<EXPR>)

Registers a javascript expression to be evaluated on each emission of the B<SIGNAL> from the widget.

Parameters: B<SIGNAL> - the signal string, B<EXPR> - the javascript expression to be invoked

Returns: returns false if the signal is invalid

=cut

sub signalConnect {
    my ($self, $signal, $callback) = @_;

    if ($self->{_customSignals}{$signal}
        || grep {$_ eq $signal} qw(
            mouseenter mouseleave mousewheel
            drag_begin drag_motion drag_end drag_hover drag_drop
           )
    ) {
	push @{$self->{_customSignals}{$signal}}, $callback;
	return $self;
    }
    return if !exists $self->{_signals}{$signal};

    my $callbacks = $self->getAttribute("on$signal", 1);

    if (!$callbacks) {
	$callbacks = $callback;
    } elsif ($callbacks =~ /;\s*$/) {
	$callbacks .= $callback;
    } else {
	$callbacks .= "; $callback";
    }
    $self->setAttribute("on$signal" => $callbacks);

    return $self;
}

=item B<signalDisconnect> ([B<SIGNAL>], [B<EXPR>])

Disconnects the expression from the signal handler

Parameters: B<SIGNAL> - the signal. If omitted, all signal handlers wil be removed, B<EXPR> - the javascript expression to be disconnected. If omitted, all expressions for the given signal will be removed.

=cut

sub signalDisconnect {
    my ($self, $signal, $callback) = @_;

    if ($signal && !$callback) {
        if ($self->{_customSignals}{$signal}) {
            $self->{_customSignals}{$signal} = [];
            return $self;
        } elsif (exists $self->{_signals}{$signal}) {
            $self->deleteAttribute("on$signal");
            return $self;
        }
        return;
    } elsif (!$signal) {
        $self->{_customSignals}{$_} = [] foreach keys %{$self->{_customSignals}};
        $self->deleteAttribute("on$_") foreach keys %{$self->{_signals}};
        return $self;
    }

    if ($self->{_customSignals}{$signal}) {
	foreach my $cb (@{$self->{_customSignals}{$signal}}) {
	    undef $cb if $cb eq $callback;
	}
	return $self;
    }
    return if !exists $self->{_signals}{$signal};

    my $callbacks = $self->getAttribute("on$signal", 1);

    my $index = index $callbacks, $callback;
    return if $index == -1;

    substr $callbacks, $index, length $callback, '';
    $self->setAttribute("on$signal" => $callbacks);

    return $self;
}

=item B<signalDisconnectAll> (B<SIGNAL>)

Disconnects all of the expressions from the signal handler

Parameters: B<SIGNAL> - the signal

B<DEPRECATED> - use L<IWL::Widget::signalDisconnect|/signalConnect> without an expression parameter instead.

=cut

sub signalDisconnectAll {
    my ($self, $signal) = @_;

    if ($self->{_customSignals}{$signal}) {
	$self->{_customSignals}{$signal} = [];
	return $self;
    }
    return if !exists $self->{_signals}{$signal};
    $self->deleteAttribute("on$signal");

    return $self;
}

=item B<setStyle> (B<STYLE>)

setStyle sets the given style attributes for the current widget.

Parameters: B<STYLE> - the given style, in a hash format.

=cut

sub setStyle {
    my ($self, %style) = @_;

    foreach my $key (keys %style) {
	$self->__setStyle($key, $style{$key});
    }

    return $self;
}

=item B<getStyle> ([B<ATTR>])

Returns the given value for the style attribute, or the whole hash if no style was specified.

Parameters: B<ATTR> - the attribute style property to be returned

=cut

sub getStyle {
    my ($self, $attr) = @_;

    if ($attr) {
	return $self->{_style}{$attr};
    } else {
	return %{$self->{_style}};
    }
}

=item B<deleteStyle> (B<ATTR>)

Deletes the given style attribute

Parameters: B<ATTR> - the style attribute name to be deleted

=cut

sub deleteStyle {
    my ($self, $attr) = @_;

    delete $self->{_style}{$attr};
    return $self;
}

=item B<setId> (B<ID>)

setId sets the given id for the current widget. It overwrites any previous id set for the widget.

Parameters: B<ID> - the given id

=cut

sub setId {
    my ($self, $id) = @_;

    return $self->setAttribute(id => $id);
}

=item B<getId>

Returns the id of the current widget

=cut

sub getId {
    return shift->getAttribute('id', 1);
}

=item B<setClass> (B<CLASS>)

setClass sets the given class for the current widget. It overwrites any previous class set for the widget.

Parameters: B<CLASS> - the given class

=cut

sub setClass {
    my ($self, $class) = @_;

    return $self->setAttribute(class => $class);
}

=item B<appendClass> (B<CLASS>)

Appends a class to the current list of classes for the widget

Parameters: B<CLASS> - the given class

=cut

sub appendClass {
    my ($self, $class) = @_;

    my $class_list = $self->getClass;
    if (!$class_list) {
	return $self->setAttribute(class => $class);
    } else {
        return $self if $self->hasClass($class);
	return $self->setAttribute(class => $class_list . ' ' . $class);
    }
}

=item B<prependClass> (B<CLASS>)

Prepends a class to the current list of classes for the widget

Parameters: B<CLASS> - the given class

=cut

sub prependClass {
    my ($self, $class) = @_;

    my $class_list = $self->getClass;
    if (!$class_list) {
	return $self->setAttribute(class => $class);
    } else {
        return $self if $self->hasClass($class);
	return $self->setAttribute(class => $class . ' ' . $class_list);
    }
}

=item B<hasClass> (B<CLASS>)

Returns true if the widget belongs to the given class

Parameters: B<CLASS> - the class to be checked

=cut

sub hasClass {
    my ($self, $class) = @_;
    my $class_list = $self->getClass;
    foreach (split / /, $class_list) {
	return 1 if $_ eq $class;
    }
    return '';
}

=item B<removeClass> (B<CLASS>)

Removes the given class from the class list

Parameters: B<CLASS> - the class to remove

=cut

sub removeClass {
    my ($self, $class) = @_;
    my $class_list = $self->getClass;
    my $new_list;
    return unless $class_list;
    foreach (split / /, $class_list) {
	if ($new_list) {
	    $new_list .= ' ' . $_ if $_ ne $class;
	} else {
	    $new_list = $_ if $_ ne $class;
	}
    }
    $self->setAttribute(class => $new_list);
}

=item B<getClass>

Returns the class of the current widget

=cut

sub getClass {
    return shift->getAttribute('class', 1);
}

=item B<setName> (B<NAME>)

Sets the name of the current widget to the given name.

Parameters: B<NAME> - the given name

=cut

sub setName {
    my ($self, $name) = @_;

    return $self->setAttribute(name => $name);
}

=item B<getName>

Gets the name of the current widget

=cut

sub getName {
    return shift->getAttribute('name', 1);
}

=item B<setTitle> (B<TITLE>)

Sets the given title for the current widget. It overwrites any previous title set for the widget.

Parameters: B<TITLE> - the given title

=cut

sub setTitle {
    my ($self, $title) = @_;

    return $self->setAttribute(title => $title);
}

=item B<getTitle>

Gets the title of the current widget.

=cut

sub getTitle {
    return shift->getAttribute('title', 1);
}

=item B<setSelectable> (B<BOOL>)

Sets whether the text inside the object can be selected by the user

Parameters: B<BOOL> - if true, the user can select the text of the object (default)

=cut

sub setSelectable {
    my ($self, $selectable) = @_;

    $self->{__selectable} = !(!$selectable);
    return $self;
}

=item B<isSelectable>

Returns true if the user can select the text inside the object

=cut

sub isSelectable {
    return shift->{__selectable};
}

# Overrides
#
sub registerEvent {
    my $self = shift;

    $self->SUPER::registerEvent(@_);
    $self->require(js => 'base.js');

    return $self;
}

# Protected
#
=head1 PROTECTED METHODS

The following methods should only be used by classes that inherit
from B<IWL::Widget>.

=cut

sub _realize {
    my $self = shift;

    $self->IWL::DND::_realize;
    $self->IWL::Object::_realize;

    unless ($self->{__selectable}) {
        $self->setAttribute(unselectable => 'on');
        $self->appendClass('iwl-unselectable');
    }

    if ($self->{_customSignals}) {
	my $id = $self->getId;

        if ($id) {
            foreach my $signal (keys %{$self->{_customSignals}}) {
                my $expr = join '; ', @{$self->{_customSignals}{$signal}};
                if ($expr) {
                    $signal = $self->_namespacedSignalName($signal);
                    $self->_appendInitScript(
                        "\$('$id').signalConnect('$signal', function() { $expr });"
                    );
		}
	    }
	}
    }

    $self->_realizeEvents if $self->can('_realizeEvents');
    if ($self->can('_setupDefaultClass')) {
	$self->_setupDefaultClass;
    } else {
	$self->prependClass($self->{_defaultClass}) if $self->{_defaultClass};
    }
}

sub _realizeEvents {
    my $self = shift;
    my $id = $self->getId;
    return unless $self->{_handlers} && $id;

    $self->SUPER::_realizeEvents;

    $self->_appendInitScript("\$('$id').prepareEvents();");
}

sub _constructorArguments {
    my ($self, %args) = @_;

    foreach my $key (keys %args) {
	if ($key eq 'style' && ref $args{$key} eq 'HASH') {
            $self->setStyle(%{$args{$key}});
	} elsif ($key eq 'class') {
	    $self->setClass($args{$key});
	} elsif ($key eq 'id') {
	    $self->setId($args{$key});
	} else {
	    $self->setAttribute($key => $args{$key});
	}
    }
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    my ($package, $signal) = $event =~ /^(.*)-(\w+)$/;
    $package =~ s/-/::/g;
    return unless ref $self eq $package;

    $signal =~ s/(?<=\w)([A-Z])/_\l$1/g;
    $self->signalConnect($signal => "this.emitEvent('$event', {eventData: Event.serialize(arguments[0])}, {id: this.id})");
    return $options;
}

sub _namespacedSignalName {
    my ($self, $signal) = @_;
    return 'iwl:' . $signal
      if exists $self->{_customSignals}{$signal}
      || grep {$_ eq $signal} qw(drag_begin drag_motion drag_end drag_hover drag_drop);
    return 'dom:' . $signal
      if $signal =~ /mouse(?:enter|leave|wheel)/;
    return $signal;
}

=item B<_matchTerm> (B<TERM>)

Returns I<1> if the widget matches the given term, I<0> if it doesn't, or I<-1> if the term is not supported.

Parameters: B<TERM> - a hash reference with the following key-value pairs:

=over 8

=item B<class>

The class, which is contained in the widget's class attribute

=item B<id>

The id of the widget

=back

=cut

sub _matchTerm {
    my ($self, $term) = @_;
    my $ret = -1;

    if ($term->{class}) {
        $ret = $self->hasClass($term->{class}) ? 1 : 0;
    } elsif ($term->{id}) {
        $ret = $self->getId eq $term->{id} ? 1 : 0;
    }

    return $ret;
}

# Internal
#
sub __setStyle {
    my ($self, $attr, $value) = @_;

    unless ($attr =~ /^[a-zA-Z_:][-.a-zA-Z0-9_:]*$/) {
	require Carp;

	my $safe_attr = $self->__safeErrorFormat ($attr);
	if ($IWLConfig{STRICT_LEVEL} > 1) {
		Carp::croak ("Attempt to set illegal attribute '$safe_attr'");
	} else {
		Carp::carp ("Attempt to set illegal attribute '$safe_attr'");
	}
	return;
    }

    $self->{_style}{$attr} = $value;

    return $self;
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

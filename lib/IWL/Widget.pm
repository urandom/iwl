#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Widget;

use strict;

use base qw(IWL::Object IWL::RPC::Request);
use IWL::Config qw(%IWLConfig);
use IWL::Script;
use JSON;

=head1 NAME

IWL::Widget - the base widget object

=head1 INHERITANCE

IWL::Object -> IWL::Widget

=head1 DESCRIPTION

The Widget package provides basic methods that every widget inherits.

=head1 CONSTRUCTOR

IWL::Widget->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-value options. 

IWL::Widget->newMultiple (B<ARGS>, B<ARGS>, ...)

Returns an array of multiple widgets, one for each B<ARGS>.

Parameters: B<ARGS> - a hash ref of arguments, or a integer, specifying how many widgets to create without any arguments

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

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

    $self->_constructorArguments(%args);

    return $self;
}

sub newMultiple {
    my ($proto, @args) = @_;
    my @widgets;
    if (scalar @args == 1 && !ref $args[0]) {
	foreach (1..$args[0]) {
	    my $widget = $proto->new;
	    push @widgets, $widget;
	}
    } else {
	foreach my $args (@args) {
	    my $widget = $proto->new(%$args);
	    push @widgets, $widget;
	}
    }
    return @widgets;
}

=head1 METHODS

=over 4

=item B<signalConnect> (B<SIGNAL>, B<JS_CALLBACK>)

signalConnect registers a javascript callback to be called on each emission of the B<SIGNAL> from the widget.

Parameters: B<SIGNAL> - the signal string, B<JS_CALLBACK> - the javascript expression to be invoked

Returns: returns false if the signal is invalid
  
=cut

sub signalConnect {
    my ($self, $signal, $callback) = @_;

    if ($self->{_customSignals}{$signal} ||
	  $signal eq 'mouseenter' || $signal eq 'mouseleave' || $signal eq 'mousewheel'
    ) {
	push @{$self->{_customSignals}{$signal}}, $callback;
	return $self;
    }
    return if !exists $self->{_signals}{$signal};

    my $callbacks = $self->getAttribute("on$signal", 'none');

    if (!$callbacks) {
	$callbacks = $callback;
    } elsif ($callbacks =~ /;\s*$/) {
	$callbacks .= $callback;
    } else {
	$callbacks .= "; $callback";
    }
    $self->setAttribute("on$signal" => $callbacks, 'none');

    return $self;
}

=item B<signalDisconnect> (B<SIGNAL>, B<JS_CALLBACK>)

Disconnects the callback from the signal handler

Parameters: B<SIGNAL> - the signal, B<JS_CALLBACK> - the callback to be disconnected

=cut

sub signalDisconnect {
    my ($self, $signal, $callback) = @_;

    if ($self->{_customSignals}{$signal}) {
	foreach my $cb (@{$self->{_customSignals}{$signal}}) {
	    undef $cb if $cb eq $callback;
	}
	return $self;
    }
    return if !exists $self->{_signals}{$signal};

    my $callbacks = $self->getAttribute("on$signal", 'none');

    my $index = index $callbacks, $callback;
    return if $index == -1;

    substr $callbacks, $index, length $callback, '';
    $self->setAttribute("on$signal" => $callbacks, 'none');

    return $self;
}

=item B<signalDisconnectAll> (B<SIGNAL>)

Disconnects all the callbacks from the signal handler

Parameters: B<SIGNAL> - the signal

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
    return shift->getAttribute('id');
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

    my $class_list = $self->getAttribute('class');
    if (!$class_list) {
	return $self->setAttribute(class => $class);
    } else {
	return $self->setAttribute(class => $class_list . ' ' . $class);
    }
}

=item B<prependClass> (B<CLASS>)

Prepends a class to the current list of classes for the widget

Parameters: B<CLASS> - the given class

=cut

sub prependClass {
    my ($self, $class) = @_;

    my $class_list = $self->getAttribute('class');
    if (!$class_list) {
	return $self->setAttribute(class => $class);
    } else {
	return $self->setAttribute(class => $class . ' ' . $class_list);
    }
}

=item B<hasClass> (B<CLASS>)

Returns true if the widget belongs to the given class

Parameters: B<CLASS> - the class to be checked

=cut

sub hasClass {
    my ($self, $class) = @_;
    my $class_list = $self->getAttribute('class');
    foreach (split / /, $class_list) {
	return 1 if $_ eq $class;
    }
    return 0;
}

=item B<removeClass> (B<CLASS>)

Removes the given class from the class list

Parameters: B<CLASS> - the class to remove

=cut

sub removeClass {
    my ($self, $class) = @_;
    my $class_list = $self->getAttribute('class');
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
    return shift->getAttribute('class');
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
    return shift->getAttribute('name');
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
    return shift->getAttribute('title');
}

# Protected
#
sub _realize {
    my $self = shift;

    if ($self->{_customSignals}) {
	my $id = $self->getId;
	my $parent = $self->__findTopParent || $self;

	if ($id) {
	    foreach my $signal (keys %{$self->{_customSignals}}) {
		my $expr = '';
		$expr .= ($_ || '') . ';' foreach (@{$self->{_customSignals}{$signal}});
		if ($expr) {
		    $parent->{_customSignalScript} = IWL::Script->new
		      unless $parent->{_customSignalScript};
		    $parent->{_customSignalScript}->appendScript(<<EOF);
\$('$id').signalConnect('$signal', function() { $expr });
EOF
		}
	    }
	}
	if ($parent->{_customSignalScript} && !$parent->{_customSignalScript}{_added}) {
	    $parent->_appendAfter($parent->{_customSignalScript}) if $parent->{_customSignalScript};
	    $parent->{_customSignalScript}{_added} = 1;
	}
    }

    $self->_realizeEvents if $self->can('_realizeEvents');
    if ($self->can('_setupDefaultClass')) {
	$self->_setupDefaultClass;
    } else {
	$self->prependClass($self->{_defaultClass}) if $self->{_defaultClass};
    }
}

sub _constructorArguments {
    my ($self, %args) = @_;

    foreach my $key (keys %args) {
	if ($key eq 'style' && ref $args{$key} eq 'HASH') {
	    foreach my $style (keys %{$args{$key}}) {
		$self->setStyle($style => $args{$key}{$style});
	    }
	} elsif ($key eq 'class') {
	    $self->setClass($args{$key});
	} elsif ($key eq 'id') {
	    $self->setId($args{$key});
	} else {
	    $self->setAttribute($key => $args{$key});
	}
    }
}

=item B<registerEvent> (B<EVENT>, B<URL>, B<PARAMS>)

Registers a generic event handler to the given event. The event will be processed by a IWL::RPC::handleEvent(3pm) call in the handling script.

Parameters: B<EVENT> - The event name to register. B<URL> the script url, which will provide the event handling. B<PARAMS> - a hash of parameters to be passed to the handler subroutine as a parameter. The following parameters are also interpretted:

  onStart     - a javascript expression to be evaluated before the
                request takes place. It receives I<PARAMS> as an
		argument
  onComplete  - a javascript expression to be evaluated after the
                request takes place
  update      - the id of element to be updated. If empty, the
                document body is updated. The following parameters
		are also taken under consideration if this one is
		specified:
  evalScripts - true, if any script elements in the response should
                be evaluated using javascript's eval() function
  insertion   - if omitted, the contents of the container will be
                replaced with the response of the script. Otherwise,
		depeding on the value, the reponse will be placed
		around the exsting content. Valid values are:
		I<after> - will be inserted as the next sibling of
		           the container, 
		I<before> - will be inserted as the previous
		            sibling of the container,
		I<bottom> - will be inserted as the last child
		            of the container,
		I<top> - will be inserted as the first child of
		            the container

=cut 

sub _registerEvent {
    my ($self, $event, $params) = @_;

    my $handlers = {};
    my ($package, $signal) = $event =~ /^(.*)-(\w+)$/;
    $package =~ s/-/::/g;
    return unless ref $self eq $package;

    if (exists $params->{update}) {
	$handlers->{update} = $params->{update} || 'document.body';
	$handlers->{insertion} = {
	    after  => 'Insertion.After',
	    before => 'Insertion.Before',
	    bottom => 'Insertion.Bottom',
	    top    => 'Insertion.Top',
	}->{$params->{insertion}} if $params->{insertion};
	$handlers->{evalScripts} = 'true' if $params->{evalScripts};
    }

    return $handlers if $self->signalConnect($signal => "this.prepareEvents(); this.emitEvent('$event', {value: this.value})");
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

sub __findTopParent {
    my $self = shift;
    my $parent = $self->{parentNode};

    while ($parent) {
	last if !$parent->{parentNode} || $parent->{parentNode}->isa('IWL::Page::Body');
	$parent = $parent->{parentNode};
    }
    return $parent;
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

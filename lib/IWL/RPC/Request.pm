#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::RPC::Request;

use strict;

use JSON;

=head1 NAME

IWL::RPC::Request - an RPC Requst helper class

=head1 DESCRIPTION

The RPC Request helper class is an abstract class, which provides RPC functionality (via XMLHttpRequest) to IWL Objects

=head1 METHODS

=over 4

=item B<registerEvent> (B<EVENT>, B<URL>, B<PARAMS>)

Registers an event handler to the given event. The event will be processed by a handleEvent(3pm) call in the handling script

Parameters: B<EVENT> - The event name to register. B<URL> the script url, which will provide the event handling. B<PARAMS> - a hash of parameters to be passed to the handler subroutine as a parameter. The following parameters are also interpretted:

=over 8

=item B<onStart>

A javascript expression to be evaluated before the request takes place. It receives I<params> as an argument

=item B<onComplete>

A javascript expression to be evaluated after the request takes place

=item B<emitOnce>

A boolean flag, causes the event to be emitted only once

=item B<disableView>

An indication will be shown that a response is active, if the parameter exists. It can be a hash with the following options:

=over 12

=item B<noCover> I<BOOL>

If true, the screen will not be covered, only the mouse cursor will indicate that a response is active (default: I<false>)

=item B<fullCover> I<BOOL>

If true, the screen will be fully covered (default: I<false>)

=item B<opacity> I<FLOAT>

The opacity of the covering element (default: I<0.8>)

=back

=back

=cut

sub registerEvent {
    my ($self, $event, $url, $params) = @_;

    return $self if $self->{_handlers}{$event};

    my $event_params =
        $self->can('_registerEvent')
      ? $self->_registerEvent($event, $params) || {}
      : {};
    $event_params->{emitOnce} = $params->{emitOnce} if exists $params->{emitOnce};
    if ($params->{disableView}) {
	if (ref $params->{disableView} eq 'HASH') {
	    $event_params->{disableView} = $params->{disableView};
	} else {
	    $event_params->{disableView} = 'true';
	}
    }
    $self->{_handlers}{$event} = [$url, {userData => $params, %$event_params}];

    return $self;
}

sub _realizeEvents {
    my $self = shift;

    $self->setAttribute('iwl:RPCEvents', objToJson($self->{_handlers}), 'escape')
        if $self->{_handlers};
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

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

=item B<registerEvent> (B<EVENT>, B<URL>, [B<PARAMS>, B<OPTIONS>])

Registers an event handler to the given event. The event will be processed by a handleEvent(3pm) call in the handling script

Parameters: B<EVENT> - The event name to register. B<URL> the script url, which will provide the event handling. B<PARAMS> - a hash reference of parameters to be passed to the handler subroutine as a parameter. B<OPTIONS> - a hash reference of options to be interpretted by the handler

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

=item B<update>

The id of element to be updated. If empty, the document body is updated. The following parameters are also taken under consideration if this one is specified:

=over 12

=item B<evalScripts>

True, if any script elements in the response should be evaluated using javascript's eval() function

=item B<insertion>

If omitted, the contents of the container will be replaced with the response of the script. Otherwise, depeding on the value, the reponse will be placed around the exsting content. Valid values are:

=over 16

=item B<after>

Will be inserted as the next sibling of the container, 

=item B<before>

Will be inserted as the previous sibling of the container,

=item B<bottom>

Will be inserted as the last child of the container,

=item B<top>

Will be inserted as the first child of the container

=back

=back

=back

=cut

sub registerEvent {
    my ($self, $event, $url, $params, $options) = @_;

    return $self if $self->{_handlers}{$event};

    $options =
        $self->can('_registerEvent')
      ? $self->_registerEvent($event, $params, $options) || $options
      : $options;
    $self->{_handlers}{$event} = [$url, $params, $options];

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

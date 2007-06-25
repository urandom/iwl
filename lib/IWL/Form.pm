#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Form;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Form - a form object

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Form

=head1 DESCRIPTION

The form object provides the B<<form>> html markup, with all it's attributes.

=head1 CONSTRUCTOR

IWL::Form->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<form>> markup would have.

=head1 SIGNALS

=over 4

=item B<submit>

Fires when a form is submitted

=item B<reset>

Fires when a form is reset

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "form";
    $self->{_signals} = {
        %{$self->{_signals}},
        submit => 1,
        reset  => 1,
    };

    return $self;
}

=head1 METHODS

=over 4

=item B<setAction> (B<ACTION>)

Sets the action of the form to B<ACTION>

Parameter: B<ACTION> - the action of form processing

=cut

sub setAction {
    my ($self, $action) = @_;

    return $self->setAttribute(action => $action, 'uri');
}

=item B<getAction>

Returns the form action

=cut

sub getAction {
    return shift->getAttribute('action', 1);
}

=item B<setMethod> (B<METHOD>)

Sets the method of the form to B<METHOD>

Parameter: B<METHOD> - the method of form processing

Returns false if the given method is invalid

=cut

sub setMethod {
    my ($self, $method) = @_;

    return unless (lc $method eq 'get' || lc $method eq 'post');

    return $self->setAttribute(method => $method);
}

=item B<getMethod>

Returns the form method

=cut

sub getMethod {
    return shift->getAttribute('method', 1) || 'get';
}

=item B<setEnctype> (B<ENCTYPE>)

Sets the content-type of the form to B<ENCTYPE>

Parameter: B<ENCTYPE> - the content-type of form processing

=cut

sub setEnctype {
    my ($self, $enctype) = @_;

    return $self->setAttribute(enctype => $enctype);
}

=item B<getEnctype>

Returns the content-type of the form

=cut

sub getEnctype {
    return shift->getAttribute('enctype', 1);
}

=item B<setTarget> (B<TARGET>)

Sets the target attribute for the form 

Parameters: B<TARGET> - the target

=cut

sub setTarget {
    my ($self, $target) = @_;

    return $self->setAttribute(target => $target);
}

=item B<getTarget>

Returns the form target

=cut

sub getTarget {
    return shift->getAttribute('target', 1);
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

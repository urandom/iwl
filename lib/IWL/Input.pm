#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Input;

use strict;

use base 'IWL::Widget';

=head1 NAME

IWL::Input - input widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input

=head1 DESCRIPTION

The Input widget provides the base for it's offspring widgets, such as the combobox or the text entry.

=head1 CONSTRUCTOR

IWL::Input->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<input>> markup would have.

IWL::Input->newMultipleFromHash (B<NAME> => B<VALUE>, ...)

Where B<NAME> => B<VALUE> is a hash of name/values for creating multiple input controls, where the keys are the names, and the values are the values. Returns an array of created inputs.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->{_tag} = "input";
    $self->{_noChildren} = 1;
    $self->{_signals} = {
        %{$self->{_signals}},
        change => 1,
        select => 1,
        blur   => 1,
        focus  => 1,
    };

    return $self;
}

sub newMultipleFromHash {
    my ($proto, @args) = @_;
    my @inputs;
    while (my $name = shift @args) {
	my $input = $proto->new(name => $name, value => shift @args);
	push @inputs, $input;
    }
    return @inputs;
}

=head1 METHODS

=over 4

=item B<setName> (B<NAME>)

Sets the name of the input to B<NAME>

Parameter: B<NAME> - the name to use

=cut

sub setName {
    my ($self, $name) = @_;

    return $self->setAttribute(name => $name);
}

=item B<getName>

Gets the name (attribute) of the input element.

=cut

sub getName {
    shift->getAttribute ('name');
}

=item B<setValue> (B<VALUE>)

Sets the value of the input to B<VALUE>

Parameter: B<VALUE> - the data to be set as the value

=cut

sub setValue {
    my ($self, $value) = @_;

    return $self->setAttribute(value => $value);
}

=item B<getValue>

Gets the value of the input

=cut

sub getValue {
    shift->getAttribute('value');
}

=item B<setDisabled> (B<BOOL>)

Sets whether the input will be disabled

Parameters: B<BOOL> - true if the input should be disabled (i.e. will not react to user input)

=cut

sub setDisabled {
    my ($self, $bool) = @_;

    if ($bool) {
	return $self->setAttribute("disabled");
    } else {
	return $self->deleteAttribute("disabled");
    }
}

=item B<extractState> (B<STATE>)

Update the IWL::Stash(3pm) B<STATE> according to the input state.

=cut

sub extractState {
    my ($self, $state) = @_;

    my $type = $self->getAttribute('type');
    return if $type && 'submit' eq lc $type;
    return if $type && 'image' eq lc $type;

    my $name = $self->getName;

    my $value = $self->getAttribute('value');
    $value = '' unless defined $value;

    $state->pushValues($name, $value);

    return 1;
}

=item B<applyState> (B<STATE>)

Update the input element according to the IWL::Stash(3pm) B<STATE>
object.  The B<STATE> will get modified, i.e. the "used" element
will be shifted from the according slot (name attribute) of the
state.

=cut

sub applyState {
    my ($self, $state) = @_;

    my $type = $self->getAttribute('type');
    return if $type && 'submit' eq lc $type;
    return if $type && 'image' eq lc $type;

    my $name = $self->getName;
    my $value = $state->shiftValue($name);
    $value = '' unless defined $value;

    $self->setValue($value);

    return 1;
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

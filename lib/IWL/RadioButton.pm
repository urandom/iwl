#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::RadioButton;

use strict;

use base 'IWL::Checkbox';

use IWL::Label;
use IWL::String qw(randomize);

=head1 NAME

IWL::RadioButton - a radio button

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Checkbox -> IWL::RadioButton

=head1 DESCRIPTION

The radio button provides a radio button most commonly used in forms.

=head1 CONSTRUCTOR

IWL::RadioButton->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  checked: set to true if the check button should be checked on default
  label: set the label of the checkbutton

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);

    $self->setAttribute(type => 'radio');
    $self->{_defaultClass} = 'radiobutton';

    my $id = $args{id} || randomize($self->{_defaultClass});
    $self->setId($id);
    $self->setName($args{name}) if $args{name};

    return $self;
}

=head1 METHODS

=over 4

=item B<setGroup> (B<NAME>)

Sets the radio button to the name of the given group. This is an alias to the setName method, since html doesn\'t have groups.

Parameter: B<NAME> - the name of the group

=cut

sub setGroup {
    my ($self, $name) = @_;

    return $self->setName($name);
}

# Overrides
#
=item B<applyState> (B<STATE>)

Update the input element according to the IWL::Stash(3pm) B<STATE>
object.  The B<STATE> will get modified, i.e. the "used" element
will be shifted from the according slot (name attribute) of the
state.

=cut

sub applyState {
    my ($self, $state) = @_;

    my $name = $self->getName;

    if ($state->existsKey($name)) {
	my $my_value = $self->getAttribute('value', 1);
	my $set_value = $state->getValues($name);

	if (defined $my_value && defined $set_value 
	    && $my_value eq $set_value) {
	    $self->setChecked(1);
	    $state->popValue($name);
	} else {
	    $self->setChecked(0);
	}
    } else {
	$self->setChecked(0);
    }

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

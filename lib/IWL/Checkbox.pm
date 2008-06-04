#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Checkbox;

use strict;

use base 'IWL::Input';

use IWL::Label;
use IWL::String qw(randomize);

=head1 NAME

IWL::Checkbox - a checkbox

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::Checkbox>

=head1 DESCRIPTION

The checkbox provides a checkbox most commonly used in forms.

=head1 CONSTRUCTOR

IWL::Checkbox->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<checked>

Set to true if the checkbox should be checked on default

=item B<label>

Set the label of the checkbox

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setLabel> (B<TEXT>)

Sets the text of the checkbox label

Parameter: B<TEXT> - the text.

=cut

sub setLabel {
    my ($self, $text) = @_;

    $self->{_label}{_ignore} = 0;
    $self->{_label}->setText($text);
    return $self;
}

=item B<getLabel>

Gets the text of the checkbox label

=cut

sub getLabel {
    return shift->{_label}->getText;
}

=item B<setChecked> (B<BOOL>)

Sets whether the checkbox is checked or not

Parameter: B<BOOL> - a boolean value.

=cut

sub setChecked {
    my ($self, $bool) = @_;

    if ($bool) {
        return $self->setAttribute(checked => 'checked');
    } else {
        return $self->deleteAttribute('checked');
    }
}

=item B<isChecked>

Returns true if the checkbox is checked, false otherwise.

=cut

sub isChecked {
    my ($self) = @_;

    return unless $self->hasAttribute('checked');

    return $self;
}

# Overrides
#

=item B<extractState> (B<STATE>)

Update the L<IWL::Stash> B<STATE> according to the input state.

=cut

sub extractState {
    my ($self, $state) = @_;

    my $name = $self->getName;

    if ($self->isChecked) {
	my $value = $self->getAttribute('value', 1);
	$value = 'on' unless defined $value;
	$state->pushValues($name, $value);
    }

    return 1;
}

=item B<applyState> (B<STATE>)

Update the input element according to the L<IWL::Stash> B<STATE>
object.  The B<STATE> will get modified, i.e. the "used" element
will be shifted from the according slot (name attribute) of the
state.

=cut

sub applyState {
    my ($self, $state) = @_;

    my $name = $self->getName;
    if ($state->existsKey($name)) {
	$self->setChecked (1);
	my $value = $state->popValue($name);
	$value = '' unless defined $value;
	$self->setValue($value);
    } else {
	$self->setChecked(0);
    }

    return 1;
}

sub setId {
    my ($self, $id, $control_id) = @_;

    $self->SUPER::setId($id)               or return;
    $self->{_label}->setId($id . '_label') or return;

    $self->{_label}->setAttribute(for => $id);
    return $self->setName($id);
}

sub setClass {
    my ($self, $class) = @_;

    $self->{_label}->setClass($class . '_label');
    return $self->SUPER::setClass($class) or return;
}

sub setTitle {
    my ($self, $title) = @_;

    $self->{_label}->setTitle($title);
    return $self->SUPER::setTitle($title);
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;
    $self->prependClass($self->{_defaultClass});
    return $self->{_label}->prependClass($self->{_defaultClass} . '_label');
}

# FIXME create an IWL::InputLabel, so that the necessary signals are inherited from IWL::Input
sub _init {
    my ($self, %args) = @_;
    my $label = IWL::Label->new(expand => 0);

    $self->{_label} = $label;
    $self->appendAfter($label);
    $self->{_defaultClass} = 'checkbox';

    my $id = $args{id} || randomize($self->{_defaultClass});
    $self->setId($id);

    $label->{_ignore} = 1;
    $label->{_tag} = 'label';
    $self->setChecked(1) if $args{checked};
    if ($args{label}) {
        $label->{_ignore} = 0;
        $label->setText($args{label});
    }
    delete @args{qw(id label checked)};

    $self->setAttribute(type => 'checkbox');
    $self->_constructorArguments(%args);

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

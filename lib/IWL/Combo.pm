#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Combo;

use strict;

use base 'IWL::Input';

=head1 NAME

IWL::Combo - a combo box widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Combo

=head1 DESCRIPTION

The Combo widget provides a wrapper for the B<<select>> markup tag.

=head1 CONSTRUCTOR

IWL::Combo->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values corresponding to the attributes that a regular B<<select>> markup would have.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(%args);
    $self->{_tag} = "select";
    $self->{_defaultClass} = 'combo';
    $self->{_noChildren} = 0;

    return $self;
}

=head1 METHODS

=over 4

=item B<appendOption> (B<TEXT>, B<VALUE>, [B<SELECTED>])

Adds an option to the combobox.

Parameter: B<TEXT> - the text to be added, B<VALUE> - the value that will be passed along, SELECTED - true if the option is selected

=cut

sub appendOption {
    my ($self, $text, $value, $sel) = @_;

    require IWL::Combo::Option;
    my $option = IWL::Combo::Option->new;

    $option->setSelected($sel);
    $value = $text unless defined $value;
    $option->setValue($value);
    $option->setText($text);

    return $self->appendChild($option);
}

=item B<setMultiple> (B<BOOL>)

Sets whether the combo box will have multiple selection

Parameters: B<BOOL> - true if the combo box should be multiple-selection enabled

=cut

sub setMultiple {
    my ($self, $bool) = @_;

    if ($bool) {
	return $self->setAttribute("multiple");
    } else {
	return $self->deleteAttribute("multiple");
    }
}

=item B<extractState> (B<STATE>)

Update the IWL::Stash(3pm) B<STATE> according to the combo state,
ie. reflect the selected and unselected entries.

Note that this method does not work absolutely correct if you have
multiple HTML input elements with the same name (attribute).  It 
will update B<STATE> as if it was the only element in the entire form.

=cut

sub extractState {
    my ($self, $state) = @_;

    my $name = $self->getName;
    $state->deleteValues($name);
    my $children = $self->{childNodes};
    my @values;
    my $first_value;
    foreach my $child (@$children) {
	if ($child->isa ('IWL::Combo::Option')) {
	    my $value = $child->getAttribute('value');
	    $value = '' unless defined $value;

	    $first_value = $value unless defined $first_value;
	    
	    $state->pushValues($name, $value) if $child->getSelected;
	}
    }

    unless ($state->getValues($name)) {
	$state->pushValues($name, $first_value) if defined $first_value;
    }
    
    return 1;
}

sub applyState {
    my ($self, $state) = @_;

    my $name = $self->getName;
    my @values = $state->deleteValues($name);
    my %values = map {$_ => 1} @values;
    my $children = $self->{childNodes};
    
    foreach my $child (@$children) {
	if ($child->isa('IWL::Combo::Option')) {
	    my $value = $child->getAttribute('value');
	    
	    if (defined $value && exists $values{$value}) {
		$child->setSelected(1);
	    } else {
		$child->setSelected(0);
	    }
	}
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

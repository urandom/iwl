#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::NavBar;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize);

=head1 NAME

IWL::NavBar - a navigation bar

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::NavBar

=head1 DESCRIPTION

The Navigation Bar provides a breadcrumb style navigation

=head1 CONSTRUCTOR

IWL::NavBar->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
 - delimeter : the delimeter between the crumbs (defaults to "/")

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new();

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendPath> (B<TEXT>, B<CALLBACK>)

Appends a crumb to the navbar.

Parameters: B<TEXT> - the label of the crumb, B<CALLBACK> - the click callback

=cut

sub appendPath {
    my ($self, $text, $callback) = @_;
    my $delim = IWL::Label->new(class => 'nav_delim');
    my $label = IWL::Label->new(class => 'nav_crumb');

    $delim->setText($self->{__delimeter});
    $label->setText($text);
    $label->signalConnect(click => $callback);
    $self->{__crumbCon}->appendChild($delim);

    return $self->{__crumbCon}->appendChild($label);
}

=item B<appendCombo> (B<TEXT>, B<VALUE>)

Appends an element to the combo of the navbar.

Parameters: B<TEXT> - the label of the crumb, B<VALUE> - the data value

=cut

sub appendCombo {
    my ($self, $text, $value) = @_;
    return $self->{__navCombo}->appendOption($text, $value);
}

=item B<setComboChangeCB> (B<CALLBACK>)

Sets the combobox change callback

Parameters: B<CALLBACK> - the change callback

=cut

sub setComboChangeCB {
    my ($self, $callback) = @_;
    return $self->{__navCombo}->signalConnect(change => $callback);
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{__crumbCon}->setId($id . '_crumb_con');
    return $self->{__navCombo}->setId($id . '_nav_combo');
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__crumbCon}->prependClass($self->{_defaultClass} . '_crumb_con');
    return $self->{__navCombo}->prependClass($self->{_defaultClass} . '_nav_combo');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $crumb_con = IWL::Container->new(inline => 1);
    my $delim     = IWL::Label->new(class => 'nav_delim');
    my $combo     = IWL::Combo->new;
    my $delimeter;

    if ($args{delimeter}) {
        $delimeter = $args{delimeter};
    } else {
        $delimeter = '/';
    }
    delete $args{delimeter};


    $delim->setText($delimeter);

    $self->{_defaultClass} = 'navbar';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $self->{__delimeter} = $delimeter;
    $self->{__crumbCon}  = $crumb_con;
    $self->{__navCombo}  = $combo;
    $self->appendChild($crumb_con);
    $self->appendChild($delim);
    $self->appendChild($combo);
    return $self->_constructorArguments(%args);
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

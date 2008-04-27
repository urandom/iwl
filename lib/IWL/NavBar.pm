#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::NavBar;

use strict;

use base 'IWL::Container';

use IWL::Label;
use IWL::Combo;
use IWL::String qw(randomize);

=head1 NAME

IWL::NavBar - a navigation bar

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::NavBar>

=head1 DESCRIPTION

The Navigation Bar provides a breadcrumb style navigation

=head1 CONSTRUCTOR

IWL::NavBar->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<delimete>

The delimeter between the crumbs (defaults to "/")

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new();

    $self->_init(%args);

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
    my ($delim, $label) = $self->__createCrumb($text, $callback);

    $self->{__crumbCon}->appendChild($delim, $label);
    return $label;
}

=item B<prependPath> (B<TEXT>, B<CALLBACK>)

Prepends a crumb to the navbar.

Parameters: B<TEXT> - the label of the crumb, B<CALLBACK> - the click callback

=cut

sub prependPath {
    my ($self, $text, $callback) = @_;
    my ($delim, $label) = $self->__createCrumb($text, $callback);

    $self->{__crumbCon}->prependChild($delim, $label);
    return $label;
}

=item B<appendOption> (B<TEXT>, B<VALUE>)

Appends an option to the combo of the navbar.

Parameters: B<TEXT> - the label of the option, B<VALUE> - the data value

=cut

sub appendOption {
    my ($self, $text, $value) = @_;
    return $self->{__navCombo}->appendOption($text, $value);
}

=item B<prependOption> (B<TEXT>, B<VALUE>)

Prepends an option to the combo of the navbar.

Parameters: B<TEXT> - the label of the option, B<VALUE> - the data value

=cut

sub prependOption {
    my ($self, $text, $value) = @_;
    return $self->{__navCombo}->prependOption($text, $value);
}

=item B<setComboChangeCB> (B<CALLBACK>)

Sets the combobox change callback

Parameters: B<CALLBACK> - the change callback

=cut

sub setComboChangeCB {
    my ($self, $callback) = @_;
    $self->{__navCombo}->signalConnect(change => $callback);
    return $self;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{__crumbCon}->setId($id . '_crumb_con');
    $self->{__navCombo}->setId($id . '_combo');
    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__crumbCon}->prependClass($self->{_defaultClass} . '_crumb_con');
    $self->{__navCombo}->prependClass($self->{_defaultClass} . '_combo');
    return $self;
}

sub _init {
    my ($self, %args) = @_;
    my $crumb_con = IWL::Container->new(inline => 1);
    my $delim     = IWL::Label->new;
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
    $delim->{_defaultClass} = $self->{_defaultClass} . '_delim';
    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $self->{__delimeter} = $delimeter;
    $self->{__crumbCon}  = $crumb_con;
    $self->{__navCombo}  = $combo;
    $self->appendChild($crumb_con);
    $self->appendChild($delim);
    $self->appendChild($combo);
    return $self->_constructorArguments(%args);
}

# Internal
#
sub __createCrumb {
    my ($self, $text, $callback) = @_;

    my $delim = IWL::Label->new;
    my $label = IWL::Label->new;

    $delim->{_defaultClass} = $self->{_defaultClass} . '_delim';
    $label->{_defaultClass} = $self->{_defaultClass} . '_crumb';

    $delim->setText($self->{__delimeter});
    $label->setText($text);
    $label->signalConnect(click => $callback);

    return $delim, $label;
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

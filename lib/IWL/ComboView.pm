#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::ComboView;

use strict;

use base 'IWL::Widget';

use IWL::Table::Container;
use IWL::Table::Row;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::ComboView - a combo widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::ComboView>

=head1 DESCRIPTION

The ComboView widget is similar to the L<IWL::Combo> widget, but uses a L<IWL::TreeModel> to represent its data

=head1 CONSTRUCTOR

IWL::ComboView->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<model>

The L<IWL::TreeModel> for the ComboView

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setModel> (B<MODEL>)

Sets the model for the view

Parameter: B<MODEL> - an L<IWL::TreeModel>

=cut

sub setModel {
    my ($self, $model) = @_;

    $self->{_model} = $model;

    return $self;
}

=item B<getModel>

Returns the currently assigned model of the view

=cut

sub getModel {
    return shift->{_model};
}

# Overrides
#
sub addClearButton {}
sub setPassword {}
sub isPassword {}
sub setText {}
sub getText {}
sub setDefaultText {}
sub getDefaultText {}
sub setAutoComplete {}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->prependClass($self->{_defaultClass});
    $self->{__button}->prependClass($self->{_defaultClass} . '_button');
    $self->{__content}->prependClass($self->{_defaultClass} . '_content');
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    $self->SUPER::_realize;
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.ComboView.create('$id', $options);");
}

sub _init {
    my ($self, %args) = @_;
    my $body          = IWL::Table::Container->new;
    my $row           = IWL::Table::Row->new;
    my $button        = IWL::Container->new;
    my $content       = IWL::Container->new;

    $self->setAttributes(cellpadding => 0, cellspacing => 0);
    $self->appendChild($body);
    $body->appendChild($row);
    $row->appendCell($content);
    $row->appendCell($button);

    $self->{_defaultClass} = 'comboview';
    $args{id} ||= randomize('comboview');

    $self->{_tag} = 'table';
    $self->{__button}  = $button;
    $self->{__content} = $content;
    $self->requiredJs('comboview.js');
    $self->_constructorArguments(%args);

    return $self;
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

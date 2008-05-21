#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::ComboView;

use strict;

use base 'IWL::Widget';

use IWL::Container;
use IWL::Table::Container;
use IWL::Table::Row;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Locale::TextDomain qw(org.bloka.iwl);

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

    $self->{_model}->remove if $self->{_model};
    $self->{_model} = $model;
    $self->{__content}{parentNode}->appendChild($model);

    return $self;
}

=item B<getModel>

Returns the currently assigned model of the view

=cut

sub getModel {
    return shift->{_model};
}

=item B<setCellAttributes> (B<INDEX>, B<ATTRIBUTES>)

Sets the cell attributes for a particular cell index

Parameter: B<INDEX> - a cell index, B<ATTRIBUTES> - a hash reference of attributes, with the following possible keys:

=over 8

=item B<renderTemplate>

=item B<renderFunction>

=back

=cut

sub setCellAttributes {
    my ($self, $index, $attr) = @_;
    return unless %$attr;

    $self->{_options}{cellAttributes}[$index] = $attr;

    return $self;
}

=item B<getCellAttributes> (B<INDEX>)

Sets the get attributes for a particular cell index

Parameter: B<INDEX> - a cell index

=cut

sub getCellAttributes {
    return shift->{_options}{cellAttributes}[shift];
}

=item B<setActive> (B<PATH>)

Sets the active item of the L<IWL::ComboView>

Parameters: B<PATH> - the model path (or an index for flat models) for the item

=cut

sub setActive {
    my ($self, $path) = @_;
    $path = [$path] unless 'ARRAY' eq ref $path;
    $self->{_options}{initialPath} = $path;

    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;

    $self->prependClass($self->{_defaultClass} . '_editable')
        if $self->{_options}{editable};
    $self->prependClass($self->{_defaultClass});
    $self->{__button}->prependClass($self->{_defaultClass} . '_button');
    $self->{__content}->prependClass($self->{_defaultClass} . '_content');
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    return $self->_pushFatalError(__"No model was given!")
        unless $self->{_model};

    $self->SUPER::_realize;

    my $model = $self->{_model}->toJSON;

    $self->{__content}->setStyle(height => $self->{_options}{nodeHeight} . 'px')
        if $self->{_options}{nodeHeight};

    foreach my $attrs (@{$self->{_options}{cellAttributes}}) {
        next unless 'HASH' eq ref $attrs;
        $attrs->{renderTemplate} = $attrs->{renderTemplate}->getContent
            if $attrs->{renderTemplate};
    }
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.ComboView.create('$id', $model, $options);");
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
    $row->appendCell($button)->appendClass('comboview_button_cell');

    $self->{_defaultClass} = 'comboview';
    $args{id} ||= randomize('comboview');

    $self->{_tag} = 'table';
    $self->{_options}  = {columnWidth => [], cellAttributes => []};
    $self->{__button}  = $button;
    $self->{__content} = $content;

    $self->{_options}{columnWidth}    = $args{columnWidth} if 'ARRAY' eq ref $args{columnWidth};
    $self->{_options}{columnClass}    = $args{columnClass} if 'ARRAY' eq ref $args{columnClass};
    $self->{_options}{nodeHeight}     = $args{nodeHeight}  if $args{nodeHeight};
    $self->{_options}{maxHeight}      = $args{maxHeight}   if defined $args{maxHeight};

    $self->setModel($args{model}) if defined $args{model};

    if ('ARRAY' eq ref $args{cellAttributes}) {
        my $index = 0;
        $self->setCellAttributes($index++, $_)
            foreach @{$args{cellAttributes}};
    }

    delete @args{qw(columnWidth columnClass cellAttributes nodeHeight maxHeight model)};

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

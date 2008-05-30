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

A function which can manipulate the given cell for every node. It will receive the following parameters:

=over 12

=item B<cell>

The view cell for the particular node

=item B<type>

The data type for that cell

=item B<value>

The value of the cell

=item B<node>

The current node

=back

=item B<renderClass> (name => className, options => {})

I<renderFunction> and I<renderClass> are mutually exclusive. If a I<renderClass> is defined, it will be instantiated, and if it has a B<render> method, it will be used as a I<renderFunction>.

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

=item B<getActive>

Returns the active item path

=cut

sub getActive {
    return shift->{_options}{initialPath};
}

=item B<setPageControlOptions> (B<URL>, [B<PARAMS>, B<OPTIONS>])

Sets the L<IWL::PageControl> bind settings, if the used model requires page control.

For parameter documentation, see L<IWL::PageControl::bindToWidget>

=cut

sub setPageControlOptions {
    my $self = shift;

    $self->{__pageControlEvent} = \@_;
    return $self;
}

=item B<setNodeSeparatorCallback> (B<CALLBACK>)

Sets the JavaScript callback which will determine whether a node is rendered as a separator

Parameters: B<CALLBACK> - the JavaScript function. It will receive the B<MODEL> and current B<NODE> as its two parameters. If it returns a true value, the node will be rendered as a separator.

=cut

sub setNodeSeparatorCallback {
    my ($self, $callback) = @_;

    $self->{_options}{nodeSeparatorCallback} = $callback;

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
    $self->{__content}->prependClass($self->{_defaultClass} . '_content ' . $self->{_defaultClass} . '_content_empty');
}

sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    return $self->_pushFatalError(__"No model was given!")
        unless $self->{_model};

    $self->SUPER::_realize;

    my $model = $self->{_model};
    if ($model->{options}{limit} && $model->isFlat && @{$self->{__pageControlEvent}}) {
        my $event = ref($self->{_model}) . "::refresh";
        $event =~ s/::/-/g;
        $self->{_options}{pageControlEventName} = $event;
        $self->{_model}->registerEvent($event, @{$self->{__pageControlEvent}});

        require IWL::PageControl;
        my $limit = $model->{options}{limit};
        my $pager = IWL::PageControl->new(
            pageCount => int(($model->{options}{totalCount} -1 ) / $limit) + 1,
            pageSize => $limit,
            page => int($model->{options}{offset} / $limit) + 1,
            id => $id . '_pagecontrol',
            style => {position => 'absolute', left => '-1000px'},
        );
        $self->appendAfter($pager);
        $self->{_options}{pageControl} = $id . '_pagecontrol';
    }
    if ($self->{_options}{columnMap}) {
        foreach my $column (@{$self->{_options}{columnMap}}) {
            unless ($column =~ /^[0-9]+$/) {
                my $index = -1;
                foreach (@{$model->{columns}}) {
                    ++$index;
                    if ($_->{name} eq $column) {
                        $column = $index;
                        last;
                    }
                }
            }
        }
    } else {
        $self->{_options}{columnMap} = [0 .. @{$model->{columns}} - 1];
    }

    $self->{__content}->setStyle(height => $self->{_options}{nodeHeight} . 'px')
        if $self->{_options}{nodeHeight};

    foreach my $attrs (@{$self->{_options}{cellAttributes}}) {
        next unless 'HASH' eq ref $attrs;
        $attrs->{renderTemplate} = $attrs->{renderTemplate}->getContent
            if $attrs->{renderTemplate};
    }
    my $options = toJSON($self->{_options});

    $self->_appendInitScript("IWL.ComboView.create('$id', @{[$model->toJSON]}, $options);");
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
    $self->{__pageControlEvent} = [];

    $self->{_options}{columnWidth}    = $args{columnWidth} if 'ARRAY' eq ref $args{columnWidth};
    $self->{_options}{columnClass}    = $args{columnClass} if 'ARRAY' eq ref $args{columnClass};
    $self->{_options}{columnMap}      = $args{columnMap}   if 'ARRAY' eq ref $args{columnMap};
    $self->{_options}{nodeHeight}     = $args{nodeHeight}  if $args{nodeHeight};
    $self->{_options}{maxHeight}      = $args{maxHeight}   if defined $args{maxHeight};

    $self->setModel($args{model}) if defined $args{model};

    if ('ARRAY' eq ref $args{cellAttributes}) {
        my $index = 0;
        $self->setCellAttributes($index++, $_)
            foreach @{$args{cellAttributes}};
    }

    delete @args{qw(columnWidth columnClass columnMap cellAttributes nodeHeight maxHeight model)};

    $self->requiredJs('base.js', 'model.js', 'comboview.js');
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

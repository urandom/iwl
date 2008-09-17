#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::TreeView;

use strict;

use base 'IWL::Container';

use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::TreeView - a combo widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::TreeView>

=head1 DESCRIPTION

The TreeView widget is similar to the L<IWL::Tree> widget, but uses a L<IWL::ListModel> or L<IWL::TreeModel> to represent its data

=head1 CONSTRUCTOR

IWL::TreeView->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<model>

The L<IWL::ListModel> or L<IWL::TreeModel> for the TreeView

=item B<columnWidth>

An array reference of width per column, in pixels

=item B<columnClass>

An array reference of I<CSS> class names per column

=item B<columnMap>

An array reference of column names/indices which will be used to build the combo view

=item B<cellAttributes>

An array reference of cell attributes per column. See L<IWL::TreeView::setCellAttributes|IWL::TreeView/setCellAttributes>

=item B<multipleSelection>

Sets whether multiple items can be selected.

=item B<boxSelection>

If selecting multiple items is enabled, setting this option to a true value will allow the user to select multiple items by dragging a rectangular shape around them. Defaults to I<1>

=back

=head1 PROPERTIES

=over 4

=item B<header>

The header L<IWL::Container>

=item B<content>

The content L<IWL::Container>

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

Parameter: B<MODEL> - an L<IWL::ListModel> or L<IWL::TreeModel>

=cut

sub setModel {
    my ($self, $model) = @_;

    $self->unrequire($self->{_model}->getRequiredResources)
        if $self->{_model};

    if ($model) {
        $self->{_model} = $model;
        $self->require($model->getRequiredResources);
    }

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

Parameter: B<INDEX> - a cell index, B<ATTRIBUTES> - a hash of attributes, with the following possible keys:

=over 8

=item B<renderTemplate>

An L<IWL::Widget> which will be used to draw the cell, overriding the default template. Use L<IWL::String::tS|IWL::String/templateSymbol> to set replace-able template symbols.

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

=item B<resizable>

If true, the user can resize the column by dragging the right edge of the header cell

=item B<editable>

If true (or hashref), and if the renderer supports it, the cell will be made editable. If a hashref value is given, it will be used as the options for the editable. The following keys are currently recognized:

=over 12

=item B<commitChange>

If true, the new value of the cell will be used to set the corresponding value of the model node.

=back

Editable cells cause the view to emit the following signals:

=over 12

=item B<edit_begin>

Fires when editing has started. The callback receives the event and the value as parameters

=item B<edit_end>

Fires when editing has ended, changing the value of the cell. The callback receives the event and the value as parameters. Note that the actual node values do not change.

=back

=item B<booleanRadio>

By default, editable columns of type I<BOOLEAN> will be converted into checkboxes. If this option is true, radio buttons will be used instead. The radio button group will be based on the view's id, as well as the depth of the nodes. Furthermore, only one node in the current depth will have a true value.

=item B<header>

A hashref of options for the header of the column, this cell belongs to

=over 12

=item B<title>

The title, which is displayed in the header

=item B<template>

An L<IWL::Widget> which will be used to draw the header, overriding the default template

=back

=back

=cut

sub setCellAttributes {
    my ($self, $index, %attr) = @_;
    return unless %attr;

    $self->{_options}{cellAttributes}[$index] = \%attr;

    return $self;
}

=item B<getCellAttributes> (B<INDEX>)

Gets the get attributes for a particular cell index

Parameter: B<INDEX> - a cell index

=cut

sub getCellAttributes {
    return %{shift->{_options}{cellAttributes}[shift] || {}};
}

=item B<toggleActive> (B<PATH>)

Sets the active item of the L<IWL::TreeView>

Parameters: B<PATH> - the model path (or an index for flat models) for the item

=cut

sub toggleActive {
    my ($self) = shift;
    foreach my $path (@_) {
        push @{$self->{_options}{initialActive}}, 'ARRAY' eq ref $path
            ? $path : [$path];
    }

    return $self;
}

=item B<getActive>

Returns the active item path

=cut

sub getActive {
    return @{shift->{_options}{initialActive}};
}

=item B<setPageControlOptions> (B<URL>, [B<PARAMS>, B<OPTIONS>])

Sets the L<IWL::PageControl> bind settings, if the used model requires page control.

For parameter documentation, see L<IWL::PageControl::bindToWidget>

Returns a newly created IWL::PageControl with the given options. Users can place it manually, if the default location is not desired.

=cut

sub setPageControlOptions {
    my $self = shift;
    require IWL::PageControl;

    $self->{__pageControlEvent} = \@_;

    my $pager = IWL::PageControl->new();
    return $self->{__pager} = $pager;
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

=item B<setHeaderVisibility> (B<BOOL>)

Sets whether the header of the view is visible

Parameters: B<BOOL> - if true, the header will be visible

=cut

sub setHeaderVisibility {
    my ($self, $bool) = @_;

    $self->{_options}{headerVisible} = !(!$bool);

    return $self;
}

=item B<getHeaderVisibility>

Returns true if the header of the view is visible

=cut

sub getHeaderVisibility {
    return shift->{_options}{headerVisible};
}

=item B<setModelDragSource> (B<BOOL>, [B<ACTIONS>])

Enables or disables item dragging in the tree view

Parameters: B<BOOL> - if true, item dragging is enabled. B<ACTIONS> - Can be either B<MOVE> (I<default>) or B<COPY>, where B<MOVE> - with remove the node, associated with the item on a successfull drop.

=cut

sub setModelDragSource {
    my ($self, $bool, $actions) = @_;

    $self->{__dragSource} = !(!$bool);
    $self->{__dragSourceActions} = $actions;

    return $self;
}

=item B<setModelDragDest> (B<BOOL>, [B<ACTIONS>])

Enables or disables drag destination to the tree view items.

Parameters: B<BOOL> - if true, item destination is enabled. B<ACTIONS> - Can be either B<MOVE> (I<default>) or B<COPY>, where B<MOVE> - with remove the node, associated with the drag source item on a successfull drop.

=cut

sub setModelDragDest {
    my ($self, $bool, $actions) = @_;

    $self->{__dragDest} = !(!$bool);
    $self->{__dragDestActions} = $actions;

    return $self;
}

=item B<setReorderable> (B<BOOL>)

Enables automatic reordering of nodes via D&D

Parameters: B<BOOL> - if true, D&D reordering will be enabled

=cut

sub setReorderable {
    my ($self, $bool) = @_;
    $self->{__reorderable} = !(!$bool);

    return $self;
}

=item B<setColumnsReorderable> (B<BOOL>)

Enables automatic reordering of columns via D&D

Parameters: B<BOOL> - if true, D&D reordering will be enabled

=cut

sub setColumnsReorderable {
    my ($self, $bool) = @_;
    $self->{__columnsReorderable} = !(!$bool);

    return $self;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $id      = $self->getId;

    $self->SUPER::_realize;

    my $model = $self->{_model};
    if ($model) {
        if ($model->{options}{limit} && (!$model->isa('IWL::TreeModel')) && @{$self->{__pageControlEvent}}) {
            my $event = ref($self->{_model}) . "::refresh";
            $event =~ s/::/-/g;
            $self->{_options}{pageControlEventName} = $event;
            $self->{_model}->registerEvent($event, @{$self->{__pageControlEvent}});

            my $limit = $model->{options}{limit};
            $self->{__pager}->setPageOptions(
                pageCount => int(($model->{options}{totalCount} -1 ) / $limit) + 1,
                pageSize => $limit,
                page => int($model->{options}{offset} / $limit) + 1,
            );
            my $placed = !(!$self->{__pager}{parentNode});
            if ($placed) {
                $self->{_options}{placedPageControl} = 1;
            } else {
                $self->appendAfter($self->{__pager});
                $self->{__pager}->setStyle(position => 'absolute', left => '-1000px');
            }
            $self->{_options}{pageControl} = $self->{__pager}->getId;
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
    }

    foreach my $attrs (@{$self->{_options}{cellAttributes}}) {
        next unless 'HASH' eq ref $attrs;
        $attrs->{renderTemplate} = $attrs->{renderTemplate}->getContent
            if $attrs->{renderTemplate};
        $self->{_options}{editable} = 1 if $attrs->{editable};
    }
    $self->prependClass('iwl-view');
    $self->appendClass($self->{_defaultClass} . '_editable')
        if $self->{_options}{editable};
    my $options = toJSON($self->{_options});
    my $dragAction = 'IWL.Draggable.Actions.' . ($self->{__dragSourceActions} || 'MOVE');
    my $dropAction = 'IWL.Draggable.Actions.' . ($self->{__dragDestActions} || 'MOVE');

    $self->_appendInitScript(<<EOF);
(function() {
    var tv = IWL.TreeView.create('$id', @{[$model ? $model->toJSON : 'null']}, $options);
    if ('$self->{__dragSource}')
        tv.setModelDragSource(true, $dragAction);
    if ('$self->{__dragDest}')
        tv.setModelDragDest(true, $dropAction);
    if ('$self->{__reorderable}')
        tv.setReorderable(true);
    if ('$self->{__columnsReorderable}')
        tv.setColumnsReorderable(true);
})();
EOF
}

sub _init {
    my ($self, %args) = @_;
    my ($header, $content) = IWL::Container->newMultiple(2);

    $self->{_defaultClass}   = 'treeview';
    $header->{_defaultClass} = 'treeview_header';
    $content->{_defaultClass}   = 'treeview_content treeview_node_container iwl-node-container';
    $self->appendChild($header->setStyle(display => 'none'), $content);
    $self->{header} = $header;
    $self->{content} = $content;
    $args{id} ||= randomize('treeview');

    $self->{_options}  = {columnWidth => [], cellAttributes => []};
    $self->{__pageControlEvent} = [];

    $self->{_options}{columnWidth}   = $args{columnWidth}   if 'ARRAY' eq ref $args{columnWidth};
    $self->{_options}{columnClass}   = $args{columnClass}   if 'ARRAY' eq ref $args{columnClass};
    $self->{_options}{columnMap}     = $args{columnMap}     if 'ARRAY' eq ref $args{columnMap};

    $self->{_options}{multipleSelection} = $args{multipleSelection} if defined $args{multipleSelection};
    $self->{_options}{boxSelection}      = $args{boxSelection}      if defined $args{boxSelection};

    $self->setModel($args{model}) if defined $args{model};

    if ('ARRAY' eq ref $args{cellAttributes}) {
        my $index = 0;
        $self->setCellAttributes($index++, $_)
            foreach @{$args{cellAttributes}};
    }

    delete @args{qw(columnWidth columnClass columnMap multipleSelection boxSelection cellAttributes model)};

    $self->requiredJs('base.js', 'dist/dragdrop.js', 'dnd.js', 'dist/delegate.js', 'cellrenderer.js', 'queue.js', 'treeview.js');
    $self->_constructorArguments(%args);
    $self->{_customSignals} = {change => [], popup => [], popdown => [], edit_begin => [], edit_end => []};

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

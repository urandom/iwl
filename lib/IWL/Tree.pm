#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Tree;

use strict;

use IWL::String qw(randomize escape);
use IWL::JSON qw(toJSON);

use base qw(IWL::Table);

use Scalar::Util qw(weaken);

=head1 NAME

IWL::Tree - a tree widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table> -> L<IWL::Tree>

=head1 DESCRIPTION

The tree widget provides a container that holds cells arranged in a tree layout, with multiple rows. Inherits from L<IWL::Table>

=head1 CONSTRUCTOR

IWL::Tree->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

=over 4

=item B<list>

Boolean. true if the tree is a list.

=item B<multipleSelect>

True if the iconbox should be able to select multiple icons

=item B<scrollToSelection>

True if the selected row should be scrolled into visibility

=item B<alternate>

True if the tree should alternate

=item B<animate>

True if the tree should animate the collapse of its rows

=back

=head1 SIGNALS

=over 4

=item B<select_all>

Fires when all rows of the tree have been selected

=item B<unselect_all>

Fires when all rows of the tree have been unselected

=item B<row_activate>

Fires when a row has been activated by double-clicking on it, or pressing [Enter]

=item B<row_collapse>

Fires when a row has collapsed

=item B<row_expand>

Fires when a row has expanded

=back

=head1 EVENTS

=over 4

=item B<IWL-Tree-refresh>

Emitted when the tree has to be refreshed. This event is used by L<IWL::PageControl>. As a return first parameter, the perl callback has to return an arrayref of L<IWL::Tree::Row> objects. As a second return parameter, the perl callback can return the same values as the L<IWL::Iconbox> refresh event. These values will change the state of the L<IWL::PageControl> for this widget.

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<getAllBodyRows>

Returns an array of all the body rows of the tree

=cut

sub getAllBodyRows {
    my $self = shift;
    return keys %{$self->{_bodyRows}};
}

=item B<setList> (B<BOOL>)

Sets whether the tree is a list

Parameters: B<BOOL> - a boolean value

=cut

sub setList {
    my ($self, $bool) = @_;
    if ($bool) {
        $self->{_options}{list} = 1;
    } else {
        $self->{_options}{list} = 0;
    }
    return $self;
}

=item B<isList>

Returns true if the tree is a list

=cut

sub isList {
    return !(!shift->{_options}{list});
}

=item B<setSortableCallback> (B<COL_INDEX>, B<JS_CALLBACK>)

Sets the callback to provide the sorting function for the tree/list, based on the column with index B<COL_NUM>

Parameters: B<COL_INDEX> - the column index, B<JS_CALLBACK> - the javascript callback, which will receive the column index as a parameter, and must return a sorting function for the rows

=cut

sub setSortableCallback {
    my ($self, $col_index, $callback) = @_;

    push @{$self->{__sortables}}, [$col_index, $callback];
    return $self;
}

=item B<appendRow> (B<ROW>)

Appends an array of rows to the body to the tree. An alias to the B<appendBody> method.

Parameters: B<ROW> - a row of L<IWL::Tree::Row>

=cut

sub appendRow {
    my ($self, $row) = @_;
    return $self->appendBody($row);
}

=item B<prependRow> (B<ROW>)

Prepeds an array of rows to the body to the tree. An alias to the B<prependBody> method.

Parameters: B<ROW> - a row of L<IWL::Tree::Row>

=cut

sub prependRow {
    my ($self, $row) = @_;
    return $self->prependBody($row);
}


# Overrides
#
sub appendBody {
    my ($self, $row) = @_;

    $self->{_body}->appendChild($row);
    my $prev_row = $row->prevSibling;
    if ($prev_row) {
        $prev_row->{_lastRow} = 0;
    }
    $self->{_bodyRows}{$row} = 1;
    $row->{_tree} = $self and weaken $row->{_tree};
    $self->__flag_children($row);
    push @{$self->{_body}{_children}}, $row;

    $row->_rebuildPath;

    return $self;
}

sub prependBody {
    my ($self, $row) = @_;

    $self->{_body}->prependChild($row);
    $self->{_bodyRows}{$row} = 1;
    weaken($row->{_tree} = $self);
    $self->__flag_children($row);
    unshift @{$self->{_body}{_children}}, $row;

    $row->_rebuildPath;

    return $self;
}

sub appendHeader {
    my ($self, $row) = @_;
    $row->{_tree} = $self and weaken $row->{_tree};
    $row->setNavigation(0);
    $self->SUPER::appendHeader($row);
}

sub prependHeader {
    my ($self, $row) = @_;
    weaken($row->{_tree} = $self);
    $row->setNavigation(0);
    $self->SUPER::prependHeader($row);
}

sub appendFooter {
    my ($self, $row) = @_;
    $row->{_tree} = $self and weaken $row->{_tree};
    $self->SUPER::appendFooter($row);
}

sub prependFooter {
    my ($self, $row) = @_;
    weaken($row->{_tree} = $self);
    $self->SUPER::prependFooter($row);
}

# Protected
#
sub _realize {
    my $self  = shift;
    my $images = '{}';
    unless ($self->{_options}{list}) {
        my $cell = IWL::Tree::Cell->new;
        my $b    = escape($cell->_blank_indent->getJSON);
        my $i    = escape($cell->_row_indent->getJSON);
        my $l    = escape($cell->_l_junction->getJSON);
        my $l_e  = escape($cell->_l_expand->getJSON);
        my $l_c  = escape($cell->_l_collapse->getJSON);
        my $t    = escape($cell->_t_junction->getJSON);
        my $t_e  = escape($cell->_t_expand->getJSON);
        my $t_c  = escape($cell->_t_collapse->getJSON);
        $images = qq({b:"$b",i:"$i",l:"$l",l_e:"$l_e",l_c:"$l_c",t:"$t",t_e:"$t_e",t_c:"$t_c"});
    }
    my $id      = $self->getId;
    my $options = {};
    my $script;

    $self->prependClass('list') if $self->{_options}{list};
    $self->SUPER::_realize;
    $options->{multipleSelect}    = 1 if $self->{_options}{multipleSelect};
    $options->{isAlternating}     = 1 if $self->{_options}{alternate};
    $options->{animate}           = 1 if $self->{_options}{animate};
    $options->{scrollToSelection} = 1 if $self->{_options}{scrollToSelection};
    $options = toJSON($options);

    $self->_set_alternate if $self->{_options}{alternate};

    $script = "IWL.Tree.create('$id', $images, $options);";
    foreach my $sortable (@{$self->{__sortables}}) {
	$script .= "\$('$id').setCustomSortable($sortable->[0], $sortable->[1]);";
    }

    $self->_appendInitScript($script);
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-Tree-refresh') {
	$options->{method} = '_refreshResponse';
    } else {
	return $self->SUPER::_registerEvent($event, $params, $options);
    }

    return $options;
}

sub _refreshEvent {
    my ($event, $handler) = @_;
    my $response = IWL::Response->new;

    my ($list, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params})
      : (undef, undef);
    $list = [] unless ref $list eq 'ARRAY';

    $response->send(
        content => '{rows: ['
           . join(',', map {'"' . escape($_->getContent) . '"'} @$list)
           . '], extras: ' . (toJSON($extras) || 'null'). '}',
        header => IWL::Object::getJSONHeader,
    );
}

sub _init {
    my ($self, %args) = @_;
    my $options = {multipleSelect => 0, scrollToSelection => 0, list => 0, alternate => 0};
    my $default_class;

    $default_class = 'tree';

    $args{id} = randomize($default_class) if !$args{id};

    $options->{list} = 1 if $args{list};
    $options->{multipleSelect} = 1 if $args{multipleSelect};
    $options->{scrollToSelection} = 1 if $args{scrollToSelection};
    $options->{alternate} = 1 if $args{alternate};
    $options->{animate} = 1 if $args{animate};
    delete @args{qw(list multipleSelect scrollToSelection alternate)};

    $self->SUPER::_init(%args);
    $self->{_defaultClass} = $default_class;
    $self->requiredJs('base.js', 'tree.js');

    # All the rows from the body of the tree
    $self->{_bodyRows} = {};

    # Holds the custom sortable callbacks for the tree/list
    $self->{__sortables} = [];

    $self->{_options} = $options;
    $self->{_customSignals} = {
        select_all   => [],
        unselect_all => [],
        row_activate => [],
        row_collapse => [],
        row_expand   => []
    };
    $self->setSelectable(0);
}

# Internal
#
sub _set_alternate {
    my ($self, $row, $level) = @_;
    my $children;
    $level ||= 0;
    if ($row) {
        $children = $row->{_children};
    } else {
        $children = $self->{_body}{_children};
    }
    $children = [] unless $children;

    for (my $i = 0; $i < @$children; $i++) {
	$children->[$i]->prependClass($children->[$i]{_defaultClass} . '_' . $level . ($i % 2 ? "_alt" : ''));
	$self->_set_alternate($children->[$i], $level + 1) if $children->[$i]{_children};
    }
}

sub __flag_children {
    my ($self, $row) = @_;
    foreach my $child (@{$row->{_children}}) {
	$child->{_tree} = $self;
	$self->{_bodyRows}{$child} = 1;
	$self->__flag_children($child) if (scalar @{$child->{_children}});
    }
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

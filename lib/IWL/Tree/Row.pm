#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Tree::Row;

use strict;

use base qw(IWL::Table::Row);

use IWL::Tree::Cell;
use IWL::Container;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use Scalar::Util qw(weaken);

=head1 NAME

IWL::Tree::Row - a row widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Table::Row> -> L<IWL::Tree::Row>

=head1 DESCRIPTION

The Row widget provides a row for IWL::Tree(3pm). It inherits from IWL::Table::Row(3pm).

=head1 CONSTRUCTOR

IWL::Tree::Row->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=head1 SIGNALS

=over 4

=item B<select>

Fires when the row is selected

=item B<unselect>

Fires when the row is unselected

=item B<remove>

Fires when the row is removed

=item B<activate>

Fires when the row is activated

=item B<collapse>

Fires when the row has collapsed

=item B<expand>

Fires when the row has expanded

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $id = $args{id};
    delete @args{qw(id)};

    my $self = $class->SUPER::new(%args);

    # The children of the row
    $self->{_children} = [];

    # The parent row for this row
    $self->{_parentRow} = undef;

    # True if the row has/will have children
    $self->{_isParent} = 0;

    # True if the row is collapsed
    $self->{_collapsed} = 1;

    # True if the row is the last row of the tree
    $self->{_lastRow}    = 1;
    $self->{__navigation} = 1;

    # The path of the row
    $self->{path} = [];

    # The tree the row belongs to
    $self->{_tree} = undef;

    $self->{_customSignals} = {
        select   => [],
        unselect => [],
        activate => [],
        collapse => [],
        expand   => [],
        remove   => []
    };
    $self->{_defaultClass} = 'tree_row';
    $id ||= randomize($self->{_defaultClass});
    $self->setId($id);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendRow> (B<ROW>)

Adds a row as a child of another row in the tree.

Parameters: B<ROW> - the row to be appended

=cut

sub appendRow {
    my ($self, $row) = @_;

    return unless $row;

    push @{$self->{_children}}, $row;
    $self->{_isParent} = 1;

    my $total = @{$self->{_children}} - 1;
    $self->{_children}[$total - 1]->{_lastRow} = 0;

    weaken($row->{_parentRow} = $self);
    if ($self->{_tree}) {
	$row->{_tree} = $self->{_tree};
    }
    $self->_rebuildPath;
    return $self;
}

=item B<prependRow> (B<ROW>)

Prepends a row as a child of another row in the tree.

Parameters: B<ROW> - the row to be prepended 

=cut

sub prependRow {
    my ($self, $row) = @_;

    return unless $row;

    unshift @{$self->{_children}}, $row;
    $self->{_isParent} = 1;

    $row->{_parentRow} = $self and weaken $row->{_parentRow};
    if ($self->{_tree}) {
	$row->{_tree} = $self->{_tree};
    }
    $self->_rebuildPath;
    return $self;
}

=item B<getChildRows> (B<FLAT>)

Returns a list of the row objects appended or empty list if no rows have been appended.

Parameters: B<FLAT> - flase if the method should return all the subrows on all levels

=cut

sub getChildRows {
    my ($self, $flat) = @_;

    unless ($flat) {
        my @rows = ();
        foreach my $row (@{$self->{_children}}) {
            push @rows, $row;
            push @rows, @{$row->getChildRows($flat)};
        }
        return \@rows;
    }
    return $self->{_children};
}

=item B<expand> (B<BOOL>)

Expands or collapses the row

Parameters: B<BOOL> - true if the row should be expanded

=cut

sub expand {
    my ($self, $bool) = @_;

    if ($bool) {
        $self->{_collapsed} = 0;
    } else {
        $self->{_collapsed} = 1;
    }
    return $self;
}

=item B<makeParent>

Makes the row a parent row, even if it currently has no children

=cut

sub makeParent {
    my $self = shift;

    $self->{_isParent} = 1;
    return $self;
}

=item B<getPath>

Returns the row's path. The path itself is set when the row is appended to the tree or to another row.

=cut

sub getPath {
    my $self = shift;

    return $self->{path};
}

=item B<setPath>

Sets the row's path explicitly. The path then can be used to append child rows.

=cut

sub setPath {
    my $self = shift;
    my @path = @_;
    my $path;
    if (ref $path[0] eq 'ARRAY') {
	$path = $path[0];
    } else {
	$path = \@path;
    }

    $self->{path} = $path;
    $self->_rebuildPath;
    return $self;
}

=item B<getPrevRow>

Returns the previous row on the same level.

=cut

sub getPrevRow {
    my $self = shift;

    if (my $parent = $self->{_parentRow}) {

        # We don't care for the first row, as it doesn't have a previous sibling
        for (my $i = 1; $i < @{$parent->{_children}}; $i++) {
            return $parent->{_children}[$i - 1]
              if $parent->{_children}[$i] == $self;
        }
    } else {
        return $self->prevSibling;
    }
    return;
}

=item B<getNextRow>

Returns the next row on the same level.

=cut

sub getNextRow {
    my $self = shift;

    if (my $parent = $self->{_parentRow}) {
        for (my $i = 0; $i < @{$parent->{_children}} - 1; $i++) {
            return $parent->{_children}[$i + 1]
              if $parent->{_children}[$i] == $self;
        }
    } else {
        return $self->nextSibling;
    }
    return;
}

=item B<setSelected> (B<BOOL>)

Sets whether the row is the currently selected row.

Parameters: B<BOOL> - true if the row should be selected

=cut

sub setSelected {
    my ($self, $bool) = @_;
    if ($bool) {
	$self->{_selected} = 1;
    } else {
	$self->{_selected} = 0;
    }
    return $self;
}

=item B<isSelected>

Returns true if the row is selected

=cut

sub isSelected {
    return !(!shift->{_selected});
}

sub setNotLast {
    my $self = shift;

    $self->{_lastRow} = 0;
    return $self;
}

=head1 METHODS

=over 4

=item getParentRow

Returns the parent rows of the current row, if it has any

=cut

sub getParentRow {
    my $self = shift;

    return $self->{_parentRow};
}

=item getFirstChildRow

Returns the first childr row of the current row.

=cut

sub getFirstChildRow {
    my $self = shift;

    return $self->{_children}[0];
}

=item B<getLastChildRow>

Returns the last child row of the current row

=cut

sub getLastChildRow {
    my $self = shift;
    return $self->{_children}[-1];
}

=item getFromPath (B<PATH>)

Returns a row from a given path

Parameters: B<PATH> - the path array

=cut

sub getFromPath {
    my ($self, @path) = @_;

    return unless $self->{_tree};
    my @rows = @{$self->{_tree}->getAllBodyRows};
    foreach my $row (@rows) {
        return $row if @{$row->{path}} == @path;
    }
}

=item B<setNavigation> (B<BOOL>)

setNavigation is used to enable or disable the naviagtion of the row.
by default the navigation is enabled.

Parameters: B<BOOL> - a boolean value, true if navigation should be enabled
=cut

sub setNavigation {
    my ($self, $bool) = @_;
    $self->{__navigation} = $bool ? 1 : 0;

    return $self;
}

=item B<makeSortable> (B<COL_NUM>, [B<CALLBACK>, B<URL>])

Sorts the tree when the column is clicked. Should only be used for header rows.

Parameters: B<COL_NUM> - the column number, which will be used for sorting. B<CALLBACK> - an optional callback to be called instead of the default, B<URL> - URL of an ajax script to sort the tree and return the new content (with getContent()), B<CALLBACK> has no effect if B<URL> is set.

=cut

sub makeSortable {
    my ($self, $col_num, $callback, $url) = @_;
    my $cell = $self->{childNodes}[$col_num];
    return if !$cell;

    $cell->setStyle(cursor => 'pointer');
    $cell->{_sortable} = {enabled => 1, callback => $callback, url => $url};
    return $self;
}

# Overrides
#
sub getContent {
    my $self = shift;
    my $list = $self->{_tree} ? $self->{_tree}{_options}{list} : 0;

    $self->__prepend_nav if $self->{__navigation} && !$list;
    return $self->SUPER::getContent;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $tree = $self->{_tree};

    $self->SUPER::_realize;

    my $data  = {};
    $data->{path} = $self->getPath;
    @{$data->{childList}} = map { $_->getId } @{$self->{_children}};
    $data->{isParent}   = $self->{_isParent};
    $data->{collapsed}  = $self->{_collapsed};

    $self->setAttribute('iwl:treeRowData' => toJSON($data), 'uri');

    if ($self->{_parentRow} && $self->{_parentRow}{_collapsed}) {
        $self->setStyle(display => 'none');
    }
    if ($tree) {
	$tree->{_body}->insertAfter($self, @{$self->{_children}});
    } else {
	$self->appendAfter(@{$self->{_children}});
    }
}

sub _expandEvent {
    my ($event, $handler) = @_;

    IWL::Object::printJSONHeader;
    my ($list, $extras) = $handler->($event->{params}, $event->{options}{all})
        if 'CODE' eq ref $handler;
    $list = [] unless ref $list eq 'ARRAY';

    print '[' . join(',', map {$_->getJSON} @$list) . ']';
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-Tree-Row-expand') {
	$self->makeParent;
	$options->{method} = '_expandResponse';
    } else {
	return $self->SUPER::_registerEvent($event, $params, $options);
    }

    return $options;
}

sub _rebuildPath {
    my $self = shift;

    my $row  = (my $prev_row = $self->getPrevRow)
               || $self->{_parentRow}
               || $self;
    my @path = @{$row->{path}} ? @{$row->{path}} : (0);

    if ($prev_row) {
        $path[$#path]++;
    } elsif ($self->{_parentRow}) {
        $path[@path] = 0;
    }
    $self->{path} = \@path;

    foreach my $child (@{$self->{_children}}) {
        $child->_rebuildPath;
    }
    return $self;
}

sub _getAncestor {
    my ($self, $num) = @_;
    my $row = $self;

    return if $num < 1;

    for (1 .. $num) {
        $row = $row->{_parentRow};
    }

    return $row;
}

# Internal
#
sub __prepend_nav {
    my ($self) = @_;

    my $first_col = $self->{childNodes}[0];
    my $nav_con   = IWL::Container->new(
        inline => 1,
        id     => $self->getId . "_nav_con",
        class  => 'tree_nav_con'
    );
    if ($first_col) {
        $first_col->{_navCon} = $nav_con;
        $first_col->prependChild($nav_con);
    }

    return $self;
}

sub __create_cell {
    my ($self, $type, $attrs) = @_;
    return IWL::Tree::Cell->new(type => $type, %$attrs);
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

#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Tree;

use strict;

use IWL::Script;
use IWL::String qw(randomize escape);

use base qw(IWL::Table);

use Scalar::Util qw(weaken);
use JSON;

=head1 NAME

IWL::Tree - a tree widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Table -> IWL::Tree

=head1 DESCRIPTION

The tree widget provides a container that holds cells arranged in a tree layout, with multiple rows. Inherits from IWL::Table;

=head1 CONSTRUCTOR

IWL::Tree->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values:

  list: boolean. true if the tree is a list.
  multipleSelect: true if the iconbox should be able to select multiple
                  icons
  scrollToSelection: true if the selected row should be scrolled into
                     visibility
  alternate: true if the tree should alternate
  animate: true if the tree should animate the collapse of its rows

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $options = {multipleSelect => 0, scrollToSelection => 0, list => 0, alternate => 0};
    my $default_class;
    my $id;

    $default_class = 'tree';

    $id = randomize($default_class) if !$args{id};

    $options->{list} = 1 if $args{list};
    $options->{multipleSelect} = 1 if $args{multipleSelect};
    $options->{scrollToSelection} = 1 if $args{scrollToSelection};
    $options->{alternate} = 1 if $args{alternate};
    $options->{animate} = 1 if $args{animate};
    delete @args{qw(list multipleSelect scrollToSelection alternate)};

    my $self = $class->SUPER::new(%args);
    $self->{_defaultClass} = $default_class;
    $self->setId($id) if $id;
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

Parameters: B<ROW> - a row of IWL::Tree::Row(3pm)

=cut

sub appendRow {
    my ($self, $row) = @_;
    return $self->appendBody($row);
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
    weaken($row->{_tree} = $self);
    $self->__flag_children($row);
    push @{$self->{_body}{_children}}, $row;

    $row->_rebuildPath;

    return $self;
}

sub appendHeader {
    my ($self, $row) = @_;
    weaken($row->{_tree} = $self);
    $row->setNavigation(0);
    $self->SUPER::appendHeader($row);
}

sub appendFooter {
    my ($self, $row) = @_;
    weaken($row->{_tree} = $self);
    $self->SUPER::appendFooter($row);
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $cell    = IWL::Tree::Cell->new;
    my $script  = IWL::Script->new;
    my $b       = escape($cell->_blank_indent->getContent);
    my $i       = escape($cell->_row_indent->getContent);
    my $l       = escape($cell->_l_junction->getContent);
    my $l_e     = escape($cell->_l_expand->getContent);
    my $l_c     = escape($cell->_l_collapse->getContent);
    my $t       = escape($cell->_t_junction->getContent);
    my $t_e     = escape($cell->_t_expand->getContent);
    my $t_c     = escape($cell->_t_collapse->getContent);
    my $id      = $self->getId;
    my $options = {};

    $self->prependClass('list') if $self->{_options}{list};
    $self->SUPER::_realize;
    $options->{multipleSelect} = "true" if $self->{_options}{multipleSelect};
    $options->{isAlternating} = "true" if $self->{_options}{alternate};
    $options->{animate} = "true" if $self->{_options}{animate};
    $options->{scrollToSelection} = "true" if $self->{_options}{scrollToSelection};
    $options = objToJson($options);

    $self->{_header}->prependClass($self->{_defaultClass} . '_header');
    $self->{_footer}->prependClass($self->{_defaultClass} . '_footer');
    $self->{_body}->prependClass($self->{_defaultClass} . '_body');
    $self->_set_alternate if $self->{_options}{alternate};

    my $images = qq({b:"$b",i:"$i",l:"$l",l_e:"$l_e",l_c:"$l_c",t:"$t",t_e:"$t_e",t_c:"$t_c"});
    $script->prependScript("Tree.create('$id', $images, $options);");
    foreach my $sortable (@{$self->{__sortables}}) {
	$script->appendScript("\$('$id').setCustomSortable($sortable->[0], $sortable->[1])");
    }

    $self->_appendAfter($script);
}

sub _registerEvent {
    my ($self, $event, $params) = @_;

    my $handlers = {};
    if ($event eq 'IWL-Tree-refresh') {
	$handlers->{method} = '_refreshResponse';
        $handlers->{append} = $params->{append} ? 'true' : 'false';
    } else {
	$self->SUPER::_registerEvent($event, $params);
    }

    return $handlers;
}

sub _refreshEvent {
    my ($params, $handler) = @_;

    IWL::Object::printJSONHeader;
    my ($list, $user_extras) = $handler->($params->{userData})
        if 'CODE' eq ref $handler;
    $list = [] unless ref $list eq 'ARRAY';

    print '{rows: ['
           . join(',', map {'"' . escape($_->getContent) . '"'} @$list)
           . '], user_extras: ' . (objToJson($user_extras) || 'null'). '}';
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

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

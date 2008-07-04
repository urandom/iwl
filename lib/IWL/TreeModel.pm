#!/bin/false

package IWL::TreeModel;

use strict;

use base qw(IWL::ListModel);

use IWL::TreeModel::Node;

use IWL::String qw(randomize);

use Locale::TextDomain qw(org.bloka.iwl);

sub getNodeByPath {
    my ($self, $path) = @_;
    return unless 'ARRAY' eq ref $path;
    my $node = $self->{rootNodes}[shift @$path];
    $node = $node->{childNodes}[$_] foreach @$path;

    return $node;
}

sub insertNode {
    my ($self, $index, $parent) = @_;
    return IWL::TreeModel::Node->new($self, $index, $parent);
}

sub insertNodeBefore {
    my ($self, $sibling, $parent) = @_;
    return IWL::TreeModel::Node->new($self, $sibling->getIndex, $parent);
}

sub insertNodeAfter {
    my ($self, $sibling, $parent) = @_;
    return IWL::TreeModel::Node->new($self, $sibling->getIndex + 1, $parent);
}

sub prependNode {
    my ($self, $parent) = @_;
    return IWL::TreeModel::Node->new($self, 0, $parent);
}

sub appendNode {
    my ($self, $parent) = @_;
    return IWL::TreeModel::Node->new($self, -1, $parent);
}

sub each {
    my ($self, $iterator) = @_;
    foreach (@{$self->{rootNodes}}) {
        my $ret = $iterator->($_);
        last if $ret && 'last' eq $ret;
        next if $ret && 'next' eq $ret;
        $_->each($iterator);
    }
}

sub dataReader {
    my ($self, %options) = @_;
    $options{optionsList} = [qw(totalCount limit offset parentNode)]
        unless exists $options{optionsList};

    $self->SUPER::dataReader(%options);
}

=head1

Data:
  {
      options => {
          id => '',
          columnTypes => {},
          totalCount => int,
          limit => int,
          offset => int,
          preserve => boolean,
          parentNode => [],
      },
      nodes => [
        {
          values => ['Sample', 15],
          childNodes =>
              [
                   {
                       ...
                   }
              ],
        },
        {
          ...
        }
      ]
  }

=cut


# Protected
#
sub _init {
    my $self = shift;
    my ($columns, %args) = (@_ % 2 ? (shift, @_) : (undef, @_));

    $self->{options}{parentNode} = $args{parentNode} if 'ARRAY' eq ref $args{parentNode};
    delete $args{parentNode};

    $self->SUPER::_init($columns, %args);
    $self->{_classType} = 'IWL.TreeModel';
    push @{$self->{_requiredResources}{js}}, 'treemodel.js';
}

sub _requestChildrenEvent {
    my ($event, $handler) = @_;
    my %options = %{$event->{options}};
    my %params = %{$event->{params}};
    my $model = ($options{class} || __PACKAGE__)->new(
        $options{columns},
        preserve => 1,
        id => $options{id},
        parentNode => $options{parentNode}
    );

    $model = ('CODE' eq ref $handler)
      ? $handler->(\%params, $model, {values => $options{values}, allDescendants => $options{allDescendants}})
      : undef;
    IWL::RPC::eventResponse($event, {data => $model->toJSON, extras => {allDescendants => $options{allDescendants}}});
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-TreeModel-refresh') {
        $options->{method} = '_refreshResponse';
    } elsif ($event eq 'IWL-TreeModel-requestChildren') {
        $options->{method} = '_requestChildrenResponse';
    }

    return $options;
}

sub _refreshEvent {
    IWL::ListModel::_refreshEvent(@_);
}

sub _sortColumnEvent {
    IWL::ListModel::_sortColumnEvent(@_);
}

=head1

[ ['Sample', '15'], ['Foo', 2] ]
[ [['Sample', '15'], [children]], [['Foo', 2], [children]] ]

=cut

sub _readArray {
    my ($self, $array, %options) = @_;

    my $values = $options{valuesIndex};
    my $children = $options{childrenIndex};
    foreach my $item (@$array) {
        my $node = $self->appendNode($options{parent});
        unless (defined $values || defined $children) {
            my $index = 0;
            $node->setValues($index++, $_) foreach ('ARRAY' eq ref $item ? @$item : $item);
        } else {
            for (my $i = 0; $i < @$item; $i++) {
                if (defined $values && $values eq $i) {
                    my $index = 0;
                    $node->setValues($index++, $_)
                        foreach ('ARRAY' eq ref $item->[$i] ? @{$item->[$i]} : $item->[$i]);
                } elsif (defined $children && $children eq $i) {
                    $self->_readArray($item->[$i], parent => $node);
                }
            }
        }
    }
}

=head1

  [
    {
      childrenProperty => [ ... ],
      valuesProperty => [ ... ],
    },
    {
      ...
    }
  ]

  {
    someInfo => [],
    nodesProperty => 
      [
        {
          childrenProperty => [ ... ],
          valuesProperty => [ ... ],
        },
        {
          ...
        }
      ]
  }

=cut

sub _readHashList {
    my ($self, $list, %options) = @_;
    my $modifiers = {};
    my $values = $options{valuesProperty} || 'values';
    my $indices = 'ARRAY' eq ref $options{valuesIndices} ? $options{valuesIndices} : undef;
    my $children = $options{childrenProperty} || 'children';

    if (ref $list eq 'HASH') {
        $modifiers->{totalCount} = $list->{$options{totalCountProperty}};
        $modifiers->{limit} = $list->{$options{sizeProperty}};
        $modifiers->{offset} = $list->{$options{offsetProperty}};

        $list = $list->{$options{nodesProperty}} || [];
    }

    foreach my $item (@$list) {
        next unless 'HASH' eq ref $item;
        my $node = $self->appendNode($options{parent});
        $self->_readHashList($item->{$children}, %options, parent => $node)
            if ref $item->{$children} eq 'ARRAY';
        if (ref $item->{$values} eq 'ARRAY') {
            if ($indices) {
                my $i = 0;
                foreach my $index (@$indices) {
                    $node->setValues($i++, defined $index ? $item->{$values}[$index] : undef)
                }
            } else {
                my $index = 0;
                $node->setValues($index++, $_)
                    foreach @{$item->{$values}};
            }
        } elsif (ref $options{valueProperties} eq 'ARRAY') {
            my $index = 0;
            $node->setValues($index++, $item->{$_}) foreach @{$options{valueProperties}};
        }
    }

    return $modifiers;
}

1;

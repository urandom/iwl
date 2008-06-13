#!/bin/false

package IWL::TreeModel::Node;

use strict;

use base 'IWL::ListModel::Node';

sub insert {
    my ($self, $model, $index, $parent) = @_;
    return unless $model;

    $self->remove;
    if (!$self->{model} || $self->{model} != $model) {
        $self->_addModel($model);
        $self->each(sub { shift->_addModel($model) });
    }

    my $nodes;
    $index = -1 if !defined $index || $index < 0;

    if ($parent) {
        $self->{parentNode} = $parent;
        $nodes = $parent->{childNodes};
        $parent->{childCount}++;
    } else {
        $nodes = $model->{rootNodes};
    }

    $self->_addNodeRelationship($index, $nodes);

    $self->{columns} = [@{$model->{columns}}];
    
    return $self;
}

sub remove {
    my $self = shift;
    return unless $self->{model};
    my $parent = $self->{parentNode};
    $parent
        ? $parent->{childNodes} = [grep {$_ != $self} @{$parent->{childNodes}}]
        : $self->{model}{rootNodes} = [grep {$_ != $self} @{$self->{model}{rootNodes}}];

    $self->{parentNode} = undef;

    $self->_removeNodeRelationship;

    return $self;
}

sub clear {
    my $self = shift;
    return $self->each(sub { shift->remove });
}

sub getIndex {
    my $self = shift;
    return -1 unless $self->{model};
    my @list = $self->{parentNode}
        ? @{$self->{parentNode}{childNodes}}
        : @{$self->{model}{rootNodes}};
    my $index = 0;
    foreach (@list) {
        return $index if $_ == $self;
        ++$index;
    }
    return -1;
}

sub getDepth {
    my $self = shift;
    return -1 unless $self->{model};
    my ($depth, $node) = (0, $self);
    $depth++ while $node = $node->{parentNode};

    return $depth;
}

sub getPath {
    my $self = shift;
    return unless $self->{model};
    my ($path, $node) = ([$self->getIndex], $self->{parentNode});
    if ($node) {
        do {
            unshift @$path, $node->getIndex;
        } while ($node = $node->{parentNode});
    }

    return $path;
}

sub isAncestor {
    my ($self, $descendant) = @_;
    my $ret;
    $self->each(sub {
        if (shift == $descendant) {
            $ret = 1;
            return 'last';
        }
    });

    return $ret;
}

sub isDescendant {
    my ($self, $ancestor) = @_;
    my $node = $self->{parentNode};
    return unless $node;
    do {
        return 1 if $node == $ancestor;
    } while ($node = $node->{parentNode});
    return;
}

sub each {
    my ($self, $iterator) = @_;
    foreach (@{$self->{childNodes}}) {
        my $ret = $iterator->($_);
        last if $ret && 'last' eq $ret;
        next if $ret && 'next' eq $ret;
        $_->each($iterator);
    }
    return $self;
}

sub toObject {
    my $self = shift;
    my $object = $self->SUPER::toObject;
    $object->{childNodes} = [map {$_->toObject} @{$self->{childNodes}}]
        if @{$self->{childNodes}};
    $object->{childCount} = $self->{childCount};
    return $object;
}

# Protected
#
sub _init {
    my $self = shift;

    $self->{childNodes} = [];
    $self->{childCount} = undef;
    $self->SUPER::_init(@_);
}

1;

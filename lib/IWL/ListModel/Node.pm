#!/bin/false

package IWL::ListModel::Node;

use strict;

use IWL::JSON;

use base 'IWL::Error';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    
    $self->_init(@_);

    return $self;
}

sub insert {
    my ($self, $model, $index) = @_;
    return unless $model;

    $self->remove;
    $self->_addModel($model) if !$self->{model} || $self->{model} != $model;

    $index = -1 if !defined $index || $index < 0;
    $self->_addNodeRelationship($index, $model->{rootNodes});

    $self->{columns} = [@{$model->{columns}}];
    
    return $self;
}

sub remove {
    my $self = shift;
    return unless $self->{model};
    $self->{model}{rootNodes} = [grep {$_ != $self} @{$self->{model}{rootNodes}}];

    $self->_removeNodeRelationship;

    return $self;
}

sub getValues {
    my $self = shift;
    return unless $self->{model};
    return @{$self->{values}} unless @_;
    my @ret;
    push @ret, $self->{values}[$_] foreach @_;
    return @ret;
}

sub setValues {
    my $self = shift;
    return unless $self->{model};
    while (@_) {
        my @tuple = splice @_, 0, 2;
        next unless $self->{columns}[$tuple[0]];
        $self->{values}[$tuple[0]] = $tuple[1];
    }

    return $self;
}

sub getAttributes {
    my $self = shift;
    return %{$self->{attributes}} unless @_;
    my @ret;
    push @ret, $self->{attributes}{$_} foreach @_;
    return @ret;
}

sub setAttributes {
    my ($self, %attributes) = @_;
    while (my ($key, $value) = each %attributes) {
        $self->{attributes}{$key} = $value;
    }

    return $self;
}

sub getIndex {
    my $self = shift;
    return -1 unless $self->{model};
    my @list = @{$self->{model}{rootNodes}};
    my $index = 0;
    foreach (@list) {
        return $index if $_ == $self;
        ++$index;
    }
    return -1;
}

sub getPath {
    my $self = shift;
    return unless $self->{model};
    return [$self->getIndex];
}

sub toObject {
    my $self = shift;
    my $object = {values => $self->{values}};
    $object->{attributes} = $self->{attributes} if %{$self->{attributes}};
    return $object;
}

sub toJSON {
    return IWL::JSON::toJSON(shift->toObject);
}


# Protected
#
sub _init {
    my $self = shift;

    $self->{values} = [];
    $self->{attributes} =  {id => "$self" =~ /.*0x([0-9a-fA-F]+)/};
    $self->{previousSibling} = $self->{nextSibling} = undef;
    $self->insert(@_) if $_[0];
}

sub _addModel {
    my ($self, $model) = @_;
    $self->{model} = $model;
    if ($self->{columns}) {
        $self->{values} = []
            unless $self->_compareColumns($self->{columns}, $model->{columns});
    }
}

sub _removeModel {
    shift->{model} = undef;
}

sub _compareColumns {
    my ($self, $c1, $c2) = @_;
    return unless @$c1 == @$c2;
    for (my $i = 0; $i < @$c1; $i++) {
        return unless $c1->[$i]{type} eq $c2->[$i]{type};
    }

    return 1;
}

sub _addNodeRelationship {
    my ($self, $index, $nodes) = @_;
    my ($previous, $next);

    if ($index > -1) {
        splice @$nodes, $index, 0, $self;
        $previous = $nodes->[$index - 1];
        $next = $nodes->[$index + 1];
    } else {
        push @$nodes, $self;
        $previous = $nodes->[-2];
    }

    if ($previous) {
        $previous->{nextSibling} = $self;
        $self->{previousSibling} = $previous;
    }
    if ($next) {
        $next->{previousSibling} = $self;
        $self->{nextSibling} = $next;
    }
}

sub _removeNodeRelationship {
    my $self = shift;
    my ($next, $previous) = ($self->{nextSibling}, $self->{previousSibling});
    $next->{previousSibling} = $previous if $next;
    $previous->{nextSibling} = $next if $previous;

    $self->{nextSibling} = $self->{previousSibling} = undef;
    $self->_removeModel;
}

1;

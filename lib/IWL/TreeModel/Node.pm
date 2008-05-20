#!/bin/false

package IWL::TreeModel;

use strict;

use base 'IWL::Object';

use IWL::JSON qw(evalJSON toJSON);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;
    
    $self->_init(@_);

    return $self;
}

my ($addModel, $removeModel, $compareColumns);

sub insert {
    my ($self, $model, $parent, $index) = @_;
    return unless $model;

    $self->remove;
    if ($self->{model} != $model) {
        $addModel->($model, $self);
        $self->each(sub { $addModel->($model, shift) });
    }

    my ($previous, $next, $nodes);
    $index = -1 if !defined $index || $index < 0;

    if ($parent) {
        $self->{parentNode} = $parent;
        $nodes = $parent->{childNodes};
    } else {
        $nodes = $model->{rootNodes};
    }

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

    my ($next, $previous) = ($self->{nextSibling}, $self->{previousSibling});
    $next->{previousSibling} = $previous if $next;
    $previous->{nextSibling} = $next if $previous;

    $self->{parentNode} = $self->{nextSibling} = $self->{previousSibling} = undef;
    $removeModel->($self);
    $self->each($removeModel);

    return $self;
}

sub getValues {
    my $self = shift;
    return unless $self->{model};
    return $self->{values} unless @_;
    my @ret;
    push @ret, $self->{values}{$_} foreach @_;
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

sub each {
    my ($self, $iterator) = @_;
    foreach (@{$self->{childNodes}}) {
        $iterator->($_);
        $_->each($iterator);
    }
}

# Protected
#
sub _init {
    my $self = shift;

    $self->insert(@_) if $_[0];
}

# Private
#
$addModel = sub {
    my ($model, $node) = @_;
    $node->{model} = $model;
    if ($node->{columns}) {
        $node->{values} = []
            unless $compareColumns->($node->{columns}, $model->{columns});
    }
};

$removeModel = sub {
    shift->{model} = undef;
};

$compareColumns = sub {
    my ($c1, $c2) = @_;
    return unless @$c1 == @$c2;
    for (my $i = 0; $i < @$c1; $i++) {
        return unless $c1->[$i]{type} eq $c2->[$i]{type};
    }

    return 1;
};

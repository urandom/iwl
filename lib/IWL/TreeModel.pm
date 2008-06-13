#!/bin/false

package IWL::TreeModel;

use strict;

use base qw(IWL::Error IWL::RPC::Request);

use IWL::TreeModel::Node;

use IWL::String qw(randomize);
use IWL::JSON qw(evalJSON);

use Locale::TextDomain qw(org.bloka.iwl);

sub new {
    my $class = shift;
    my $self = bless {}, (ref($class) || $class);
    
    $self->_init(@_);

    return $self;
}

sub getId {
    return shift->{options}{id};
}

sub getNodeByPath {
    my ($self, $path) = @_;
    return unless 'ARRAY' eq ref $path;
    my $node = $self->{rootNodes}[shift @$path];
    $node = $node->{childNodes}[$_] foreach @$path;

    return $node;
}

sub isFlat {
    my $self = shift;
    my $ret = '';
    $self->each(sub {
        return 'last' if $ret = (
            $_[0]->{childNodes} && @{$_[0]->{childNodes}} > 0
        ) || $_[0]->{attributes}{isParent}
    });
    return !$ret;
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

sub clear {
    my $self = shift;
    $_->remove foreach @{$self->{rootNodes}};
    return $self;
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

my $typeIndex = -1;
my $Types = {};

sub addColumnType {
    my $self = UNIVERSAL::isa($_[0], 'IWL::TreeModel') ? shift : undef;
    foreach (@_) {
        $Types->{$_} = ++$typeIndex unless exists $Types->{$_};
    }

    return $self;
}

sub dataReader {
    my ($self, %options) = @_;
    my ($content, $data, $modifiers) = ('', undef, {});
    %options = (type => '', subtype => '', %{$self->{options}}, %options);

    if ($options{file}) {
        local *FILE;
        local $/ = undef;
        open FILE, $options{file}
            or return $self->_pushFatalError(__x(
                "Cannot open {FILE}: {ERROR}",
                FILE => $options{file},
                ERROR => $!,
            ));
        $content = <FILE>;
        close FILE;
    } elsif ($options{host}) {
        $options{port}  ||= 80;
        $options{uri}   ||= '/';
        $options{proto} ||= 'tcp';
        require IO::Socket;

        my $uri = $options{uri};
        if (defined $options{offset}) {
            $uri .=
                  (index($uri, '?') > -1 ? '&' : '?')
                . ($options{offsetParameter} || 'offset')
                . '=' . $options{offset};
        }
        if (defined $options{limit}) {
            $uri .=
                  (index($uri, '?') > -1 ? '&' : '?')
                . ($options{limitParameter} || 'limit')
                . '=' . $options{limit};
        }
        my $r = IO::Socket::INET->new(Proto => $options{proto}, PeerAddr => $options{host}, PeerPort => $options{port});
        my @printer = ("GET $uri HTTP/1.1", "Host: $options{host}:$options{port}");
        my $body;

        binmode $r;
        $r->print(join "\n", @printer, "\n");
        my ($headers, @content, $size) = ({});
        while (my $line = <$r>) {
            unless ($body) {
                if ($line eq "\n" || $line eq "\r\n") {
                    $body = 1;
                } else {
                    my @header = split ': ', $line, 2;
                    if (@header == 2) {
                        $header[1] =~ s/\r\n$//;
                        $headers->{$header[0]} = $header[1];
                    }
                }

                next;
            }
            if ($headers->{'Transfer-Encoding'} eq 'chunked') {
                $line =~ s/\r\n//;
                if (!defined $size) {
                    $size = hex($line);
                    next;
                }
                last if $size == 0;
                $content .= $line;

                if (length $content eq $size) {
                    push @content, $content;
                    $content = '';
                    undef $size;
                }
            } else {
                $content .= $line;
            }
        }
        $content = join '', @content if @content;
        $r->shutdown(2);
    } elsif ($options{data}) {
        $data = $options{data};
    }

    if ($options{type} eq 'storable') {
        eval "require Storable" or return
            $self->_pushFatalError($@);

        $data = Storable::thaw($content);
        if ($options{subtype} eq 'array') {
            $self->__readArray($data, %options);
        } else {
            $modifiers = $self->__readHashList($data, %options);
        }
    } elsif ($options{type} eq 'json') {
        $data = evalJSON($content, 1);
        if ($options{subtype} eq 'array') {
            $self->__readArray($data, %options);
        } else {
            $modifiers = $self->__readHashList($data, %options);
        }
    } elsif ($options{type} eq 'array') {
        $self->__readArray($data, %options);
    } else {
        $modifiers = $self->__readHashList($data, %options);
    }
    foreach (keys %$modifiers) {
        delete $modifiers->{$_} unless defined $modifiers->{$_};
    }
    $self->{options} = {
        %{$self->{options}},
        %$modifiers,
    };
    $self->{options}{preserve} = $options{preserve} if defined $options{preserve};

    $self->{options}{$_} = $options{$_} foreach
        grep {defined $options{$_}} qw(totalCount limit offset parentNode);

    return $self;
}

sub getScript {
    my $self = shift;

    my $data = $self->toJSON;
    return 'window.' . $self->{options}{id} . " = new IWL.TreeModel($data);";
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


sub toObject {
    my $self = shift;
    my $object = {options => {%{$self->{options}}, columnTypes => $Types}};
    $object->{columns} = $self->{columns};
    $object->{nodes} = [map {$_->toObject} @{$self->{rootNodes}}];

    return $object;
}

sub toJSON {
    return IWL::JSON::toJSON(shift->toObject);
}

sub registerEvent {
    my $self = shift;
    $self->SUPER::registerEvent(@_);
    $self->{options}{handlers} = $self->{_handlers};

    return $self;
}

# Protected
#
sub _init {
    my $self = shift;
    my ($columns, %args) = (@_ % 2 ? (shift, @_) : (undef, @_));
    my %options;

    if ($args{data}) {
        %options = %{$args{data}{options}};
        $columns = $args{data}{columns} if 'ARRAY' eq ref $args{data}{columns};
    } else {
        %options = %args;
        $columns = $args{columns} if 'ARRAY' eq ref $args{columns};
    }

    $self->{options}{totalCount} = $options{totalCount} if $options{totalCount};
    $self->{options}{offset}     = $options{offset}     if $options{offset};
    $self->{options}{limit}      = $options{limit}      if $options{limit};
    $self->{options}{preserve}   = $options{preserve}   if defined $options{preserve};
    $self->{options}{parentNode} = $options{parentNode} if 'ARRAY' eq ref $options{parentNode};
    $self->{options}{id} = $options{id} || randomize('treemodel');

    $self->{columns} = [];
    $self->{rootNodes} = [];
    $columns = [] unless 'ARRAY' eq ref $columns;

    return $self->_pushFatalError(__"No columns have been given.")
        unless @$columns;
    my $index = 0;
    foreach (@$columns) {
        # TRANSLATORS: {COLUMN} is a placeholder
        return $self->_pushFatalError(__x("Unknown column type: {COLUMN}", COLUMN => $_->{type}))
            unless exists $Types->{$_->{type}};
        $_->{type} = $Types->{$_->{type}};
        $self->{columns}[$index++] = $_;
    }
}

sub _refreshEvent {
    my ($event, $handler) = @_;
    my %options = %{$event->{options}};
    my %params = %{$event->{params}};
    $params{value} = $params{value} < 1
        ? 1
        : $params{value} > $params{pageCount}
            ? $params{pageCount}
            : $params{value} if $params{value};
    my $page = {
        input => $params{value},
        first => 1,
        prev => $params{page} - 1 || 1,
        next => $params{page} + 1 > $params{pageCount} ? $params{pageCount} : $params{page} + 1,
        last => $params{pageCount}
    }->{$params{type}};
    $options{offset} = ($page - 1) * $options{limit};
    my $model = ($options{class} || 'IWL::TreeModel')->new($options{columns}, preserve => 0, map {$_ => $options{$_}} qw(id totalCount limit offset));

    $model = ('CODE' eq ref $handler)
      ? $handler->(\%params, $model)
      : (undef, undef);
    my $limit = $model->{options}{limit};
    my $extras = {
        pageCount => int(($model->{options}{totalCount} -1 ) / $limit) + 1,
        pageSize => $limit,
        page => int($model->{options}{offset} / $limit) + 1,
    };

    IWL::RPC::eventResponse($event, {data => $model->toJSON, extras => $extras});
}

sub _requestChildrenEvent {
    my ($event, $handler) = @_;
    my %options = %{$event->{options}};
    my %params = %{$event->{params}};
    my $model = ($options{class} || 'IWL::TreeModel')->new($options{columns}, preserve => 1, id => $options{id}, parentNode => $options{parentNode});

    $model = ('CODE' eq ref $handler)
      ? $handler->(\%params, $model, {values => $options{values}})
      : undef;
    IWL::RPC::eventResponse($event, {data => $model->toJSON});
}

sub _sortColumnEvent {
    my ($event, $handler) = @_;
    my %options = %{$event->{options}};
    my %params = %{$event->{params}};
    my $model = ($options{class} || 'IWL::TreeModel')->new($options{columns}, preserve => 0, id => $options{id}, parentNode => $options{parentNode});

    $model = ('CODE' eq ref $handler)
      ? $handler->(\%params, $model)
      : undef;
    IWL::RPC::eventResponse($event, {data => $model->toJSON});
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

# Internal
#
=head1

[ ['Sample', '15'], ['Foo', 2] ]
[ [['Sample', '15'], [children]], [['Foo', 2], [children]] ]

=cut

sub __readArray {
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
                    $self->__readArray($item->[$i], parent => $node);
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

sub __readHashList {
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
        $self->__readHashList($item->{$children}, %options, parent => $node)
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

addColumnType(qw(NONE STRING INT FLOAT BOOLEAN COUNT));

1;

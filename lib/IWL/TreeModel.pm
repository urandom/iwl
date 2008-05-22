#!/bin/false

package IWL::TreeModel;

use strict;

use base 'IWL::Error';

use IWL::TreeModel::Node;

use IWL::String qw(randomize);
use IWL::JSON qw(evalJSON);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    
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
        return 'last' if $ret = $_[0]->{childNodes} && @{$_[0]->{childNodes}} > 0
    });
    return !$ret;
}

sub insertNode {
    my ($self, $parent, $index) = @_;
    return IWL::TreeModel::Node->new($self, $parent, $index);
}

sub insertNodeBefore {
    my ($self, $parent, $sibling) = @_;
    return IWL::TreeModel::Node->new($self, $parent, $sibling->getIndex);
}

sub insertNodeAfter {
    my ($self, $parent, $sibling) = @_;
    return IWL::TreeModel::Node->new($self, $parent, $sibling->getIndex + 1);
}

sub prependNode {
    my ($self, $parent) = @_;
    return IWL::TreeModel::Node->new($self, $parent, 0);
}

sub appendNode {
    my ($self, $parent) = @_;
    return IWL::TreeModel::Node->new($self, $parent, -1);
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
    %options = (type => '', subtype => '', %options);

    if ($options{file}) {
        local *FILE;
        local $/ = undef;
        open FILE, $options{file};
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
    $self->{options} = {
        %{$self->{options}},
        %$modifiers,
        preserve => defined $options{preserve} ? $options{preserve} : 1,
    };

    $self->{options}{$_} = $options{$_} foreach
        grep {defined $options{$_}} qw(totalCount limit offset index parentNode);

    return $self;
}

sub getScript {
    my $self = shift;

    my ($even, @script) = (1);
    push @script, 'window.' . $self->{options}{id} . ' = new IWL.TreeModel();';

    return join "\n", @script;
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
          index => int,
      },
      parentNode => {},
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
    $object->{columns} = [map {$_->{type}, $_->{name}} @{$self->{columns}}];
    $object->{nodes} = [map {$_->toObject} @{$self->{rootNodes}}];

    return $object;
}

sub toJSON {
    return IWL::JSON::toJSON(shift->toObject);
}

# Protected
#
sub _sortColumnEvent {
    my ($event, $handler) = @_;
    my $response = IWL::Response->new;

    my ($data, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params}, {
              ascending => $event->{options}{ascending},
              columnValues => 
                  $event->{options}{columnValues} ? evalJSON($event->{options}{columnValues}, 1) : undef,
              defaultOrder => $event->{options}{defaultOrder},
              id => $event->{options}{id}
          })
      : (undef, undef);
    $data = UNIVERSAL::isa($data, 'IWL::TreeModel') ? $data->toJSON : IWL::JSON::toJSON($data);

    require IWL::Object;

    $response->send(
        content => '{data: ' . $data . ', extras: ' . (IWL::JSON::toJSON($extras) || 'null') . '}',
        header => IWL::Object::getJSONHeader()
    );
}

sub _init {
    my ($self, $columns, %args) = @_;
    my $index = 0;

    $self->{options}{id} = $args{id} || randomize('treemodel');
    $self->{options}{totalCount} = $args{totalCount} if $args{totalCount};
    $self->{options}{offset}     = $args{offset}     if $args{offset};
    $self->{options}{limit}      = $args{limit}      if $args{limit};

    $self->{columns} = [];
    $self->{rootNodes} = [];
    $columns = [] unless 'ARRAY' eq ref $columns;
    while (@$columns) {
        my @tuple = splice @$columns, 0, 2;
        $self->{columns}[$index++] = {type => $Types->{$tuple[0]}, name => $tuple[1]};
    }
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

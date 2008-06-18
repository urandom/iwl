#!/bin/false

package IWL::ListModel;

use strict;

use base qw(IWL::Error IWL::RPC::Request);

use IWL::ListModel::Node;

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
    $path = $path->[0] if 'ARRAY' eq ref $path;
    return $self->{rootNodes}[$path];
}

sub insertNode {
    my ($self, $index) = @_;
    return IWL::ListModel::Node->new($self, $index);
}

sub insertNodeBefore {
    my ($self, $sibling) = @_;
    return IWL::ListModel::Node->new($self, $sibling->getIndex);
}

sub insertNodeAfter {
    my ($self, $sibling) = @_;
    return IWL::ListModel::Node->new($self, $sibling->getIndex + 1);
}

sub prependNode {
    my ($self) = @_;
    return IWL::ListModel::Node->new($self, 0);
}

sub appendNode {
    my ($self) = @_;
    return IWL::ListModel::Node->new($self, -1);
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
    }
}

my $typeIndex = -1;
my $Types = {};

sub addColumnType {
    my $self = UNIVERSAL::isa($_[0], 'IWL::ListModel') ? shift : undef;
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
        return $self->_pushFatalError(__"No data available") unless $data;
        if ($options{subtype} eq 'array') {
            $self->_readArray($data, %options);
        } else {
            $modifiers = $self->_readHashList($data, %options);
        }
    } elsif ($options{type} eq 'json') {
        $data = evalJSON($content, 1);
        return $self->_pushFatalError(__"No data available") unless $data;
        if ($options{subtype} eq 'array') {
            $self->_readArray($data, %options);
        } else {
            $modifiers = $self->_readHashList($data, %options);
        }
    } else {
        return $self->_pushFatalError(__"No data available") unless $data;
        if ($options{type} eq 'array') {
            $self->_readArray($data, %options);
        } else {
            $modifiers = $self->_readHashList($data, %options);
        }
    }
    foreach (keys %$modifiers) {
        delete $modifiers->{$_} unless defined $modifiers->{$_};
    }
    $self->{options} = {
        %{$self->{options}},
        %$modifiers,
    };
    $self->{options}{preserve} = $options{preserve} if defined $options{preserve};

    $options{optionsList} = [qw(totalCount limit offset)]
        unless exists $options{optionsList};
    $self->{options}{$_} = $options{$_} foreach
        grep {defined $options{$_}} @{$options{optionsList}};

    return $self;
}

sub getScript {
    my ($self, $environment) = @_;

    $environment->require($self->getRequiredResources)
        if $environment;

    my $data = $self->toJSON;
    return 'window.' . $self->{options}{id} . " = new " . $self->{_classType} . "($data);";
}

sub getRequiredResources {
    return %{shift->{_requiredResources} || {}};
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
      },
      nodes => [
        {
          values => ['Sample', 15],
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
    $object->{classType} = $self->{_classType};

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
    $self->{options}{id} = $options{id} || randomize('treemodel');

    $self->{columns} = [];
    $self->{rootNodes} = [];
    $self->{_classType} = 'IWL.ListModel';
    $self->{_requiredResources} = {js => ['dist/prototype.js', 'model.js', 'listmodel.js']};
    $columns = [] unless 'ARRAY' eq ref $columns;

    return $self->_pushFatalError(__"No columns have been given.")
        unless @$columns;
    my $index = 0;
    my @typeValues = values %$Types;
    foreach my $column (@$columns) {
        # TRANSLATORS: {COLUMN} is a placeholder
        return $self->_pushFatalError(__x("Unknown column type: {COLUMN}", COLUMN => $column->{type}))
            unless exists $Types->{$column->{type}} || grep {$_ eq $column->{type}} @typeValues;
        $column->{type} = $Types->{$column->{type}};
        $self->{columns}[$index++] = $column;
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
    my $package = __eventNameToPackage($event);
    my $model = ($options{class} || $package)->new($options{columns}, preserve => 0, map {$_ => $options{$_}} qw(id totalCount limit offset));

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

sub _sortColumnEvent {
    my ($event, $handler) = @_;
    my %options = %{$event->{options}};
    my %params = %{$event->{params}};
    my $package = __eventNameToPackage($event);
    my $model = ($options{class} || $package)->new($options{columns}, preserve => 0, id => $options{id}, parentNode => $options{parentNode});

    $model = ('CODE' eq ref $handler)
      ? $handler->(\%params, $model)
      : undef;
    IWL::RPC::eventResponse($event, {data => $model->toJSON});
}

sub _registerEvent {
    my ($self, $event, $params, $options) = @_;

    if ($event eq 'IWL-ListModel-refresh') {
        $options->{method} = '_refreshResponse';
    } elsif ($event eq 'IWL-ListModel-requestChildren') {
        $options->{method} = '_requestChildrenResponse';
    }

    return $options;
}

=head1

[ ['Sample', '15'], ['Foo', 2] ]
[ [['Sample', '15'], [something else]], [['Foo', 2], [something else]] ]

=cut

sub _readArray {
    my ($self, $array, %options) = @_;

    my $values = $options{valuesIndex};
    foreach my $item (@$array) {
        my $node = $self->appendNode;
        unless (defined $values) {
            my $index = 0;
            $node->setValues($index++, $_) foreach ('ARRAY' eq ref $item ? @$item : $item);
        } else {
            for (my $i = 0; $i < @$item; $i++) {
                if (defined $values && $values eq $i) {
                    my $index = 0;
                    $node->setValues($index++, $_)
                        foreach ('ARRAY' eq ref $item->[$i] ? @{$item->[$i]} : $item->[$i]);
                }
            }
        }
    }
}

=head1

  [
    {
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

    if (ref $list eq 'HASH') {
        $modifiers->{totalCount} = $list->{$options{totalCountProperty}};
        $modifiers->{limit} = $list->{$options{sizeProperty}};
        $modifiers->{offset} = $list->{$options{offsetProperty}};

        $list = $list->{$options{nodesProperty}} || [];
    }

    foreach my $item (@$list) {
        next unless 'HASH' eq ref $item;
        my $node = $self->appendNode;
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

# Internal
#
sub __eventNameToPackage {
    my $name = shift->{eventName};
    $name =~ s/-/::/g;
    my ($package, undef) = $name =~ /(.*)::([^:]*)$/;
    return $package;
}

addColumnType(qw(NONE STRING INT FLOAT BOOLEAN COUNT IMAGE));

1;

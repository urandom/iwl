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

=head1

Data:
  {
    totalCount => int,
    size => int,
    offset => int,
    preserve => boolean,
    index => int,
    parentNode => [path],
    nodes => [
      {
        values => ['Sample', 15],
        children => [
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


sub dataReader {
    my ($self, %options) = (@_ % 2 ? (shift @_, @_) : (undef, @_));
    my ($content, $data, $modifiers) = ('', undef, {});

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

        my $r = IO::Socket::INET->new(Proto => $options{proto}, PeerAddr => $options{host}, PeerPort => $options{port});
        my @printer = ("GET $options{uri} HTTP/1.1", "Host: $options{host}:$options{port}");
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
        eval "require Storable" or die $@;

        $data = Storable::thaw($content);
        if ($options{subtype} eq 'array') {
            $data = __readArray($data, %options);
        } else {
            ($data, $modifiers) = __readHashList($data, %options);
        }
    } elsif ($options{type} eq 'json') {
        $data = evalJSON($content, 1);
        if ($options{subtype} eq 'array') {
            $data = __readArray($data, %options);
        } else {
            ($data, $modifiers) = __readHashList($data, %options);
        }
    } elsif ($options{type} eq 'array') {
        $data = __readArray($data, %options);
    } else {
        ($data, $modifiers) = __readHashList($data, %options);
    }
    $modifiers = {
        %$modifiers,
        preserve => defined $options{preserve} ? $options{preserve} : 1,
    };

    $modifiers->{$_} = $options{$_} foreach
        grep {defined $options{$_}} qw(totalCount size offset index parentNode);

    my $ret = {%$modifiers, nodes => $data};
    if ($self) {
        $self->{__data} = $ret;
        return $self;
    } else {
        return $ret
    }
}

# Overrides
#
sub getContent {
    shift->SUPER::getContent;

    return '';
}

# Protected
#
sub _realize {
    my $self = shift;

    my ($even, @script) = (1);
    push @script, 'window.' . $self->{__name} . ' = new IWL.TreeModel(';
    push @script, join ', ', map {($even = !$even) ? "'$_'" : $_} @{$self->{__columns}};
    push @script, ');';

    push @script, $self->{__name} . '.loadData(' . toJSON($self->{__data}) . ');'
        if $self->{__data};

    $self->_appendInitScript(join "\n", @script);
}

sub _sortColumnEvent {
    my ($event, $handler) = @_;
    my $response = IWL::Response->new;

    my ($data, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params}, {
              ascending => $event->{options}{ascending},
              columnValues => 
                  $event->{options}{columnValues} ? evalJSON($event->{options}{columnValues}, 1) : undef,
              defaultOrder => $event->{options}{defaultOrder}
          })
      : (undef, undef);
    $data = toJSON($data);

    require IWL::Object;

    $response->send(
        content => '{data: ' . $data . ', extras: ' . (toJSON($extras) || 'null') . '}',
        header => IWL::Object::getJSONHeader()
    );
}

sub _init {
    my ($self, $name, $columns, %args) = @_;

    $self->{__name} = $name;
    $self->{__columns} = $columns;
}

# Internal
#
=head1

[ ['Sample', '15'], ['Foo', 2] ]
[ [['Sample', '15'], [children]], [['Foo', 2], [children]] ]

=cut

sub __readArray {
    my ($array, %options) = @_;

    my $values = $options{valuesIndex};
    my $children = $options{childrenIndex};
    my $data = [];
    foreach my $item (@$array) {
        unless (defined $values || defined $children) {
            push @$data, {values => $item};
        } else {
            my $node = {};
            for (my $i = 0; $i < @$item; $i++) {
                if (defined $values && $values eq $i) {
                    $node->{values} = $item->[$i];
                } elsif (defined $children && $children eq $i) {
                    $node->{children} = __readArray($item->[$i]);
                }
            }
            push @$data, $node;
        }
    }

    return $data;
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
    my ($list, %options) = @_;
    my $data = [];
    my $modifiers = {};
    my $values = $options{valuesProperty} || 'values';
    my $children = $options{childrenProperty} || 'children';

    if (ref $list eq 'HASH') {
        $modifiers->{totalCount} = $list->{$options{totalCountProperty}};
        $modifiers->{size} = $list->{$options{sizeProperty}};
        $modifiers->{offset} = $list->{$options{offsetProperty}};

        $list = $list->{$options{nodesProperty}} || [];
    }

    foreach my $item (@$list) {
        next unless 'HASH' eq ref $item;
        my $node = {};
        ($node->{children}) = __readHashList($item->{$children}, %options)
            if ref $item->{$children} eq 'ARRAY';
        if (ref $item->{$values} eq 'ARRAY') {
            $node->{values} = $item->{$values};
        } elsif (ref $options{valueProperties} eq 'ARRAY') {
            $node->{values} = [map {$item->{$_}} @{$options{valueProperties}}];
        }
        push @$data, $node;
    }

    return $data, $modifiers;
}

1;

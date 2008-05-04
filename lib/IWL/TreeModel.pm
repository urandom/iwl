#!/bin/false

package IWL::TreeModel;

use strict;

use IWL::JSON qw(evalJSON);

=head1

Data:
  [
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

=cut


sub dataReader {
    my (%options) = @_;
    my ($content, $data) = ('', undef);

    if ($options{file}) {
        local *FILE;
        local $/ = undef;
        open FILE, $options{file};
        $content = <FILE>;
        close FILE;
    } elsif ($options{host}) {
        eval "require Net::Telnet" or die $@;
        $options{port} ||= 80;
        $options{uri}  ||= '/';
        my $t = Net::Telnet->new(Host => $options{host}, Port => $options{port});
        my @printer = ("GET $options{uri} HTTP/1.1", "Host: $options{host}:$options{port}");
        my $body;

        $t->put(join "\n", @printer, "\n");
        while (my $line = $t->getline) {
            unless ($body) {
                $body = 1 if $line eq "\n";
                next;
            }
            $content .= $line;
            last if $t->eof;
        }
        $t->close;
    } elsif ($options{data}) {
        $data = $options{data};
    }

    if ($options{type} eq 'storable') {
        eval "require Storable" or die $@;

        $data = Storable::thaw($content);
        if ($options{subtype} eq 'array') {
            $data = __readArray($data, %options);
        } else {
            $data = __readHashList($data, %options);
        }
    } elsif ($options{type} eq 'array') {
        $data = __readArray($data, %options);
    } elsif ($options{type} eq 'hashlist') {
        $data = __readHashList($data, %options);
    } elsif ($options{type} eq 'json') {
        $data = evalJSON($content, 1);
        if ($options{subtype} eq 'array') {
            $data = __readArray($data, %options);
        } else {
            $data = __readHashList($data, %options);
        }
    }

    return $data;
}

sub _sortColumnEvent {
    my ($event, $handler) = @_;
    my $response = IWL::Response->new;

    my ($data, $extras) = ('CODE' eq ref $handler)
      ? $handler->($event->{params}, $event->{options}{ascending},
        $event->{options}{columnValues} ? evalJSON($event->{options}{columnValues}, 1) : undef)
      : (undef, undef);
    $data = toJSON($data);

    require IWL::Object;

    $response->send(
        content => '{data: ' . $data . ', extras: ' . (toJSON($extras) || 'null') . '}',
        header => IWL::Object::getJSONHeader()
    );
}

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

=cut

sub __readHashList {
    my ($list, %options) = @_;
    my $data = [];
    my $values = $options{valuesProperty};
    my $children = $options{childrenProperty};
    foreach my $item (@$list) {
        next unless 'HASH' eq ref $item;
        my $node = {};
        $node->{children} = $item->{$children} if ref $item->{$children} eq 'ARRAY';
        $node->{values} = $item->{$values} if ref $item->{$values} eq 'ARRAY';
        push @$data, $node;
    }

    return $data;
}

1;

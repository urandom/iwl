#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::HBox;

use strict;

use base 'IWL::Container';

=head1 NAME

IWL::HBox - A horizontal box container

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::HBox

=head1 DESCRIPTION

While there's really no need for a vertical box container (the elements are stacked vertically in html), an HBox is just a time saver, so developers don't have to add a float style to their containers.

=head1 CONSTRUCTOR

IWL::HBox->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(%args);

    $self->{_defaultClass} = 'hbox';

    return $self;
}

=head1 METHODS

=over 4

=item B<packStart> (B<WIDGET>, [B<MARGIN>])

Packs the given widget from the left side of the container.

Parameters: B<WIDGET> - the widget to be packed, B<MARGIN> - the margin

Returns: the packing container

=cut

sub packStart {
    my ($self, $widget, $margin) = @_;
    my $pack = IWL::Container->new(class => 'hbox_start');

    $self->appendChild($pack);
    $pack->setStyle(margin => $margin) if $margin;
    $pack->appendChild($widget);

    return $pack;
}

=item B<packEnd> (B<WIDGET>, [B<MARGIN>])

Packs the given widget from the right side of the container.

Parameters: B<WIDGET> - the widget to be packed, B<MARGIN> - the margin

Returns: the packing container

=cut

sub packEnd {
    my ($self, $widget, $margin) = @_;
    my $pack = IWL::Container->new(class => 'hbox_end');

    $self->appendChild($pack);
    $pack->setStyle(margin => $margin) if $margin;
    $pack->appendChild($widget);

    return $pack;
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    return if !$id;

    my $children = $self->{childNodes};
    for (my $i = 0; $i < scalar @$children; $i++) {
	$children->{$i}->setId($id . '_pack_' . $i);
    }
    return $self->SUPER::setId($id);
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->appendAfter(IWL::Container->new(inline => 1, style => {clear => 'both'}));
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

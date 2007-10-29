#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::VBox;

use strict;

use base 'IWL::Container';

=head1 NAME

IWL::VBox - A horizontal box container

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::VBox>

=head1 DESCRIPTION

An VBox is a container for stacking L<IWL::Widget>s vertically.

=head1 CONSTRUCTOR

IWL::VBox->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(%args);

    $self->{_defaultClass} = 'vbox';
    $self->{_start} = [];
    $self->{_end} = [];

    return $self;
}

=head1 METHODS

=over 4

=item B<packStart> (B<WIDGET>, [B<MARGIN>])

Packs the given widget to the top of the container.

Parameters: B<WIDGET> - the widget to be packed, B<MARGIN> - the margin

Returns: the packing container

=cut

sub packStart {
    my ($self, $widget, $margin) = @_;
    my $pack = IWL::Container->new;

    $pack->setStyle(margin => $margin) if $margin;
    $pack->appendChild($widget);
    $pack->{_defaultClass} = 'vbox_start';
    push @{$self->{_start}}, $pack;

    return $pack;
}

=item B<packEnd> (B<WIDGET>, [B<MARGIN>])

Packs the given widget to the bottom of the container.

Parameters: B<WIDGET> - the widget to be packed, B<MARGIN> - the margin

Returns: the packing container

=cut

sub packEnd {
    my ($self, $widget, $margin) = @_;
    my $pack = IWL::Container->new;

    $pack->setStyle(margin => $margin) if $margin;
    $pack->appendChild($widget);
    $pack->{_defaultClass} = 'vbox_end';
    unshift @{$self->{_end}}, $pack;

    return $pack;
}

# Protected
#
sub _realize {
    my $self = shift;

    $self->SUPER::_realize;
    $self->appendChild($_) foreach (@{$self->{_start}}, @{$self->{_end}});
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

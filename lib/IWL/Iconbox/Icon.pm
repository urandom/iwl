#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Iconbox::Icon;

use strict;

use base qw(IWL::Container IWL::RPC::Request);

use IWL::Text;
use IWL::Image;
use IWL::String qw(randomize);

use JSON;

=head1 NAME

IWL::Icon - an icon widget for the iconbox 

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Container -> IWL::Iconbox::Icon

=head1 DESCRIPTION

The Icon widget is a basic widget for the iconbox. It features an icon, and a title underneath it.

=head1 CONSTRUCTOR

IWL::Iconbox::Icon->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-value options. These include:
  direction: the direction in which the icon will float in the iconbox
  margin: the margin around the icon. Defaults to '5px'

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setImage> (B<IMAGE>, [B<ALT>])

Sets the image of the icon to the one provided 

Parameters: B<IMAGE> - the location of the image, B<ALT> - the alt text of the image

=cut

sub setImage {
    my ($self, $src, $alt) = @_;

    $self->{image}->setAlt($alt);
    return $self->{image}->set($src);
}

=item B<setText> (B<TEXT>)

Sets the text underneath the icon to the one provided 

Parameters: B<TEXT> - the text string

=cut

sub setText {
    my ($self, $text) = @_;

    return $self->{__label}->setText($text);
}

=item B<setSelected> (B<BOOL>)

Sets whether the icon should be selected.

Parameters: B<BOOL> - true if the icon should be selected;

=cut

sub setSelected {
    my ($self, $bool) = @_;

    if ($bool) {
	$self->{_selected} = 1;
    } else {
	$self->{_selected} = 0;
    }
    return $self;
}

=item B<setDimensions> (B<WIDTH>, [B<HEIGHT>])

Sets the dimensions of the icon to the given ones.

Parameters: B<WIDTH> - the width, B<HEIGHT> - the height.

Note: the dimension units should be provided. Thus, the above parameters will be strings, with the dimension integer, and the given unit to it. E.g.: I<"64px">. Omitting the units might not work on some user agents.

=cut

sub setDimensions {
    my ($self, $width, $height) = @_;

    #    if ($height) {
    #        $self->{image}->setStyle(height => $height, width => $width);
    #    } else {
    #        $self->{image}->setStyle(width => $width);
    #    }
    $self->{__label}->setStyle(width => $width);
    return $self->setStyle(width    => $width);
}

# Overrides
#
sub signalConnect {
    my ($self, $signal, $callback) = @_;
    if ($signal eq 'load') {
	$self->{image}->signalConnect(load => $callback);
    } else {
        $self->SUPER::signalConnect($signal, $callback);
    }

    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id = $self->getId;

    $self->SUPER::_realize;
    $self->signalConnect(load => <<'EOF');
var iconbox = $(this).up(null, 2);
if (iconbox && iconbox._iconCountdown)
    iconbox._iconCountdown();
else
    this.up()._loaded = true;
EOF
}

# Internal
#
sub __init {
    my ($self, %args) = @_;

    $self->{image}          = IWL::Image->new;
    $self->{_customSignals} = {select => [], unselect => [], activate => [], remove => []};
    $self->{_defaultClass}  = 'icon';
    $self->{_selected}      = 0;
    $self->{__label}        = IWL::Label->new(expand => 1);

    $args{id} ||= randomize($self->{_defaultClass});

    $self->setStyle(margin => $args{margin} || '5px');
    $self->setStyle(float => $args{direction}) if $args{direction};
    $self->{__label}->{_defaultClass} = "icon_label";
    delete @args{qw(margin direction)};

    $self->appendChild($self->{image});
    $self->appendChild($self->{__label});
    $self->_constructorArguments(%args);
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

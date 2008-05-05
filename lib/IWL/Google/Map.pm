#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Google::Map;

use strict;

use base qw(IWL::Container);

use IWL::JSON 'toJSON';
use IWL::String 'randomize';
use IWL::Config '%IWLConfig';
use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Google::Map - a button with a background

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Container> -> L<IWL::Google::Map>

=head1 DESCRIPTION

The Google Map widget provides an easy way of creating maps, provided by Google.

=head1 CONSTRUCTOR

IWL::Google::Map->new ([B<%ARGS>])

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new;

    $self->_init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setWidth> (B<WIDTH>)

Sets the given width as the width of the map 

Parameters: B<WIDTH> - the width with the appropriate dimensions

=cut

sub setWidth {
    my ($self, $width) = @_;

    $self->setStyle (width => $width);

    return $self;
}

=item B<setHeight> (B<HEIGHT>)

Sets the given height as the height of the map 

Parameters: B<HEIGHT> - the height with the appropriate dimensions

=cut

sub setHeight {
    my ($self, $height) = @_;

    $self->setStyle (height => $height);

    return $self;
}

=item B<setLongitude> (B<LONGITUDE>)

Sets the given longitude as the initial longitude of the map 

Parameters: B<LONGITUDE> - the longitude, -180 <=> 180

=cut

sub setLongitude {
    my ($self, $longitude) = @_;

    $longitude = 0 + $longitude;
    $longitude = 180 if $longitude > 180;
    $longitude = -180 if $longitude < -180;

    $self->{_options}{longitude} = $longitude;
    return $self;
}

=item B<setLatitude> (B<LATITUDE>)

Sets the given latitude as the initial latitude of the map 

Parameters: B<LATITUDE> - the latitude, -90 <=> 90

=cut

sub setLatitude {
    my ($self, $latitude) = @_;

    $latitude = 0 + $latitude;
    $latitude = 90 if $latitude > 90;
    $latitude = -90 if $latitude < -90;

    $self->{_options}{latitude} = $latitude;
    return $self;
}

=item B<setZoom> (B<ZOOM>)

Sets the given zoom as the initial zoom of the map 

Parameters: B<ZOOM> - the zoom >= 0

=cut

sub setZoom {
    my ($self, $zoom) = @_;

    $zoom = 0 + $zoom;
    $zoom = 1 if $zoom < 0;

    $self->{_options}{zoom} = $zoom;
    return $self;
}

=item B<setMapType> (B<TYPE>)

Sets the initial map type

Parameters: B<TYPE> - the map type, one of:

=over 8

=item B<normal>

Normal map

=item B<satellite>

Satellite map

=item B<hybrid>

Mixed normal/satellite map

=item B<physical>

Physical map

=back

=cut

sub setMapType {
    my ($self, $type) = @_;

    $self->{_options}{mapType} = $type;

    return $self;
}

=item B<setScaleView> (B<TYPE>)

Sets the scale view of the map

Parameters: B<TYPE> - the scale type, either I<none>, or I<ruler>

=cut

sub setScaleView {
    my ($self, $type) = @_;

    $type = 'none' unless grep { $_ eq $type } qw(none ruler);
    $self->{_options}{scaleView} = $type;

    return $self;
}

=item B<setMapControl> (B<CONTROL>)

Sets the map control

Parameters: B<CONTROL> - the control type, one of I<none> ,I<smal>, I<large> or I<smallZoom>

=cut

sub setMapControl {
    my ($self, $control) = @_;

    $control = 'none' unless grep { $_ eq $control } qw(none small large smallZoom);
    $self->{_options}{mapControl} = $control;
    return $self;
}

=item B<setMapTypeControl> (B<CONTROL>)

Sets the control for selecting the map type

Parameters: B<CONTROL> - the control type, one of I<none>, I<normal>, I<menu>, I<hierarchical>

=cut

sub setMapTypeControl {
    my ($self, $control) = @_;

    $control = 'none' unless grep { $_ eq $control } qw(none normal menu hierarchical);
    $self->{_options}{mapTypeControl} = $control;
    return $self;
}

=item B<setOverview> (B<TYPE>)

Sets the overview type of the map

Parameters: B<TYPE> - the overview, one of I<none>, I<mini>

=cut

sub setOverview {
    my ($self, $type) = @_;

    $type = 'none' unless grep { $_ eq $type } qw(none mini);
    $self->{_options}{overview} = $type;

    return $self;
}

=item B<addMarker> ([B<CONTENT>, B<LATITUDE>, B<LONGITUDE>])

Adds a marker to the map

Parameters: B<CONTENT> - the optional content of the information window, which will appear if the marker is clicked. Can be a string, html or L<IWL::Object>, B<LATITUDE> - the latitude of the marker, B<LONGITUDE> - the longitude of the marker. If the coordinates are not supplied, the initial map coordinates will be used.

=cut

sub addMarker {
    my $self = shift;

    push @{$self->{__markers}}, [@_];
    return $self;
}

# Protected
#
sub _realize {
    my $self = shift;
    my $id = $self->getId;

    foreach my $marker (@{$self->{__markers}}) {
        $marker->[0] = $marker->[0]->getContent if UNIVERSAL::isa($marker->[0], 'IWL::Object');
    }
    $self->{_options}{markers} = $self->{__markers};
    my $options = toJSON($self->{_options});
    my $signals = $self->{_customSignals};

    delete $self->{_customSignals};
    $self->SUPER::_realize;

    $self->_appendInitScript("IWL.Google.Map.create('$id', $options)");
    my $added = 0;
    foreach my $signal (keys %$signals) {
        my $expr = join '; ', @{$signals->{$signal}};
        if ($expr) {
            $self->_appendInitScript("\$('$id').signalConnect('iwl:load', function() { var map = \$('$id').control;")
                unless $added;
            $self->_appendInitScript(
                "GEvent.addListener(map, '$signal', function() { $expr });"
            );
            $self->_appendInitScript("});")
                unless $added;
            $added = 1;
        }
    }
}

sub _init {
    my ($self, %args) = @_;

    $self->{__key} = $args{key} || $IWLConfig{GOOGLE_MAPS_KEY};

    $self->{_options} = {
        longitude => $args{longitude} || 0,
        latitude => $args{latitude} || 0,
        zoom => $args{zoom} || 1,
        mapType => $args{mapType} || 'normal',
    };
    $self->{_options}{dragging}        = !(!$args{dragging})        if defined $args{dragging};
    $self->{_options}{infoWindow}      = !(!$args{infoWindow})      if defined $args{infoWindow};
    $self->{_options}{doubleClickZoom} = !(!$args{doubleClickZoom}) if defined $args{doubleClickZoom};
    $self->{_options}{scrollWheelZoom} = !(!$args{scrollWheelZoom}) if defined $args{scrollWheelZoom};
    $self->{_options}{googleBar}       = !(!$args{googleBar})       if defined $args{googleBar};
    $self->{_options}{language}        = $args{language} || $ENV{LANG} || $ENV{LANGUAGE};

    return $self->_pushFatalError(__x(
            "No API key provided. One can be obtained from {URL}",
            URL => "http://www.google.com/apis/maps/signup.html"
        )) unless $self->{__key};

    delete @args{qw(key longitude latitude zoom mapType dragging infoWindow doubleClickZoom scrollWheelZoom googleBar)};
    $self->{_defaultClass} = 'google_map';
    $args{id} ||= randomize($self->{_defaultClass});
    $self->_constructorArguments(%args);

    $self->requiredJs('google/map.js', 'http://www.google.com/jsapi?key=' . $self->{__key});
    $self->{_signals}{click} = $self->{_signals}{dblclick} = $self->{_signals}{mouseover} = $self->{_signals}{mouseout} = $self->{_signals}{mousemove} = '';
    $self->{_customSignals} = {
        load => [], click => [], dblclick => [], singlerightclick => [],
        movestart => [], move => [], moveend => [], zoomend => [],
        maptypechanged => [], infowindowopen => [], infowindowbeforeclose => [],
        infowindowclose => [], mouseover => [], mouseout => [], mousemove => [],
        drag => [], dragend => [],
    };
    $self->{__markers} = [];
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

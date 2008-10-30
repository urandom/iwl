#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::GoogleMap;

use strict;

use base qw (IWL::Widget);

use IWL::Anchor;

use IWL::Config '%IWLConfig';
use Locale::TextDomain $IWLConfig{TEXT_DOMAIN};

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $button = $args{button};
    delete $args{button};

    my $key = delete $args{key};

    my $self = $class->SUPER::new (%args);

    $key = '' unless defined $key;

    $self->{__googlemapKey} = $key;
    $self->requiredJs ("http://maps.google.com/maps?file=api&v=2&key=$key");
    $self->requiredJs ('base.js');
    $self->requiredJs ('gmap.js');

    my $id = $args{id};
    unless ($id && $id =~ /^[A-Za-z_][0-9A-Za-z_]*$/) {
	$id = "$self";
	$id =~ s/.*0x([0-9a-fA_F]+)\)$/iwl_googlemap_$1/;
    }

    $self->setId ($id);
    $self->{_tag} = 'div';
    $self->setStyle (width => 500, height => 300);

    $self->{__googlemapDisplayContainers} = [];
    $self->{__googlemapInputFields} = [];
    $self->{__googlemapInfoWindows} = [];

    return $self;
}

sub setWidth {
    my ($self, $width) = @_;

    $self->setStyle (width => $width);

    return $self;
}

sub setHeight {
    my ($self, $height) = @_;

    $self->setStyle (height => $height);

    return $self;
}

sub getContent {
    my ($self, @args) = @_;

    $self->__updateContent;
    
    return $self->SUPER::getContent (@args);
}

sub setLongitude {
    my ($self, $longitude) = @_;

    $longitude = 0 + $longitude;
    $longitude = 180 if $longitude > 180;
    $longitude = -180 if $longitude < -180;

    $self->{__googlemapLongitude} = $longitude;

    return $self;
}

sub setLatitude {
    my ($self, $latitude) = @_;

    $latitude = 0 + $latitude;
    $latitude = 90 if $latitude > 90;
    $latitude = -90 if $latitude < -90;

    $self->{__googlemapLatitude} = $latitude;

    return $self;
}

sub setZoom {
    my ($self, $zoom) = @_;

    $zoom = 0 + $zoom;
    $zoom = 1 if $zoom < 0;

    $self->{__googlemapZoom} = $zoom;

    return $self;
}

sub setMapTypeControl {
    my ($self, $flag) = @_;

    $self->{__googlemapMapTypeControl} = $flag;

    return $self;
}

sub setSmallMapControl {
    my ($self, $flag) = @_;

    $self->{__googlemapSmallMapControl} = $flag;

    return $self;
}

sub connectInputField {
    my ($self, $input, $format) = @_;

    my $input_id = $input->getId;
    return $self->_pushError ("input field has no id")
	unless defined $input_id && length $input_id;

    $format = "%c" unless defined $format && length $format;

    push @{$self->{__googlemapInputFields}}, {
	id => $input_id,
	format => $format,
    };

    return $self;
}

sub connectInputId {
    my ($self, $input_id, $format) = @_;

    $format = "%c" unless defined $format && length $format;

    push @{$self->{__googlemapInputFields}}, {
	id => $input_id,
	format => $format,
    };

    return $self;
}

sub connectDisplayContainer {
    my ($self, $container, $format) = @_;

    my $container_id = $container->getId;
    return $self->_pushError (__"Container has no id")
	unless defined $container_id && length $container_id;

    $format = "%c" unless defined $format && length $format;

    push @{$self->{__googlemapDisplayContainers}}, {
	id => $container_id,
	format => $format,
    };

    return $self;
}

sub connectDisplayId {
    my ($self, $container_id, $format) = @_;

    $format = "%c" unless defined $format && length $format;

    push @{$self->{__googlemapDisplayContainers}}, {
	id => $container_id,
	format => $format,
    };

    return $self;
}

sub openInfoWindow {
    my ($self, $text, $lat, $lng) = @_;

    push @{$self->{__googlemapInfoWindows}}, {
	lat => $lat,
	lng => $lng,
	text => $text,
   };

    return $self;
}

sub __updateContent {
    my ($self) = @_;

    my $elem;

    if (length $self->{__googlemapKey}) {
	my $key = $self->{__googlemapKey};
	my $id = $self->getId;
	my $div = 'window.map_' . $id;
	my $latitude = $self->{__googlemapLatitude};
	$latitude = '50.890013' unless defined $latitude;
	my $longitude = $self->{__googlemapLongitude};
	$longitude = '6.903362' unless defined $longitude;
	my $zoom = $self->{__googlemapZoom} || 13;

	my $script_source = <<EOF;
if (GBrowserIsCompatible()) {
    $div = new GMap2(document.getElementById("$id"));
    $div.setCenter (new GLatLng($latitude, $longitude), $zoom);
EOF

        if ($self->{__googlemapSmallMapControl}) {
	    $script_source .= 
		qq{    $div.addControl (new GSmallMapControl());\n};
	}
    
        if ($self->{__googlemapMapTypeControl}) {
	    $script_source .= 
		qq{    $div.addControl (new GMapTypeControl());\n};
	}

	foreach my $entry (@{$self->{__googlemapInputFields}}) {
	    my $input_id = $entry->{id};
	    my $format = $self->__escape_one_line_js ($entry->{format});
	    $script_source .= <<EOF;
    GEvent.addListener ($div, 'moveend', function () {
        iwl_gmap_update_input ($div, "$input_id", "$format");
    });
EOF
	}

	foreach my $entry (@{$self->{__googlemapDisplayContainers}}) {
	    my $container_id = $entry->{id};
	    my $format = $self->__escape_one_line_js ($entry->{format});
	    $script_source .= <<EOF;
    GEvent.addListener ($div, 'moveend', function () {
        iwl_gmap_update_container ($div, "$container_id", "$format");
    });
EOF
	}    

        foreach my $entry (@{$self->{__googlemapInfoWindows}}) {
	    my $string = $entry->{text};
	    my $lat = $entry->{lat};
	    my $lng = $entry->{lng};
	    unless (defined $lat) {
		$lat = "$div.getCenter().lat()";
	    }
	    unless (defined $lng) {
		$lng = "$div.getCenter().lng()";
	    }
	    $string = $self->__escape_one_line_js ($string);
	    $script_source .= <<EOF;
	    var coord = new GLatLng ($lat, $lng);
	    $div.openInfoWindow (coord, "$string");
EOF
        }

        $script_source .= "}\n";
        $elem = IWL::Script->new;
	$elem->setScript ($script_source);
    } else {
	$elem = IWL::Anchor->new;
	$elem->setHref ('http://www.google.com/apis/maps/signup.html');
	$elem->setText (__("No key provided.  Please follow this link"
			   . " in order to obtain a key from Google."));
    }

    unshift @{$self->{_tailObjects}}, $elem;
    return $self;
}

# This must also be a class method because it is called from a class method!
sub __escape_one_line_js {
    my ($class, $string) = @_;

    return unless defined $string;

    $string = $class->__escape_js ($string);
    $string =~ s/\n/\\n/g;

    return $string;
}

# This must also be a class method because it is called from a class method!
sub __escape_js {
    my (undef, $string) = @_;

    return unless defined $string;

    $string =~ s/\\/\\\\/g;
    $string =~ s/&/\\&/g;
    $string =~ s/</\\</g;
    $string =~ s/>/\\>/g;
    $string =~ s/\"/\\\"/g; #" St. Emacs
    $string =~ s/\'/\\\'/g; #'

    return $string;
}

1;

=head1 NAME

IWL::GoogleMap - An embedded Google map.

=head1 SYNOPSIS

  use IWL::GoogleMap;
  
  my $map = IWL::GoogleMap->new (key => 'abcdef');

=head1 DESCRIPTION

The B<IWL::GoogleMap> object provides an interface to the Google
Map API from IWL:

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::GoogleMap>

=head1 CONSTRUCTORS

=over 4

=item B<new>

The constructor takes .

=back

=head1 PUBLIC METHODS

=head1 SEE ALSO

L<IWL::Widget>, perl(1)

=cut


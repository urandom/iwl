#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Button;

use strict;

use base 'IWL::Widget';

use IWL::Input;
use IWL::Anchor;
use IWL::Image;
use IWL::Container;
use IWL::String qw(randomize escape);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::Button - a button with a background

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Button>

=head1 DESCRIPTION

The Button widget is different from a regular Button widget, in that it can be styled with a background.

=head1 CONSTRUCTOR

IWL::Button->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item I<image>

Set the image of the button

=item B<alt>

Set the alt text for the image of the button

=item B<label>

Set the label of the button

=item B<size>

default - 26px in height, medium - 20px in height, small - 13px in height,

=back

IWL::Button->newFromStock (B<STOCK_ID>, [B<%ARGS>])

Where B<STOCK_ID> is the B<IWL::Stock> id.

=head1 SIGNALS

=over 4

=item B<load>

Fires when the button has finished loading

=item B<load>

Fires when the button has finished adjusting

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->__init(%args);

    return $self;
}

sub newFromStock {
    my ($self, $stock_id, %args) = @_;
    my $button = IWL::Button->new(%args);

    $button->setFromStock($stock_id);

    return $button;
}

=head1 METHODS

=over 4

=item B<setLabel> (B<TEXT>)

Sets the given text as the label of the button

Parameters: B<TEXT> - the text for the label

=cut

sub setLabel {
    my ($self, $text) = @_;

    $self->{_options}{label} = $text;
    return $self;
}

=item B<getLabel>

Returns the text of the button label

=cut

sub getLabel {
    return shift->{_options}{label};
}

=item B<setImage> (B<SRC>, [B<ALT>])

Sets the given url as the source of the image

Parameters: B<SRC> - the url for the image. If the B<SRC> begins with I<IWL_STOCK_>, the B<SRC> is treaded as a stock id, B<ALT> - the alternative text for the image, optional.

=cut

sub setImage {
    my ($self, $src, $alt) = @_;

    my $image = $self->{image};
    $image->{_ignore} = 0;
    if ($src =~ /^IWL_STOCK_/) {
        $image->setFromStock($src);
        if ($alt) {
            $image->setAlt($alt);
            $self->setTitle($alt);
        }
        return $self;
    }
    $image->set($src);
    if ($alt) {
        $image->setAlt($alt);
        $self->setTitle($alt);
    }
    return $self;
}

=item B<getImage>

Returns the button image

=cut

sub getImage {
    return shift->{image};
}

=item B<setFromStock> (B<STOCK_ID>)

Sets the button from the stock id

Parameters: B<STOCK_ID> - the stock id

=cut

sub setFromStock {
    my ($self, $stock_id) = @_;
    my $stock = IWL::Stock->new;

    my $image = $stock->getSmallImage($stock_id);
    my $label = $stock->getLabel($stock_id);

    $self->setLabel($label);
    $self->setImage($image, $label, $label);
    return $self;
}

=item B<setSubmit> (B<NAME>, [B<VALUE>, B<FORM_NAME>])

Sets the button to act as a submit button for a form. It creates a signal handler to the I<CLICK> signal.

Parameters: B<NAME> - the name of the element, B<VALUE> - the value of the element, B<FORM_NAME> - the name of the form

=cut

sub setSubmit {
    my ($self, $name, $value, $form_name) = @_;

    if (!$name) {
        $self->{_options}{submit} = 1;
    } else {
        $self->{_options}{submit} = [$name, $value, $form_name];
    }
    return $self;
}

=item B<setHref> (B<URL>) 

Sets the href of the anchor. Due to one of the many bugs in Internet Explorer involving buttons, it also has to set an onclick handler to "document.location.href = $url"

Parameters: B<URL> - the url of the href

=cut

sub setHref {
    my ($self, $url) = @_;

    if (!$self->{__nsAnchor}{added}) {
	$self->appendChild($self->{__nsAnchor});
	$self->{__nsAnchor}{added} = 1;
    }
    $self->{__nsAnchor}->setHref($url);
    if ($url =~ /JavaScript/i) {
        $self->signalConnect(click => $url);
    } else {
        $self->signalConnect(click => "document.location.href = '$url'");
    }
    $self->signalConnect(mouseover => "window.status = unescape('" . escape($url) . "')");
    return $self->signalConnect(mouseout => "window.status = ''");
}

=item B<setDisabled> (B<BOOL>)

Sets whether the button will be disabled

Parameters: B<BOOL> - true if the button should be disabled (i.e. will not react to user input)

=cut

sub setDisabled {
    my ($self, $bool) = @_;

    $self->{_options}{disabled} = $bool ? 1 : 0;
    return $self;
}

=item B<isDisabled>

Returns true if the button is disabled

=cut

sub isDisabled {
    return !(!shift->{_options}{disabled});
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id);
    $self->{image}->setId($id . '_image');
    my $index = 0;
    foreach (qw(tl top tr l content r bl bottom br)) {
        $self->{__parts}[$index++]->setId($id . '_' . $_);
    }
    return $self;
}

sub setAlt {
    my ($self, $alt) = @_;

    $self->{image}->setAlt($alt);
    return $self;
}

sub getAlt {
    return shift->{image}->getAlt;
}

sub set {
    my ($self, $src) = @_;

    $self->{image}->set($src);
    return $self;
}

sub getSrc {
    return shift->{image}->getSrc;
}

sub getHref {
    return shift->{__nsAnchor}->getHref;
}

# Protected
#
sub _realize {
    my $self       = shift;
    my $id         = $self->getId;
    my $visibility = $self->getStyle('visibility');
    my $options    = {};

    $self->SUPER::_realize;

    $self->{_options}{visibility} = $visibility if $visibility;
    $self->setStyle(visibility => 'hidden');
    $options = toJSON($self->{_options});
    $self->_appendInitScript("IWL.Button.create('$id', $options);");
}

sub _setupDefaultClass {
    my $self = shift;
    $self->SUPER::prependClass($self->{_defaultClass} . '_' . $self->{_options}{size});
    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{image}->prependClass($self->{_defaultClass} . '_image');
    my $index = 0;
    foreach (qw(tl top tr l content r bl bottom br)) {
        $self->{__parts}[$index++]->prependClass(
            $self->{_defaultClass} . '_' . $_);
    }
    return $self;
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $anchor = IWL::Anchor->new;
    my $image  = IWL::Image->new;
    my $id     = $args{id};

    $self->{_defaultClass}     = 'button';
    $image->{_ignore}          = 1;

    $self->{image}             = $image;
    $self->{__nsAnchor}        = $anchor;
    $self->{__nsAnchor}{added} = 0;
    $self->{__parts}           = [IWL::Widget->newMultiple(9)];

    $id = randomize($self->{_defaultClass}) unless $id;
    $self->{_tag} = 'div';
    foreach (@{$self->{__parts}}) {
        $_->{_tag} = 'div';
        $self->appendChild($_);
    }
    $self->{__parts}[4]->appendChild($image);
    $self->setId($id);

    $self->{_options}{size} = $args{size} || 'default';
    $self->{_options}{disabled} = $args{disabled} ? 1 : 0;

    delete @args{qw(size id)};
    $self->_constructorArguments(%args);
    $self->requiredJs('base.js', 'button.js');

    # Callbacks
    # Hides the dashed focus border in IE. For firefox, this is done by css
    $self->signalConnect(focus => "this.hideFocus = true");
    $self->{_customSignals} = {load => [], adjust => []};

    return $self;
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

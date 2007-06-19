#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Button;

use strict;

use base 'IWL::Widget';

use IWL::Script;
use IWL::Input;
use IWL::Anchor;
use IWL::Image;
use IWL::Container;
use IWL::String qw(randomize encodeURIComponent);

use JSON;

=head1 NAME

IWL::Button - a button with a background

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Button

=head1 DESCRIPTION

The Button widget is different from a regular Button widget, in that it can be styled with a background.

=head1 CONSTRUCTOR

IWL::Button->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  image: set the image of the button
  alt: set the alt text for the image of the button
  label: set the label of the button
  size: default - 26px in height, 
        medium - 20px in height,
	small - 13px in height,

IWL::Button->newFromStock (B<STOCK_ID>, [B<%ARGS>])

Where B<STOCK_ID> is the B<IWL::Stock> id.
  size: default - 26px in height, 
        medium - 20px in height,
	small - 13px in height,

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

    $self->{__button}{label} = $text;
    return $self;
}

=item B<getLabel>

Gets the text of the button label

=cut

sub getLabel {
    return shift->{__button}{label};
}

=item B<setImage> (B<SRC>, [B<ALT>])

Sets the given url as the source of the image

Parameters: B<SRC> - the url for the image. If the B<SRC> begins with I<IWL_STOCK_>, the B<SRC> is treaded as a stock id, B<ALT> - the alternative text for the image, optional.

=cut

sub setImage {
    my ($self, $src, $alt) = @_;

    my $image = $self->{__button}{image};
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
    $self->setId('button_' . randomize(lc $label))
      if !$self->getId;
    return $self;
}

=item B<setSubmit> (B<NAME>, [B<VALUE>, B<FORM_NAME>])

Sets the button to act as a submit button for a form. It creates a signal handler to the I<CLICK> signal.

Parameters: B<FORM_NAME> - the name of the form. B<NAME> - the name of the element, B<VALUE> - the value of the element

=cut

sub setSubmit {
    my ($self, $name, $value, $form_name) = @_;

    return unless $name;
    $self->{_options}{submit} = 1;
    $self->{__hidden}{_ignore} = 0;
    $self->{__hidden}->setName($name);
    $self->{__hidden}->setValue($value);
    $self->{__hidden}->setClass('fake_button_submit');
    $self->{__hiddenName} = $name;
    $self->{__formName}   = $form_name;
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
    $self->signalConnect(mouseover => "window.status = decodeURIComponent('" . encodeURIComponent($url) . "')");
    return $self->signalConnect(mouseout => "window.status = ''");
}

# Overrides
#
sub setStyle {
    my ($self, %style) = @_;

    $self->{__button}->setStyle(%style);
    return $self;
}

sub getStyle {
    my ($self, $attr) = @_;
    return $self->{__button}->getStyle($attr);
}

sub deleteStyle {
    my ($self, $attr) = @_;
    $self->{__button}->deleteStyle($attr);
    return $self;
}

sub setId {
    my ($self, $id) = @_;
    $self->SUPER::setId($id . '_noscript');
    $self->{__button}->setId($id);
    $self->{__button}{image}->setId($id . '_image');
    return $self;
}

sub getId {
    return shift->{__button}->getId;
}

sub setClass {
    my ($self, $class) = @_;

    $self->{__button}->setClass($class);
    return $self;
}

sub appendClass {
    my ($self, $class) = @_;

    $self->{__button}->appendClass($class);
    return $self;
}

sub prependClass {
    my ($self, $class) = @_;

    $self->{__button}->prependClass($class);
    return $self;
}

sub hasClass {
    my ($self, $class) = @_;

    $self->{__button}->hasClass($class);
    return $self;
}

sub removeClass {
    my ($self, $class) = @_;

    $self->{__button}->removeClass($class);
    return $self;
}

sub getClass {
    return shift->{__button}->getClass;
}

sub signalConnect {
    my ($self, $signal, $handler) = @_;

    $self->{__button}->signalConnect($signal, $handler);
    return $self;
}

sub signalDisconnect {
    my ($self, $signal, $handler) = @_;

    $self->{__button}->signalDisconnect($signal, $handler);
    return $self;
}

sub signalDisconnectAll {
    my ($self, $signal) = @_;

    $self->{__button}->signalDisconnectAll($signal);
    return $self;
}

sub setTitle {
    my ($self, $title) = @_;

    $self->{__button}->setTitle($title);
    return $self;
}

sub getTitle {
    return shift->{__button}->getTitle;
}

sub setName {
    my ($self, $name) = @_;
    $self->{__button}->setName($name);
    return $self;
}

sub getName {
    return shift->{__button}->getName;
}

sub setAlt {
    my ($self, $alt) = @_;

    $self->{__button}{image}->setAlt($alt);
    return $self;
}

sub getAlt {
    return shift->{__button}{image}->getAlt;
}

sub set {
    my ($self, $src) = @_;

    $self->{__button}{image}->set($src);
    return $self;
}

sub getSrc {
    return shift->{__button}{image}->getSrc;
}

sub getHref {
    return shift->{__nsAnchor}->getHref;
}

# Protected
#
sub _realize {
    my $self    = shift;
    my $script  = IWL::Script->new;
    my $id      = $self->{__button}->getId;
    my $options = {};

    $self->SUPER::_realize;
    if ($self->{__formName}) {
        $self->{__button}->signalConnect(
            click => qq{this.submitForm("$self->{__formName}")});
    } elsif ($self->{__hiddenName}) {
        $self->{__button}->signalConnect(
            click => "this.submit()");
    }

    $self->{__button}{image}->signalConnect(load => "\$('$id').adjust()");
    $self->{__button}{_handlers} = $self->{_handlers};
    my $container = encodeURIComponent($self->{__button}->getJSON);
    my $image     = encodeURIComponent($self->{__button}{image}->getJSON);
    my $label     = encodeURIComponent($self->{__button}{label});
    my $json      =
      qq|{container:"$container",image:"$image",label:"$label"}|;

    $options = objToJson($self->{_options});
    $script->setScript("Button.create('$id', $json, $options);");
    $script->appendScript($self->{__button}{_customSignalScript}->getScript)
      if $self->{__button}{_customSignalScript};
    $self->_appendAfter($script);
    $self->_appendAfter($self->{__hidden}) if $self->{_options}{submit};
}

sub _setupDefaultClass {
    my $self = shift;
    $self->SUPER::prependClass($self->{_defaultClass} . '_noscript');
    $self->{__button}->prependClass($self->{_defaultClass});
    return $self->{__button}{image}->prependClass($self->{_defaultClass} . '_image');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $hidden = IWL::Input->new;
    my $anchor = IWL::Anchor->new;
    my $image  = IWL::Image->new;
    my $id     = $args{id};

    $self->{_defaultClass}     = 'button';
    $image->{_ignore}          = 1;
    $hidden->{_ignore}         = 1;

    $self->{__button}          = IWL::Container->new;
    $self->{__button}{image}   = $image;
    $self->{__button}{label}   = '';
    $self->{__hidden}          = $hidden;
    $self->{__nsAnchor}        = $anchor;
    $self->{__nsAnchor}{added} = 0;

    $hidden->setAttribute(type => 'submit');
    $hidden->setStyle(display => 'none');
    $id = randomize($self->{_defaultClass}) unless $id;
    $self->{_tag} = "noscript";
    $self->setId($id);

    $self->{_options}{size} = $args{size} || 'default';
    $self->{_options}{submit} = 0;

    delete @args{qw(size id)};
    $self->{__button}->_constructorArguments(%args);
    $self->requiredJs('base.js', 'button.js');

    # Callbacks
    # Hides the dashed focus border in IE. For firefox, this is done by css
    $self->signalConnect(focus => "this.hideFocus = true");
    $self->{__button}{_customSignals} = {load => []};

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

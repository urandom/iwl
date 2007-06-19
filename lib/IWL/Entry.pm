#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Entry;

use strict;

use base 'IWL::Input';

use IWL::String qw(randomize);

=head1 NAME

IWL::Entry - a text entry widget

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Input -> IWL::Entry

=head1 DESCRIPTION

The entry widget is a single-line, text entry, also capable of showing password-type fields.

=head1 CONSTRUCTOR

IWL::Entry->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  password: set to true if the entry is a password field.
  readonly: set to true if the entry is read-only
  text: set to whatever string should be shown as a default
  maxlength: the maximum number of characters the entry can hold

=head1 NOTES

Since the Entry is a compound object, settings the class and the id will also set the above to the components of the Entry. They will automatically obtain a suffix of "_image1" for the left image, "_image2" for the right image, and "_text" for the text control.

=head1 PROPERTIES

=over 4

=item B<image1>

The left icon of the entry

=item B<image2>

The right icon of the entry

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag}   = 'span';
    $self->{_noChildren}   = 0;
    $self->{__clearButton} = 0;
    $self->{__setDefault}  = 0;
    $self->__init(%args);
    return $self;
}

=head1 METHODS

=over 4

=item B<setPassword> (B<BOOL>)

Sets whether the type of the entry is a password type 

Parameter: B<BOOL> - a boolean value.

=cut

sub setPassword {
    my ($self, $bool) = @_;

    if ($bool) {
        $self->{__entry}->setAttribute(type => 'password');
    } else {
        $self->{__entry}->setAttribute(type => 'text');
    }

    return $self;
}

=item B<setReadonly> (B<BOOL>)

Sets whether the type of the entry is read-only 

Parameter: B<BOOL> - a boolean value.

=cut

sub setReadonly {
    my ($self, $bool) = @_;

    if ($bool) {
        $self->{__entry}->setAttribute(readonly => 'true');
    } else {
        $self->{__entry}->deleteAttribute('readonly');
    }

    return $self;
}

=item B<setText> (B<TEXT>)

Sets the text of the entry

Parameter: B<TEXT> - the text.

=cut

sub setText {
    my ($self, $text) = @_;

    $self->{__entry}->setValue($text);

    return $self;
}

=item B<setDefaultText> (B<TEXT>)

Sets the default text of the entry

Parameter: B<TEXT> - the text.

=cut

sub setDefaultText {
    my ($self, $text) = @_;

    $self->{__entry}->signalConnect(blur => <<EOF);
if (this.value == '') {
    this.value = '$text';
    \$(this).addClassName('$self->{_defaultClass}_text_default');
}
EOF
    $self->{__entry}->signalConnect(focus => <<EOF);
if (this.value == '$text') {
    this.value = '';
    \$(this).removeClassName('$self->{_defaultClass}_text_default');
}
EOF

    $self->setText($text);
    $self->{__setDefault} = 1;
    $self->setClass($self->getClass);
    return $self;
}

=item B<setMaxLength> (B<NUM>)

Sets the maximum character length of the entry

Parameter: B<NUM> - a number.

=cut

sub setMaxLength {
    my ($self, $num) = @_;

    $self->{__entry}->setAttribute(maxlength => $num);
    return $self;
}

=item B<setSize> (B<NUM>)

Sets the size of the entry field

Parameter: B<NUM> - a number.

=cut

sub setSize {
    my ($self, $num) = @_;

    $self->{__entry}->setAttribute(size => $num);
    return $self;
}

=item B<setIcon> (B<SRC>, [B<ALT>, B<POSITION>, B<CLICKABLE>])

Sets the icon that is shown in the entry

Parameters: B<SRC> - the source of the image, B<ALT> - the alternate text of the image, B<POSITION> - the icon position, either "left", or "right" (default: "left"), B<CLICKABLE> - true if the icon is clickable (sets the cursor)

=cut

sub setIcon {
    my ($self, $src, $alt, $position, $clickable) = @_;

    if ($position eq 'right') {
        $self->{image2}{_ignore} = 0;
        $self->{image2}->set($src);
        $self->{image2}->setAlt($alt);
	return $self->{image2}->setStyle(cursor => 'pointer') if $clickable;
    } elsif ($position eq 'left' || !$position) {
        $self->{image1}{_ignore} = 0;
        $self->{image1}->set($src);
        $self->{image1}->setAlt($alt);
	return $self->{image1}->setStyle(cursor => 'pointer') if $clickable;
    }

    return $self;
}

=item B<setIconFromStock> (B<STOCK_ID>, [B<POSITION>, B<CLICKABLE>])

Sets the icon that is shown in the entry, from a stock image

Parameters: B<STOCK_ID> - the stock id of the image, B<POSITION> - the icon position, either "left", or "right" (default: "left"), B<CLICKABLE> - true if the icon is clickable (sets the cursor)

=cut

sub setIconFromStock {
    my ($self, $stock_id, $position, $clickable) = @_;

    if ($position && $position eq 'right') {
        $self->{image2}->setFromStock($stock_id) or return;
        $self->{image2}{_ignore} = 0;
	return $self->{image2}->setStyle(cursor => 'pointer') if $clickable;
    } elsif (!$position || $position eq 'left') {
        $self->{image1}->setFromStock($stock_id) or return;
        $self->{image1}{_ignore} = 0;
	return $self->{image1}->setStyle(cursor => 'pointer') if $clickable;
    }
}

=item B<addClearButton>

A wrapper function that adds a clear button to the end of the entry

=cut

sub addClearButton {
    my $self = shift;

    $self->setIconFromStock(IWL_STOCK_CLEAR => 'right', 1);
    $self->__set_clear_callback;
    return $self->{__clearButton} = 1;
}

=item B<setAutoComplete> (B<URL>, [B<%OPTIONS>])

Adds auto-completion for the entry

Parameters: B<URL> - the url of the destination script, B<%OPTIONS> - a hash with the following options:
  paramName - the name of the parameter, which will hold the 
	      currently written string
  minChars  - the minimum number of typed character, 
              in order to invoke an ajax call
  indicator - id of an element to be shown, during the ajax call
    
=cut

sub setAutoComplete {
    my ($self, $url, %options) = @_;
    return unless $url;

    $self->{__completeOptions}{options} = \%options;
    $self->{__completeOptions}{url} = $url;
    return $self->__setup_completion;
}

# Overrides
#

=item B<setId> (B<ID>, [B<CONTROL_ID>])

Sets the id of the entry and all of it's parts. Can optionally set the id of the control.

Parameters: B<ID> - the id of the entry, B<CONTROL_ID> - the id of the text control, optional

=cut

sub setId {
    my ($self, $id, $control_id) = @_;

    $self->setAttribute(id              => $id);
    $self->{image1}->setAttribute(id    => $id . '_image1');
    $self->{image2}->setAttribute(id    => $id . '_image2');
    $self->{__receiver}->setAttribute(id => $id . '_receiver');
    if ($control_id) {
        $self->{__entry}->setAttribute(id => $control_id);
    } else {
        $self->{__entry}->setAttribute(id => $id . '_text');
    }
    return $self->__setup_completion;
}

sub setAttribute {
    my ($self, $attr, $value) = @_;

    if ($attr eq 'id' || $attr eq 'class') {
        $self->SUPER::setAttribute($attr, $value);
	if ($attr eq 'id') {
	    return $self->__setup_completion;
	} else {
	    return $self;
	}
    } else {
        $self->{__entry}->setAttribute($attr, $value);
	return $self;
    }
}

sub signalConnect {
    my ($self, $signal, $callback) = @_;

    $self->{__entry}->signalConnect($signal => $callback);
    return $self;
}

# Protected
#
sub _setupDefaultClass {
    my $self = shift;
    my $password = $self->{__entry}->getAttribute('type', 1);

    $self->prependClass('password') if $password eq 'password';
    $self->prependClass($self->{_defaultClass});
    $self->{image1}->prependClass($self->{_defaultClass} . '_image1');
    $self->{image2}->prependClass($self->{_defaultClass} . '_image2');
    $self->{__receiver}->prependClass($self->{_defaultClass} . '_receiver');
    if ($self->{__setDefault}) {
	$self->{__entry}->prependClass($self->{_defaultClass} . '_text_default');
    }
    $self->{__entry}->prependClass($self->{_defaultClass} . '_text');

    return $self->__set_clear_callback if $self->{__clearButton};
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $entry  = IWL::Input->new;
    my $image1 = IWL::Image->new;
    my $image2 = IWL::Image->new;
    my $span   = IWL::Container->new;
    my $completion = IWL::Script->new;
    my $receiver   = IWL::Container->new;

    $self->{image1} = $image1;
    $self->{image2} = $image2;
    $self->{__entry} = $entry;
    $self->{__completion} = $completion;
    $self->{__receiver}   = $receiver;
    $self->{_defaultClass} = 'entry';

    $self->appendChild($image1);
    $self->appendChild($entry);
    $self->appendChild($image2);

    $entry->setAttribute(type => 'text');

    $args{id} = randomize($self->{_defaultClass}) if !$args{id};
    $entry->setAttribute(type => 'password') if $args{password};
    $entry->setAttribute(readonly => 'true') if $args{readonly};
    $entry->setAttribute(value => $args{text}) if $args{text};
    $entry->setAttribute(maxlength => $args{maxlength}) if $args{maxlength};
    $self->setClass($args{class}) if $args{class};
    $self->setId($args{id}) if $args{id};
    delete @args{qw(password readonly text maxlength id class)};
    $entry->_constructorArguments(%args);

    $image1->{_ignore} = 1;
    $image2->{_ignore} = 1;

    return $self;
}

sub __set_clear_callback {
    my $self  = shift;
    my $class = $self->{__entry}->getClass;

    $class =~ s/_default// if $self->{__setDefault};
    $self->{image2}->signalConnect(
        click => qq|
	  var clearButton = \$(this).up().cleanWhitespace().down();
	  if (clearButton) {
	      clearButton.value = '';
	      clearButton.focus();
	  }
	|
    );

    return $self;
}

sub __setup_completion {
    my $self = shift;
    my $id = $self->{__entry}->getId;
    my $url = $self->{__completeOptions}{url};
    my $receiver = $self->{__receiver}->getId;
    return unless $url && $receiver;
    my $options = $self->{__completeOptions}{options};
    my $text = "new Ajax.Autocompleter('$id', '$receiver', '$url', {";
    foreach my $key (keys %$options) {
	$text .= "'$key':'$options->{$key}',";
    }
    $text =~ s/,$//;
    $text .= "})";
    $self->{__completion}->setScript($text);
    unless ($self->{__completionAdded}) {
	$self->appendChild($self->{__receiver});
	$self->appendChild($self->{__completion});
	$self->{__completionAdded} = 1;
    }
    $self->requiredJs('dist/prototype.js');
    $self->requiredJs('dist/effects.js');
    $self->requiredJs('dist/controls.js');
    $self->requiredJs('scriptaculous_extensions.js');
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

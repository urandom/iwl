#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Entry;

use strict;

use base 'IWL::Input';

use IWL::Image;
use IWL::Table::Container;
use IWL::Table::Row;
use IWL::Container;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

=head1 NAME

IWL::Entry - a text entry widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Input> -> L<IWL::Entry>

=head1 DESCRIPTION

The entry widget is a single-line, text entry, also capable of showing password-type fields.

=head1 CONSTRUCTOR

IWL::Entry->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<password>

Set to true if the entry is a password field.

=item B<readonly>

Set to true if the entry is read-only

=item B<text>

Set to whatever string should be shown as a default

=item B<maxlength>

The maximum number of characters the entry can hold

=back

=head1 PROPERTIES

=over 4

=item B<text>

The input text of the entry

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

    $self->{_tag}   = 'table';
    $self->{_noChildren} = 0;
    $self->_init(%args);
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
        $self->{text}->setAttribute(type => 'password');
    } else {
        $self->{text}->setAttribute(type => 'text');
    }

    return $self;
}

=item B<isPassword>

Returns true if the entry is a password type

=cut

sub isPassword {
    return shift->{text}->getAttribute('type') eq 'password';
}

=item B<setReadonly> (B<BOOL>)

Sets whether the type of the entry is read-only 

Parameter: B<BOOL> - a boolean value.

=cut

sub setReadonly {
    my ($self, $bool) = @_;

    if ($bool) {
        $self->{text}->setAttribute(readonly => 'true');
    } else {
        $self->{text}->deleteAttribute('readonly');
    }

    return $self;
}

=item B<isReadonly>

Returns true if the entry is a read-only

=cut

sub isReadonly {
    return shift->{text}->hasAttribute('readonly');
}

=item B<setText> (B<TEXT>)

Sets the text of the entry

Parameter: B<TEXT> - the text.

=cut

sub setText {
    my ($self, $text) = @_;

    $self->{text}->setValue($text);

    return $self;
}

=item B<getText>

Returns the text of the entry

=cut

sub getText {
    return shift->{text}->getValue;
}

=item B<setDefaultText> (B<TEXT>)

Sets the default text of the entry

Parameter: B<TEXT> - the text.

=cut

sub setDefaultText {
    my ($self, $text) = @_;

    $self->{_options}{defaultText} = $text;
    return $self;
}

=item B<getDefaultText>

Returns the default text of the entry

=cut

sub getDefaultText {
    return shift->{_options}{defaultText};
}

=item B<setMaxLength> (B<NUM>)

Sets the maximum character length of the entry

Parameter: B<NUM> - a number.

=cut

sub setMaxLength {
    my ($self, $num) = @_;

    $self->{text}->setAttribute(maxlength => $num);
    return $self;
}

=item B<getMaxLength>

Returns the maximum character length of the entry

=cut

sub getMaxLength {
    return shift->{text}->getAttribute('maxlength');
}

=item B<setSize> (B<NUM>)

Sets the size of the entry field

Parameter: B<NUM> - a number.

=cut

sub setSize {
    my ($self, $num) = @_;

    $self->{text}->setAttribute(size => $num);
    return $self;
}

=item B<getSize>

Returns the size of the entry field

=cut

sub getSize {
    return shift->{text}->getAttribute('size');
}

=item B<setIcon> (B<SRC>, [B<ALT>, B<POSITION>, B<CLICKABLE>])

Sets the icon that is shown in the entry

Parameters: B<SRC> - the source of the image, B<ALT> - the alternate text of the image, B<POSITION> - the icon position, either "left", or "right" (default: "left"), B<CLICKABLE> - true if the icon is clickable (sets the cursor)

Returns the set image

=cut

sub setIcon {
    my ($self, $src, $alt, $position, $clickable) = @_;

    if (!$position || $position eq 'left') {
        $self->{image1}{_ignore} = 0;
        $self->{image1}->set($src);
        $self->{image1}->setAlt($alt);
	$self->{image1}->setStyle(cursor => 'pointer') if $clickable;
	return $self->{image1};
    } elsif ($position eq 'right') {
        $self->{image2}{_ignore} = 0;
        $self->{image2}->set($src);
        $self->{image2}->setAlt($alt);
	$self->{image2}->setStyle(cursor => 'pointer') if $clickable;
	return $self->{image2};
    }
}

=item B<setIconFromStock> (B<STOCK_ID>, [B<POSITION>, B<CLICKABLE>])

Sets the icon that is shown in the entry, from a stock image

Parameters: B<STOCK_ID> - the stock id of the image, B<POSITION> - the icon position, either "left", or "right" (default: "left"), B<CLICKABLE> - true if the icon is clickable (sets the cursor)

Returns the set image

=cut

sub setIconFromStock {
    my ($self, $stock_id, $position, $clickable) = @_;

    if ($position && $position eq 'right') {
        $self->{image2}->setFromStock($stock_id) or return;
        $self->{image2}{_ignore} = 0;
	$self->{image2}->setStyle(cursor => 'pointer') if $clickable;
	return $self->{image2};
    } elsif (!$position || $position eq 'left') {
        $self->{image1}->setFromStock($stock_id) or return;
        $self->{image1}{_ignore} = 0;
	$self->{image1}->setStyle(cursor => 'pointer') if $clickable;
	return $self->{image1};
    }
}

=item B<addClearButton>

A wrapper function that adds a clear button to the end of the entry

=cut

sub addClearButton {
    my $self = shift;

    $self->setIconFromStock(IWL_STOCK_CLEAR => 'right', 1);
    $self->{image2}->setAttribute(id => $self->getId . '_right');
    $self->{_options}{clearButton} = 1;
    return $self;
}

=item B<setAutoComplete> (B<URL>, [B<%OPTIONS>])

Adds auto-completion for the entry

Parameters: B<URL> - the url of the destination script, B<%OPTIONS> - a hash with the following options:

=over 8

=item B<paramName>

The name of the parameter, which will hold the currently written string

=item B<minChars>

The minimum number of typed character, in order to invoke an ajax call

=item B<indicator>

Id of an element to be shown, during the ajax call

=back

=cut

sub setAutoComplete {
    my ($self, $url, %options) = @_;
    return unless $url;

    $self->{_options}{autoComplete} = [$url, \%options];
    return $self;
}

=item B<printCompletions> (B<COMPLETION>, ...)

Prints the supplied completions in a format, which is required for auto-completion.

This method is a class method!  You do not need to instantiate an object in order to call it.

=cut

sub printCompletions {
    my @completions = @_;

    my $list = IWL::List->new->setClass('entry_completion_list');
    $list->appendListItemText($_) foreach @completions;

    return $list->send(type => 'text');
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
    $self->{image1}->setAttribute(id    => $id . '_left');
    $self->{image2}->setAttribute(id    => $id . '_right');
    if ($control_id) {
        $self->{text}->setAttribute(id => $control_id);
    } else {
        $self->{text}->setAttribute(id => $id . '_text');
    }
}

sub setAttribute {
    my ($self, $attr, $value) = @_;

    if (grep {$attr eq $_} qw(id class cellspacing cellpadding)) {
        $self->SUPER::setAttribute($attr, $value);
    } else {
        $self->{text}->setAttribute($attr, $value);
    }
    return $self;
}

sub getAttribute {
    my ($self, $attr) = @_;

    if (grep {$attr eq $_} qw(id class cellspacing cellpadding)) {
        return $self->SUPER::getAttribute($attr);
    } else {
        return $self->{text}->getAttribute($attr);
    }
}

sub signalConnect {
    my ($self, $signal, $callback) = @_;

    $self->{text}->signalConnect($signal => $callback);
    return $self;
}

# Protected
#
sub _realize {
    my $self   = shift;
    my $id     = $self->getId;

    $self->SUPER::_realize;

    my $options = toJSON($self->{_options});
    $self->_appendInitScript("IWL.Entry.create('$id', $options);");
}

sub _setupDefaultClass {
    my $self = shift;
    my $password = $self->{text}->getAttribute('type', 1);

    $self->prependClass('password') if $password eq 'password';
    $self->prependClass($self->{_defaultClass});
    $self->{image1}->prependClass($self->{_defaultClass} . '_left');
    $self->{image2}->prependClass($self->{_defaultClass} . '_right');
    if ($self->{_options}{defaultText}) {
	$self->{text}->prependClass($self->{_defaultClass} . '_text_default');
    }
    $self->{text}->prependClass($self->{_defaultClass} . '_text');
}

# Internal
#
sub _init {
    my ($self, %args) = @_;
    my $entry         = IWL::Input->new;
    my $image1        = IWL::Image->new;
    my $image2        = IWL::Image->new;
    my $body          = IWL::Table::Container->new;
    my $row           = IWL::Table::Row->new;

    $self->{image1}        = $image1;
    $self->{image2}        = $image2;
    $self->{text}          = $entry;
    $self->{_row}          = $row;
    $self->{_defaultClass} = 'entry';

    $self->appendChild($body);
    $body->appendChild($row);
    $row->appendCell($image1);
    $row->appendCell($entry);
    $row->appendCell($image2);

    $self->setAttributes(cellpadding => 0, cellspacing => 0);
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

    $self->{_options} = {};

    $self->requiredJs('base.js', 'entry.js');

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

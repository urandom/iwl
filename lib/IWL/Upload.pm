#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Upload;

use strict;

use IWL::Button;
use IWL::File;
use IWL::IFrame;
use IWL::String qw(randomize);
use IWL::JSON qw(toJSON);

use base 'IWL::Form';

use Locale::TextDomain qw(org.bloka.iwl);

=head1 NAME

IWL::Upload - a file upload widget

=head1 INHERITANCE

L<IWL::Error> -> L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Form> -> L<IWL::Upload>

=head1 DESCRIPTION

The Upload widget is a form widget, with it's own file selector.

=head1 CONSTRUCTOR

IWL::Upload->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<action>

The form action

=item B<showTooltip>

True, if an information tooltip should be shown

=back

=head1 SIGNALS

=over 4

=item B<upload>

Fires when a file has been uploaded

=back

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(
        method  => 'post',
        enctype => 'multipart/form-data'
    );

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<setAccept> (B<EXPR>)

Sets the accepted mime types. Browsers which support this can use it to filter out the files that a user can choose.

Parameters: B<EXPR> - the expression which is used for filtering

=cut

sub setAccept {
    my ($self, $expr) = @_;

    $self->{__file}->setAccept($expr);
    return $self;
}

=item B<getAccept>

Returns the accept filter

=cut

sub getAccept {
    return shift->{__file}->getAccept;
}

=item B<setLabel> (B<TEXT>)

Sets the label of the button

Parameters: B<TEXT> - the text for the label

=cut

sub setLabel {
    my ($self, $text) = @_;

    $self->{__button}->setLabel($text);
    return $self;
}

=item B<getLabel>

Returns the label of the button

=cut

sub getLabel {
    return shift->{__button}->getLabel;
}

=item B<printMessage> (B<MESSAGE>, B<DATA>)

Prints a message, so that it can be displayed in the upload tooltip

Parameters: B<MESSAGE> - the message to be displayed when a file is uploaded. B<DATA> - the data to be passed to a listener for the I<upload> signal.

This method is a class method!  You do not need to instantiate an object
in order to call it.

=cut

sub printMessage {
    my $message = shift;
    $message = shift if ref $message;
    my $data = shift || {};

    my $json = IWL::Text->new;
    my $page = IWL::Page->new(simple => 1);
    $json->setContent(toJSON({message => $message, data => $data}));
    $page->appendChild($json);
    $page->send(type => 'html');
}

# Overrides
#
sub setId {
    my ($self, $id) = @_;

    $self->SUPER::setId($id);
    $self->{__file}->setId($id . '_file');
    $self->{__frame}->setId($id . '_frame');
    $self->{__button}->setId($id . '_button');

    $self->{__file}->setName($id . '_file');
    $self->{__frame}->setName($id . '_frame');

    $self->setTarget($id . '_frame');
}

sub setName {
    my ($self, $name) = @_;

    $self->{__file}->setName($name);
    return $self;
}

sub getName {
    return shift->{__file}->getName;
}

# Protected
#
sub _realize {
    my $self   = shift;
    my $id     = $self->getId;

    $self->SUPER::_realize;

    $self->{__file}->setStyle(visibility => 'hidden');
    my $file = $self->{__file}->getJSON;
    my $options = toJSON($self->{_options});
    my $uploading = __"Uploading ...";
    $self->_appendInitScript("IWL.Upload.create('$id', $file, $options, {uploading: '$uploading'})");
}

sub _setupDefaultClass {
    my $self = shift;

    $self->SUPER::prependClass($self->{_defaultClass});
    $self->{__file}->prependClass($self->{_defaultClass} . '_file');
    $self->{__frame}->prependClass($self->{_defaultClass} . '_frame');
    $self->{__button}->prependClass($self->{_defaultClass} . '_button');
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $file   = IWL::File->new;
    my $frame  = IWL::IFrame->new;
    my $button = IWL::Button->new(size => 'medium');

    $self->{_defaultClass} = 'upload';
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{__file}   = $file;
    $self->{__frame}  = $frame;
    $self->{__button} = $button;
    $self->{_options} = {};
    $self->{_options}{showTooltip} = $args{showTooltip} if defined $args{showTooltip};
    $self->appendChild($frame);
    $self->appendChild($button);
    $self->setId($args{id});
    $self->setAction($args{action});
    delete @args{qw(id action showTooltip)};

    $button->setLabel(__('Browse ...'));
    $file->_constructorArguments(%args);
    $self->requiredJs('base.js', 'upload.js', 'tooltip.js');
    $self->{_customSignals} = { upload => [] };

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

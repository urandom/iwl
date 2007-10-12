#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Upload;

use strict;

use IWL::Button;
use IWL::File;
use IWL::IFrame;
use IWL::String qw(randomize);

use base 'IWL::Form';

=head1 NAME

IWL::Upload - a file upload widget

=head1 INHERITANCE

L<IWL::Object> -> L<IWL::Widget> -> L<IWL::Form> -> L<IWL::Upload>

=head1 DESCRIPTION

The Upload widget is a form widget, with it's own file selector.

=head1 CONSTRUCTOR

IWL::File->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.

=over 4

=item B<action>

The form action

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

=item B<setUploadCallback> (B<CALLBACK>)

Sets the function to be executed when a file has been uploaded.

Parameters: B<CALLBACK> - the javascript callback, it will receive the json as it's parameter

=cut

sub setUploadCallback {
    my ($self, $callback) = @_;

    $self->{__uploadCallback} = $callback;
    return $self;
}

=item B<printMessage> (B<MESSAGE>)

Prints a message, so that it can be displayed in the upload tooltip

This method is a class method!  You do not need to instantiate an object
in order to call it.

=cut

sub printMessage {
    my $message = shift;
    $message = shift if ref $message;

    my $json = IWL::Text->new;
    my $page = IWL::Page->new(simple => 1);
    $json->setContent("{message:'$message'}");
    $page->appendChild($json);
    $page->print;
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

# Protected
#
sub _realize {
    my $self = shift;
    my $id   = $self->getId;

    $self->SUPER::_realize;

    my $file = $self->{__file}->getJSON;
    my $arg = $self->{__uploadCallback} || 0;
    $self->{__init}->setScript("Upload.create('$id', $file, {uploadCallback: window[$arg]})");
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
    my $frame  = IWL::IFrame->new;
    my $file   = IWL::File->new;
    my $button = IWL::Button->new(size => 'medium');
    my $init   = IWL::Script->new;

    $self->{_defaultClass} = 'upload';
    $args{id} ||= randomize($self->{_defaultClass});

    $self->{__file}   = $file;
    $self->{__frame}  = $frame;
    $self->{__button} = $button;
    $self->{__init}   = $init;
    $self->appendChild($button);
    $self->appendChild($frame);
    $self->appendChild($init);
    $self->setId($args{id});
    delete @args{qw(id)};

    $button->setLabel('Browse ...');
    $file->_constructorArguments(%args);
    $self->requiredJs('base.js', 'upload.js', 'tooltip.js');

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

#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL::Page;

use strict;

use base qw(IWL::Widget);

use IWL::Page::Body;
use IWL::Page::Head;
use IWL::Page::Link;
use IWL::Page::Meta;
use IWL::Page::Title;
use IWL::Script;
use IWL::Config qw(%IWLConfig);
use IWL::Comment;

use JSON;

use constant DOCTYPES => {
    html401 => <<DECL,
DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd"
DECL
    html401strict => <<DECL,
DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd"
DECL
    xhtml1 => <<DECL,
DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
DECL
    xhtml1strict => <<DECL,
DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
DECL
    xhtml11 => <<DECL,
DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
DECL
};

=head1 NAME

IWL::Page - The root widget, containing the body and header markup.

=head1 INHERITANCE

IWL::Object -> IWL::Widget -> IWL::Page

=head1 DESCRIPTION

Page is the primary widget of IWL. It acts as a container for everything else and also contains the <head> and <body> elements.

=head1 CONSTRUCTOR

IWL::Page->new ([B<%ARGS>])

Where B<%ARGS> is an optional hash parameter with with key-values.
  simple - true if the page should be a simple document, useful for iframes

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();

    $self->{_tag}         = "html";
    $self->{_HTTPHeader} = "Content-type: text/html; charset=utf-8\n\n";
    $self->{_declaration} = DOCTYPES->{'xhtml1'};
    $self->setAttribute(xmlns => "http://www.w3c.org/1999/xhtml");
    $self->setAttribute('xmlns:iwl' => "http://namespace.bloka.org/iwl");

    $self->__init(%args);

    return $self;
}

=head1 METHODS

=over 4

=item B<appendMetaEquiv> (B<EQUIV>, B<CONTENT>)

Adds a B<<meta>> tag with the given equiv and content.

Parameters: B<EQUIV> - the http-equiv, B<CONTENT> - the content

=cut

sub appendMetaEquiv {
    my ($self, $equiv, $content) = @_;
    my $meta = IWL::Page::Meta->new;

    $meta->set($equiv => $content);
    $self->{_head}->appendChild($meta);
    return $self;
}

=item B<appendHeader> (B<OBJECT>)

Appends the object to the head of the page

Parameters: B<OBJECT> - IWL::Object(3pm)

=cut

sub appendHeader {
    my ($self, $object) = @_;

    $self->{_head}->appendChild($object);
    return $self;
}

=item B<prependHeader> (B<OBJECT>)

Prepends the object to the head of the page

Parameters: B<OBJECT> - IWL::Object(3pm)

=cut

sub prependHeader {
    my ($self, $object) = @_;

    $self->{_head}->prependChild($object);
    return $self;
}

=item B<setTitle> (B<TEXT>)

Sets the title of the page

Parameters: B<TEXT> - the title to be set

=cut

sub setTitle {
    my ($self, $text) = @_;

    my $title = IWL::Page::Title->new;
    $title->setTitle($text);
    $self->{_head}{_title} = $title;
    return $self;
}

=item B<setHTTPHeader> (B<HEADER>)

Sets the header of the page. The default one is:
  Content-type: text/html; charset=utf-8

The two final new lines are not required

Parameters: B<HEADER> - the header string

=cut

sub setHTTPHeader {
    my ($self, $header) = @_;
    return unless $header;

    $self->{_HTTPHeader} = $header . "\n\n";
    return $self;
}

=item B<setDeclaration> (B<DECLARATION>)

Sets the document type declaration. The default one is:

  DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"

For conveniece, the following strings are automatically converted to declarations:
  html401, html401strict, xhtml1, xhtml1strict, xhtml11

Parameters: B<DECLARATION> - the DOCTYPE to change to

=cut

sub setDeclaration {
    my ($self, $declaration) = @_;
    return unless $declaration;

    if (DOCTYPES->{$declaration}) {
	$self->{_declaration} = DOCTYPES->{$declaration};
    } else {
	$self->{_declaration} = $declaration;
    }
    return $self;
}

# Overrides
#
sub signalConnect {
    my ($self, $signal, $callback) = @_;

    $self->{_body}->signalConnect($signal, $callback);
}

sub appendChild {
    my ($self, @objects) = @_;
    $self->{_body}->appendChild(@objects);
}

sub prependChild {
    my ($self, @objects) = @_;
    $self->{_body}->prependChild(@objects);
}

sub requiredJs {
    my ($self, @urls) = @_;
    
    return $self->{_head}->requiredJs(@urls);
}

# Internal
#
sub __init {
    my ($self, %args) = @_;
    my $head = IWL::Page::Head->new;
    my $body = IWL::Page::Body->new;

    $self->{_head} = $head;
    $self->{_body} = $body;
    $self->SUPER::appendChild($head);
    $self->SUPER::appendChild($body);

    return 1 if $args{simple};
    delete $args{simple};

    $self->_constructorArguments(%args);
    my $skin = IWL::Page::Link->new(
        rel   => 'stylesheet',
        type  => 'text/css',
	href  => $IWLConfig{SKIN_DIR} . '/main.css',
        media => 'screen',
	title => 'Main',
    );
    my $ie          = IWL::Page::Link->newLinkToCSS($IWLConfig{SKIN_DIR} . '/ie.css');
    my $ie6         = IWL::Page::Link->newLinkToCSS($IWLConfig{SKIN_DIR} . '/ie6.css');
    my $conditional = IWL::Comment->new;
    $self->requiredJs('dist/prototype.js', 'dist/scriptaculous.js', 'base.js');

    my $script = IWL::Script->new;
    $script->appendScript("window.IWLConfig = " . objToJson(\%IWLConfig) . ";");
    $head->appendChild($script);

    $head->appendChild($skin);
    $head->appendChild($conditional);
    $conditional->setConditionalData('IE', $ie);
    $conditional = IWL::Comment->new;
    $head->appendChild($conditional);
    return $conditional->setConditionalData('lt IE 7', $ie6);
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

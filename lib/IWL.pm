#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL;

use strict;

use IWL::Anchor;
use IWL::Break;
use IWL::Button;
use IWL::Canvas;
use IWL::Checkbox;
use IWL::Combo::Option;
use IWL::Combo;
use IWL::Comment;
use IWL::Container;
use IWL::Contentbox;
use IWL::Druid;
use IWL::Entry;
use IWL::File;
use IWL::Form;
use IWL::Frame;
use IWL::Hidden;
use IWL::HBox;
use IWL::Iconbox::Icon;
use IWL::Iconbox;
use IWL::Image;
use IWL::Input;
use IWL::InputButton;
use IWL::Label;
use IWL::List;
use IWL::List::Definition;
use IWL::Menu;
use IWL::Menu::Item;
use IWL::Menubar;
use IWL::NavBar;
use IWL::Notebook::Tab;
use IWL::Notebook;
use IWL::Page::Link;
use IWL::Page::Meta;
use IWL::Page;
use IWL::PageControl;
use IWL::RadioButton;
use IWL::RPC;
use IWL::Script;
use IWL::Slider;
use IWL::Stash;
use IWL::Style;
use IWL::SubmitImage;
use IWL::Table::Cell;
use IWL::Table::Row;
use IWL::Table;
use IWL::Text;
use IWL::Textarea;
use IWL::Tooltip;
use IWL::Tree::Cell;
use IWL::Tree::Row;
use IWL::Tree;
use IWL::Upload;

use vars qw($VERSION);

$VERSION = '0.46';

1;

=head1 NAME

IWL - A widget library for the web

=head1 VERSION

This documentation refers to B<IWL> version 0.45

=head1 SYNOPSIS

    use IWL;
    
    # create the main container, and a few widgets
    my $page = IWL::Page->new;
    my $frame = IWL::Frame->new;
    my $iconbox = IWL::Iconbox->new
	(width => '800px', height => '600px');
    my $button = IWL::Button->newFromStock
	('IWL_STOCK_CANCEL');
    my %some_icon_info = {"foo.jpg" => 'foo', "bar.png" => 'bar');

    # Setting up the icons and adding them to the iconbox
    foreach (keys %some_icon_info) {
	my $icon = IWL::Iconbox::Icon->new;
	$icon->setImage($_);
	$icon->setText($some_icon_info{$_});
	$icon->setDimensions('64px', '64px');
	$icon->setSelected(1) if $_ == 'something';
	$iconbox->appendIcon($icon);
    }

    $page->appendMetaEquiv("Cache-control" => "no-cache");
    $frame->setLabel("Frame label");
    # Adding the children to their parents
    $frame->appendChild($iconbox);
    $frame->appendChild($button);
    $page->appendChild($frame);

    # Finally printing the page
    $page->print;



=head1 DESCRIPTION

The IWL includes several widgets with which consistent web pages can be built quickly. The structure resembles the DOM tree, with the API mimicking Javascript very closely.
The widgets themselves can be used either as standalone object in an already existing scripts, or can be used to build new scripts from the grounds up. They can be finalized in both HTML markup, and JSON notation, which can be used for scripts. More advanced widgets like the Iconbox come with Javascript files which are automatically included when the widget is finalized as HTML.


=head1 INCLUDED MODULES

The following widgets have so far been written. They have extensive documentation for their methods

 IWL::Anchor - An anchor widget ("<a>")
 IWL::Break - A break widget ("<br>")
 IWL::Button - A graphic button widget
 IWL::Canvas - The html5 canvas element ("<canvas>")
 IWL::Checkbox - A checkbox widget (checkbox + text)
 IWL::Combo - A combobox widget ("<select>")
 IWL::Combo::Option - The content of a combobox ("<option>")
 IWL::Comment - A widget for placing comments (and conditional comments)
 IWL::Container - A basic container widget ("<div>")
 IWL::Contentbox - A generic window-like contentbox
 IWL::Druid - A step-based druid widget
 IWL::Entry - An entry widget with support for icons
 IWL::File - A file upload widget ("<input type="file">")
 IWL::Form - A form widget ("<form>")
 IWL::Frame - A frame widget ("<fieldset>")
 IWL::Hidden - A hidden input object ("<input type="hidden">")
 IWL::Hbox - A container widget for positioning widgets horizontally
 IWL::Iconbox - An iconbox widget (holds icons and has keyboard navigation)
 IWL::Iconbox::Icon - An icon widget for the iconbox
 IWL::Image - An image widget ("<img>")
 IWL::Input - A generic input widget ("<input>")
 IWL::InputButton - A generic button widget ("<input type="button">")
 IWL::Label - A label widget 
 IWL::List - A widget for creating bulleted or numbered lists
 IWL::List::Definition - A definition list item
 IWL::Menu - A menu widget
 IWL::Menu::Item - A menu item widget for menus and menubars
 IWL::Menubar - A menubar widget
 IWL::NavBar - A navigation bar widget
 IWL::Notebook - A tab notebook widget
 IWL::Notebook::Tab - A tab widget for the notebook
 IWL::Page - A page widget, for creating new pages
 IWL::Page::Link - A link object for the page widget ("<link>")
 IWL::Page::Meta - A meta object for the page widget ("<meta>")
 IWL::PageControl - A page control widget for paginating other widgets
 IWL::RadioButton - A radiobutton widget (radiobutton + text)
 IWL::RPC - A helper class for ajax connections and cgi parameters
 IWL::Script - A script object ("<script>")
 IWL::Slider - A slider widget
 IWL::Stash - A stash class for form information encapsulation
 IWL::Stock - A stock object, for buttons and images
 IWL::Style - A style object ("<style>")
 IWL::SubmitImage - An input image widget ("<input type="image">")
 IWL::Table - A table widget ("<table>")
 IWL::Table::Cell - A cell widget for the table row ("<td>", "<th>")
 IWL::Table::Row - A row widget for the table ("<tr">)
 IWL::Text - A simple text container
 IWL::Textarea - A textarea widget ("<textarea>")
 IWL::Tooltip - A tooltip widget
 IWL::Tree - A tree widget (has keyboard navigation)
 IWL::Tree::Cell - A tree cell widget
 IWL::Tree::Row - A tree row widget
 IWL::Upload - A theme-able upload widget

=head1 CONFIGURATION AND ENVIRONMENT

Configuration is done by editing the I<iwl.conf> file. It can be placed in the directory of the scripts that use IWL, or it's full path and name can be fiven in the I<IWL_CONFIG_FILE> environment variable. A default configuration is provided inside IWL::Config(3pm). See IWL::Config(3pm) for more details

In order to actually use the library, the javascript and css files will also have to be installed in the server's document root. To do that, the 'iwl-install' script is provided. It is usually located in '/usr/bin'. The script also creates a I<iwl.conf> file from the user input.


=head1 DEPENDENCIES

  JSON
  Scalar::Util
  Locale::Messages
  Locale::TextDomain
  HTML::Parser

=head1 TODO

=head2 General

 - Write more testcases

=head2 Perl

 - Add more stock items to IWL::Stock
 - Add an EmbedObject (<object>) and IFrame (<iframe>) widgets

=head2 Graphics

 - Create prettier icons (use tango gif icons?)


=head1 BUGS AND LIMITATIONS

 - In Internet explorer, floats will escape a container with scrollbars,
   if the positioning on the container is static, or the floats have a 
   relative positioning
 - The JSON library used in IWL has a bug where it will incorrectly unescape
   double quotes. It is preferred to escape potentially dangerous strings
   beforehand, or not use JSON at all

=head1 AUTHOR

  Viktor Kojouharov


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


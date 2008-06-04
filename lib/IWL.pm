#! /bin/false
# vim: set autoindent shiftwidth=4 tabstop=8:

package IWL;

use strict;

use IWL::Accordion;
use IWL::Accordion::Page;
use IWL::Anchor;
use IWL::Break;
use IWL::Button;
use IWL::Calendar;
use IWL::Canvas;
use IWL::Checkbox;
use IWL::Combo::Option;
use IWL::Combo;
use IWL::Comment;
use IWL::Container;
use IWL::Contentbox;
use IWL::Druid::Page;
use IWL::Druid;
use IWL::Entry;
use IWL::Expander;
use IWL::File;
use IWL::Form;
use IWL::Frame;
use IWL::Google::Map;
use IWL::Hidden;
use IWL::HBox;
use IWL::Iconbox::Icon;
use IWL::Iconbox;
use IWL::IFrame;
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
use IWL::ProgressBar;
use IWL::RadioButton;
use IWL::Response;
use IWL::RPC;
use IWL::Script;
use IWL::Slider;
use IWL::Spinner;
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
use IWL::VBox;

use vars qw($VERSION);

$VERSION = '0.61';

1;

=head1 NAME

IWL - A widget library for the web

=head1 VERSION

This documentation refers to B<IWL> version 0.61

=head1 SYNOPSIS

    use IWL;
    
    # create the main container, and a few widgets
    my $page = IWL::Page->new;
    my $frame = IWL::Frame->new;
    my $iconbox = IWL::Iconbox->new
	(width => '800px', height => '600px');
    my $button = IWL::Button->newFromStock
	('IWL_STOCK_CANCEL');
    my %some_icon_info = ("foo.jpg" => 'foo', "bar.png" => 'bar');

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
    $page->send(type => 'html');



=head1 DESCRIPTION

The IWL includes several widgets with which consistent web pages can be built quickly. The structure resembles the DOM tree, with the API mimicking Javascript very closely.
The widgets themselves can be used either as standalone object in an already existing scripts, or can be used to build new scripts from the grounds up. They can be finalized in both HTML markup, and JSON notation, which can be used for scripts. More advanced widgets like the Iconbox come with Javascript files which are automatically included when the widget is finalized as HTML.


=head1 INCLUDED MODULES

The following widgets have so far been written. They have extensive documentation for their methods

L<IWL::Accordion>        - An accordion container widget
L<IWL::Accordion::Page>  - A page widget for an accordion
L<IWL::Anchor>           - An anchor widget ("<a>")
L<IWL::Break>            - A break widget ("<br>")
L<IWL::Button>           - A graphic button widget
L<IWL::Calendar>         - a calendar widget
L<IWL::Canvas>           - The html5 canvas element ("<canvas>")
L<IWL::Checkbox>         - A checkbox widget (checkbox + text)
L<IWL::Combo>            - A combobox widget ("<select>")
L<IWL::Combo::Option>    - The content of a combobox ("<option>")
L<IWL::Comment>          - A widget for placing comments (and conditional comments)
L<IWL::Config>           - The IWL Config module
L<IWL::Container>        - A basic container widget ("<div>")
L<IWL::Contentbox>       - A generic window-like contentbox
L<IWL::DND>              - A Drag & Drop interface, implemented by L<IWL::Widget>
L<IWL::Druid>            - A step-based druid widget
L<IWL::Druid::Page>      - A page widget for a druid
L<IWL::Entry>            - An entry widget with support for icons
L<IWL::Environment>      - An environment, used to manage shared resources, used in L<IWL::Page>
L<IWL::Error>            - A base class for handling errors, implemented by L<IWL::Object>
L<IWL::Expander>         - An expander widget, which can show and hide its children
L<IWL::File>             - A file upload widget ("<input type="file">")
L<IWL::Form>             - A form widget ("<form>")
L<IWL::Frame>            - A frame widget ("<fieldset>")
L<IWL::Google::Map>      - A widget for adding Google Maps
L<IWL::Hidden>           - A hidden input object ("<input type="hidden">")
L<IWL::HBox>             - A container widget for positioning widgets horizontally
L<IWL::Iconbox>          - An iconbox widget (holds icons and has keyboard navigation)
L<IWL::Iconbox::Icon>    - An icon widget for the iconbox
L<IWL::IFrame>           - An iframe container
L<IWL::Image>            - An image widget ("<img>")
L<IWL::Input>            - A generic input widget ("<input>")
L<IWL::InputButton>      - A generic button widget ("<input type="button">")
L<IWL::JSON>             - A module, providing helper functions for encoding and decoding data as JSON
L<IWL::Label>            - A label widget
L<IWL::List>             - A widget for creating bulleted or numbered lists
L<IWL::List::Definition> - A definition list item
L<IWL::Menu>             - A menu widget
L<IWL::Menu::Item>       - A menu item widget for menus and menubars
L<IWL::Menubar>          - A menubar widget
L<IWL::NavBar>           - A navigation bar widget
L<IWL::Notebook>         - A tab notebook widget
L<IWL::Notebook::Tab>    - A tab widget for the notebook
L<IWL::Object>           - The base class for all content objects
L<IWL::Page>             - A page widget, for creating new pages
L<IWL::Page::Link>       - A link object for the page widget ("<link>")
L<IWL::Page::Meta>       - A meta object for the page widget ("<meta>")
L<IWL::PageControl>      - A page control widget for paginating other widgets
L<IWL::ProgressBar>      - A visual progress indicator widget
L<IWL::RadioButton>      - A radiobutton widget (radiobutton + text)
L<IWL::Response>         - An abstract response output class
L<IWL::RPC>              - A helper class for ajax connections and cgi parameters
L<IWL::Script>           - A script object ("<script>")
L<IWL::Slider>           - A slider widget
L<IWL::Spinner>          - A spinner widget
L<IWL::Stash>            - A stash class for form information encapsulation
L<IWL::Static>           - A static file handler module
L<IWL::Stock>            - A stock object, for buttons and images
L<IWL::String>           - A module, providing helper function for strings
L<IWL::Style>            - A style object ("<style>")
L<IWL::SubmitImage>      - An input image widget ("<input type="image">")
L<IWL::Table>            - A table widget ("<table>")
L<IWL::Table::Cell>      - A cell widget for the table row ("<td>", "<th>")
L<IWL::Table::Row>       - A row widget for the table ("<tr">)
L<IWL::Text>             - A simple text container
L<IWL::Textarea>         - A textarea widget ("<textarea>")
L<IWL::Tooltip>          - A tooltip widget
L<IWL::Tree>             - A tree widget (has keyboard navigation)
L<IWL::Tree::Cell>       - A tree cell widget
L<IWL::Tree::Row>        - A tree row widget
L<IWL::Upload>           - A theme-able upload widget
L<IWL::VBox>             - A vertical box container
L<IWL::Widget>           - The base class for all widgets

=head1 CONFIGURATION AND ENVIRONMENT

Configuration is done by editing the I<iwl.conf> file. It can be placed in the directory of the scripts that use IWL, or it's full path and name can be fiven in the I<IWL_CONFIG_FILE> environment variable. A default configuration is provided inside L<IWL::Config>. See L<IWL::Config> for more details

In order to actually use the library, the javascript and css files will also have to be installed in the server's document root. To do that, the I<iwl-install> script is provided. It is usually located in '/usr/bin'. The script also creates a I<iwl.conf> file from the user input.


=head1 DEPENDENCIES

  Scalar::Util
  Locale::Messages
  Locale::TextDomain
  HTML::Parser
  Cwd

=head1 TODO

=head2 Perl

 - Add an EmbedObject (<object>)

=head1 BUGS AND LIMITATIONS

 - In Internet explorer, floats will escape a container with scrollbars,
   if the positioning on the container is static, or the floats have a 
   relative positioning

=head1 AUTHOR

  Viktor Kojouharov

=head1 WEBSITE

L<http://code.google.com/p/iwl>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


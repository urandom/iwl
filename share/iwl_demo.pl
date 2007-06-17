#! /usr/local/bin/perl
#! /usr/local/bin/perl -d:ptkdb
# $Id: iwl_demo.pl,v 1.24.2.22 2007/06/15 13:15:21 viktor Exp $
# vim: set autoindent shiftwidth=4 tabstop=8:

# Imperia AG is the sole owner and producer of its software "Imperia". For
# our software license and copyright information please refer to: License.txt
# Copyright (C) 1995-2006 Imperia AG.  All rights reserved.

use strict;

BEGIN {
    push @INC, $1 if $0 =~ m#(.*)[\\\/]#;
    require site_lowlevel;
}

# use CGI qw/:standard/;
use IWL;
use IWL::Config qw(%IWLConfig);
use IWL::Ajax qw(updaterCallback);
use IWL::String qw(encodeURIComponent);

my $rpc = IWL::RPC->new;
my %form = $rpc->getParams();

$rpc->handleEvent(
    'IWL-Tree-Row-expand',
    sub {
	my $row = IWL::Tree::Row->new(id => 'rpc_events');
	$row->appendTextCell('RPC Events');
	register_row_event($row);
	return [$row];
    },
    'IWL-Tree-Row-activate',
    sub {
	my $params = shift;

	my $func = $::{$params->{function}};
	if (defined $func && defined *{$func}{CODE}) {
	    return &{$func}
	} else {
	    die "function $params->{function} is not defined";
	}
    },
    'IWL-Notebook-Tab-select',
    sub {
	my $params = shift;

	show_the_code_for($params->{codeFor});
    },
);

# Event row handlers
$rpc->handleEvent(
    'IWL-Button-click',
    sub {
	my $params = shift;

	return {text => 'This message will only be shown once.'}, $params;
    },
    'IWL-Combo-change',
    sub {
	my $params = shift;

	return {text => 'The combo was changed to ' . $params->{value}}, $params;
    },
);

if (my $file = $form{upload_file}) {
    my $name = $file->[1];
    my $json = IWL::Text->new;
    my $page = IWL::Page->new(simple => 1);
    $json->setContent("{message:'$name uploaded.'}");
    $page->appendChild($json);
    $page->print;
    exit 0;
} elsif (my $text = $form{text}) {
    IWL::Object::printHTMLHeader;
    print "The following text was received: $text";
    print IWL::Break->new()->getContent;
    exit 0;
} else {
    my $page = IWL::Page->new;
    my $hbox = IWL::HBox->new;
    my $tree = IWL::Tree->new(id => 'widgets_tree', alternate => 1);
    my $notebook = IWL::Notebook->new(id => 'main_notebook');
    my $container = IWL::Container->new(id => 'content');
    my $style = IWL::Page::Link->newLinkToCSS($IWLConfig{SKIN_DIR} . '/demo.css');
    my @scripts = (qw(demo.js firebug/firebug.js));
#    my @scripts = (qw(demo.js button.js iconbox.js tree.js contentbox.js druid.js notebook.js upload.js popup.js firebug/firebug.js));

    $page->appendChild($hbox);
    $page->appendHeader($style);
    $hbox->packStart($tree);
    $hbox->packStart($notebook);
    $page->requiredJs(@scripts);
    $notebook->appendTab('Display', $container)->setId('display_tab');
    $notebook->appendTab('Source')->setId('source_tab')->registerEvent('IWL-Notebook-Tab-select' => 'iwl_demo.pl', {
	    onStart => <<'EOF',
var content = $('content').down();
if (content)
    params.codeFor = content.id;
EOF
	    update => "source_page",
    });

    my $cal_scripts = IWL::Calendar->getRequiredScripts;
    my $cal_styles = IWL::Calendar->getRequiredStyles;
    foreach my $link (@$cal_scripts, @$cal_styles) {
	$page->appendHeader ($link);
    }

    build_tree($tree);
    $page->setTitle('Widget Library');
    $page->print;
}

sub build_tree {
    my $tree = shift;
    my $header = IWL::Tree::Row->new;
    my $basic_widgets = IWL::Tree::Row->new(id => 'basic_row');
    my $advanced_widgets = IWL::Tree::Row->new(id => 'advanced_row');
    my $containers = IWL::Tree::Row->new(id => 'containers_row');
    my $misc = IWL::Tree::Row->new(id => 'misc_row');
    my $event = IWL::Tree::Row->new(id => 'event_row');

    $tree->appendHeader($header);
    $header->appendTextHeaderCell('Widgets');
    $header->makeSortable(0);

    $tree->appendBody($basic_widgets);
    $basic_widgets->appendTextCell('Basic Widgets');
    $tree->appendBody($advanced_widgets);
    $advanced_widgets->appendTextCell('Advanced Widgets');
    $tree->appendBody($containers);
    $containers->appendTextCell('Containers');
    $tree->appendBody($misc);
    $misc->appendTextCell('Miscellaneous');
    $tree->appendBody($event);
    $event->appendTextCell('IWL Events');
    $event->registerEvent('IWL-Tree-Row-expand', 'iwl_demo.pl', { jijii => 1});

    build_basic_widgets($basic_widgets);
    build_advanced_widgets($advanced_widgets);
    build_containers($containers);
    build_misc($misc);
}

sub build_basic_widgets {
    my $row = shift;
    my $buttons = IWL::Tree::Row->new(id => 'buttons_row');
    my $entries = IWL::Tree::Row->new(id => 'entries_row');
    my $images = IWL::Tree::Row->new(id => 'images_row');
    my $labels = IWL::Tree::Row->new(id => 'labels_row');

    $buttons->appendTextCell('Buttons');
    $row->appendRow($buttons);
    $entries->appendTextCell('Entries');
    $row->appendRow($entries);
    $images->appendTextCell('Images');
    $row->appendRow($images);
    $labels->appendTextCell('Labels');
    $row->appendRow($labels);

    register_row_event($buttons, $entries, $images, $labels);
}

sub build_advanced_widgets {
    my $row = shift;
    my $tables = IWL::Tree::Row->new(id => 'tables_row');
    my $combobox = IWL::Tree::Row->new(id => 'combobox_row');
    my $sliders = IWL::Tree::Row->new(id => 'sliders_row');
    my $iconbox = IWL::Tree::Row->new(id => 'iconbox_row');
    my $menus = IWL::Tree::Row->new(id => 'menus_row');
    my $list = IWL::Tree::Row->new(id => 'list_row');
    my $table = IWL::Tree::Row->new(id => 'table_row');
    my $tree = IWL::Tree::Row->new(id => 'tree_row');

    $combobox->appendTextCell('Combobox');
    $row->appendRow($combobox);
    $sliders->appendTextCell('Sliders');
    $row->appendRow($sliders);
    $iconbox->appendTextCell('Iconbox');
    $row->appendRow($iconbox);
    $menus->appendTextCell('Menus');
    $row->appendRow($menus);
    $tables->appendTextCell('Tables');
    $row->appendRow($tables);
    $list->appendTextCell('List');
    $tables->appendRow($list);
    $table->appendTextCell('Table');
    $tables->appendRow($table);
    $tree->appendTextCell('Tree');
    $tables->appendRow($tree);

    register_row_event($combobox, $sliders, $iconbox, $menus, $list, $table, $tree);
}

sub build_containers {
    my $row = shift;
    my $contentbox = IWL::Tree::Row->new(id => 'contentbox_row');
    my $druid = IWL::Tree::Row->new(id => 'druid_row');
    my $notebook = IWL::Tree::Row->new(id => 'notebook_row');
    my $tooltips = IWL::Tree::Row->new(id => 'tooltips_row');

    $contentbox->appendTextCell('Contentbox');
    $row->appendRow($contentbox);
    $druid->appendTextCell('Druid');
    $row->appendRow($druid);
    $notebook->appendTextCell('Notebook');
    $row->appendRow($notebook);
    $tooltips->appendTextCell('Tooltips');
    $row->appendRow($tooltips);

    register_row_event($contentbox, $druid, $notebook, $tooltips);
}

sub build_misc {
    my $row       = shift;
    my $file      = IWL::Tree::Row->new(id => 'file_row');
    my $flat_cal  = IWL::Tree::Row->new(id => 'flat_calendar_row');
    my $popup_cal = IWL::Tree::Row->new(id => 'popup_calendar_row');

    $file->appendTextCell('File Upload');
    $row->appendRow($file);

    $flat_cal->appendTextCell('Calendar');
    $row->appendRow($flat_cal);

    $popup_cal->appendTextCell('Popup calendar');
    $row->appendRow($popup_cal);

    register_row_event($file, $flat_cal, $popup_cal);
}

sub generate_buttons {
    my $container = IWL::Container->new(id => 'buttons_container');
    my $normal_button = IWL::Button->new(style => {float => 'none'}, id => 'normal_button');
    my $stock_button = IWL::Button->newFromStock('IWL_STOCK_APPLY', style => {float => 'none'}, id => 'stock_button', size => 'medium');
    my $image_button = IWL::Button->new(style => {float => 'none'}, id => 'image_button', size => 'small')->setHref('iwl_demo.pl');
    my $input_button = IWL::InputButton->new(id => 'input_button');
    my $check = IWL::Checkbox->new;
    my $radio1 = IWL::RadioButton->new;
    my $radio2 = IWL::RadioButton->new;

    $container->appendChild($normal_button, $stock_button, $image_button, $input_button, $check, IWL::Break->new, $radio1, $radio2);
    $normal_button->setTitle('This is a title');
    $image_button->setImage('IWL_STOCK_DELETE');
    $normal_button->setLabel('Labeled button')->setClass('demo');
    $stock_button->signalConnect(load => "displayStatus('Stock button loaded')");
    $input_button->setLabel('Input Button');
    $check->setLabel('A check button');
    $radio1->setLabel('A radio button');
    $radio2->setLabel('Another radio button');
    $radio1->setGroup('radio')->setClass('demo');
    $radio2->setGroup('radio');
    return $container->getObject;
}

sub generate_entries {
    my $container = IWL::Container->new(id => 'entries_container');
    my $normal_entry = IWL::Entry->new;
    my $password_entry = IWL::Entry->new;
    my $cleanup_entry = IWL::Entry->new;
    my $image_entry = IWL::Entry->new(id => 'image_entry');

    $container->appendChild($normal_entry, IWL::Break->new);
    $container->appendChild($password_entry, IWL::Break->new);
    $container->appendChild($cleanup_entry, IWL::Break->new);
    $container->appendChild($image_entry, IWL::Break->new);
    $normal_entry->setDefaultText('Type here');
    $password_entry->setPassword(1);
    $cleanup_entry->addClearButton;
    $image_entry->setIconFromStock('IWL_STOCK_SAVE', 'left', 1);
    $image_entry->{image1}->signalConnect(click => updaterCallback(
	    'entries_container', 'iwl_demo.pl',
	    parameters => 'text: $F("image_entry_text") || false',
	    insertion => 'bottom',
	    onComplete => 'displayStatus("Completed")',
    ));
    return $container->getObject;
}

sub generate_images {
    my $container = IWL::Container->new(id => 'images_container');
    my $normal_image = IWL::Image->new;
    my $stock_image1 = IWL::Image->newFromStock('IWL_STOCK_CLOSE');
    my $stock_image2 = IWL::Image->newFromStock('IWL_STOCK_FULLSCREEN');
    my $frame = IWL::Frame->new;

    $container->appendChild($normal_image);
    $container->appendChild($frame);
    $frame->appendChild($stock_image1);
    $frame->appendChild($stock_image2);
    $frame->setLabel('Stock images');
    $normal_image->set($IWLConfig{SKIN_DIR} . '/images/icons/close15x15.gif');

    return $container->getObject;
}

sub generate_labels {
    my $container = IWL::Container->new(id => 'labels_container');
    my $normal_label = IWL::Label->new;
    my $paragraph = IWL::Label->new(expand => 1);

    $container->appendChild($normal_label);
    $container->appendChild($paragraph);
    $normal_label->setText('A label');
    $paragraph->setText(<<EOF);
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
EOF

    return $container->getObject;
}

sub generate_combobox {
    my $container = IWL::Container->new(id => 'combobox_container');
    my $normal_combobox = IWL::Combo->new;

    $container->appendChild($normal_combobox);
    $normal_combobox->appendOption('Lorem' => 1);
    $normal_combobox->appendOption('ipsum' => 2, 1);
    $normal_combobox->appendOption('dolor' => 3);
    $normal_combobox->appendOption('sit' => 4);

    return $container->getObject;
}

sub generate_sliders {
    my $container = IWL::Container->new(id => 'slider_container');
    my $normal_slider = IWL::Slider->new(id => 'normal_slider')->setSize(100);
    my $ranged_slider = IWL::Slider->new(id => 'ranged_slider');
    my $vertical_slider = IWL::Slider->new(id => 'vertical_slider')->setVertical(1)->setSize(50);
    my $normal_label = IWL::Label->new(id => 'normal_label')->setText(0);
    my $ranged_label = IWL::Label->new(id => 'ranged_label')->setText(10);
    my $vertical_label = IWL::Label->new(id => 'vertical_label')->setText(0);

    $container->appendChild(IWL::Label->new->setText('Normal slider: '),
	$normal_label,
	$normal_slider,
	IWL::Label->new->setText('Ranged slider: '),
	$ranged_label,
	$ranged_slider,
	IWL::Label->new->setText('Vertical slider: '),
	$vertical_label,
	$vertical_slider
    );
    $ranged_slider->setValues(10, 20, 30, 50, 80, 90, 100);
    $normal_slider->signalConnect(change => "\$('normal_label').update(value.toPrecision(2))");
    $ranged_slider->signalConnect(slide => "\$('ranged_label').update(value)");
    $vertical_slider->signalConnect(slide => "\$('vertical_label').update(value.toPrecision(2))");

    return $container->getObject;
}

sub generate_iconbox {
    my $container = IWL::Container->new(id => 'iconbox_container');
    my $iconbox = IWL::Iconbox->new(id => 'iconbox', width => '310px', height => '200px');

    $container->appendChild($iconbox);
    $iconbox->signalConnect(load => "displayStatus('Iconbox fully loaded')");
    foreach (1 .. 10) {
        my $icon = IWL::Iconbox::Icon->new;
        $iconbox->appendIcon($icon);
        $icon->setImage('/imperia/skin/menuicons/drawer.png');
        $icon->setText($_ x 10);
	if ($_ == 5) {
	    $icon->setText('Irregular icon title');
	    $icon->signalConnect(select =>
		  "displayStatus('This callback was activated when icon $_ was selected')");
	    $icon->setClass('demo');
	}
        $icon->setDimensions('64px', '64px');
	$icon->setSelected(1) if $_ == 1;
    }

    return $container->getObject;
}

sub generate_menus {
    my $container = IWL::Container->new(id => 'menus_container');
    my $menubar = IWL::Menubar->new(id => 'menubar');
    my $file_menu = IWL::Menu->new(id => 'file_menu');
    my $edit_menu = IWL::Menu->new(id => 'edit_menu');
    my $button = IWL::Button->new;
    my $button_menu = IWL::Menu->new(id => 'button_menu');
    my $submenu = IWL::Menu->new(id => 'submenu');

    $container->appendChild($menubar, $button, $button_menu);

    $menubar->appendMenuItem('File', undef, id => 'file_mi')->setSubmenu($file_menu);
    $menubar->appendMenuItem('Edit', undef, id => 'edit_mi')->setSubmenu($edit_menu);
    $menubar->appendMenuSeparator;
    $menubar->appendMenuItem('Help', undef, id => 'help_mi', class => 'demo')->
      signalConnect('click' => q|displayStatus("Don't panic!")|);

    $file_menu->appendMenuItem('Open')->setClass('demo');
    $file_menu->appendMenuItem('Save', 'IWL_STOCK_SAVE');

    $edit_menu->appendMenuItem('Cut');
    $edit_menu->appendMenuItem('Copy');
    $edit_menu->appendMenuItem('Paste');

    $button->setLabel('Click me!');
    $button_menu->bindToWidget($button, 'click');
    $button_menu->appendMenuItem("Check item 1", undef)->setType('check')->signalConnect(change => q|displayStatus('Check item 1 changed')|);
    $button_menu->appendMenuItem("Check item 2", undef)->setType('check')->toggle(1);
    $button_menu->appendMenuSeparator;
    $button_menu->appendMenuItem("Radio item 1", undef)->setType('radio')->toggle(1);
    $button_menu->appendMenuItem("Radio item 2", undef)->setType('radio');
    $button_menu->appendMenuItem("Radio item 3", undef)->setType('radio');
    $button_menu->appendMenuItem("Submenu")->setSubmenu($submenu);

    $submenu->setMaxHeight(200);
    $submenu->appendMenuItem("Submenu item $_")->setType('check') foreach (1 .. 20);

    return $container->getObject;
}

sub generate_list {
    my $container = IWL::Container->new(id => 'list_container');
    my $list = IWL::Tree->new(list => 1, id => 'list');
    my $header = IWL::Tree::Row->new;
    my $body = IWL::Tree::Row->new;

    $container->appendChild($list);
    $list->appendHeader($header);
    $header->appendTextHeaderCell('Name');
    $header->appendTextHeaderCell('Volume');
    $header->appendTextHeaderCell('Value');
    $header->makeSortable(0);
    $header->makeSortable(1);
    $header->makeSortable(2);

    $list->appendBody($body);
    $body->appendTextCell('F');
    $body->appendTextCell('79,520,600');
    $body->appendTextCell('$7.24');
    $body = IWL::Tree::Row->new;
    $list->appendBody($body);
    $body->appendTextCell('TWX');
    $body->appendTextCell('5,760,500');
    $body->appendTextCell('$20.59');
    $body = IWL::Tree::Row->new;
    $list->appendBody($body);
    $body->appendTextCell('PFE');
    $body->appendTextCell('5,607,700');
    $body->appendTextCell('$24.89');
    $body = IWL::Tree::Row->new;
    $list->appendBody($body);
    $body->appendTextCell('SLE');
    $body->appendTextCell('4,379,900');
    $body->appendTextCell('$17.12');
    $body = IWL::Tree::Row->new;
    $list->appendBody($body);
    $body->appendTextCell('MOT');
    $body->appendTextCell('4,320,600');
    $body->appendTextCell('$21.80');

    $list->setSortableCallback(2, "sortTheMoney");

    return $container->getObject;
}

sub generate_table {
    my $container = IWL::Container->new(id => 'table_container');
    my $table = IWL::Table->new(id => 'table', class => 'demo');
    my $header = IWL::Table::Row->new;
    my $body = IWL::Table::Row->new;
    my $sorting = IWL::Script->new;

    $container->appendChild($table);
    $table->appendHeader($header);
    $header->appendTextHeaderCell('Name');
    $header->appendTextHeaderCell('Volume');
    $header->appendTextHeaderCell('Value');

    $table->appendBody($body);
    $body->appendTextCell('F');
    $body->appendTextCell('79,520,600');
    $body->appendTextCell('$7.24');
    $body = IWL::Table::Row->new;
    $table->appendBody($body);
    $body->appendTextCell('TWX');
    $body->appendTextCell('5,760,500');
    $body->appendTextCell('$20.59');
    $body = IWL::Table::Row->new;
    $table->appendBody($body);
    $body->appendTextCell('PFE');
    $body->appendTextCell('5,607,700');
    $body->appendTextCell('$24.89');
    $body = IWL::Table::Row->new;
    $table->appendBody($body);
    $body->appendTextCell('SLE');
    $body->appendTextCell('4,379,900');
    $body->appendTextCell('$17.12');
    $body = IWL::Table::Row->new;
    $table->appendBody($body);
    $body->appendTextCell('MOT');
    $body->appendTextCell('4,320,600');
    $body->appendTextCell('$21.80');

    return $container->getObject;
}

sub generate_tree {
    my $container = IWL::Container->new(id => 'tree_container');
    my $label = IWL::Label->new;

    $container->appendChild($label);
    $label->setText('<----   The tree');

    return $container->getObject;
}

sub generate_contentbox {
    my $container = IWL::Container->new(id => 'contentbox_container');
    my $contentbox = IWL::Contentbox->new(id => 'contentbox', autoWidth => 1);
    my $chooser = IWL::Combo->new(id => 'contentbox_chooser');

    $container->appendChild($contentbox);
    $contentbox->appendTitleText('The title');
    $contentbox->appendHeaderText('The header of the contentbox');
    $contentbox->appendContentText('Select the type of the contentbox');
    $contentbox->appendContent(IWL::Break->new, $chooser);
    $contentbox->appendFooterText('The footer of the contentbox');
    $contentbox->setShadows(1);
    $contentbox->signalConnect(close => q|displayStatus("Don't close me!"); this.show()|);
    $chooser->appendOption('none');
    $chooser->appendOption('drag');
    $chooser->appendOption('resize');
    $chooser->appendOption('dialog');
    $chooser->appendOption('window');
    $chooser->appendOption('noresize');
    $chooser->signalConnect(change => "contentbox_chooser_change(this)");
    return $container->getObject;
}

sub generate_druid {
    my $container = IWL::Container->new(id => 'druid_container');
    my $druid = IWL::Druid->new(id => 'druid');
    my $label1 = IWL::Label->new;
    my $label2 = IWL::Label->new;

    $container->appendChild($druid);
    $druid->appendPage($label1)->signalConnect(remove => "displayStatus('Page 1 removed.')");;
    $druid->appendPage($label2)->signalConnect(select => "displayStatus('Page 2 selected.')");
    $label1->setText('This is page 1');
    $label2->setText('This is page 2');

    return $container->getObject;
}

sub generate_notebook {
    my $container = IWL::Container->new(id => 'notebook_container');
    my $notebook = IWL::Notebook->new(id => 'notebook');
    my $label1 = IWL::Label->new;
    my $label2 = IWL::Label->new;

    $container->appendChild($notebook);
    $notebook->appendTab('Page 1', $label1);
    $notebook->appendTab('Page 2', $label2)->signalConnect(select => "displayStatus(this.getLabel() + ' selected.')");
    $label1->setText('This is page 1');
    $label2->setText('This is page 2');

    return $container->getObject;
}

sub generate_tooltips {
    my $container = IWL::Container->new(id => 'tooltips_container');
    my $button = IWL::Button->new(size => 'medium', style => {float => 'none', margin => '0 auto'});
    my $label = IWL::Label->new(expand => 1, style => {'text-align' => 'center'});
    my $image = IWL::Image->new;
    my $tip1 = IWL::Tooltip->new;
    my $tip2 = IWL::Tooltip->new;

    $image->set($IWLConfig{SKIN_DIR} . '/images/contentbox/arrow_right.gif');
    $tip1->bindToWidget($button, 'mouseenter');
    $tip1->bindHideToWidget($button, 'mouseleave');
    $tip1->setContent('Some text here.');
    $tip2->bindToWidget($label, 'mouseover');
    $tip2->bindHideToWidget($label, 'mouseout');
    $tip2->setContent($image);
    $button->setLabel("Hover over me");
    $label->setText("Hover over me");
    $container->appendChild($button, $label, $tip1, $tip2);

    return $container->getObject;
}

sub generate_file {
    my $container = IWL::Container->new(id => 'file_container');
    my $file = IWL::Upload->new(id => 'upload', action => 'iwl_demo.pl');
    my $label = IWL::Label->new;

    $container->appendChild($label);
    $container->appendChild($file);
    $label->setText('Press the button to upload a file.');
    $file->setLabel('Browse ...');

    return $container->getObject;
}

sub __generate_feedback_form {
    my $calendar = shift;

    my $table = IWL::Table->new(cellspacing => 2, cellpadding => 2);
    my $feedbacks = [
		     {
			 name => 'Day of the week',
			 format => '%A',
			},
			{
			    name => 'Day of the month',
			    format => '%e',
			},
			{
			    name => 'Month',
			    format => '%B',
			},
			{
			    name => 'Year',
			    format => '%Y',
			},
			{
			    name => 'Hour',
			    format => '%H',
			},
			{
			    name => 'Minute',
			    format => '%M',
			},
			{
			    name => 'Seconds',
			    format => '%S',
			},
			];

    my $headline = IWL::Table::Row->new;
    $headline->appendTextHeaderCell('Description');
    $headline->appendTextHeaderCell('Format');
    $headline->appendTextHeaderCell('Value');
    $table->appendHeader($headline);

    foreach my $entry(@$feedbacks) {
        my $row = IWL::Table::Row->new;
        $row->appendTextCell($entry->{name});
        $row->appendTextCell($entry->{format});
        my $input = IWL::Input->new;
        my $input_id = "$input";
        $input_id =~ s/.*0x([0-9a-fA_F]+)\)$/fb_$1/;
        $input->setId($input_id);
        $row->appendCell($input);
        $table->appendBody($row);
        $calendar->connectInputField($input, $entry->{format});
    }

    return $table;
}

sub generate_flat_calendar {
    my $container = IWL::Container->new(id => 'flat_calendar_container');
    my $calendar = IWL::Calendar->new;

    my $hbox = IWL::HBox->new;
    $hbox->packStart(__generate_feedback_form($calendar));

    my $inner_container = IWL::Container->new(id => 'flat_calendar_inner');
    $inner_container->appendChild($calendar);
    $hbox->packStart($inner_container);
    $container->appendChild($hbox);

    return $container->getObject;
}

sub generate_popup_calendar {
    my $container = IWL::Container->new(id => 'popup_calendar_container');
    my $calendar = IWL::Calendar->new;
    $calendar->setPopupMode(1);
    my $trigger = IWL::Image->newFromStock('IWL_STOCK_CALENDAR');
    $trigger->setId('popup_calendar_trigger');
    $calendar->connectToTrigger($trigger, 'click');

    my $hbox = IWL::HBox->new;
    $hbox->packStart(__generate_feedback_form($calendar));

    my $inner_container = IWL::Container->new(id => 'popup_calendar_inner');
    $inner_container->appendChild($trigger);
    $inner_container->appendChild(IWL::Label->new->setText("Click image"));
    $inner_container->appendChild($calendar);
    $hbox->packStart($inner_container);
    $container->appendChild($hbox);

    return $container->getObject;
}

sub generate_rpc_events {
    my $container = IWL::Container->new(id => 'rpc_events_container');
    my $button = IWL::Button->new(id => 'rpc_button')->setLabel('Click me!');
    my $combo = IWL::Combo->new(id => 'rpc_combo');

    $combo->appendOption('First option' => 'first')->appendOption('Second option' => 'second');
    $combo->registerEvent('IWL-Combo-change', 'iwl_demo.pl', {onComplete => "displayStatus(arguments[0].data.text)"});
    $button->registerEvent('IWL-Button-click', 'iwl_demo.pl', {onComplete => "displayStatus(arguments[0].data.text)", emitOnce => 1});

    $container->appendChild($button, $combo);

    return $container->getObject;
}

sub register_row_event {
    foreach my $row (@_) {
	my $function = 'generate_' .$row->getId;

	$function =~ s/_row$//;
	$row->registerEvent('IWL-Tree-Row-activate', 'iwl_demo.pl', {
		function => $function,
		onComplete => 'activate_widgets_response(json)',
	});
    }
}

sub read_code {
    my ($start, $count) = @_;
    my $counter = 0;
    my $read = 0;
    my $contents = '';
    local *DEMO;
    open DEMO, "$0";

    while (<DEMO>) {
	$read++ if $_ =~ /$start/;
	last if $read && $count == $counter++;
	$contents .= $_ if $read;
    }
    close DEMO;
    eval {
	my %CSS_colors = (
	    none      => "</span>",

	    comment      => '<span class="c_comment">',
	    label      => '<span class="c_label">',
	    string      => '<span class="c_string">',
	    subroutine      => '<span class="c_subroutine">',
	    variable => '<span class="c_variable">',
	    keyword => '<span class="c_keyword">',
	    misc => '<span class="c_misc">',
	  );

	require Syntax::Highlight::Perl;
	my $formatter = Syntax::Highlight::Perl->new;
	$formatter->unstable(1);
	$formatter->set_format(
	    'Comment_Normal'   => [$CSS_colors{'comment'},    $CSS_colors{'none'}],
	    'Comment_POD'      => [$CSS_colors{'comment'},    $CSS_colors{'none'}],
	    'Directive'        => [$CSS_colors{'label'},  $CSS_colors{'none'}],
	    'Label'            => [$CSS_colors{'label'},  $CSS_colors{'none'}],
	    'Quote'            => [$CSS_colors{'string'},   $CSS_colors{'none'}],
	    'String'           => [$CSS_colors{'string'},    $CSS_colors{'none'}],
	    'Subroutine'       => [$CSS_colors{'subroutine'},  $CSS_colors{'none'}],
	    'Variable_Scalar'  => [$CSS_colors{'variable'},   $CSS_colors{'none'}],
	    'Variable_Array'   => [$CSS_colors{'variable'},   $CSS_colors{'none'}],
	    'Variable_Hash'    => [$CSS_colors{'variable'},   $CSS_colors{'none'}],
	    'Variable_Typeglob'=> [$CSS_colors{'subroutine'},   $CSS_colors{'none'}],
	    'Whitespace'       => ['',                       ''                  ],
	    'Character'        => [$CSS_colors{'keyword'},     $CSS_colors{'none'}],
	    'Keyword'          => [$CSS_colors{'keyword'},   $CSS_colors{'none'}],
	    'Builtin_Function' => [$CSS_colors{'keyword'},   $CSS_colors{'none'}],
	    'Builtin_Operator' => [$CSS_colors{'keyword'},   $CSS_colors{'none'}],
	    'Operator'         => [$CSS_colors{'keyword'},    $CSS_colors{'none'}],
	    'Bareword'         => [$CSS_colors{'subroutine'},    $CSS_colors{'none'}],
	    'Package'          => [$CSS_colors{'variable'},    $CSS_colors{'none'}],
	    'Number'           => [$CSS_colors{'label'}, $CSS_colors{'none'}],
	    'Symbol'           => [$CSS_colors{'misc'},    $CSS_colors{'none'}],
	    'CodeTerm'         => [$CSS_colors{'misc'},     $CSS_colors{'none'}],
	    'DATA'             => [$CSS_colors{'misc'},     $CSS_colors{'none'}],

	    'Line'             => [$CSS_colors{'misc'},  $CSS_colors{'none'}],
	    'File_Name'        => [$CSS_colors{'misc'}, $CSS_colors{'none'}],
	);

	$contents = $formatter->format_string($contents);
    };;
    return $contents;
}

sub show_the_code_for {
    my $code_for = shift;
    my $paragraph = IWL::Label->new;

    if ($code_for eq 'buttons_container') {
	$paragraph->appendTextType(read_code("generate_buttons", 22), 'pre');
    } elsif ($code_for eq 'entries_container') {
	$paragraph->appendTextType(read_code("generate_entries", 24), 'pre');
    } elsif ($code_for eq 'images_container') {
	$paragraph->appendTextType(read_code("generate_images", 17), 'pre');
    } elsif ($code_for eq 'labels_container') {
	$paragraph->appendTextType(read_code("generate_labels", 18), 'pre');
    } elsif ($code_for eq 'combobox_container') {
	$paragraph->appendTextType(read_code("generate_combobox", 13), 'pre');
    } elsif ($code_for eq 'slider_container') {
	$paragraph->appendTextType(read_code("generate_sliders", 27), 'pre');
    } elsif ($code_for eq 'iconbox_container') {
	$paragraph->appendTextType(read_code("generate_iconbox", 23), 'pre');
    } elsif ($code_for eq 'menus_container') {
	$paragraph->appendTextType(read_code("generate_menus", 40), 'pre');
    } elsif ($code_for eq 'list_container') {
	$paragraph->appendTextType(read_code("generate_list", 45), 'pre');
    } elsif ($code_for eq 'table_container') {
	$paragraph->appendTextType(read_code("generate_table", 41), 'pre');
    } elsif ($code_for eq 'tree_container') {
	$paragraph->appendTextType(read_code("sub build_tree", 109), 'pre');
    } elsif ($code_for eq 'contentbox_container') {
	$paragraph->appendTextType(read_code("generate_contentbox", 22), 'pre');
    } elsif ($code_for eq 'druid_container') {
	$paragraph->appendTextType(read_code("generate_druid", 15), 'pre');
    } elsif ($code_for eq 'notebook_container') {
	$paragraph->appendTextType(read_code("generate_notebook", 15), 'pre');
    } elsif ($code_for eq 'tooltips_container') {
	$paragraph->appendTextType(read_code("generate_tooltips", 22), 'pre');
    } elsif ($code_for eq 'file_container') {
	$paragraph->appendTextType(read_code("generate_file", 13), 'pre');
    } elsif ($code_for eq 'flat_calendar_container') {
	$paragraph->appendTextType(read_code("generate_feedback_form", 71), 'pre');
    } elsif ($code_for eq 'popup_calendar_container') {
	$paragraph->appendTextType(read_code("generate_popup_calendar", 20), 'pre');
    } elsif ($code_for eq 'rpc_events_container') {
	$paragraph->appendTextType(read_code("generate_rpc_events", 14), 'pre');
	$paragraph->appendTextType(read_code("Event row handlers", 15), 'pre');
    } else {
	$paragraph->setText('Code not available');
    }

    return $paragraph->getContent;
}

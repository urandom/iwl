#! /usr/bin/perl
# vim: set autoindent shiftwidth=4 tabstop=8:

use strict;

use IWL;
use IWL::Config qw(%IWLConfig);
use IWL::Ajax qw(updaterCallback);

my $rpc = IWL::RPC->new;
my %form = $rpc->getParams();

# Tree row handlers
$rpc->handleEvent(
    'IWL-Tree-Row-expand',
    sub {
	my ($events, $page) = IWL::Tree::Row->newMultiple({id => 'rpc_events'}, {id => 'rpc_pagecontrol'});
	$events->appendTextCell('RPC Events');
	$page->appendTextCell('RPC PageControl');
	register_row_event($events, $page);
	return [$events, $page];
    },
    'IWL-Tree-Row-activate',
    sub {
	my $params = shift;

        $ENV{LANG} = $params->{locale} || '';
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
    'IWL-Anchor-click',
    sub {
	my $params = shift;

	return "easily create AJAX requests through Perl.";
    },
    'IWL-Button-click',
    sub {
	my $params = shift;

	return {text => 'This message will only be shown once.'}, $params;
    },
    'IWL-Combo-change',
    sub {
        my ($params, $id, $elementData) = @_;

        return {text => 'The combo was changed to ' . $elementData->{$id}}, $params;
    },
);

# PageControl handlers
$rpc->handleEvent(
    'IWL-Container-refresh',
    sub {
	my $params = shift;

	my $page_number = {
	    input => $params->{value},
	    first => 1,
	    prev => $params->{page} - 1 || 1,
	    next => $params->{page} + 1 > $params->{pageCount} ? $params->{pageCount} : $params->{page} + 1,
	    last => $params->{pageCount}
	}->{$params->{type}};

	if ($page_number == 1) {
	    return IWL::Image->new->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif');
	} elsif ($page_number == 2) {
	    return IWL::Label->new(expand => 1)->setText(<<EOF);
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
EOF
	} elsif ($page_number == 3) {
	    return IWL::Label->new->setText('This is the end of the road');
	}
    }
);

# Druid handlers
$rpc->handleEvent(
    'IWL-Druid-Page-previous',
    sub {
	my ($params, $id) = @_;
	my $image = IWL::Image->new, my $label = IWL::Label->new;

	if ($id eq 'first_page') {
	    $image->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif');
	    $label->setText('Final page');
	}
        return [$image, $label],
               {
                   final => {url => 'iwl_demo.pl', options => {update => 'druid_container'}},
                   newId => 'final_page',
               }
    },
    'IWL-Druid-Page-final',
    sub {
	my ($params, $id) = @_;
	my $label = IWL::Label->new->appendTextType(
	    'The druid actions have ended', 'h1', style => {'font-style' => 'italic'});

	return $label;
    },
    'IWL-Druid-Page-next',
    sub {
	my ($params, $id, $elementData) = @_;

	if ($id eq 'first_page') {
	    my $label = IWL::Label->new->setText(<<'EOF');
	    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
EOF
            my $checkbox = IWL::Checkbox->new(name => 'checkbox')->setValue('bar')->setLabel('Confirm?');
	    return [$label, $checkbox], {
		newId => 'second_page',
                next => {url => 'iwl_demo.pl', params => {what => 'third_page'},
                    options => {emitOnce => 1, collectData => 1}}
	    };
	} elsif ($id eq 'second_page') {
	    my $label, my %deter;
            if ($elementData->{checkbox}) {
                $label = IWL::Label->new->setText('The third page');
            } else {
                $label = IWL::Label->new->setText('Please confirm!');
                %deter = (deter => 1, expression => "IWL.Status.display('Fix it!')");
            }
	    return [$label], {
		newId => 'third_page',
                %deter
	    };
	}
    }
);

# NavBar handlers
$rpc->handleEvent(
    'IWL-NavBar-activatePath',
    sub {
        my ($params, $id) = @_;

        my $con = IWL::Container->new;
        my $label = IWL::Label->new->setText('/' . join '/', @{$params->{path}});
        my $list = IWL::List->new(type => 'ordered');

        if ('Foo/Bar' eq join '/', @{$params->{path}}) {
            $list->appendListItemText($_)
                foreach qw(base.js button.js calendar.js contentbox.js unittest_extensions.js upload.js);
        } elsif ('Foo/Bar/Baz/Beta' eq join '/', @{$params->{path}}) {
            $list->appendListItemText($_)
                foreach qw(main.css demo.css);
        }

        $con->appendChild(
            IWL::Label->new->appendTextType("Elements for: ", 'strong'),
            $label,
            IWL::Label->new->appendTextType(" with values: ", 'em'),
            IWL::Label->new->setText(join ':', @{$params->{values}}),
            $list
        );

        return $con;
    }
);

# IWL RPC JavaScript unit tests
$rpc->handleEvent(
    'IWL-Object-testEvent',
    sub {
        my ($params, $id, $data) = @_;
        if ($params->{foo}) {
            return "\$('res1').update('Test: $params->{test}, Foo: $params->{foo}')";
        } elsif ($params->{text}) {
            return "$params->{text}"
        } elsif ($data && $data->{hidden} eq 'foo') {
            return "true";
        } elsif ($params->{cancel}) {
            sleep 1;
            return "Yes, I am cancelled";
        }
    }
);

if (my $file = $form{upload_file}) {
    my $name = $file->[1];
    IWL::Upload::printMessage("$name uploaded.", {filename => $name, uploaded => 1});
    exit 0;
} elsif (my $text = $form{text}) {
    my $response = IWL::Response->new;
    $response->send(
        content => "The following text was received: $text" . IWL::Break->new()->getContent,
        header => IWL::Object::getHTMLHeader
    );
    exit 0;
} elsif ($form{completion} && (my $search = quotemeta $form{completion})) {
    my @completions;
    if ($search =~ /IWL/) {
        @completions = map{'IWL::'. $_} qw(Calendar Entry List Spinner);
    } elsif ($search =~ /tk/i) {
        @completions = qw(GTK+ GTK+2.0 ETK);
    }
    IWL::Entry::printCompletions(@completions);
    exit 0;
} elsif ($text = $form{image}) {
    my $response = IWL::Response->new;
    $response->send(content => "The following text was received: $text", header => IWL::Object::getHTMLHeader);
    exit 0;
} else {
    my $page = IWL::Page->new;
    my $hbox = IWL::HBox->new;
    my $tree = IWL::Tree->new(id => 'widgets_tree', alternate => 1, animate => 1);
    my $notebook = IWL::Notebook->new(id => 'main_notebook');
    my $container = IWL::Container->new(id => 'content');
    my @scripts = (qw(demo.js dist/unittest.js unittest_extensions.js));
    my $locale = IWL::Combo->new(id => 'locale');

    $page->requiredCSS('demo.css');
    $page->appendChild($hbox);
    $hbox->packStart($tree)->appendChild($locale);
    $hbox->packStart($notebook);
    $page->requiredJs(@scripts);
    $notebook->appendTab('Display', $container)->setId('display_tab');
    $notebook->appendTab('Source')->setId('source_tab')->registerEvent('IWL-Notebook-Tab-select' => 'iwl_demo.pl', {}, {
	    onStart => <<'EOF',
var content = $('content').down();
if (content)
    params.codeFor = content.id;
EOF
	    update => "source_page",
	    disableView => {fullCover => 1},
    });

    $locale->appendOption('Български', 'bg');
    $locale->appendOption('Deutsch', 'de');
    $locale->appendOption('Français', 'fr');
    $locale->appendOption('English', 'en', 1);

    build_tree($tree);
    $page->setTitle('Widget Library');
    $page->send(type => 'html', static => 1);
}

sub build_tree {
    my $tree = shift;
    my $header = IWL::Tree::Row->new;
    my $basic_widgets = IWL::Tree::Row->new(id => 'basic_row');
    my $advanced_widgets = IWL::Tree::Row->new(id => 'advanced_row');
    my $containers = IWL::Tree::Row->new(id => 'containers_row');
    my $misc = IWL::Tree::Row->new(id => 'misc_row');
    my $event = IWL::Tree::Row->new(id => 'event_row');
    my $tests = IWL::Tree::Row->new(id => 'tests_row');

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
    $event->registerEvent('IWL-Tree-Row-expand', 'iwl_demo.pl');
    $tree->appendBody($tests);
    $tests->appendTextCell('JavaScript Unit tests');

    build_basic_widgets($basic_widgets);
    build_advanced_widgets($advanced_widgets);
    build_containers($containers);
    build_misc($misc);
    build_tests($tests);
}

sub build_basic_widgets {
    my $row = shift;
    my $buttons = IWL::Tree::Row->new(id => 'buttons_row');
    my $entries = IWL::Tree::Row->new(id => 'entries_row');
    my $spinners = IWL::Tree::Row->new(id => 'spinners_row');
    my $images = IWL::Tree::Row->new(id => 'images_row');
    my $labels = IWL::Tree::Row->new(id => 'labels_row');

    $buttons->appendTextCell('Buttons');
    $row->appendRow($buttons);
    $entries->appendTextCell('Entries');
    $row->appendRow($entries);
    $spinners->appendTextCell('Spinners');
    $row->appendRow($spinners);
    $images->appendTextCell('Images');
    $row->appendRow($images);
    $labels->appendTextCell('Labels');
    $row->appendRow($labels);

    register_row_event($buttons, $entries, $spinners, $images, $labels);
}

sub build_advanced_widgets {
    my $row = shift;
    my $tables = IWL::Tree::Row->new(id => 'tables_row');
    my $calendars = IWL::Tree::Row->new(id => 'calendars_row');
    my $combobox = IWL::Tree::Row->new(id => 'combobox_row');
    my $sliders = IWL::Tree::Row->new(id => 'sliders_row');
    my $iconbox = IWL::Tree::Row->new(id => 'iconbox_row');
    my $menus = IWL::Tree::Row->new(id => 'menus_row');
    my $navbar = IWL::Tree::Row->new(id => 'navbar_row');
    my $progress = IWL::Tree::Row->new(id => 'progress_bars_row');
    my $list = IWL::Tree::Row->new(id => 'list_row');
    my $table = IWL::Tree::Row->new(id => 'table_row');
    my $tree = IWL::Tree::Row->new(id => 'tree_row');

    $calendars->appendTextCell('Calendars');
    $row->appendRow($calendars);
    $combobox->appendTextCell('Combobox');
    $row->appendRow($combobox);
    $sliders->appendTextCell('Sliders');
    $row->appendRow($sliders);
    $iconbox->appendTextCell('Iconbox');
    $row->appendRow($iconbox);
    $menus->appendTextCell('Menus');
    $row->appendRow($menus);
    $navbar->appendTextCell('Navigation Bar');
    $row->appendRow($navbar);
    $progress->appendTextCell('Progress bars');
    $row->appendRow($progress);
    $tables->appendTextCell('Tables');
    $row->appendRow($tables);
    $list->appendTextCell('List');
    $tables->appendRow($list);
    $table->appendTextCell('Table');
    $tables->appendRow($table);
    $tree->appendTextCell('Tree');
    $tables->appendRow($tree);

    register_row_event($calendars, $combobox, $sliders, $iconbox, $menus, $navbar, $progress, $list, $table, $tree);
}

sub build_containers {
    my $row = shift;
    my $accordions = IWL::Tree::Row->new(id => 'accordions_row');
    my $contentbox = IWL::Tree::Row->new(id => 'contentbox_row');
    my $druid      = IWL::Tree::Row->new(id => 'druid_row');
    my $expander   = IWL::Tree::Row->new(id => 'expander_row');
    my $notebook   = IWL::Tree::Row->new(id => 'notebook_row');
    my $tooltips   = IWL::Tree::Row->new(id => 'tooltips_row');

    $accordions->appendTextCell('Accordions');
    $row->appendRow($accordions);
    $contentbox->appendTextCell('Contentbox');
    $row->appendRow($contentbox);
    $druid->appendTextCell('Druid');
    $row->appendRow($druid);
    $expander->appendTextCell('Expander');
    $row->appendRow($expander);
    $notebook->appendTextCell('Notebook');
    $row->appendRow($notebook);
    $tooltips->appendTextCell('Tooltips');
    $row->appendRow($tooltips);

    register_row_event($accordions, $contentbox, $druid, $expander, $notebook, $tooltips);
}

sub build_misc {
    my $row    = shift;
    my $file   = IWL::Tree::Row->new(id => 'file_row');
    my $gmap   = IWL::Tree::Row->new(id => 'gmap_row');
    my $canvas = IWL::Tree::Row->new(id => 'canvas_row');
    my $dnd    = IWL::Tree::Row->new(id => 'dnd_row');

    $file->appendTextCell('File Upload');
    $row->appendRow($file);
    $gmap->appendTextCell('Google Map');
    $row->appendRow($gmap);
    $canvas->appendTextCell('Canvas');
    $row->appendRow($canvas);
    $dnd->appendTextCell('Drag & Drop');
    $row->appendRow($dnd);

    register_row_event($file, $gmap, $canvas, $dnd);
}

sub build_tests {
    my $row              = shift;
    my $prototype        = IWL::Tree::Row->new(id => 'prototype_row');
    my $scriptaculous    = IWL::Tree::Row->new(id => 'scriptaculous_row');
    my $base             = IWL::Tree::Row->new(id => 'base_row');
    my $button_test      = IWL::Tree::Row->new(id => 'button_test_row');
    my $calendar_test    = IWL::Tree::Row->new(id => 'calendar_test_row');
    my $contentbox_test  = IWL::Tree::Row->new(id => 'contentbox_test_row');
    my $druid_test       = IWL::Tree::Row->new(id => 'druid_test_row');
    my $entry_test       = IWL::Tree::Row->new(id => 'entry_test_row');
    my $iconbox_test     = IWL::Tree::Row->new(id => 'iconbox_test_row');
    my $menu_test        = IWL::Tree::Row->new(id => 'menu_test_row');
    my $notebook_test    = IWL::Tree::Row->new(id => 'notebook_test_row');
    my $progressbar_test = IWL::Tree::Row->new(id => 'progressbar_test_row');
    my $spinner_test     = IWL::Tree::Row->new(id => 'spinner_test_row');
    my $tooltip_test     = IWL::Tree::Row->new(id => 'tooltip_test_row');
    my $tree_test        = IWL::Tree::Row->new(id => 'tree_test_row');
    my $upload_test      = IWL::Tree::Row->new(id => 'upload_test_row');

    $prototype->appendTextCell('Prototype extesions');
    $row->appendRow($prototype);
    $scriptaculous->appendTextCell('Scriptaculous extesions');
    $row->appendRow($scriptaculous);
    $base->appendTextCell('Base');
    $row->appendRow($base);
    $button_test->appendTextCell('Button Test');
    $row->appendRow($button_test);
    $calendar_test->appendTextCell('Calendar Test');
    $row->appendRow($calendar_test);
    $contentbox_test->appendTextCell('Contentbox Test');
    $row->appendRow($contentbox_test);
    $druid_test->appendTextCell('Druid Test');
    $row->appendRow($druid_test);
    $entry_test->appendTextCell('Entry Test');
    $row->appendRow($entry_test);
    $iconbox_test->appendTextCell('Iconbox Test');
    $row->appendRow($iconbox_test);
    $menu_test->appendTextCell('Menu Test');
    $row->appendRow($menu_test);
    $notebook_test->appendTextCell('Notebook Test');
    $row->appendRow($notebook_test);
    $progressbar_test->appendTextCell('Progress bar Test');
    $row->appendRow($progressbar_test);
    $spinner_test->appendTextCell('Spinner Test');
    $row->appendRow($spinner_test);
    $tooltip_test->appendTextCell('Tooltip Test');
    $row->appendRow($tooltip_test);
    $tree_test->appendTextCell('Tree Test');
    $row->appendRow($tree_test);
    $upload_test->appendTextCell('Upload Test');
    $row->appendRow($upload_test);

    register_row_event($prototype, $scriptaculous, $base, $button_test, $calendar_test,
        $contentbox_test, $druid_test, $entry_test, $iconbox_test, $menu_test,
        $notebook_test, $progressbar_test, $spinner_test, $tooltip_test, $tree_test, $upload_test);
}

sub generate_buttons {
    my $container = IWL::Container->new(id => 'buttons_container');
    my $normal_button = IWL::Button->new(style => {float => 'none'}, id => 'normal_button');
    my $stock_button = IWL::Button->newFromStock('IWL_STOCK_APPLY', style => {float => 'none'}, id => 'stock_button', size => 'medium');
    my $image_button = IWL::Button->new(style => {float => 'none'}, id => 'image_button', size => 'small')->setHref('iwl_demo.pl');
    my $disabled_button = IWL::Button->new(style => {float => 'none', margin => '12px 5px 8px 4px'}, id => 'disabled_button');
    my $input_button = IWL::InputButton->new(id => 'input_button');
    my $check = IWL::Checkbox->new;
    my $radio1 = IWL::RadioButton->new;
    my $radio2 = IWL::RadioButton->new;
    my $form = IWL::Form->new(target => '_blank', action => 'iwl_demo.pl', name => 'some_form');

    $container->appendChild($normal_button, $stock_button, $image_button, $disabled_button,
        $input_button, $check, IWL::Break->new, $radio1, $radio2, $form);
    $normal_button->setTitle('This is a title')->setSubmit(image => 'DELETE', 'some_form');
    $image_button->setImage('IWL_STOCK_DELETE');
    $normal_button->setLabel('Labeled button')->setClass('demo');
    $stock_button->signalConnect(load => "IWL.Status.display('Stock button loaded')");
    $disabled_button->setLabel('Disabled button')->setDisabled(1);
    $input_button->setLabel('Input Button');
    $check->setLabel('A check button');
    $radio1->setLabel('A radio button');
    $radio2->setLabel('Another radio button');
    $radio1->setGroup('radio')->setClass('demo');
    $radio2->setGroup('radio');
    return $container;
}

sub generate_entries {
    my $container      = IWL::Container->new(id => 'entries_container');
    my $normal_entry   = IWL::Entry->new;
    my $password_entry = IWL::Entry->new;
    my $cleanup_entry  = IWL::Entry->new;
    my $useless        = IWL::Entry->new;
    my $image_entry    = IWL::Entry->new(id => 'image_entry');
    my $label          = IWL::Label->new;
    my $completion     = IWL::Entry->new(id => 'entry_completion');

    $container->appendChild($normal_entry, $password_entry, $cleanup_entry,
        $image_entry, $useless, IWL::Break->new, $label, $completion);
    $normal_entry->setDefaultText('Type here');
    $password_entry->setPassword(1);
    $cleanup_entry->addClearButton->setValue('__cleanHere = 1', 'Clean me!');
    $cleanup_entry->{text}->setStyle(width => '160px');
    $image_entry->setIconFromStock('IWL_STOCK_SAVE', 'left', 1);
    $image_entry->{image1}->signalConnect(click => updaterCallback(
	    'entries_container', 'iwl_demo.pl',
	    parameters => "text: \$F('image_entry_text') || false",
	    insertion => 'bottom',
	    onComplete => q|IWL.Status.display.bind(this, 'Completed')|,
    ));
    $useless->setIconFromStock('IWL_STOCK_DOWNLOAD', 'left');
    $useless->setIconFromStock('IWL_STOCK_UPLOAD', 'right');
    $label->setText("The following entry provides completion capabilities. Try searching for 'gtk' or 'IWL'.");
    $completion->setAutoComplete('iwl_demo.pl', paramName => 'completion');
    return $container;
}

sub generate_spinners {
    my $container = IWL::Container->new(id => 'spinners_container');
    my $spinner = IWL::Spinner->new(id => 'normal_spinner');
    my $mask_spinner = IWL::Spinner->new(id => 'masked_spinner', acceleration => 0.5, precision => 2);

    $mask_spinner->setRange(-250, 1000)->setWrap(1)->setMask("Цена: #{number} лв")->setIncrements(0.2, 7.6);
    $container->appendChild($spinner, $mask_spinner);
    return $container;
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
    $normal_image->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif');

    return $container;
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

    return $container;
}

sub generate_calendars {
    my $container = IWL::Container->new(id => 'calendars_container');
    my $entry1 = IWL::Entry->new(readonly => 1);
    my $calendar1 = IWL::Calendar->new(id => 'calendar1', fromYear => 1989, fromMonth => 2, toYear => 2010, toMonth => 7, startDate => [1990, 3, 1, 12], markedDates => [{month => 0, date => 8}, {year => 1989, month => 11, date => 15}], showTime => 0);
    my $label = IWL::Label->new->setText("Click the icon to bring up another calendar.\nActivate a date to update the entry and close the calendar.");
    my $icon = IWL::Image->newFromStock('IWL_STOCK_CALENDAR')->setId('calendar_image');
    my $tip1 = IWL::Tooltip->new;
    my $calendar2 = IWL::Calendar->new(id => 'calendar2', astronomicalTime => 0, showHeading => 0, showWeekNumbers => 0, startOnMonday => 0, markWeekends => 0, showAdjacentMonths => 0);
    my $entry2 = IWL::Entry->new(readonly => 1);

    $tip1->bindToWidget($icon, 'click');
    $tip1->bindHideToWidget($calendar2, 'activate_date');
    $calendar1->setCaption("This calendar has a lower boundary at 1989/3, and an upper one at 2010/8. It also has 2 marked dates.");
    $calendar1->updateOnSignal(change => $entry1, "%A, %b %d, %Y");
    $calendar2->updateOnSignal(activate_date => $entry2, "%F - %T");
    $tip1->setContent($calendar2);
    $container->appendChild($calendar1, $entry1, IWL::Break->new, $label, $icon, $tip1, IWL::Break->new, $entry2);

    return $container;
}

sub generate_combobox {
    my $container = IWL::Container->new(id => 'combobox_container');
    my $normal_combobox = IWL::Combo->new;

    $container->appendChild($normal_combobox);
    $normal_combobox->appendOption('Lorem' => 1);
    $normal_combobox->appendOption('ipsum' => 2, 1);
    $normal_combobox->appendOption('dolor' => 3);
    $normal_combobox->appendOption('sit' => 4);

    return $container;
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

    return $container;
}

sub generate_iconbox {
    my $container = IWL::Container->new(id => 'iconbox_container');
    my $iconbox = IWL::Iconbox->new(id => 'iconbox', width => '310px', height => '200px');

    $container->appendChild($iconbox);
    $iconbox->signalConnect(load => "IWL.Status.display('Iconbox fully loaded')");
    foreach (1 .. 10) {
        my $icon = IWL::Iconbox::Icon->new;
        $iconbox->appendIcon($icon);
        $icon->setImage($IWLConfig{IMAGE_DIR} . '/demo/moon.gif');
        $icon->setText($_ x 10);
	if ($_ == 5) {
	    $icon->setText('Irregular icon title');
	    $icon->signalConnect(select =>
		  "IWL.Status.display('This callback was activated when icon $_ was selected')");
	    $icon->setClass('demo');
	}
        $icon->setDimensions('80px', '80px');
	$icon->setSelected(1) if $_ == 1;
    }

    return $container;
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
      signalConnect('activate' => q|IWL.Status.display('Don\\'t panic!')|);

    $file_menu->appendMenuItem('Open')->setClass('demo');
    $file_menu->appendMenuItem('Save', 'IWL_STOCK_SAVE');

    $edit_menu->appendMenuItem('Cut');
    $edit_menu->appendMenuItem('Copy');
    $edit_menu->appendMenuItem('Paste');

    $button->setLabel('Click me!');
    $button_menu->bindToWidget($button, 'click');
    $button_menu->appendMenuItem("Check item 1", undef)->setType('check')->signalConnect(change => q|IWL.Status.display('Check item 1 changed')|);
    $button_menu->appendMenuItem("Check item 2", undef)->setType('check')->toggle(1);
    $button_menu->appendMenuSeparator;
    $button_menu->appendMenuItem("Radio item 1", undef)->setType('radio')->toggle(1);
    $button_menu->appendMenuItem("Radio item 2", undef)->setType('radio');
    $button_menu->appendMenuItem("Radio item 3", undef)->setType('radio');
    $button_menu->appendMenuItem("Submenu")->setSubmenu($submenu);

    $submenu->setMaxHeight(200)->signalConnect(menu_item_activate => q{
        IWL.Status.display('Received item ' + arguments[1].id);
    });
    $submenu->appendMenuItem("Submenu item $_")->setType('check')->setId($_) foreach (1 .. 20);

    return $container;
}

sub generate_navbar {
    my $container = IWL::Container->new(id => 'navbar_container');
    my $navbar    = IWL::NavBar->new(id => 'navbar');
    my $updatee   = IWL::Container->new(id => 'updatee');

    $navbar->appendPath('Bar', 'something_else');
    $navbar->appendPath('Baz', 'baz');
    $navbar->prependPath('Foo', 'foo');
    $navbar->appendOption('Alpha', 'alpha');
    $navbar->appendOption('Beta', 'beta');
    $navbar->appendOption('Gamma', 'gamma');
    $navbar->registerEvent('IWL-NavBar-activatePath', 'iwl_demo.pl', {}, {update => 'updatee'});
    $container->appendChild($navbar, $updatee);

    return $container;
}

sub generate_progress_bars {
    my $container = IWL::Container->new(id => 'menus_container');
    my $progress  = IWL::ProgressBar->new(id => 'progress');
    my $pulsating = IWL::ProgressBar->new(pulsate => 1, id => 'pulsating');
    my $script    = IWL::Script->new->setScript("animate_progress_bar.delay(1)");

    $progress->setText("Overall progress: #{percent}")->setValue(0.37);
    $pulsating->signalConnect(click => '$(this).isPulsating() ? this.setPulsate(false) : this.setPulsate(true)');
    $container->appendChild($progress, $pulsating, $script);
    return $container;
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

    return $container;
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

    return $container;
}

sub generate_tree {
    my $container = IWL::Container->new(id => 'tree_container');
    my $label = IWL::Label->new;

    $container->appendChild($label);
    $label->setText('<----   The tree');

    return $container;
}

sub generate_accordions {
    my $container  = IWL::Container->new(id => 'accordions_container');
    my $accordion  = IWL::Accordion->new(id => 'vertical_accordion');
    my $horizontal = IWL::Accordion->new(id => 'horizontal_accordion', horizontal => 1, eventActivation => 'mouseover');

    $accordion->appendPage('Introduction', IWL::Label->new->setText('An accordion is a graphical user interface widget in which several sections of a document can be expanded or collapsed, displaying one at a time.')->appendTextType('Whenever a section is selected for opening, the open one is closed.', 'h2'))->setId('intro');
    $accordion->appendPage('Music', IWL::Label->new->setText('An accordion is a musical instrument of the handheld bellows-driven free reed aerophone family, sometimes referred to as squeezeboxes.'), 1)->setId('music');
    $accordion->appendPage('History', IWL::Label->new->setText('The accordion\'s basic form was invented in Berlin in 1822 by Friedrich Buschmann. The accordion is one of several European inventions of the early 19th century that used free reeds driven by a bellows; notable among them were:'))->setId('history');
    $accordion->appendPage('Horizontal', $horizontal);
    $accordion->appendPage('Misc', IWL::Image->new->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif'))->appendContent(IWL::Label->new->setText('The Moon (Latin: Luna) is Earth\'s only natural satellite and the fifth largest moon in the Solar System. The average centre-to-centre distance from the Earth to the Moon is 384,403 kilometres (238,857 miles),a which is about 30 times the diameter of the Earth. The Moon has a diameter of 3,474 kilometres (2,159 miles)[1] — slightly more than a quarter that of the Earth. This means that the volume of the Moon is only 1/50th that of Earth. The gravitational pull at its surface is about a 1/6th of Earth\'s. The Moon makes a complete orbit around the Earth every 27.3 days, and the periodic variations in the geometry of the Earth–Moon–Sun system are responsible for the lunar phases that repeat every 29.5 days.'));

    $horizontal->setStyle(height => '150px')->setDefaultSize(width => 400);
    $horizontal->appendPage('1', IWL::Label->new->setText('Integer commodo nibh sit amet odio. Pellentesque semper. Integer dolor. Donec scelerisque sapien placerat velit.'));
    $horizontal->appendPage('2', IWL::Label->new->setText('Sed at pede vitae turpis porta condimentum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla facilisi. Morbi erat. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae.'));
    $horizontal->appendPage('3', IWL::Label->new->setText('Curabitur quam lorem, laoreet molestie, eleifend id, pulvinar vel, nunc. Proin congue felis quis purus. Aenean porttitor, lacus vel bibendum pulvinar, leo nulla suscipit leo, nec lobortis orci diam eget turpis. Sed eu eros et orci consectetuer molestie. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.'));

    $container->appendChild($accordion);

    return $container;
}

sub generate_contentbox {
    my $container = IWL::Container->new(id => 'contentbox_container');
    my $contentbox = IWL::Contentbox->new(id => 'contentbox', autoWidth => 1);
    my $chooser = IWL::Combo->new(id => 'contentbox_chooser');
    my $outline = IWL::Checkbox->new(id => 'contentbox_outline_check');

    $container->appendChild($contentbox);
    $contentbox->appendTitleText('The title');
    $contentbox->appendHeaderText('The header of the contentbox');
    $contentbox->appendContentText('Select the type of the contentbox');
    $contentbox->appendContent(IWL::Break->new, $chooser, IWL::Break->new, $outline);
    $contentbox->appendFooterText('The footer of the contentbox');
    $contentbox->setShadows(1);
    $contentbox->signalConnect(close => q|IWL.Status.display("The contentbox has been closed.")|);
    $chooser->appendOption('none');
    $chooser->appendOption('drag');
    $chooser->appendOption('resize');
    $chooser->appendOption('dialog');
    $chooser->appendOption('window');
    $chooser->appendOption('noresize');
    $chooser->signalConnect(change => "contentbox_chooser_change(this)");
    $outline->setLabel('Outline resizing');
    return $container;
}

sub generate_druid {
    my $container = IWL::Container->new(id => 'druid_container');
    my $druid = IWL::Druid->new(id => 'druid');
    my $label1 = IWL::Label->new;

    $container->appendChild($druid);
    my $page = $druid->appendPage($label1)->signalConnect(remove => "IWL.Status.display('Page 1 removed.')");;
    $page->registerEvent(
	'IWL-Druid-Page-previous', 'iwl_demo.pl', {where => 'going back...'}
    )->registerEvent(
        'IWL-Druid-Page-next', 'iwl_demo.pl', {}, {emitOnce => 1}
    )->setId('first_page');
    $label1->setText('This is page 1');

    return $container;
}

sub generate_expander {
    my $container = IWL::Container->new(id => 'expander_container');
    my $expander = IWL::Expander->new(id => 'expander');
    my $image = IWL::Image->new(style => {float => 'left'});
    my $label = IWL::Label->new(expand => 1);

    $container->appendChild($expander);
    $expander->appendChild($image->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif'), $label)->setLabel('Moon details');
    $label->setText('The Moon (Latin: Luna) is Earth\'s only natural satellite and the fifth largest moon in the Solar System. The average centre-to-centre distance from the Earth to the Moon is 384,403 kilometres (238,857 miles),a which is about 30 times the diameter of the Earth. The Moon has a diameter of 3,474 kilometres (2,159 miles)[1] — slightly more than a quarter that of the Earth. This means that the volume of the Moon is only 1/50th that of Earth. The gravitational pull at its surface is about a 1/6th of Earth\'s. The Moon makes a complete orbit around the Earth every 27.3 days, and the periodic variations in the geometry of the Earth–Moon–Sun system are responsible for the lunar phases that repeat every 29.5 days.');

    return $container;
}

sub generate_notebook {
    my $container = IWL::Container->new(id => 'notebook_container');
    my $notebook = IWL::Notebook->new(id => 'notebook');
    my $label1 = IWL::Label->new;
    my $label2 = IWL::Label->new;

    $container->appendChild($notebook);
    $notebook->appendTab('Page 1', $label1);
    $notebook->appendTab('Page 2', $label2)->signalConnect(select => "IWL.Status.display(this.getLabel() + ' selected.')");
    $label1->setText('This is page 1');
    $label2->setText('This is page 2');

    return $container;
}

sub generate_tooltips {
    my $container = IWL::Container->new(id => 'tooltips_container');
    my $button = IWL::Button->new(size => 'medium', style => {float => 'none', margin => '0 auto'});
    my $label = IWL::Label->new(expand => 1, style => {'text-align' => 'center', border => '1px solid gray'});
    my $tip1 = IWL::Tooltip->new;
    my $tip2 = IWL::Tooltip->new(followMouse => 1);
    my $calendar = IWL::Calendar->new(id => 'calendar', showTime => 0, showWeekNumbers => 0, noMonthChange => 1);

    $tip1->bindToWidget($button, 'click', 1);
    $tip1->setContent($calendar);
    $tip2->bindToWidget($label, 'mouseover');
    $tip2->bindHideToWidget($label, 'mouseout');
    $tip2->setContent('Some text here. Кирилица.');
    $button->setLabel('Click for date');
    $label->signalConnect(click => $tip1->showingCallback);
    $calendar->signalConnect(activate_date => $tip1->hidingCallback);
    $label->setText('Hover over me');
    $container->appendChild($button, $label, $tip1, $tip2);

    return $container;
}

sub generate_file {
    my $container = IWL::Container->new(id => 'file_container');
    my $file = IWL::Upload->new(id => 'upload', action => 'iwl_demo.pl');
    my $label = IWL::Label->new;

    $container->appendChild($label);
    $container->appendChild($file);
    $label->setText('Press the button to upload a file.');

    return $container;
}

sub generate_gmap {
    my $container = IWL::Container->new(id => 'gmap_container');
    my $map = IWL::Google::Map->new(id => 'gmap', latitude => 42.60244915107272, longitude => 23.24128746986389, zoom => 9);
    my $entry = IWL::Entry->new(id => 'updatee', readonly => 1);

    $map->setScaleView('ruler')->setMapTypeControl('menu')->setMapControl('small')->setOverview('mini');
    $map->setMapType('physical')->setWidth('490px')->addMarker(IWL::Label->new->appendTextType('Hello World!', 'strong'));
    $map->signalConnect('movestart', "IWL.Status.display('Move from ' + this.getCenter().toString())");
    $map->updateOnSignal('moveend', $entry, "Move to %c with zoom level: %z");
    $map->addMarker('Still here', 42, 23);
    $entry->{text}->setStyle(width => '488px');
    $container->appendChild($map, $entry);

    return $container;
}

sub generate_canvas {
    my $container = IWL::Container->new(id => 'canvas_container');
    my $canvas = IWL::Canvas->new(id => 'html_canvas');
    my $moon = IWL::Image->new(id => 'moon')->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif')->setStyle(display => 'none');
    my $pi = 4 * atan2(1, 1);

    $canvas->setDimensions(400, 400);
    $canvas->getContext('2d')->globalAlpha(0.8);
    $canvas->fillStyle('#626fc2')->fillRect(10, 10, 74, 65);
    $canvas->fillStyle(65, 12, 62, 0.5)->fillRect(15, 15, 40, 40);
    $canvas->createLinearGradient(0, 0, 0, 150)->addColorStop(0, '#00ABEB')->addColorStop(0.5, '#fff')->addColorStop(0.5, '#26C000')->addColorStop(1, '#fff');
    $canvas->createLinearGradient(0, 50, 0, 95, 'gradient2')->addColorStop(0.5, '#000')->addColorStop(1, 0, 0, 0, 0);
    $canvas->fillStyle('gradient')->strokeStyle('gradient2')->fillRect(25,25,100,100)->clearRect(45,45,60,60)->strokeRect(50,50,50,50);
    $canvas->createRadialGradient(45, 45, 10, 52, 50, 30)->addColorStop(0, '#A7D30C')->addColorStop(0.9, '#019F62')->addColorStop(1, 1, 159, 98, 0)->fillStyle('gradient')->fillRect(0, 0, 150, 150);
    $canvas->fillStyle('#000')->strokeStyle('#000');
    $canvas->beginPath->moveTo(175, 150)->lineTo(200, 175)->lineTo(200, 125)->fill;
    $canvas->beginPath->arc(175, 175, 50, 0, $pi * 2, 1)->moveTo(210, 175)->arc(175, 175, 30, 0, $pi)->moveTo(165, 165)->arc(160, 165, 5, 0, $pi * 2, 1)->moveTo(195, 165)->arc(190, 165, 5, 0, $pi * 2, 1)->stroke;
    $canvas->beginPath->moveTo(25, 125)->lineTo(105, 125)->lineTo(25, 205)->fill;
    $canvas->beginPath->moveTo(125, 225)->lineTo(125, 145)->lineTo(45, 225)->closePath->stroke;
    $canvas->shadowOffsetX(3)->shadowOffsetY(3)->shadowColor('#92ba6f')->shadowBlur(2);
    $canvas->fillStyle('#000')->strokeStyle('#000');
    $canvas->beginPath->moveTo(275, 25)->quadraticCurveTo(225, 25, 225, 62.5)->quadraticCurveTo(225, 100, 250, 100)->quadraticCurveTo(250, 120, 230, 125)->quadraticCurveTo(260, 120, 265, 100)->quadraticCurveTo(325, 100, 325, 62.5)->quadraticCurveTo(325, 25, 275, 25)->stroke;
    $canvas->beginPath->moveTo(275, 240)->bezierCurveTo(275, 237, 270, 225, 250, 225)->bezierCurveTo(220, 225, 220, 262.5, 220, 262.5)->bezierCurveTo(220, 280, 240, 302, 275, 320)->bezierCurveTo(310, 302, 330, 280, 330, 262.5)->bezierCurveTo(330, 262.5, 330, 225, 300, 225)->bezierCurveTo(285, 225, 275, 237, 275, 240)->fill;
    $canvas->beginPath->rect(100, 350, 200, 20)->fill;
    $canvas->drawImage($moon, 50, 300)->drawImage($moon, 100, 300, 55, 55)->drawImage($moon, 10, 10, 30, 30, 310, 140, 50, 61);

    $container->appendChild($moon, $canvas);

    return $container;
}

sub generate_dnd {
    my $container = IWL::Container->new(id => 'dnd_container');
    my $source1 = IWL::Container->new(id => 'source1');
    my $source2 = IWL::Container->new(id => 'source2');
    my $view = IWL::Image->new->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif');
    my $dest1 = IWL::Container->new(id => 'dest1');

    $source1->setDragSource(outline => 1);
    $source2->setDragSource(view => $view, revert => 1);
    $dest1->setDragDest(containment => $container, hoverclass => 'hover');
    $source1->appendChild(IWL::Label->new->setText('Drag me!'));
    $dest1->setDragSource(ghosting => 1);
    $dest1->appendChild(IWL::Label->new->setText('Drop something here'));
    $dest1->signalConnect('drag_drop', 'dest1_drop(arguments[1], arguments[2])');
    $dest1->signalConnect('drag_begin', 'this.setOpacity(0.6)');
    $dest1->signalConnect('drag_end', 'this.setOpacity(1)');

    return $container->appendChild(
        IWL::Label->new(expand => 1)->appendTextType("The green containers are draggable, while the blue one is both draggable, and accepts the green ones as targets", 'em'),
        $source1, $dest1, $source2
    );
}

sub generate_rpc_events {
    my $container = IWL::Container->new(id => 'rpc_events_container');
    my $label = IWL::Label->new(id => 'rpc_label', expand => 1);
    my $link = IWL::Anchor->new(id => 'rpc_label_link');
    my $button = IWL::Button->new(id => 'rpc_button')->setLabel('Click me!');
    my $combo = IWL::Combo->new(id => 'rpc_combo');

    $label->setText("RPC Events are used to ... \n");
    $link->setText('read more')->setStyle(cursor => 'pointer', color => '#053AA1');
    $combo->appendOption('First option' => 'first');
    $combo->appendOption('Second option' => 'second');

    $link->registerEvent('IWL-Anchor-click', 'iwl_demo.pl', {}, {
	    onStart => "this.remove()",
	    update => 'rpc_label',
	    insertion => 'bottom',
    });
    $button->registerEvent('IWL-Button-click', 'iwl_demo.pl', {}, {
            onComplete => "IWL.Status.display(arguments[0].data.text)",
            emitOnce => 1
    });
    $combo->registerEvent('IWL-Combo-change', 'iwl_demo.pl', {}, {
            onComplete => "IWL.Status.display(arguments[0].data.text)",
            collectData => 1
    });

    $label->appendChild($link);
    $container->appendChild($label, $button, $combo);

    return $container;
}

sub generate_rpc_pagecontrol {
    my $container = IWL::Container->new(id => 'rpc_pagecontrol_container');
    my $content = IWL::Container->new(id => 'page_content');
    my $pager = IWL::PageControl->new(pageCount => 3, pageSize => 10, id => 'pagecontrol')->bindToWidget(
          $content, 'iwl_demo.pl', {}, {update => 'page_content', evalScripts => 1}
    );

    $content->appendChild(IWL::Image->new->set($IWLConfig{IMAGE_DIR} . '/demo/moon.gif'));
    $container->appendChild($content, $pager);

    return $container;
}

sub generate_prototype {
    my $container = IWL::Container->new(id => 'prototype_container');
    my $testlog = IWL::Container->new(id => 'testlog');
    my $script = IWL::Script->new;

    $script->setScript("run_prototype_tests()");
    $container->appendChild($testlog, $script);
    return $container;
}

sub generate_scriptaculous {
    my $container = IWL::Container->new(id => 'scriptaculous_container');
    my $testlog = IWL::Container->new(id => 'testlog');
    my $script = IWL::Script->new;

    $script->setScript("run_scriptaculous_tests()");
    $container->appendChild($testlog, $script);
    return $container;
}

sub generate_base {
    my $container = IWL::Container->new(id => 'base_container');
    my $testlog = IWL::Container->new(id => 'testlog');
    my $script = IWL::Script->new;

    $script->setScript("run_base_tests()");
    $container->appendChild($testlog, $script);
    return $container;
}

sub generate_button_test {
    my $container = IWL::Container->new(id => 'button_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $button    = IWL::Button->new(id => 'button_test');
    my $script    = IWL::Script->new;

    $script->setScript("run_button_tests()");
    $container->appendChild($testlog, $button, $script);
    return $container;
}

sub generate_calendar_test {
    my $container = IWL::Container->new(id => 'calendar_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $calendar  = IWL::Calendar->new(id => 'calendar_test', startDate => [2007, 10, 21, 17, 23, 5]);
    my $script    = IWL::Script->new;

    $script->setScript("run_calendar_tests()");
    $container->appendChild($testlog, $calendar, $script);
    return $container;
}

sub generate_contentbox_test {
    my $container  = IWL::Container->new(id => 'contentbox_test_container');
    my $testlog    = IWL::Container->new(id => 'testlog');
    my $contentbox = IWL::Contentbox->new(id => 'contentbox_test');
    my $script     = IWL::Script->new;

    $contentbox->appendTitleText('Tango');
    $contentbox->appendHeaderText('Foo');
    $contentbox->appendContentText('Bar');
    $contentbox->appendFooterText('Baz');
    $script->setScript("run_contentbox_tests()");
    $container->appendChild($testlog, $contentbox, $script);
    return $container;
}

sub generate_druid_test {
    my $container = IWL::Container->new(id => 'druid_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $druid     = IWL::Druid->new(id => 'druid_test');
    my $script    = IWL::Script->new;

    $druid->appendPage(IWL::Label->new(id => 'first_page_label')->setText('Some text'));
    $script->setScript("run_druid_tests()");
    $container->appendChild($testlog, $druid, $script);
    return $container;
}

sub generate_entry_test {
    my $container = IWL::Container->new(id => 'entry_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $entry     = IWL::Entry->new(id => 'entry_test');
    my $script    = IWL::Script->new;

    $entry->setIconFromStock('IWL_STOCK_REFRESH');
    $entry->addClearButton;
    $script->setScript("run_entry_tests()");
    $container->appendChild($testlog, $entry, $script);
    return $container;
}

sub generate_iconbox_test {
    my $container = IWL::Container->new(id => 'iconbox_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $iconbox   = IWL::Iconbox->new(id => 'iconbox_test');
    my $script    = IWL::Script->new;

    $script->setScript("run_iconbox_tests()");
    $container->appendChild($testlog, $iconbox, $script);
    return $container;
}

sub generate_menu_test {
    my $container = IWL::Container->new(id => 'menu_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $menubar   = IWL::Menubar->new(id => 'menubar_test');
    my $menu      = IWL::Menu->new(id => 'menu_test');
    my $script    = IWL::Script->new;

    $menubar->appendMenuItem('Item 1', 'IWL_STOCK_SAVE', id => 'item_1')->setSubmenu($menu);
    $menubar->appendMenuSeparator;
    $menubar->appendMenuItem('Item 2', undef, id => 'item_2');
    $menu->appendMenuItem('Item 3', undef, id => 'item_3')->setType('check');
    $menu->appendMenuSeparator;
    $menu->appendMenuItem('Item 4', 'IWL_STOCK_CANCEL', id => 'item_4');

    $script->setScript("run_menu_tests()");
    $container->appendChild($testlog, $menubar, $script);
    return $container;
}

sub generate_notebook_test {
    my $container = IWL::Container->new(id => 'notebook_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $notebook  = IWL::Notebook->new(id => 'notebook_test');
    my $script    = IWL::Script->new;

    $script->setScript("run_notebook_tests()");
    $container->appendChild($testlog, $notebook, $script);
    return $container;
}

sub generate_progressbar_test {
    my $container   = IWL::Container->new(id => 'progressbar_test_container');
    my $testlog     = IWL::Container->new(id => 'testlog');
    my $progressbar = IWL::ProgressBar->new(id => 'progressbar_test');
    my $script      = IWL::Script->new;

    $script->setScript("run_progressbar_tests()");
    $container->appendChild($testlog, $progressbar, $script);
    return $container;
}

sub generate_spinner_test {
    my $container = IWL::Container->new(id => 'spinner_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $spinner   = IWL::Spinner->new(id => 'spinner_test');
    my $script    = IWL::Script->new;

    $script->setScript("run_spinner_tests()");
    $container->appendChild($testlog, $spinner, $script);
    return $container;
}

sub generate_tooltip_test {
    my $container = IWL::Container->new(id => 'tooltip_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $tooltip   = IWL::Tooltip->new(id => 'tooltip_test', parent => $testlog);
    my $script    = IWL::Script->new;

    $script->setScript("run_tooltip_tests()");
    $container->appendChild($testlog, $tooltip, $script);
    return $container;
}

sub generate_tree_test {
    my $container = IWL::Container->new(id => 'tree_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $tree      = IWL::Tree->new(id => 'tree_test');
    my $row       = IWL::Tree::Row->new;
    my $script    = IWL::Script->new;

    $row->appendTextHeaderCell('Main')->makeSortable;
    $row->appendTextHeaderCell('Secondary')->makeSortable;
    $tree->appendHeader($row);
    $row = $row->new;
    $row->appendTextCell('Foo');
    $row->appendTextCell('Bar');
    $tree->appendBody($row);
    $row = $row->new;
    $row->appendTextCell('Alpha');
    $row->appendTextCell('Beta');
    $tree->appendBody($row);
    my $child = $row->new;
    $child->appendTextCell('Baz');
    $child->appendTextCell('A1');
    $row->appendRow($child);

    $script->setScript("run_tree_tests()");
    $container->appendChild($testlog, $tree, $script);
    return $container;
}

sub generate_upload_test {
    my $container = IWL::Container->new(id => 'upload_test_container');
    my $testlog   = IWL::Container->new(id => 'testlog');
    my $upload    = IWL::Upload->new(id => 'upload_test', name => 'upload_file', showTooltip => '');
    my $script    = IWL::Script->new;

    $script->setScript("run_upload_tests()");
    $container->appendChild($testlog, $upload, $script);
    return $container;
}

sub register_row_event {
    foreach my $row (@_) {
	my $function = 'generate_' .$row->getId;

	$function =~ s/_row$//;
	$row->registerEvent('IWL-Tree-Row-activate', 'iwl_demo.pl', {
		function => $function,
        }, {
                onStart => q|params.locale = $('locale').value|,
		onComplete => 'activate_widgets_response(json)',
		disableView => 1,
	});
    }
}

sub read_code {
    my ($start, $count) = @_;
    my $counter = 0;
    my $read = 0;
    my $content = '';
    local *DEMO;
    open DEMO, "$0";

    $start = "generate_" . $1 if $start =~ /^(\w+)_container$/ && !$count;

    while (<DEMO>) {
	$read++ if $_ =~ /$start/;
	last if $read && ($count ? $count == $counter++ : $_ =~ /^}/);
	$content .= $_ if $read;
    }
    close DEMO;
    $content .= "}\n" unless $count;
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

	$content = $formatter->format_string($content);
    };;
    return $content;
}

sub show_the_code_for {
    my $code_for = shift;
    my $paragraph = IWL::Label->new;

    if ($code_for eq 'entries_container') {
	$paragraph->appendTextType(read_code($code_for), 'pre');
	$paragraph->appendTextType('...', 'pre');
	$paragraph->appendTextType(read_code('my \$search = quotemeta \$form\{completion\}', 10), 'pre');
    } elsif ($code_for eq 'tree_container') {
	$paragraph->appendTextType(read_code("sub build_tree", 119), 'pre');
        $paragraph->appendTextType(read_code("Tree row handlers", 21), 'pre');
        $paragraph->appendTextType(');', 'pre');
    } elsif ($code_for eq 'druid_container') {
	$paragraph->appendTextType(read_code($code_for), 'pre');
	$paragraph->appendTextType(read_code("Druid handlers", 54), 'pre');
    } elsif ($code_for eq 'navbar_container') {
	$paragraph->appendTextType(read_code($code_for), 'pre');
	$paragraph->appendTextType(read_code("NavBar handlers", 27), 'pre');
    } elsif ($code_for eq 'rpc_events_container') {
	$paragraph->appendTextType(read_code($code_for), 'pre');
	$paragraph->appendTextType(read_code("Event row handlers", 21), 'pre');
    } elsif ($code_for eq 'rpc_pagecontrol_container') {
	$paragraph->appendTextType(read_code($code_for), 'pre');
	$paragraph->appendTextType(read_code("PageControl handlers", 28), 'pre');
    } else {
        my $code = read_code($code_for);
	$code
            ? $paragraph->appendTextType($code, 'pre')
            : $paragraph->setText('Code not available');
    }

    return $paragraph->getContent;
}

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2007  Viktor Kojouharov. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

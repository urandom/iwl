use Test::More tests => 6;

use IWL;

{
	my $form     = __create_form();
    my $state    = $form->getState;
    my $expected = IWL::Stash->new(
        skin         => ['5'],
        week_numbers => ['on'],
        display_type => ['popup']
    );
	is($form->getMethod, 'get');
	is($form->getAction, 'iwl_demo.pl');
	is($form->getTarget, '_blank');
	is($form->getEnctype, 'image/jpeg');
	is_deeply($expected, $state, 'get state');
}

{
	my $form     = __create_form();
    my $expected = IWL::Stash->new(
        skin         => ['2'],
        display_type => ['flat']
    );
    $form->applyState ($expected->clone);

    my $state    = $form->getState;
	is_deeply($expected, $state, 'set state');
}

sub __create_form {
    my $form = IWL::Form->new (name => '');
    $form->setEnctype('image/jpeg');
    $form->setAction('iwl_demo.pl');
	$form->setTarget('_blank');
    $form->setMethod('get');
    
    my $button = IWL::Input->new (type => 'submit', value => 'Refresh');
    my $button_container = IWL::Container->new;
    $button_container->appendChild ($button);
    $form->appendChild ($button_container);
    
    my $break = IWL::Break->new;
    
    my $label1 = IWL::Label->new;
    $label1->setText ("Calendar type:");
    $form->appendChild ($label1);
    $form->appendChild ($break);
    my $radio_popup = IWL::RadioButton->new (label => 'Popup',
					     name => 'display_type',
					     value => 'popup');
    my $radio_flat = IWL::RadioButton->new (label => 'Flat',
					    name => 'display_type',
					    value => 'flat');
    $radio_popup->setChecked (1);
    
    $form->appendChild ($radio_popup);
    $form->appendChild ($radio_flat);
    
    $form->appendChild ($break);
    my $label2 = IWL::Label->new;
    $label2->setText ("Skin:");
    $form->appendChild ($label2);
    $form->appendChild ($break);
    
    my $combo = IWL::Combo->new (name => 'skin');
    foreach (1 .. 10) {
	$combo->appendOption ("Number $_", $_, $_ == 5);
    }
    $form->appendChild ($combo);
    
    $form->appendChild ($break);
    my $label3 = IWL::Label->new;
    $label3->setText ("Options:");
    $form->appendChild ($label3);
    $form->appendChild ($break);
    
    my $check_week_numbers = IWL::Checkbox->new (name => 
						    'week_numbers');
    $check_week_numbers->setLabel ("Show week numbers");
    $check_week_numbers->setChecked (1);
    
    $form->appendChild ($check_week_numbers);
    
    return $form;
}

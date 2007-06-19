use Test::More tests => 11;

use IWL::Label;

{
    my $paragraph = IWL::Label->new(expand => 1);
    my $label = IWL::Label->new;

    is($paragraph->getContent, "");
    is($label->getContent, "");

    is($paragraph->appendText('Foo'), $paragraph);
    is($label->appendText('bar'), $label);

    like($paragraph->getContent, qr(<p id="label_\d+">Foo</p>));
    like($label->getContent, qr(<span id="label_\d+">bar</span>));
}

{
    my $label = IWL::Label->new;

    $label->appendText("Foo\nBar");
    like($label->getContent, qr(<span id="label_\d+">Foo<br />\n</span>));
    is($label->appendTextType('Alpha', 'strong'), $label);
    like($label->getContent, qr(<span id="label_\d+">Foo<br />\n<strong>Alpha</strong>\n</span>));
}

{
    my $label = IWL::Label->new;

    is($label->setJustify('center'), $label);
    is($label->getStyle('text-align'), 'center');
}

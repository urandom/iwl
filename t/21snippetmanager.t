use Test::More tests => 18;

BEGIN { use_ok('IWL::SnippetManager') }

{
    $manager = IWL::SnippetManager->new;
    $manager->requiredJs('manager.js');

    like($manager->getContent, qr(^<script (?:(?:src="/jscript/manager.js"|type="text/javascript"|iwl:requiredScript)\s*){3}></script>
$)s);
    ok(!$manager->getContent);

    $manager->requiredJs('manager2.js');
    my $object = $manager->getObject;
    ok($object->{snippetManager});
    is(scalar @{$object->{children}}, 1);
    is($object->{children}[0]{attributes}{src}, '/jscript/manager2.js');

    $object = $manager->getObject;
    ok(!$object->{scripts});
}

{
    my $manager = IWL::SnippetManager->new;
    my ($object1, $object2, $object3) = IWL::Object->newMultiple(3);

    $object2->requiredJs('shared.js')->requiredCSS('shared.css');
    $object3->requiredJs('shared.js')->requiredCSS('shared.css');

    $object1->appendChild($object2);
    $manager->appendChild($object1);

    like($manager->getContent, qr(^<style (?:(?:type="text/css"|iwl:requiredCSS)\s*){2}>\@import "/my/skin/darkness/shared.css";
</style>
<><></>
</>
<script (?:(?:src="/jscript/shared.js"|type="text/javascript"|iwl:requiredScript)\s*){3}></script>
$)s);

    $manager->appendChild($object3);
    is_deeply($manager->{childNodes}, [$object3]);
    is($manager->getContent, "<></>\n");
}

{
    my $manager = IWL::SnippetManager->new;
    my ($object1, $object2, $object3) = IWL::Object->newMultiple(3);

    $object2->requiredJs('shared.js');
    $object3->requiredJs('shared.js');

    $object1->appendChild($object2);
    $manager->appendChild($object1);

    my $obj = $manager->getObject;
    ok($obj->{snippetManager});
    is(scalar @{$obj->{children}}, 2);
    is(scalar @{$obj->{children}[0]{children}}, 1);
    is($obj->{children}[1]{tag}, 'script');
    is($obj->{children}[1]{attributes}{src}, '/jscript/shared.js');

    $manager->appendChild($object3);
    is_deeply($manager->{childNodes}, [$object3]);

    $obj = $manager->getObject;
    ok($obj->{snippetManager});
    is_deeply($obj->{children}, [{}]);
}

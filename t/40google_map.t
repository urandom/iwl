use Test::More tests => 17;

use IWL::Config '%IWLConfig';
use IWL::Google::Map;

{
    my $m = IWL::Google::Map->new;
    ok($m->bad);
    $m = IWL::Google::Map->new(key => 'abcdef');
    ok(!$m->bad);
}

{
    $IWLConfig{GOOGLE_MAPS_KEY} = 'abcdef';
    my $m = IWL::Google::Map->new(language => 'en');
    ok(!$m->bad);
    is($m->setWidth('400px'), $m);
    is($m->setHeight('300px'), $m);
    is($m->setLongitude(210), $m);
    is($m->setLatitude(-100), $m);
    is($m->setZoom(-100), $m);
    is($m->setMapType('hybrid'), $m);
    is($m->setScaleView('ruler'), $m);
    is($m->setMapControl('foobar'), $m);
    is($m->setMapTypeControl('menu'), $m);
    is($m->setOverview('mini'), $m);

    my $o = $m->getObject;
    is_deeply($o->{attributes}{style}, {width => '400px', height => '300px'});
    like($o->{attributes}{id}, qr/google_map_\d+/);
    is($o->{attributes}{class}, 'google_map');
    like($o->{children}[-1]{children}[0]{text}, qr/IWL.Google.Map.create.'google_map_\d+', {(?:(?:"mapTypeControl": "menu"|"longitude": 180|"language": "en"|"zoom": 0|"overview": "mini"|"mapControl": "none"|"latitude": -90|"mapType": "hybrid"|"markers": \[\]|"scaleView": "ruler"),?\s*){10}}\);/);
}

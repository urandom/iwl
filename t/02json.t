use Test::More tests => 25;

use IWL::JSON ':all';

{
    ok(isJSON("1.15"));
    ok(isJSON("-123"));
    ok(isJSON("12e+17"));
    ok(isJSON("-1.73e-162"));

    ok(isJSON('"Some string"'));
    ok(!isJSON("Some string"));
    ok(isJSON('"warn \"foo\""'));
    ok(!isJSON("warn \"foo\""));

    ok(!isJSON({}));
    ok(!isJSON([]));

    ok(isJSON('[]'));
    ok(isJSON('[1,2,"asd", "basd", 6123, {}]'));
    ok(isJSON('{"a": 1, "b": "foo", "c": [1,2,3], "d": {"A": 1, "B": 2}}'));
    ok(isJSON('{"foo": [1,2, true], "bar": {"1": null, "2": true, "3": false}}'));
}

{
    is(toJSON(''), '""');
    is(toJSON('Some string'), '"Some string"');
    is(toJSON('0.23e+16'), '0.23e+16');
    is(toJSON('-16.23e-16'), '-16.23e-16');

    is(toJSON([]), '[]');
    is(toJSON([1,2,2.3e+15,"foo",{}]), '[1, 2, 2.3e+15, "foo", {}]');

    is(toJSON({}), '{}');
    is(toJSON({foo => {bar => [1,2,3]}}), '{"foo": {"bar": [1, 2, 3]}}');
}

{
    is_deeply(evalJSON('{"handles": [], "options": {"axis": "vertical", "startSpan": null, "endSpan": null}, "axis": "vertical", "increment": 1, "step": 1, "range": {"start": 0, "end": 1}, "value": 0, "values": [0], "spans": false, "restricted": false, "maximum": 1, "minimum": 0, "alignX": 0, "alignY": 0, "trackLength": 52, "handleLength": 11, "active": false, "dragging": false, "disabled": false, "allowedValues": false, "activeHandleIdx": 0, "event": null, "initialized": true}', 1), {
        minimum => 0,
        disabled => '',
        maximum => 1,
        options => {
            startSpan => undef,
            endSpan => undef,
            axis => 'vertical'
        },
        range => {
            end => 1,
            start => 0
        },
        axis => 'vertical',
        restricted => '',
        increment => 1,
        initialized => 1,
        step => 1,
        trackLength => 52,
        handles => [],
        handleLength => 11,
        alignY => 0,
        spans => '',
        value => 0,
        active => '',
        values => [0],
        event => undef,
        allowedValues => '',
        alignX => 0,
        activeHandleIdx => 0,
        dragging => ''
    });
    is_deeply(evalJSON('{"a": "$a = 1"}', 1), {a => '$a = 1'});

    is_deeply(evalJSON('[eval("16"), 2]'), [16, 2]);
}

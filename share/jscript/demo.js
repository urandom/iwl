document.observe('contentloaded', demo_init);

function demo_init () {
    displayStatus('To display a widget demo, double click its row');
}

function activate_widgets_response(json) {
    if (!json) return;
    enableView();
    if (!json.data) return;
    var content = $('content');
    $('display_tab').setSelected(true);
    content.update();
    createHtmlElement(json.data, content);
    content.setStyle({display: 'block'});
}

function contentbox_chooser_change(chooser) {
    var outline = $('contentbox_outline_check').checked;
    $('contentbox').setType(chooser.value, {outline: outline});
}

function sortTheMoney(col_index) {
    return function (a, b) {
	var text1 = parseFloat($(a.cells[col_index]).getText().replace(/^\$/, ''));
	var text2 = parseFloat($(b.cells[col_index]).getText().replace(/^\$/, ''));
	if (!text1 || !text2) return;
	return text1 - text2;
    };
}

function run_prototype_tests() {
    var test_span;
    var tests = new Test.Unit.Runner({
        setup: function() {
            test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

        },
        teardown: function() {
            test_span.remove();
        },

        testBrowserDetection: function() { with(this) {
            var results = $H(Prototype.Browser).map(function(engine){
                return engine;
            }).partition(function(engine){
                return engine[1] === true
            });
            var trues = results[0], falses = results[1];
          
            // we should have definite trues or falses here
            trues.each(function(result){
                    assert(result[1] === true);
                });
            falses.each(function(result){
                    assert(result[1] === false);
                });

            if(navigator.userAgent.indexOf('AppleWebKit/') > -1) {
                info('Running on WebKit');
                assert(Prototype.Browser.WebKit);
            }

            if(navigator.userAgent.indexOf('KHTML') > -1) {
                info('Running on KHTML');
                assert(Prototype.Browser.KHTML);
            }

            if(!!window.opera) {
                info('Running on Opera');
                assert(Prototype.Browser.Opera);
            }

            if(!!(window.attachEvent && !window.opera)) {
                info('Running on IE');
                assert(Prototype.Browser.IE);
            }

            if(!!(window.attachEvent && !window.opera) && !!window.XMLHttpRequest) {
                info('Running on IE7');
                assert(Prototype.Browser.IE7);
            }

            if(navigator.userAgent.indexOf('Gecko') > -1 && navigator.userAgent.indexOf('KHTML') == -1) {
                info('Running on Gecko');
                assert(Prototype.Browser.Gecko);
            } 
        }},
        testEventMisc: function() { with(this) {
            assertEqual(32, Event.KEY_SPACE);
        }},
        testEventSignals: function() { with(this) {
            var fired1 = false, fired2 = false,
                callback1 = function(event) { fired1 = true }, callback2 = function(e) { fired2 = true; };
            assertIdentical(test_span, test_span.signalConnect('test:event', callback1));
            test_span.signalConnect('test:event', callback2);
            assertIdentical(test_span, test_span.emitSignal('test:event'));
            assert(fired1, "Handled callback1");
            assert(fired2, "Handled callback2");

            fired1 = false;
            fired2 = false;
            test_span.emitSignal('test:event2');
            assert(!fired1, "Fake event");
            assert(!fired2, "Fake event");

            assertIdentical(test_span, test_span.signalDisconnect('test:event', callback1));
            test_span.emitSignal('test:event');
            assert(!fired1, "Disconnected callback1");
            assert(fired2, "Disconnected callback1");
            
            fired2 = false;
            assertIdentical(test_span, test_span.signalDisconnectAll('test:event'));
            test_span.emitSignal('test:event');
            assert(!fired1, "Disconnected all callbacks");
            assert(!fired2, "Disconnected all callbacks");
        }},
        testElementMethods: function() { with(this) {
            test_span.innerHTML = "Some text right here!";
            assertEqual("Some text right here!", test_span.getText(), 'Getting text');
//            assertIdentical(document.body.parentNode, test_span.getScrollableParent(), 'Top level scrollable parent');

            test_span.update();
            test_span.appendChild(new Element('div', {style: 'width: 50px; height: 50px; overflow: auto;', id: 'first'}));
            test_span.firstChild.appendChild(new Element('div', {style: 'width: 150px; height: 100px', id: 'second'}));
            test_span.down(1).appendChild(new Element('div', {style: 'width: 10px; height: 5px', id: 'third'}));
            test_span.setStyle({visibility: 'hidden', display: 'block', position: 'absolute'});
//            assertEqual(150, test_span.firstChild.getScrollDimensions().width, 'Scroll width');
//            assertEqual(100, test_span.firstChild.getScrollDimensions().height, 'Scroll height');
//            assertIdentical(test_span.firstChild, test_span.down(2).getScrollableParent(), 'Scrollable parent');
            assertIdentical(test_span, test_span.positionAtCenter());
            assertEqual((document.viewport.getWidth() - test_span.getWidth()) / 2 + 'px', test_span.getStyle('left'));

            test_span.firstChild.appendChild(new Element('select', {name: 'select'})).appendChild(new Element('option', {value: 'foo'}));
            test_span.down(1).appendChild(new Element('input', {type: 'text', value: 'bar'}));
            test_span.down(2).appendChild(new Element('div', {className: 'slider', name: 'slider'})).control = {value: 'alpha'};
            test_span.firstChild.appendChild(new Element('textarea', {id: 'textarea'})).value = 'Some text';
            var params = test_span.getControlElementParams();
            assertInstanceOf(Hash, params, 'Params hash');
            assert(!params.values().include('bar'), 'Doesn\'t have unnamed elements');
            assertEqual('Some text', params['textarea'], 'Textarea param');
            assertEqual('foo', params['select'], 'Select param');
            assertEqual('alpha', params['slider'], 'Slider param');

            test_span.setStyle({visibility: '', display: 'none', position: ''});

            test_span.appendChild(new Element('div', {id: 15}));
            assert($(15), 'Numeric div');
        }},
        testIWLRPCEventCancel: function() { with(this) {
            var res1 = new Element('div', {id: 'res1'}), cancelled = new Element('div', {id: 'cancelled'});
            test_span.appendChild(res1);
            test_span.appendChild(cancelled);

            assertIdentical(test_span, test_span.registerEvent('IWL-Object-testEvent',
                    'iwl_demo.pl', {test: 1}));
            assert(test_span.hasEvent('IWL-Object-testEvent'));
            assertIdentical(test_span, test_span.emitEvent('IWL-Object-testEvent',
                    {cancel: 'Am I cancelled?'}, {update: cancelled}));
            assertIdentical(test_span, test_span.emitEvent('IWL-Object-testEvent', {foo: 'bar'},
                    {responseCallback: function(json) { eval(json.data); this.proceed() }.bind(this)}));

            delay(function() {
                assertEqual("Test: 1, Foo: bar", res1.innerHTML, "NOTE: Response might be slower than actual test run time"); 
                assert(!cancelled.innerHTML);

                test_span.writeAttribute('iwl:RPCEvents', "%7B%22IWL-Object-testEvent2%22%3A%20%5B%22iwl_demo.pl%22%2C%20%7B%22test%22%3A%201%7D%5D%7D");
                assertIdentical(test_span, test_span.prepareEvents());
                assert(test_span.hasEvent('IWL-Object-testEvent2'));
                assert(test_span.preparedEvents);
            });
        }},
        testIWLRPCEventUpdate: function() { with(this) {
            var res2 = new Element('div', {id: 'res2'});
            test_span.appendChild(res2);

            test_span.registerEvent('IWL-Object-testEvent', 'iwl_demo.pl', {});
            assertIdentical(test_span, test_span.emitEvent('IWL-Object-testEvent',
                    {text: 'Някакъв текст.'}, {
                        update: res2,
                        responseCallback: function() {this.proceed()}.bind(this)
                    }));

            delay(function() {
                assertEqual('Някакъв текст.', res2.innerHTML);
            });
        }},
        testIWLRPCEventCollect: function() { with(this) {
            var res3 = new Element('div', {id: 'res3'});
            test_span.appendChild(res3);

            test_span.appendChild(new Element('input', {type: 'hidden', name: 'hidden', value: 'foo'}));
            test_span.registerEvent('IWL-Object-testEvent', 'iwl_demo.pl', {});
            assertIdentical(test_span, test_span.emitEvent('IWL-Object-testEvent',
                    {}, {
                        update: res3,
                        collectData: true,
                        responseCallback: function() {this.proceed()}.bind(this)
                    }));

            delay(function() {
                assertEqual('true', res3.innerHTML);
            });
        }},
        testStrings: function() { with(this) {
            var text_node = "".createTextNode();
            assertEqual(3, text_node.nodeType);
            assertEqual("", text_node.nodeValue);
            text_node = "&lt;tag attribute=\"foo &amp; бар\"&gt;".createTextNode();
            assertEqual("<tag attribute=\"foo & бар\">", text_node.nodeValue);

            window.evalScriptsCounter = 0;
            ('foo <script>evalScriptsCounter++<'+'/script>bar').evalScripts();
            assertEqual(1, evalScriptsCounter);
            
            var stringWithScripts = '';
            (3).times(function(){ stringWithScripts += 'foo <script>evalScriptsCounter++<'+'/script>bar' });
            stringWithScripts.evalScripts();
            assertEqual(4, evalScriptsCounter);

            window.Menu = undefined;
            assertEqual("SCRIPT",
                (('foo <script src="' + IWLConfig.JS_DIR + '/menu.js"><'+'/script>bar').evalScripts())[1][0].tagName);
            wait(2000, function() { assertEqual('object', typeof Menu); });
            window.evalScriptsCounter = undefined;
        }},
        testPeriodicalAccelerator: function() { with(this) {
            var paEventCount = 0;
            paEventFired = function(pa) {
                if (++paEventCount > 2) {
                    pa.stop();
                    this.proceed();
                }
            }.bind(this);
            var pa = new PeriodicalAccelerator(paEventFired, {frequency: 0.1, border: 0.001});
            delay(function() {
                assertEqual(3, paEventCount);
                assert(pa.frequency < pa.options.frequency);
            });
        }},
        testDateExtensions: function() { with(this) {
            var date = new Date(2004, 0, 1);
            assert(date.isLeapYear());
            assertEqual(2005, date.incrementYear().getFullYear());
            assert(!date.isLeapYear());
            assertEqual(2008, date.incrementYear(3).getFullYear());
            assertEqual(2006, date.decrementYear(2).getFullYear());
            assertEqual(2005, date.decrementYear().getFullYear());

            assertEqual(1, date.incrementMonth().getMonth());
            assertEqual(4, date.incrementMonth(3).getMonth());
            assertEqual(2, date.decrementMonth(2).getMonth());
            assertEqual(1, date.decrementMonth().getMonth());

            assertEqual(2, date.incrementDate().getDate());
            assertEqual(7, date.incrementDate(5).getDate());
            assertEqual(5, date.decrementDate(2).getDate());
            assertEqual(4, date.decrementDate().getDate());

            assertEqual(1, date.incrementHours().getHours());
            assertEqual(6, date.incrementHours(5).getHours());
            assertEqual(4, date.decrementHours(2).getHours());
            assertEqual(3, date.decrementHours().getHours());

            assertEqual(1, date.incrementMinutes().getMinutes());
            assertEqual(6, date.incrementMinutes(5).getMinutes());
            assertEqual(4, date.decrementMinutes(2).getMinutes());
            assertEqual(3, date.decrementMinutes().getMinutes());

            assertEqual(1, date.incrementSeconds().getSeconds());
            assertEqual(6, date.incrementSeconds(5).getSeconds());
            assertEqual(4, date.decrementSeconds(2).getSeconds());
            assertEqual(3, date.decrementSeconds().getSeconds());

            assertEqual(1, date.incrementMilliseconds().getMilliseconds());
            assertEqual(6, date.incrementMilliseconds(5).getMilliseconds());
            assertEqual(4, date.decrementMilliseconds(2).getMilliseconds());
            assertEqual(3, date.decrementMilliseconds().getMilliseconds());

            assertEqual(20, date.getCentury());
            assertEqual(5, date.getWeek());
            assertEqual(35, date.getDayOfYear());
            assert(date.getTimezoneName().length > 0);
        }},
        testInsertScript: function() { with(this) {
            var loaded = false;
            var script = IWLConfig.JS_DIR + '/calendar.js';
            document.insertScript(script,
                {onComplete: function(url) { loaded = url; this.proceed()}.bind(this)});
            delay(function() {
                assertEqual(script, loaded, "NOTE: Response might be slower than actual test run time");
                assertEqual('object', typeof window.Calendar, "NOTE: Response might be slower than actual test run time");
            });
        }}
    }, 'testlog');
}

function run_scriptaculous_tests() {
    var tests = new Test.Unit.Runner({
        testDelayTest: function() { with(this) {
            delay(function() { assert(true) });
            setTimeout(function() {this.proceed()}.bind(this), 1000);
        }},
        testEffects: function() { with(this) {
            Effect.SmoothScroll();
            assert(window.smoothScroll);

            var paren = new Element('div', {style: 'width: 10px;height: 10px;position: absolute; visibility: hidden; overflow: auto;'});
            var child = new Element('div', {style: 'top: 40px; width: 5px; height: 5px; position: relative;'});
            paren.appendChild(child);
            document.body.appendChild(paren);
            assert(new Effect.ScrollElement(child, paren, {duration: 0.1}));

            wait(250, function() {
                assertEqual(35, paren.scrollTop);
                paren.remove();
            });
        }}
    }, 'testlog');
}

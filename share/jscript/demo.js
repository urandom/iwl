document.observe('dom:loaded', demo_init);

function demo_init () {
    IWL.displayStatus('To display a widget demo, double click its row');
}

function activate_widgets_response(json) {
    if (!json) return;
    IWL.enableView();
    if (!json.data) return;
    var content = $('content');
    content.update();
    content.createHtmlElement(json.data);
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
    new Test.Unit.Runner({
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
                callback1 = function(e) { fired1 = true }, callback2 = function(e) { fired2 = true; };
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
            assertEqual(Math.floor((document.viewport.getWidth() - test_span.getWidth()) / 2), parseInt(test_span.getStyle('left')));

            test_span.firstChild.appendChild(new Element('select', {name: 'select'})).appendChild(new Element('option', {value: 'foo'}));
            test_span.down(1).appendChild(new Element('input', {type: 'text', value: 0.17}));
            test_span.down(2).appendChild(new Element('div', {className: 'slider', name: 'slider'})).control = {value: 0.26};
            test_span.firstChild.appendChild(new Element('textarea', {id: 'textarea'})).value = 'Some text';
            var params = test_span.getControlElementParams();
            assertInstanceOf(Hash, params, 'Params hash');
            assert(!params.values().include(0.17), 'Doesn\'t have unnamed elements');
            assertEqual('Some text', params.get('textarea'), 'Textarea param');
            assertEqual('foo', params.get('select'), 'Select param');
            assertEqual(0.26, params.get('slider'), 'Slider param');

            assert(test_span.down().childElements()[1].checkValue({reg: /^(?:foo|bar)$/}), 'Regular expression');
            assert(test_span.down(1).childElements()[1].checkValue({range: $R(0,1)}), 'Range');
            assert(!test_span.down(1).childElements()[1].checkValue({range: $R(-1,0), deleteValue: true}), 'Delete value');
            wait(550, function() {
                assert(!test_span.down(1).childElements()[1].value, 'No value');
                assert(test_span.down().childElements()[1].checkValue({passEmpty: true}), 'Pass empty');
                assert(!test_span.down().childElements()[2].checkValue({reg: /^(?:foo|bar)$/, errorString: 'Invalid value'}), 'Error string');
                assertEqual('Invalid value', test_span.down().childElements()[2].value);

                test_span.setStyle({visibility: '', display: 'none', position: ''});

                test_span.appendChild(new Element('div', {id: 15}));
                assert($(15), 'Numeric div');
            });
        }},
        testFunctionMethods: function() { with(this) {
            var func = function(event, arg1, arg2, arg3, arg4) {
                assertEqual('test:event3', event.eventName);
                assertEqual(1, arg1);
                assertEqual(2, arg2);
                assertEqual(3, arg3);
                assertEqual(4, arg4);
            }.bindAsEventListener(this, 1, 2);
            var func2 = function(arg1, arg2) {
                assertEqual(1, arg1);
                assertEqual(2, arg2);
            }.bind(this, 1, 2);
            test_span.signalConnect('test:event3', func);
            test_span.signalConnect('test:event4', func2);
            test_span.emitSignal('test:event3', 3, 4);
            test_span.emitSignal('test:event4', 3, 4);
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

            IWL.Menu = undefined;
            ('foo <script src="' + IWL.Config.JS_DIR + '/menu.js"><'+'/script>bar').evalScripts();
            wait(2000, function() { assertEqual('object', typeof IWL.Menu); });
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
        testViewport: function() { with(this) {
            var test_div = document.body.appendChild(new Element(
                    'div',
                    {style: 'height: 100px; width: 100px; position: absolute; top: 1900px; left: 2400px; background: red;'}
                ));
            assertEnumEqual([2500, 2000], document.viewport.getMaxDimensions());
            assertEqual(2500, document.viewport.getMaxWidth());
            assertEqual(2000, document.viewport.getMaxHeight());
            test_div.remove();
        }},
        testInsertScript: function() { with(this) {
            var loaded = false;
            var script = IWL.Config.JS_DIR + '/calendar.js';
            document.insertScript(script,
                {onComplete: function(url) { loaded = url; this.proceed()}.bind(this)});
            delay(function() {
                assertEqual(script, loaded);
                assertEqual('object', typeof IWL.Calendar);
            });
        }}
    }, 'testlog');
}

function run_scriptaculous_tests() {
    new Test.Unit.Runner({
        testDelayTest: function() { with(this) {
            delay(function() { assert(true) });
            this.proceed.bind(this).delay(1);
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

function run_base_tests() {
    if (!!$('status_bar'))
        $('status_bar').remove();

    new Test.Unit.Runner({
        testIWLConfig: function() { with(this) {
            assert(IWL.Config);
            assert(Object.isString(IWL.Config.SKIN) && IWL.Config.SKIN);
            assert(Object.isString(IWL.Config.SKIN_DIR) && IWL.Config.SKIN_DIR);
            assert(Object.isString(IWL.Config.IMAGE_DIR) && IWL.Config.IMAGE_DIR);
            assert(Object.isString(IWL.Config.ICON_DIR) && IWL.Config.ICON_DIR);
            assert(Object.isString(IWL.Config.ICON_EXT) && IWL.Config.ICON_EXT);
            assert(Object.isString(IWL.Config.JS_DIR) && IWL.Config.JS_DIR);
            assert(Object.isNumber(IWL.Config.STRICT_LEVEL) && IWL.Config.STRICT_LEVEL >= 1);
        }},
        testIWLRPCEventCancel: function() { with(this) {
            var test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

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
                assertEqual("Test: 1, Foo: bar", res1.innerHTML); 
                assert(!cancelled.innerHTML);

                test_span.writeAttribute('iwl:RPCEvents', "%7B%22IWL-Object-testEvent2%22%3A%20%5B%22iwl_demo.pl%22%2C%20%7B%22test%22%3A%201%7D%5D%7D");
                assertIdentical(test_span, test_span.prepareEvents());
                assert(test_span.hasEvent('IWL-Object-testEvent2'));
                assert(test_span.preparedEvents);

                test_span.remove();
            });
        }},
        testIWLRPCEventUpdate: function() { with(this) {
            var test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

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
                test_span.remove();
            });
        }},
        testIWLRPCEventCollect: function() { with(this) {
            var test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

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
                test_span.remove();
            });
        }},
        testWidget: function() { with(this) {
            var test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

            IWL.Widget.create(test_span);
            assertRespondsTo('create', test_span);
            assertRespondsTo('_abortEvent', test_span);
        }},
        testIWLcreateHTMLElement: function() { with(this) {
            var obj = {
                scripts: [{
                    tag: 'script', attributes: {
                        src: IWL.Config.JS_DIR + '/iconbox.js', type: 'text/javascript'
                    }
                }],
                tailObjects: [
                    {tag: 'span', children: [{text: 'foo'}]},
                    {tag: 'table', attributes: {id: 'test_table'}, children: [
                        {tag: 'tbody', children: [
                            {tag: 'tr', children: [
                                {tag: 'td', text: 'foo'},
                                {tag: 'script', attributes: {type: 'text/javascript'}, children: [
                                    {text: "$('test_table').select('td')[0].update('beta')"}
                                ]}
                            ]}
                        ]}
                    ]}
                ],
                text:'bar', tag:'div', children: [{
                    tag: 'p', text: 'Lorem ipsum, Нещо', attributes: {
                        style: {'text-align': 'center', 'font-size': '16px'}
                    }
                }],
                attributes: {'class': 'foo', id: 'bar', 'iwl:fooBar': 'alpha'}
            };
            var element = $('testlog').createHtmlElement(obj);

            assert(Object.isElement(element));
            assertEqual('DIV', element.tagName);
            assert(/bar[\r\n]*Lorem ipsum, Нещо/.test(element.getText()));
            assertEqual('foo', element.className);
            assertEqual('bar', element.id);
            assertEqual('alpha', element.readAttribute('iwl:fooBar'));
            assertEqual('P', element.down().tagName);
            assertEqual('Lorem ipsum, Нещо', element.down().getText());
            assertEqual('center', element.down().getStyle('text-align'));
            assertEqual('16px', element.down().style.fontSize);
            assertEqual('SPAN', element.next().tagName);
            assertEqual('foo', element.next().getText());
            assertEqual('TABLE', element.next(1).tagName);
            assert($('test_table'));

            wait(1000, function() {
                assertEqual('beta', $('test_table').select('td')[0].getText());
                assert(IWL.Iconbox);
                element.next().remove();
                element.next().remove();
                element.remove();
                benchmark(function () {
                    var element = $('testlog').createHtmlElement(obj);
                    element.next().remove();
                    element.next().remove();
                    element.remove();
                }, 100);
            });
        }},
        testView: function() { with(this) {
            IWL.disableView({opacity: 0.9});
            assert($('disabled_view_rail'));
            assertEqual(0.9, $('disabled_view_rail').getOpacity());
            IWL.enableView();
            assert(!$('disabled_view_rail'));

            IWL.disableView({noCover: true});
            assert(!$('disabled_view_rail'));
            assertEqual('wait', document.body.style.cursor);
            IWL.enableView();
            assertEqual('', document.body.style.cursor);

            IWL.disableView({fullCover: true, opacity: 0.3});
            assert($('disabled_view_rail'));
            assert($('disabled_view'));
            assertEqual(0.3, $('disabled_view').getOpacity());
            assertEqual(1, $('disabled_view_rail').getOpacity());
            IWL.enableView();
            assert(!$('disabled_view'));
            assert(!$('disabled_view_rail'));
        }},
        testStatus: function() { with(this) {
            IWL.displayStatus('foo');
            assert($('status_bar'), 'First status');
            assertEqual('foo', $('status_bar').getText(), 'It has text');
            IWL.displayStatus('bar');
            assert(/foo[\r\n]*bar/.test($('status_bar').getText()), 'Another text added');
            IWL.removeStatus();
            IWL.removeStatus();
            wait(1150, function() {
                assert(!$('status_bar'), 'First removed status');
                IWL.displayStatus('alpha', {duration:0.2});
                assert($('status_bar'), 'Duration status');
                wait(1600, function() {
                    assert(!$('status_bar'), 'Removed duration status');
                });
            });
        }},
        testExceptionHandler: function() { with(this) {
            var console = Object.extend({}, window.console);
            window.console = null;

            IWL.exceptionHandler(null, new Error('Some error'));
            assert($('status_bar'));
            assertEqual('Error message: Some error', $('status_bar').firstChild.nodeValue);
            [1,2,3].each(function() {
                IWL.removeStatus();
            });
            window.console = console;
        }},
        testFocus: function() { with(this) {
            if (!Prototype.Browser.Gecko) return;
            var test_span = new Element('span', {style: "display: none", id: 'test_span'});
            $('testlog').parentNode.appendChild(test_span);

            test_span.registerFocus();
            Event.simulateMouse(test_span, 'click');
            wait(1000, function() {
                assertEqual(test_span, IWL.Focus.current);
            });
        }},
        testBrowserCss: function() { with(this) {
            var html = $$('html')[0];
            var b = Prototype.Browser;
            var class_name = b.IE7    ? 'ie7' :
                             b.IE     ? 'ie' :
                             b.Opera  ? 'opera' :
                             b.WebKit ? 'webkit' :
                             b.KHTML  ? 'khtml' :
                             b.Gecko  ? 'gecko' : 'other';
            assert(html.hasClassName(class_name));
        }}
    }, 'testlog');
}

function run_button_tests() {
    var button = $('button_test');
    var className = $A(button.classNames()).first();
    new Test.Unit.Runner({
        testParts: function() { with(this) {
            var parts = button.childElements();
            assert(button.hasClassName('button'));
            assertEqual('button_test', button.id);
            assertEqual(9, parts.length);
            $w("tl top tr l content r bl bottom br").each(function(part, index) {
                assert(parts[index].hasClassName(className + '_' + part));
                assertEqual(button.id + '_' + part, parts[index].id);
            });
            assert(button.buttonLabel);
            assertEqual('button_test_label', button.buttonLabel.id);
            assert(button.buttonLabel.hasClassName(className + '_label'));
        }},
        testLabels: function() { with(this) {
            assert(!button.getLabel());
            assertEqual(button, button.setLabel('Some label'));
            assertEqual('Some label', button.getLabel());
            assertEqual(button, button.setLabel('&lt;'));
            assertEqual('<', button.getLabel());
            assertEqual(button, button.setLabel(''));
            assert(!button.getLabel());
            assertEqual(button, button.setLabel('<foo бар="あるは">'.escapeHTML()));
            assertEqual('<foo бар="あるは">', button.getLabel());
        }},
        testImages: function() { with(this) {
            assert(!button.getImage());
            assertEqual(button, button.setImage(IWL.Config.ICON_DIR + '/next.' + IWL.Config.ICON_EXT));
            assertEqual('IMG', button.getImage().tagName);
            assertEqual(window.location.protocol + '//' + window.location.host + IWL.Config.ICON_DIR + '/next.' + IWL.Config.ICON_EXT, button.getImage().src);
            assert(button.buttonImage.hasClassName('button_image'));
            assert(button.buttonImage.hasClassName('image'));
            assertEqual('button_test_image', button.buttonImage.id);
        }},
        testDisable: function() { with(this) {
            assert(!button.isNotEnabled());
            assertEqual(button, button.setDisabled(true));
            assert(button.isNotEnabled());
            assert(button.disabledLayer);
            assert(button.hasClassName(className + '_disabled'));
            assertEqual(button, button.setDisabled(false));
            assert(!button.isNotEnabled());
            assert(!button.disabledLayer);
        }}
    }, 'testlog');
}

function run_calendar_tests() {
    var calendar = $('calendar_test');
    var className = $A(calendar.classNames()).first();
    new Test.Unit.Runner({
        testParts: function() { with(this) {
            assertEqual('calendar', className);
            assertEqual(42, calendar.dateCells.length);
            assertEqual(1, calendar.select('.' + className + '_time').length);
            assertEqual(6, calendar.select('.' + className + '_week').length);
            assertEqual(1, calendar.select('.' + className + '_heading').length);
            assertEqual(1, calendar.select('input.' + className + '_hours').length);
            assertEqual(1, calendar.select('input.' + className + '_minutes').length);
            assertEqual(1, calendar.select('input.' + className + '_seconds').length);
            assertEqual(6, calendar.select('.' + className + '_week_number').length);
            assertEqual(1, calendar.select('.' + className + '_week_days').length);
            assertEqual(7, calendar.select('.' + className + '_week_day_header').length);
            assertEqual(2, calendar.select('.' + className + '_weekend_header').length);
            assertEqual(2, calendar.select('.' + className + '_header_cell').length);
            assertEqual(1, calendar.select('span.' + className + '_month_prev').length);
            assertEqual(1, calendar.select('input.' + className + '_month').length);
            assertEqual(1, calendar.select('span.' + className + '_month_next').length);
            assertEqual(1, calendar.select('span.' + className + '_year_prev').length);
            assertEqual(1, calendar.select('input.' + className + '_year').length);
            assertEqual(1, calendar.select('span.' + className + '_year_next').length);
        }},
        testDate: function() { with(this) {
            var date = calendar.getDate();
            assertInstanceOf(Date, date);
            assertEqual(2007, date.getFullYear());
            assertEqual(10, date.getMonth());
            assertEqual(21, date.getDate());
            assertEqual(17, date.getHours());
            assertEqual(23, date.getMinutes());
            assertEqual(5, date.getSeconds());
            assertEqual(47, date.getWeek());
            assertEqual(date.getTime(), calendar.currentDate.getDate().getTime());

            assertEqual(calendar, calendar.setDate(new Date(1972, 1, 13, 17, 2, 12)));
            assertEqual(new Date(1972, 1, 13, 17, 2, 12).getTime(), calendar.getDate().getTime());
            assertEqual(new Date(1972, 1, 13, 17, 2, 12).getTime(), calendar.currentDate.getDate().getTime());
            assertEqual(new Date(1972, 1, 3, 17, 2, 12).getTime(), calendar.getByDate(new Date(1972, 1, 3)).getDate().getTime());
        }},
        testShowMethods: function() { with(this) {
            assertEqual(calendar, calendar.showWeekNumbers(false));
            var cells = calendar.select('.calendar_week_number_header').concat(
                calendar.select('.calendar_week_number')).concat(
                calendar.select('.calendar_header_cell')[0]);
            assertEnumEqual([false, false, false, false, false, false, false, false], cells.invoke('visible'));
            assertEqual(calendar, calendar.showWeekNumbers(true));
            assertEnumEqual([true, true, true, true, true, true, true, true], cells.invoke('visible'));

            assertEqual(calendar, calendar.showHeading(false));
            assert(!calendar.select('.calendar_heading')[0].visible());
            assertEqual(calendar, calendar.showHeading(true));
            assert(calendar.select('.calendar_heading')[0].visible());

            assertEqual(calendar, calendar.showTime(false));
            assert(!calendar.select('.calendar_time')[0].visible());
            assertEqual(calendar, calendar.showTime(true));
            assert(calendar.select('.calendar_time')[0].visible());
        }},
        testUpdate: function() { with(this) {
            var update = $('testlog').appendChild(new Element('span'));
            assertEqual(calendar,
                calendar.updateOnSignal('iwl:activate', update,
                    "foo %a - %A, %b - %B, %C, %d, %D, %e, %E, %F, %h, %H, %I, %j, %k, %l, %m, %M, %p, %P, %r, %R, %s, %S, %T, %u, %U, %w, %y, %Y, %%"
                ));

            assertEqual(calendar.currentDate, calendar.currentDate.activate());
            assertEqual('foo ' + IWL.Calendar.abbreviatedWeekDays[6] + ' - '
                + IWL.Calendar.weekDays[6] + ', ' + IWL.Calendar.abbreviatedMonths[1] + ' - '
                + IWL.Calendar.months[1] + ', 19, 13, 2/13/72, 13, %E, 1972-02-13, Feb, 17, 05, 044, 17, 5, 02, 02, '
                + 'PM, pm, 05:02:12 PM, 17:02, 66841332000, 12, 17:02:12, 7, 07, 0, 72, 1972, %',
                update.innerHTML);
            update.remove();
        }},
        testMarks: function() { with(this) {
            assertEqual(calendar, calendar.markDate({date: 16}));
            assertEqual(calendar, calendar.markDate({month: 1, date: 6}));
            assertEqual(calendar, calendar.markDate(new Date(1975, 2, 11)));
            assertEqual(3, calendar.options.markedDates.length);
            assertEqual(16, calendar.options.markedDates[0].date);
            assertEnumEqual([1, 6], [calendar.options.markedDates[1].month, calendar.options.markedDates[1].date]);
            assertEnumEqual([1975, 2, 11], [calendar.options.markedDates[2].year,
                calendar.options.markedDates[2].month, calendar.options.markedDates[2].date]);

            assertEqual(calendar, calendar.unmarkDate({month: 1, date: 6}));
            assertEqual(2, calendar.options.markedDates.length);
            assertEqual(16, calendar.options.markedDates[0].date);
            assertEnumEqual([1975, 2, 11], [calendar.options.markedDates[1].year,
                calendar.options.markedDates[1].month, calendar.options.markedDates[1].date]);

            assertEqual(calendar, calendar.clearMarks());
            assertEqual(0, calendar.options.markedDates.length);
        }}
    }, 'testlog');
}

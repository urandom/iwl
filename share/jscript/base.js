// vim: set autoindent shiftwidth=4 tabstop=8:
var focused_widget = null;

var loaded = false;
Event.signalConnect(window, "load", function () {
	loaded = true;
	Event.signalConnect(document.body, "click", loseFocus);
});

if (!window.IWL) var IWL = {};

/**
 * @class Widget is the base class for all IWL widgets
 *
 * @method create The 'constructor' method
 * @param id The element to transform into a widget
 * @returns The created widget
 * */
IWL.Widget = {
    create: function(id) {
	this.current = $(id);
	if (this._preInit)
	    if (!this._preInit.apply(this, arguments)) return;
	Object.extend(this.current, this);
  	if (this.current.prepareEvents)    
            this.current.prepareEvents();
	if (this.current._init)
	    this.current._init.apply(this.current, arguments);
     
	return this.current;
    },
    _abortEvent: function(collection, eventName, exception) {
	if (!collection || !collection.each || !eventName) return;
	collection.each(function(item) {
	    if (item === exception) return;
	    if (item['handlers'] 
		&& item['handlers'][eventName]
		&& item['handlers'][eventName].ajaxRequest)
		item['handlers'][eventName].ajaxRequest.transport.abort();
	});
    }
};

Object.extend(IWL, (function() {
    var script_urls = 0;
    var scripts     = [];
    
    function addScript () {
        if (--script_urls > 0) return;
        scripts.each(function(s) {
            eval(s);
        });
        scripts = [];
    }

    return {
        /**
         * Creates an html element from IWL's json structure
         * @param obj The json object
         * @param paren The parent element
         * @param before_el A reference element. If given, the created element will appear before this one. Optional
         *
         * @returns The created element or 'true', if the element is a text node
         * */
        createHtmlElement: function(obj, paren, before_el) {
            var element;
            var flags = {disabled: true, multiple: true};
            if (!obj) return;
            if (!paren) return;
            if (obj.scripts) {
                while (obj.scripts.length) {
                    var url = obj.scripts.shift().attributes.src;
                    if (!($$('script').pluck('src').grep(url + "$").length))
                        ++script_urls;
                    document.insertScript(url, {onComplete: addScript});
                }
            }
            if (!obj.tag) {
                if (obj.text === undefined || obj.text === null) return false;
                if (paren.tagName.toLowerCase() == 'script') {
                    if (script_urls)
                        scripts.push(obj.text);
                    else
                        eval(obj.text);
                    return true;
                }
                if (Prototype.Browser.IE) {
                    if (paren.tagName.toLowerCase() == 'script') {
                        paren.text = obj.text;
                        return true;
                    } else if (paren.tagName.toLowerCase() == 'style') {
                        paren.styleSheet.cssText = obj.text;
                        return true;
                    } else {
                        if (before_el) {
                            paren.insertBefore(obj.text.toString().createTextNode(),
                                    before_el);
                            return true;
                        }
                        paren.appendChild(obj.text.toString().createTextNode());
                        return true;
                    }
                } else {
                    if (before_el) {
                        paren.insertBefore(obj.text.toString().createTextNode(),
                                before_el);
                        return true;
                    }
                    paren.appendChild(obj.text.toString().createTextNode());
                    return true;
                }
            } else {
                /* We don't need a noscript when it's obvious that we have js enabled */
                if (obj.tag == 'noscript') {
                    obj.tag = 'span';
                    if (!obj.attributes) obj.attributes = {};
                    if (!obj.attributes.style) obj.attributes.style = {};
                    obj.attributes.style.display = 'none';
                }
                if ((Prototype.Browser.IE && !obj.attributes) || !Prototype.Browser.IE)
                    element = $(document.createElement(obj.tag));
            }
            // setAttribute in Internet Explorer doesn't set style, class or any of the events. What the hell were they thinking?
            if (obj.attributes) {
                if (Prototype.Browser.IE) {
                    var attributes = '';
                    for (var i in obj.attributes) {
                        var attr = obj.attributes[i];
                        if (i == 'style') {
                            var style = '';
                            for (var j in attr) {
                                style += j + ": " + attr[j] + "; ";
                            }
                            attributes += ' ' + i + '="' + style + '"';
                        } else if (i in flags) {
                            attributes += ' ' + i;
                        } else {
                            if (i == 'value' && attr == null) attr = '';
                            attributes += ' ' + i + '="' + attr + '"';
                        }
                    }
                    element = $(document.createElement("<" + obj.tag + attributes + ">"));
                } else {
                    for (var i in obj.attributes) {
                        var attr = obj.attributes[i];
                        if (i == 'style') {
                            var style = '';
                            for (var j in attr) {
                                style += j + ": " + attr[j] + "; ";
                            }
                            element.setAttribute(i, style);
                        } else {
                            element.setAttribute(i, attr);
                        }
                    }
                }
            }
            if (obj.text) {
                element.appendChild(obj.text.createTextNode());
            }
            if (before_el) {
                paren.insertBefore(element, before_el);
            } else {
                paren.appendChild(element);
            }
            if (obj.children) {
                for (var i = 0; i < obj.children.length; i++) {
                    IWL.createHtmlElement(obj.children[i], element);
                }
            }

            if (obj.tailObjects) {
                for (var i = 0; i < obj.tailObjects.length; i++) {
                    IWL.createHtmlElement(obj.tailObjects[i], paren);
                }
            }

            return element;
        }
    };
})());

Object.extend(IWL, (function() {
    var disabled_view_cnt = 0;

    return {
        /**
         * Used for the purpose of faking a 'busy' screen
         * @param options A options hash. The following keys are recognised:
         * 	noCover: boolean (default: true). True if the screen should be covered
         * 	opacity: number (default: 0.8). The opacity of the covering element
         * */
        disableView: function() {
            var options = Object.extend({
                fullCover: false,
                noCover: false,
                opacity: 0.8 
            }, arguments[0] || {});
            disabled_view_cnt++;

            if (disabled_view_cnt == 1) {
                document.body.setStyle({cursor: 'wait'});
                if (options.noCover) return;

                var rail = new Element('div', {id: "disabled_view_rail",
                            className: "disabled_view_rail", style: 'visibility: hidden'});
                if (options.fullCover) {
                    var page_dims = document.viewport.getDimensions();
                    var container = new Element('div', {id: "disabled_view",
                                className: "disabled_view", style: 'visibility: hidden'});

                    container.addClassName('full_cover');
                    container.setStyle({
                        height: page_dims.height + 'px',
                        width: page_dims.width + 'px'
                    });
                    if (options.opacity < 1.0)
                        container.setOpacity(options.opacity);
                    document.body.appendChild(container);
                    container.setStyle({visibility: 'visible'});
                    Event.signalConnect(window, 'resize', function() {
                        var page_dims = document.viewport.getDimensions();
                        container.setStyle({
                            height: page_dims.height + 'px',
                            width: page_dims.width + 'px'
                        });
                    }.bind(this));
                } else {
                    if (options.opacity < 1.0)
                        rail.setOpacity(options.opacity);
                }
                document.body.appendChild(rail);
                rail.positionAtCenter();
                rail.setStyle({visibility: 'visible'});
            }
        },
        /**
         * Restores the screen after it was disabled
         * @see IWL.disableView
         * */
        enableView: function() {
            disabled_view_cnt--;
            if (disabled_view_cnt <= 0) {
                document.body.setStyle({cursor: ''});
                disabled_view_cnt = 0;

                var rail = $('disabled_view_rail');
                if (!rail) return;
                rail.remove();
                var container = $('disabled_view');
                if (container)
                    container.remove();
            }
        }
    };
})());

Object.extend(IWL, (function() {
    var display_status_cnt = 0;
    var appear;

    return {
        /**
         * Shows a message in an animated status bar at the bottom of the screen
         * @param {String} text The text to be displayed
         * */
        displayStatus: function(text) {
            var options = Object.extend({
                duration: 10
            }, arguments[1]);
            if (display_status_cnt++) {
                var status_bar = $('status_bar');
                if (!status_bar) {
                    display_status_cnt = 0;
                    IWL.displayStatus(text);
                    return;
                }
                status_bar.appendChild(new Element('br'));
                status_bar.appendChild(text.createTextNode());
            } else {
                var status_bar = new Element('div', {id: 'status_bar'});
                Element.hide(status_bar);
                status_bar.appendChild(text.createTextNode());
                appear = Effect.Appear(status_bar, {duration: 0.2});
                document.body.appendChild(status_bar);
                status_bar.signalConnect('click', IWL.removeStatus);
            }
            if (options.duration)
                IWL.removeStatus.delay(options.duration);
        },
        removeStatus: function() {
            var status_bar = $('status_bar');
            if (!status_bar) return;
            if (display_status_cnt >= 2) {
                status_bar.removeChild(status_bar.firstChild);
                status_bar.removeChild(status_bar.firstChild);
            }
            if (display_status_cnt-- <= 1) {
                if (appear) {
                    appear.cancel();
                    appear = null;
                }
                Effect.Fade(status_bar, {duration: 1, afterFinish: function() {
                        if (status_bar.parentNode)
                            status_bar.remove();
                    }});
            }
        }
    };
})());

/**
 * The exceptionHandler used when AJAX calls throw an error
 * @param 0 unused
 * @param error The error being thrown
 * */
function exceptionHandler () {
    IWL.enableView();
    if (window.console) {
	console.dir(arguments[1]);
    } else {
	IWL.displayStatus("Error message: " + arguments[1].message);
	IWL.displayStatus(arguments[1].number & 0xFFFF);
	IWL.displayStatus(arguments[1].name);
    }
}

function removeSelection() {
    if (window.getSelection) {
	var sel = window.getSelection();
        sel.removeAllRanges();
    } else if (document.selection) {
	try {
	    document.selection.empty();
	} catch(e) {
	}
    }
}

function keyLogEvent(element, callback) {
    if (Prototype.Browser.IE)
        Event.signalConnect(document.body, 'keydown', function (event) {
            if (focused_widget != element.id)
                return;
            callback(event);
        });
    else
	Event.signalConnect(window, 'keypress', function (event) {
            if (focused_widget != element.id)
                return;
            callback(event);
        });
}

function registerFocus(element) {
    Event.signalConnect(element, 'mouseenter', function() {
        focused_widget = element.id});
    Event.signalConnect(element, 'click', function() {
        focused_widget = element.id});
}

function loseFocus(e) {
    if (!Event.checkElement(e, focused_widget))
	focused_widget = null;
}

var browser_css = function() {
    var b = Prototype.Browser;
    var class_name = b.IE7 ? 'ie7' :
		  b.IE     ? 'ie' :
		  b.Opera  ? 'opera' :
		  b.KHTML  ? 'khtml' :
		  b.WebKit ? 'webkit' :
		  b.Gecko  ? 'gecko' : 'other';
    var h = $(document.getElementsByTagName('html')[0]);
    h.addClassName(class_name);
}();

/* Deprecated */
var Widget = IWL.Widget;
var createHtmlElement = IWL.createHtmlElement;
var disableView = IWL.disableView;
var enableView = IWL.enableView;
var displayStatus = IWL.displayStatus;
var displayStatusRemove = IWL.removeStatus;
var checkElementValue = Element.checkElementValue;
var IWLRPC = IWL.RPC;
var IWLConfig = IWL.Config;

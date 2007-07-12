// vim: set autoindent shiftwidth=4 tabstop=8:
// ie4 - defined if browser is IE4+ compatible
// ns6 - defined if browser is Netscape 6/Gecko compatible
var focused_widget = null;
var ie4 = document.all && !window.opera ? true : false;
var ie7 = ie4 && window.XMLHttpRequest ? true : false;
var opera = !!window.opera;
var ns6 = document.getElementById && !document.all ? true : false;

var loaded = false;
Event.signalConnect(window, "load", function () {
	loaded = true;
	Event.signalConnect(document.body, "click", loseFocus);
});

/**
 * @class Widget is the base class for all IWL widgets
 *
 * @method create The 'constructor' method
 * @param id The element to transform into a widget
 * @returns The created widget
 * */
var Widget = {};
Widget = {
    create: function(id) {
	this.current = $(id);
	if (this._pre_init)
	    if (!this._pre_init.apply(this, arguments)) return;
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

/**
 * Creates an html element from IWL's json structure
 * @param obj The json object
 * @param paren The parent element
 * @param before_el A reference element. If given, the created element will appear before this one. Optional
 *
 * @returns The created element or 'true', if the element is a text node
 * */
function createHtmlElement(obj, paren, before_el) {
    var element;
    var flags = {disabled: true, multiple: true};
    if (!obj) return;
    if (!paren) return;
    if (obj.scripts) {
	while (obj.scripts.length) {
	    var script = obj.scripts.shift();
	    if (!checkForExistingScript(script.attributes.src))
		createHtmlElement(script,
			document.getElementsByTagName('head')[0]);
	}
    }
    if (!obj.tag) {
	if (obj.text === undefined || obj.text === null) return false;
	if (paren.tagName.toLowerCase() == 'script') {
	    setTimeout(tryEval.bind(this, obj.text), 200);
	    return true;
	}
	if (ie4) {
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
	if ((ie4 && !obj.attributes) || !ie4)
	    element = $(document.createElement(obj.tag));
    }
    // setAttribute in Internet Explorer doesn't set style, class or any of the events. What the hell were they thinking?
    if (obj.attributes) {
	if (ie4) {
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
	    createHtmlElement(obj.children[i], element);
	}
    }

    if (obj.after_objects) {
	for (var i = 0; i < obj.after_objects.length; i++) {
	    createHtmlElement(obj.after_objects[i], paren);
	}
    }

    if (obj.js_exec) {
	for (var i = 0; i < obj.js_exec.length; i++) {
	    createHtmlElement(obj.js_exec[i], document.body);
	}
    }

    return element;
}

/**
 * Used for checking whether a script tag with the same source already exists
 * @param src The source of the script
 * @returns True if such a script exists
 * */
function checkForExistingScript(src) {
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
	if (scripts[i].src.match(src + "$"))
	    return true;
    }
    return false;
}

/* "Loading" message if there is object with id "disabled_view" in the page */

var disabled_view_cnt = 0;

/**
 * Used for the purpose of faking a 'busy' screen
 * @param options A options hash. The following keys are recognised:
 * 	noCover: boolean (default: true). True if the screen should be covered
 * 	opacity: number (default: 0.8). The opacity of the covering element
 * */
function disableView() {
    var options = Object.extend({
	noCover: false,
	opacity: 0.8 
    }, arguments[0] || {});
    disabled_view_cnt++;

    if (disabled_view_cnt == 1) {
	document.body.setStyle({cursor: 'wait'});
	if (options.noCover) return;

	var container = $(Builder.node('div', {id: "disabled_view",
		    className: "disabled_view", style: 'visibility: hidden'}));
	var rail = Builder.node('div', {"className": "disabled_view_rail"});
	if (options.opacity < 1.0)
	    container.setOpacity(options.opacity);
	container.appendChild(rail);
	document.body.appendChild(container);
	container.positionAtCenter();
	container.setStyle({visibility: 'visible'});
    }
}

/**
 * Restores the screen after it was disabled
 * @see enableView
 * */
function enableView() {
    disabled_view_cnt--;
    if (disabled_view_cnt <= 0) {
	document.body.setStyle({cursor: ''});
	disabled_view_cnt = 0;

	var container = $('disabled_view');
	if (!container) return;
	document.body.removeChild(container)
    }
}

function getKeyCode(event) {
    return event.keyCode ? event.keyCode :
	event.which ? event.which : event.charCode;
}

var display_status_cnt = 0;

/**
 * Shows a message in an animated status bar at the bottom of the screen
 * @param {String} text The text to be displayed
 * */
function displayStatus(text) {
    if (display_status_cnt++) {
        var status_bar = $('status_bar');
        status_bar.appendChild(Builder.node('br'));
        status_bar.appendChild(text.createTextNode());
    } else {
        var status_bar = Builder.node('div', {id: 'status_bar'});
        Element.hide(status_bar);
        status_bar.appendChild(text.createTextNode());
        Effect.Appear(status_bar);
        document.body.appendChild(status_bar);
        Event.observe(status_bar, 'click', displayStatusRemove);
    }
    setTimeout(displayStatusRemove, 10000);
}

function displayStatusRemove() {
    var status_bar = $('status_bar');
    if (!status_bar) return;
    if (display_status_cnt >= 2) {
        status_bar.removeChild(status_bar.firstChild);
        status_bar.removeChild(status_bar.firstChild);
    }
    if (display_status_cnt-- <= 1) {
        Effect.Fade(status_bar, {duration: 2,
            queue: {position: 'start', scope: 'status_queue'}});
        new Effect.Remove(status_bar, {
            queue: {position: 'end', scope: 'status_queue'}});
    }
}

/**
 * Checks whether the value of an element passes certain conditions
 * @param el The element, whose value will be checked.
 * @param options. An options hash. The following keys are recognised:
 * 	reg: regular expression. The value will be tried for a match.
 * 	passEmpty: boolean (default: false). If true, an empty value will return true
 * 	errorString: string. The value will be tried against this string
 * 	startColor: color string (default: #ff0000). The starting color of the blink
 * 	endColor: color string (default: #ffffff). The ending color of the blink
 * 	finishColor: color string (default: transparent). The color that will stay as a background of the element
 * 	deleteValue: boolean (default: false). Whether the value of the element should be deleted, if it doesn't pass the condition.
 * 	duration: number (0.5). The duration of the blink
 * */
function checkElementValue(el) {
    el = $(el);
    var options = Object.extend({
	reg: false,
	errorString: false,
	passEmpty: false, 
	startColor: '#ff0000',
	endColor: '#ffffff',
	finishColor: 'transparent',
	deleteValue: false,
	duration: 0.5
    }, arguments[1] || {});
    if (!el || (options.reg && !el.value.match(options.reg))
	|| (!options.passEmpty && el.value == "")
	|| (options.errorString && el.value == options.errorString)) {
	new Effect.Highlight(el, {
	    startcolor: options.startColor,
	    endcolor: options.endColor,
	    beforeStart: options.errorString ? function(effect) {
		effect.element.value = options.errorString;
	    } : null,
	    afterFinish: function(effect) {
		if (options.deleteValue)
		    effect.element.value = '';
		Element.setStyle(effect.element, {
		    backgroundColor: options.finishColor});
		effect.element.focus();
	    },
	    duration: options.duration
	});
	return false;
    }
    return true;
}

/**
 * The exceptionHandler used when AJAX calls throw an error
 * @param 0 unused
 * @param error The error being thrown
 * */
function exceptionHandler () {
    enableView();
    if (window.console) {
	console.dir(arguments[1]);
    } else {
	displayStatus("Error message: " + arguments[1].message);
	displayStatus(arguments[1].number & 0xFFFF);
	displayStatus(arguments[1].name);
    }
}

function removeSelectionFromNode(id) {
    if (window.getSelection) {
	var sel = window.getSelection();
	if (sel.containsNode($(id), true))
	    sel.removeAllRanges();
    } else if (document.selection) {
	try {
	    document.selection.empty();
	} catch(e) {
	}
    }
}

function keyLogEvent(callback) {
    if (ie4)
	Event.observe(document.body, 'keydown', callback);
    else
	Event.observe(window, 'keypress', callback);
}

function loseFocus(e) {
    if (!Event.checkElement(e, focused_widget))
	focused_widget = null;
}

function tryEval(text, total) {
    if (!total || total < 0) total = 0;
    try {
	eval(text);
    } catch (e) {
	setTimeout(function () {if (++total < 20) tryEval(text, total)}, 500);
    }
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

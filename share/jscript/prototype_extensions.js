// vim: set autoindent shiftwidth=2 tabstop=8:
Object.extend(Prototype.Browser, {
  KHTML: navigator.userAgent.indexOf('KHTML') > -1,
  IE7: !!(Prototype.Browser.IE && window.XMLHttpRequest)
});

var EventMethods = {
  // Checks if the element is in the current event stack
  checkElement: function(event, element) {
    element = $(element);
    var target = Event.element(event);
    try {
      while (target) {
	if (target == element)
	  return true;
	target = target.parentNode;
      }
    } catch (e) {return false;}
    return false;
  },
  getKeyCode: function(event) {
    return event.keyCode ? event.keyCode : event.which ? event.which : 0;
  }
};
Object.extend(Event.Methods, EventMethods);
Event.extend();
Object.extend(Event, EventMethods);

Object.extend(Event, (function() {
  Event.DOMEvents.push((Prototype.Browser.Gecko) ? 'DOMMouseScroll' : 'mousewheel');
  return {
    KEY_SPACE: 32,
    signalConnect: function(element, name, observer) {
      if (!element || !name || !observer) return;
      if (!element.signals) element.signals = {};
      if (!element.signals[name])
        element.signals[name] = {observers: [], callbacks: []};
      if (element.signals[name].observers.indexOf(observer) > -1) return Event;

      var custom = Event.custom[name];
      if (custom) {
        var real = custom.real;
        var callback = custom.callback ? custom.callback.bindAsEventListener(Event, element) : null;
        if (custom.connect) custom.connect.call(Event, element, observer);
      }

      element.signals[name].observers.push(observer);
      element.signals[name].callbacks.push(callback || observer);
      if ((real || name) != 'activate')
        Event.observe.call(Event, element, real || name, callback || observer);
      return Event;
    },
    signalDisconnect: function(element, name, observer) {
      if (!element || !element.signals || !element.signals[name]) return;
      var index = element.signals[name].observers.indexOf(observer);
      if (index == -1) return;

      var custom = Event.custom[name];
      if (custom && custom.real)
        var real = custom.real;

      element.signals[name].observers.splice(index, 1);
      var callback = element.signals[name].callbacks.splice(index, 1)[0];
      Event.stopObserving.call(Event, element, real || name, callback);
      return Event;
    },
    signalDisconnectAll: function(element, name) {
      if (!element || !element.signals || !element.signals[name]) return;
      var custom = Event.custom[name];
      if (custom)
        var real = custom.real;

      for (var i = 0, length = element.signals[name].observers.length; i < length; i++) {
        Event.stopObserving.call(this, element, real || name, element.signals[name].callbacks[i]);
      }
      element.signals[name] = {observers: [], callbacks: []};
      return Event;
    },
    emitSignal: function(element, name) {
      var args = $A(arguments);
      var element = args.shift();
      var name = args.shift();
      if (!element || !element.signals || !element.signals[name]) return;
      element.signals[name].observers.each(function ($_) {
        if (args)
          $_.apply(element, args);
        else
          $_.call(element);
      });
      return Event;
    },

    // This is more or less copied from mootools, changed to use prototype's functions, and with a few additions
    custom: {
      mouseenter: {
        real: 'mouseover',
        callback: function(event, element) {
          var target = event.relatedTarget || Event.relatedTarget(event);
          try { target.parentNode } catch(e) { target = null }
          if (!target || target == element || Element.descendantOf(target, element)) return;
          Event.emitSignal(element, 'mouseenter', event);
        }
      },
      mouseleave: {
        real: 'mouseout',
        callback: function(event, element) {
          var target = event.relatedTarget || Event.relatedTarget(event);
          try { target.parentNode } catch(e) { target = null }
          if (!target || target == element || Element.descendantOf(target, element)) return;
          Event.emitSignal(element, 'mouseleave', event);
        }
      },
      mousewheel: {
        real: (Prototype.Browser.Gecko) ? 'DOMMouseScroll' : 'mousewheel',
        callback: function(event, element) {
          if (event.detail)
            event.scrollDirection = event.detail;
          else if (event.wheelDelta)
            event.scrollDirection = event.wheelDelta / -40;
          Event.emitSignal(element, 'mousewheel', event);
        }
      }
    }
  };
})());

if (!window.IWLRPC) var IWLRPC = {};
Object.extend(IWLRPC, (function() {
  function eventStart(str) {
      return function(params) {
          eval(str);
      }
  }

  function eventCompletion(str) {
      return function(json, params, options) {
          eval(str);
      }
  }

  function eventFinalize (element, eventName, options) {
    if (options.disableView)
      enableView();
    element['handlers'][eventName].ajaxRequest = null
    if (options.emitOnce)
      delete element['handlers'][eventName];
  }

  return {
    registerEvent: function(element, eventName, url, originalParams, originalOptions) {
      if (!(element = $(element))) return;
      if (!('handlers' in element)) element['handlers'] = {};
      if (element['handlers'][eventName]) return;

      element['handlers'][eventName] = function() {
        var previousRequest = element['handlers'][eventName].ajaxRequest;
        if (previousRequest && previousRequest.transport) {
          previousRequest.transport.abort();
          element['handlers'][eventName].ajaxRequest = null;
        }

        var params = Object.extend(Object.extend({}, originalParams), arguments[0]);
        var options = Object.extend(Object.extend({}, originalOptions), arguments[1]);
        if (options.onStart)
          eventStart(options.onStart).call(element, params);
        var disable = options.disableView ? disableView.bind(element, options.disableView) : Prototype.emptyFunction;

        if ('update' in options) {
          var updatee = $(options.update) || document.body;
          options.update = true;
          options.evalScripts = !!options.evalScripts;
        }
        if (options.collectData) {
            options.elementData = element.getControlElementParams();
        }

        if (typeof options.update === 'undefined') {
          element['handlers'][eventName].ajaxRequest = new Ajax.Request(url, {
            onException: exceptionHandler,
            onLoading: disable,
            onComplete: function(or) {
              var json = or.responseJSON;
              if (!json) return;
              if (options.method && options.method in element) 
                element[options.method].call(element, json, params, options);
              if (options.responseCallback && typeof options.responseCallback === 'function') 
                options.responseCallback.call(element, json, params, options);
              if (options.onComplete) {
                var callback = eventCompletion(options.onComplete);
                callback.call(element, json, params, options);
              }
              eventFinalize(element, eventName, options);
            },
            parameters: {IWLEvent: Object.toJSON({eventName: eventName, params: params, options: options})}
          });
        } else {
          element['handlers'][eventName].ajaxRequest = new Ajax.Updater(updatee, url, {
            onException: exceptionHandler,
            onLoading: disable,
            onComplete: function(or) {
              if (options.responseCallback && typeof options.responseCallback === 'function') 
                options.responseCallback.call(element, {}, params, options);
              if (options.onComplete) {
                var callback = eventCompletion(options.onComplete);
                callback.call(element, {}, params, options);
              }
              eventFinalize(element, eventName, options);
            },
            insertion: options.insertion || false,
            evalScripts: options.evalScripts || false,
            parameters: {IWLEvent: Object.toJSON({eventName: eventName, params: params, options: options})}
          });
        }
      }
      return element;
    },
    prepareEvents: function(element) {
      if (!(element = $(element))) return;
      if (element.preparedEvents) return element;
      var events = element.readAttribute('iwl:RPCEvents');
      if (events) {
        events = unescape(events).evalJSON();
        for (var name in events)
          IWLRPC.registerEvent(element, name, events[name][0], events[name][1], events[name][2]);
        element.preparedEvents = true;
        return element;
      }
    },
    emitEvent: function(element, eventName, params, options) {
      if (!(element = $(element))) return;
      if (!('handlers' in element) || !(eventName in element['handlers'])) return;
      element['handlers'][eventName](params, options);
      return element;
    },
    hasEvent: function(element, eventName) {
      if (!(element = $(element))) return false;
      if (!('handlers' in element) || !(eventName in element['handlers'])) return false;
      return element['handlers'][eventName];
    }
  };
})());

var ElementMethods = {
  getText: function(element) {
    element = $(element);
    if (element.textContent)
	return element.textContent;
    else if (element.innerText)
	return element.innerText;
  },
  positionAtCenter: function(element, relative) {
    element = $(element);
    var dims = element.getDimensions();
    var page_dim = document.viewport.getDimensions();
    if (!relative)
      element.style.position = "absolute";
    element.style.left = (page_dim.width - dims.width)/2 + 'px';
    if ((page_dim.height - dims.height) < 0)
      element.style.top = '10px';
    else
      element.style.top = (page_dim.height - dims.height)/2 + 'px';
    return element;
  },
  getScrollDimensions: function(element) {
    element = $(element);
    var display = $(element).getStyle('display');
    if (display != 'none' && display != null)
      return {width: element.scrollWidth, height: element.scrollHeight};

    var els = element.style;
    var originalVisibility = els.visibility;
    var originalPosition = els.position;
    var originalDisplay = els.display;
    els.visibility = 'hidden';
    els.position = 'absolute';
    els.display = 'block';
    var originalWidth = element.scrollWidth;
    var originalHeight = element.scrollHeight;
    els.display = originalDisplay;
    els.position = originalPosition;
    els.visibility = originalVisibility;
    return {width: originalWidth, height: originalHeight};
  },

  getScrollableParent: function(element) {
    if (!(element = $(element))) return;
    do {
      var scroll = element.getScrollDimensions();
      var dims = element.getDimensions();
      if (dims.width != scroll.width || dims.height != scroll.height)
	break;
      element = element.up();
    } while (element);
    return element;
  },
  getControlElementParams: function(element) {
    if (!(element = $(element))) return;
    var params = new Hash;
    var sliders = element.getElementsBySelector('.slider');
    var selects = element.getElementsBySelector('select');
    var textareas = element.getElementsBySelector('textarea');
    var inputs = element.getElementsBySelector('input');

    var valid_name = function(e) {
      return e.hasAttribute('name') ? e.readAttribute('name') : e.readAttribute('id');
    };
    var push_values = function(name, value) {
      if (name === null || name == undefined || name == '')
        return;
      if (params.keys().include(name))
	params[name] = [params[name], value].flatten();
      else
	params[name] = value;
    };

    sliders.each(function(s) {
        if ('control' in s)
          push_values(valid_name(s), s.control.value);
      });
    selects.each(function(s) {
	push_values(valid_name(s), s.value);
      });
    textareas.each(function(t) {
	push_values(valid_name(t), t.value);
      });
    inputs.each(function(i) {
	switch(i.type) {
	case 'text':
	case 'password':
	case 'hidden':
	  push_values(valid_name(i), i.value);
	  break;
	case 'checkbox':
	case 'radio':
	  if (i.checked)
	    push_values(valid_name(i), i.value);
	  break;
	}
      });

    if (!params.keys().length && (element.value || element.hasAttribute('value')))
      push_values(valid_name(element), element.value || element.readAttribute('value'));

    return params;
  },
  /* = IWL RPC ======================================*/
  registerEvent: function(element, eventName, url, params, options) {
    IWLRPC.registerEvent.apply(Event, arguments);
    return $A(arguments).first();        
  },
  prepareEvents: function(element) {
    IWLRPC.prepareEvents.apply(Event, arguments);
    return $A(arguments).first();       
  },
  emitEvent: function(element, eventName, params, options) {
    IWLRPC.emitEvent.apply(Event, arguments);
    return $A(arguments).first();  
  },
  hasEvent: function(element, eventName) {
    return IWLRPC.hasEvent.apply(Event, arguments);
  },
  /*==================================================*/

  signalConnect: function() {
    Event.signalConnect.apply(Event, arguments);
    return $A(arguments).first();
  },
  signalDisconnect: function() {
    Event.signalDisconnect.apply(Event, arguments);
    return $A(arguments).first();
  },
  signalDisconnectAll: function() {
    Event.signalDisconnectAll.apply(Event, arguments);
    return $A(arguments).first();
  },
  emitSignal: function() {
    Event.emitSignal.apply(Event, arguments);
    return $A(arguments).first();
  }
};
Element.addMethods(ElementMethods);
Object.extend(Element, ElementMethods);

Object.extend(String.prototype, {
  createTextNode: function() {
    if (this == "")
      return document.createTextNode(this);
    var div = document.createElement('div');
    div.innerHTML = this.stripTags();
    return div.firstChild;
  },
  evalScripts: function() {
    var head = document.getElementsByTagName('head')[0];
    var matchAll = new RegExp(Prototype.ScriptFragment, 'img');
    var source = new RegExp('<script[^>]*?src=["\'](.*?)["\'][^>]*?><\/script>', 'im');
    var result = this.extractScripts().map(function(script) { return eval(script) });
    result.push((this.match(matchAll) || []).map(function(scriptTag) {
      var match = scriptTag.match(source);
      if (match && match[1])
        return head.appendChild(new Element('script', {src: match[1], type: 'text/javascript'}));
    }));
    return result;
  }
});

var PeriodicalAccelerator = Class.create((function () {
  function onTimerEvent() {
    if (!this.callback) return;
    this.callback(this);
    if (this.frequency > this.options.border) {
      this.frequency /= this.acceleration;
      if (this.frequency < this.options.border)
        this.frequency = this.options.border;
    }
    this.timer = setTimeout(onTimerEvent.bind(this), this.frequency * 1000);
  }

  return {
    initialize: function(callback) {
      this.options = Object.extend({
        frequency: 1,
        acceleration: 0.1,
        border: 0.01
      }, arguments[1] || {});
      this.callback = callback;
      this.frequency = this.options.frequency;
      this.acceleration = this.options.acceleration + 1;
      if (this.acceleration <= 0)
        this.acceleration = 1;
      this.registerCallback();
    },

    registerCallback: function() {
      this.timer = setTimeout(onTimerEvent.bind(this), this.frequency * 1000);
    },

    stop: function() {
      if (typeof this.timer != 'number') return;
      clearTimeout(this.timer);
      this.timer = null;
      this.callback = null;
    }
  }
})());

function $(element) {
  if (arguments.length > 1) {
    for (var i = 0, elements = [], length = arguments.length; i < length; i++)
      elements.push($(arguments[i]));
    return elements;
  }
  var type = typeof element;
  if (type == 'string' || type == 'number')
    element = document.getElementById(element);
  return Element.extend(element);
}

Object.extend(Date.prototype, {
  isLeapYear: function() {
    var year = this.getFullYear();
    return !!((year & 3) == 0 && (year % 100 || (year % 400 == 0 && year)));
  },
  incrementYear: function(amount) {
    var ret = new Date(this.getTime());
    ret.setFullYear(ret.getFullYear() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementYear: function(amount) {
    var ret = new Date(this.getTime());
    ret.setFullYear(ret.getFullYear() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementMonth: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMonth(ret.getMonth() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementMonth: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMonth(ret.getMonth() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementDate: function(amount) {
    var ret = new Date(this.getTime());
    ret.setDate(ret.getDate() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementDate: function(amount) {
    var ret = new Date(this.getTime());
    ret.setDate(ret.getDate() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementHours: function(amount) {
    var ret = new Date(this.getTime());
    ret.setHours(ret.getHours() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementHours: function(amount) {
    var ret = new Date(this.getTime());
    ret.setHours(ret.getHours() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementMinutes: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMinutes(ret.getMinutes() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementMinutes: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMinutes(ret.getMinutes() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementSeconds: function(amount) {
    var ret = new Date(this.getTime());
    ret.setSeconds(ret.getSeconds() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementSeconds: function(amount) {
    var ret = new Date(this.getTime());
    ret.setSeconds(ret.getSeconds() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  incrementMilliseconds: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMilliseconds(ret.getMilliseconds() + (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  decrementMilliseconds: function(amount) {
    var ret = new Date(this.getTime());
    ret.setMilliseconds(ret.getMilliseconds() - (amount || 1));
    this.setTime(ret.getTime());
    return this;
  },
  getCentury: function() {
    return Math.floor(this.getFullYear() / 100);
  },
  getWeek: function() {
    var now = new Date(this.getTime());
    var first = new Date(this.getFullYear(), 0, 1);
    var compensation = first.getDay();

    now.incrementDate();

    if (compensation > 4) compensation -= 4;
    else compensation += 3;

    return Math.round((((now.getTime() - first.getTime()) / 86400000)
        + compensation)/7);
  },
  getDayOfYear: function() {
    var cumulative = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var ret = this.getDate() + cumulative[this.getMonth()];

    return this.isLeapYear() && ret > 59 && this.getMonth() > 1 ? ++ret : ret;
  },
  getTimezoneName: function() {
    var string = this.toString();
    if (Prototype.Browser.Gecko) {
      var zone_name = string.match(/\((\w+)\)$/);
      if (zone_name && zone_name[1]) return zone_name[1];
    } else if (Prototype.Browser.IE) {
      var zone_name = string.split(/ /);
      if (zone_name && zone_name[4]) return zone_name[4];
    } else {
      var offset = (this.getTimezoneOffset() / -60) * 100;
      return "GMT+" + (offset < 1000 ? '0' + offset : offset);
    }
  }
});

document.insertScript = (function () {
  var scripts = null;

  return function(url) {
    var options = Object.extend({
      onComplete: Prototype.emptyFunction,
      skipCache: false
    }, arguments[1]);
    if (options.skipCache) {
      var query = $H({_: Math.random()});
      var index = url.indexOf('?');
      if (index != -1) {
        query.merge(url.substr(index).toQueryParams());
        url = url.substr(0, index);
      }
      url += '?' + query.toQueryString();
    }
    if (!scripts) scripts = $$('script').pluck('src');
    if (scripts.grep(url + "$").length) return;
    scripts.push(url);

    var script = new Element('script', {type: 'text/javascript', charset: 'utf-8', defer: true});
    var alreadyFired = false;
    var stateChangedCallback = function() {
      if (script.readyState && script.readyState != 'loaded' &&
          script.readyState != 'complete')
        return;
      if (alreadyFired) return;
      script.onreadystatechange = script.onload = null;
      if (options.onComplete) options.onComplete(url);
      alreadyFired = true;
    };

    script.onload = script.onreadystatechange = stateChangedCallback;
    script.src = url;

    document.getElementsByTagName('head').item(0).appendChild(script);

    if (Prototype.Browser.WebKit && options.onComplete) {
      var version = navigator.appVersion.match(/Version\/(\d+)(?:[\d\.]*)/);
      if (version[1] >= 3) return;
      var iframe = new Element('iframe', {style: "display: none;", src: url});
      document.getElementsByTagName('body').item(0).appendChild(iframe);

      iframe.onload = function() {
        stateChangedCallback();
        iframe.remove();
      }
    }
  }
})();

/* Abort works correctly in 1.6
// Overload this, for aborting the request
Object.extend(Ajax.Request.prototype, {
  respondToReadyState: function(readyState) {
    var state = Ajax.Request.Events[readyState];
    var transport = this.transport, json = this.evalJSON();
    var aborted = false;

    if (state == 'Complete') {
      try {
	// raise an exception when transport is abort()ed
	if (transport.status) 1;
      } catch (e) {
	aborted = true;
      }
    }

    if (state == 'Complete' && !aborted) {
      try {
        this._complete = true;
        (this.options['on' + this.transport.status]
         || this.options['on' + (this.success() ? 'Success' : 'Failure')]
         || Prototype.emptyFunction)(transport, json);
      } catch (e) {
        this.dispatchException(e);
      }

      var contentType = this.getHeader('Content-type');
      if (contentType && contentType.strip().
        match(/^(text|application)\/(x-)?(java|ecma)script(;.*)?$/i))
          this.evalResponse();
    }

    try {
      (this.options['on' + state] || Prototype.emptyFunction)(transport, json);
      Ajax.Responders.dispatch('on' + state, this, transport, json);
    } catch (e) {
      this.dispatchException(e);
    }

    if (state == 'Complete' && !aborted) {
      // avoid memory leak in MSIE: clean up
      this.transport.onreadystatechange = Prototype.emptyFunction;
    }
  }
});
*/

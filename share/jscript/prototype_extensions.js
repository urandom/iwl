// vim: set autoindent shiftwidth=2 tabstop=8:
Object.extend(Prototype.Browser, {
  KHTML: navigator.userAgent.indexOf('KHTML') > -1,
  IE7: !!(Prototype.Browser.IE && window.XMLHttpRequest)
});

(function() {
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
})();

Object.extend(Event, (function() {
  function callbackWrapper(observer) {
    return function(event) {
      var args = event.memo
        ? [event].concat(Object.isArray(event.memo) ? event.memo : [event.memo])
        : [event];
      observer.apply(this, args);
    }
  }

  function getEventID(element) {
    if (element._eventID) return element._eventID;
    arguments.callee.id = arguments.callee.id || 1;
    return element._eventID = ++arguments.callee.id;
  }

  function registerCallback(element, name, callback, observer) {
    var index;
    var c = getCacheForName(element, name);
    if ((index = c.pluck('observer').indexOf(observer)) > -1) return c[index];

    c.push(callback);
    callback.observer = observer;
    return false;
  }

  function getCacheForName(element, name) {
    var id = getEventID(element);
    cache[id] = cache[id] || {};
    return cache[id][name] = cache[id][name] || [];
  }

  function destroyCache() {
    for (var id in cache)
      for (var eventName in cache[id])
        cache[id][eventName] = null;
  }

  var cache = {};

  var customEvents = {
    'dom:mouseenter': {
      real: 'mouseover',
      callback: function(event, element, callback) {
        var target = event.relatedTarget || Event.relatedTarget(event);
        try { target.parentNode } catch(e) { target = null }
        if (!target || target == element || Element.descendantOf(target, element)) return;
        callback.call(target, event)
      }
    },
    'dom:mouseleave': {
      real: 'mouseout',
      callback: function(event, element, callback) {
        var target = event.relatedTarget || Event.relatedTarget(event);
        try { target.parentNode } catch(e) { target = null }
        if (!target || target == element || Element.descendantOf(target, element)) return;
        callback.call(target, event)
      }
    },
    'dom:mousewheel': {
      real: (Prototype.Browser.Gecko) ? 'DOMMouseScroll' : 'mousewheel',
      callback: function(event, element, callback) {
        if (event.detail)
          event.scrollDirection = event.detail;
        else if (event.wheelDelta)
          event.scrollDirection = event.wheelDelta / -40;
        callback.call(element, event)
      }
    }
  };

  if (window.attachEvent) {
    window.attachEvent("onunload", destroyCache);
  }

  return {
    KEY_SPACE: 32,
    signalConnect: function(element, name, observer) {
      if (!(element = $(element)) || !name || !observer) return;

      var callback = callbackWrapper(observer);
      var custom = customEvents[name];
      if (custom) {
        var real = custom.real;
        callback = custom.callback ? custom.callback.bindAsEventListener(Event, element, callback) : null;
      }
      if (registerCallback(element, real || name, callback, observer))
        return element;

      return Event.observe(element, real || name, callback);
    },
    signalDisconnect: function(element, name, observer) {
      if (!(element = $(element))) return;

      if (!observer && name) {
        var custom = customEvents[name];
        if (custom && custom.real)
          name = custom.real;

        var id = getEventID(element);
        cache[id] = cache[id] || {};
        cache[id][name] = [];
        return Event.stopObserving(element, name);
      } else if (!name) {
        var id = getEventID(element);
        cache[id] = {};
        return Event.stopObserving(element);
      }

      var custom = customEvents[name];
      var real = custom && custom.real ? custom.real : name;
      var c = getCacheForName(element, real);
      var index;
      if ((index = c.pluck('observer').indexOf(observer)) == -1) return element;
      var callback = c[index];
      c = c.without(callback);
      return Event.stopObserving(element, real, callback);
    },
    signalDisconnectAll: function(element, name) {
      return Event.signalDisconnect(element, name);
    },
    emitSignal: function(element, name) {
      if (!(element = $(element)) || !name) return;

      var args = $A(arguments);
      var element = args.shift();
      var name = args.shift();
      return Event.fire(element, name, args);
    }
  };
})());

(function() {
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
      var sliders = element.select('.slider');
      var selects = element.select('select');
      var textareas = element.select('textarea');
      var inputs = element.select('input');

      var valid_name = function(e) {
        return e.hasAttribute('name') ? e.readAttribute('name') : e.readAttribute('id');
      };
      var push_values = function(name, value) {
        if (name === null || name == undefined || name == '')
          return;
        if (params.keys().include(name))
          params.set(name, [params[name], value].flatten());
        else
          params.set(name, value);
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
    /**
     * Checks whether the value of an element passes certain conditions
     * @param element The element, whose value will be checked.
     * @param options. An options hash. The following keys are recognised:
     * 	reg: regular expression. The value will be tried for a match.
     * 	range: An ObjectRange. The method will return true if the value of the element is within the range
     * 	passEmpty: boolean (default: false). If true, an empty value will return true
     * 	errorString: string. The value will be tried against this string
     * 	startColor: color string (default: #ff0000). The starting color of the blink
     * 	endColor: color string (default: #ffffff). The ending color of the blink
     * 	finishColor: color string (default: transparent). The color that will stay as a background of the element
     * 	deleteValue: boolean (default: false). Whether the value of the element should be deleted, if it doesn't pass the condition.
     * 	duration: number (0.5). The duration of the blink
     * 	flash: if true, the element flashes, without being otherwise checked
     * */
    checkValue: function(element) {
      if (!(element = $(element))) return false;
      var options = Object.extend({
        reg: false,
        range: false,
        errorString: false,
        passEmpty: false, 
        startColor: '#ff0000',
        endColor: '#ffffff',
        finishColor: 'transparent',
        deleteValue: false,
        duration: 0.5,
        flash: false
      }, arguments[1] || {});
    if ((options.reg.test && !options.reg.test(element.value))
        || (options.range.include && !options.range.include(element.value))
        || (!options.passEmpty && element.value == "")
        || (options.errorString && element.value == options.errorString)
        || (options.flash)
      ) {
        new Effect.Highlight(element, {
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
            try { effect.element.focus(); } catch(e) {};
          },
          duration: options.duration
        });
        return false;
      }
      return true;
    },
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
})();

Object.extend(Function.prototype, {
  bindAsEventListener: function() {
    var __method = this, args = $A(arguments), object = args.shift();
    return function(event) {
      var inner_args = $A(arguments);
      inner_args.shift();
      return __method.apply(object, [event || window.event].concat(args, inner_args));
    }
  }
});

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

  function registerCallback() {
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
      registerCallback.call(this);
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

if (Prototype.Browser.IE)
  (function() {
    var element = this.Element;
    this.Element = function(tagName, attributes) {
      attributes = attributes || { };
      tagName = tagName.toLowerCase();
      var cache = Element.cache;
      if (Prototype.Browser.IE) {
        var conflicts = $H(attributes).keys().grep(/(?:name|on\w+)/);
        if (conflicts.length) {
          var attributeString = '';
          conflicts.each(function (key) {
              if (typeof attributes[key] == 'string') {
                attributeString += key + '="' + attributes[key] + '"';
                delete attributes[key];
              }
            });
          tagName = '<' + tagName + ' ' + attributeString + '>';
          return Element.writeAttribute(document.createElement(tagName), attributes);
        }
      }
      if (!cache[tagName]) cache[tagName] = Element.extend(document.createElement(tagName));
      return Element.writeAttribute(cache[tagName].cloneNode(false), attributes);
    };
    Object.extend(this.Element, element || { });
  }).call(window);

Object.extend(document.viewport, {
  getMaxDimensions: function() {
    var width = Prototype.Browser.WebKit ? document.body.scrollWidth : document.documentElement.scrollWidth;
    var height = Prototype.Browser.WebKit ? document.body.scrollHeight : document.documentElement.scrollHeight;
    return Object.extend([width, height], {width: width, height: height});
  },
  getMaxWidth: function() {
    return this.getMaxDimensions().width;
  },
  getMaxHeight: function() {
    return this.getMaxDimensions().height;
  }
});

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

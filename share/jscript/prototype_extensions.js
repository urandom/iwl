// vim: set autoindent shiftwidth=2 tabstop=8:
Object.extend(Prototype.Browser, {
  KHTML: navigator.userAgent.indexOf('KHTML') > -1 && !Prototype.Browser.WebKit,
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
        try { target && target.parentNode } catch(e) { target = null }
        if (!target || target == element || Element.descendantOf(target, element)) return;
        callback.call(target, event)
      }
    },
    'dom:mouseleave': {
      real: 'mouseout',
      callback: function(event, element, callback) {
        var target = event.relatedTarget || Event.relatedTarget(event);
        try { target && target.parentNode } catch(e) { target = null }
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
        return element.innerText.replace(/\r\n/, "");
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
     * @param options. An options object. The following keys are recognised:
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
  parseInt: function() {
    return parseInt(this);
  },
  parseFloat: function() {
    return parseFloat(this);
  }
});

Object.extend(Array.prototype, {
  slice: function(from, length) {
    var copy = this.clone();
    if (arguments.length == 1 && arguments[0] instanceof ObjectRange) {
      var range = arguments[0];
      from = range.start;
      if (from < 0 && range.end >= 0)
        return copy.splice(from, -1 * from).concat(copy.splice(0, range.end + 1));
      else if (from < 0 && range.end < 0)
        return copy.splice(from, range.end + 1 - from);
      else
        length = range.end + 1 - from;

    } else if (length === undefined)
      length = 1;
    return copy.splice(from, length);
  }
});

Object.extend(Object, {
  isObject: function(object) {
    return object && object.constructor === Object;
  },
  isBoolean: function(object) {
    return typeof object == "boolean";
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

  if (Prototype.Browser.WebKit || Prototype.Browser.KHTML)
    Prototype._helpers = [];

  return function(url) {
    var options = Object.extend({
      onComplete: Prototype.emptyFunction,
      skipCache: false,
      debug: false
    }, arguments[1]);
    if (!scripts) scripts = $$('script').pluck('src');
    if (scripts.grep(url + "$").length) {
      if (options.onComplete)
        options.onComplete.bind(window, url).delay(0.1);
      return;
    }
    scripts.push(url);
    if (options.skipCache) {
      var query = $H({_: (new Date).valueOf()});
      var index = url.indexOf('?');
      if (index != -1) {
        query.merge(url.substr(index).toQueryParams());
        url = url.substr(0, index);
      }
      url += '?' + query.toQueryString();
    }

    var script = new Element('script', {type: 'text/javascript', charset: 'utf-8'});
    var fired = false;
    var stateChangedCallback = function() {
      if (fired) return;
      if (script.readyState && script.readyState != 'loaded' &&
          script.readyState != 'complete')
        return;
      script.onreadystatechange = script.onload = null;
      if (options.onComplete) options.onComplete(url);
      if (!options.debug) script.remove();
      fired = true;
    };

    script.onload = script.onreadystatechange = stateChangedCallback;
    script.src = url;

    document.getElementsByTagName('head').item(0).appendChild(script);

    if ((Prototype.Browser.WebKit || Prototype.Browser.KHTML) && options.onComplete) {
      var helper = new Element('script', {type: 'text/javascript'});
      var index = Prototype._helpers.push({script: helper, callback: stateChangedCallback}) - 1;
      helper.update(
        'var helper = Prototype._helpers[' + index + '];helper.callback();' +
        'helper.script.remove.delay(0.1);Prototype._helpers[' + index + '] = undefined'
      );
      Element.extend(document.body).appendChild.bind(document.body, helper).delay(0.1);
    }
  }
})();

Object.extend(String.prototype, (function() {
  var urlCount     = 0;
  var codeSnippets = [];

  function evalSnippet() {
    if (--urlCount > 0) return;
    codeSnippets.each(function(code) {
      eval(code);
    });
    codeSnippets = [];
  }

  return {
    evalScripts: function() {
      var matchAll = new RegExp(Prototype.ScriptFragment, 'img');
      var source = new RegExp('<script[^>]*?src=["\'](.*?)["\'][^>]*?><\/script>', 'im');
      (this.match(matchAll) || []).map(function(scriptTag) {
        var match = scriptTag.match(source);
        if (match && match[1]) {
          ++urlCount;
          return document.insertScript(match[1], {onComplete: evalSnippet});
        }
      });
      this.extractScripts().each(function(script) {
        if (!script) return;
        if (urlCount)
          codeSnippets.push(script) 
        else
          eval(script);
      });
    }
  }
})());

if (Prototype.Browser.IE) {
  Object.extend(Element._attributeTranslations.write.names, {
      'cellspacing': 'cellSpacing',
      'cellpadding': 'cellPadding'
  });
}
if (Prototype.Browser.IE)
  (function() {
    var element = this.Element;
    this.Element = function(tagName, attributes) {
      attributes = attributes || { };
      tagName = tagName.toLowerCase();
      var cache = Element.cache;
      if (Prototype.Browser.IE) {
        var attributeString = '';
        for (var key in attributes) {
          if (typeof attributes[key] == 'string') {
            var name = key == 'className' ? 'class' : key == 'htmlFor' ? 'for' : key;
            attributeString += name + '="' + attributes[key] + '"';
            delete attributes[key];
          }
        }
        tagName = '<' + tagName + ' ' + attributeString + '>';
        return Element.writeAttribute(document.createElement(tagName), attributes);
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
  },
  getScrollbarSize: function() {
    var testDiv = document.body.appendChild(new Element('div',
        {style: "position: absolute; top: -1000px; left: -1000px; overflow: scroll; width: 50px; height: 50px"}));
    var size = (50 - testDiv.clientWidth) || (50 - testDiv.clientHeight);

    testDiv.remove();
    return size;
  }
});

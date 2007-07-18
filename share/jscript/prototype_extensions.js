// vim: set autoindent shiftwidth=2 tabstop=8:
Object.extend(Prototype.Browser, {
  KHTML: navigator.userAgent.indexOf('KHTML') > -1,
  IE7: !!(Prototype.Browser.IE && window.XMLHttpRequest)
});

Object.extend(Event, {
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

  /* IWL RPC ======================================= */
  registerEvent: function(element, eventName, url, params) {
    if (!(element = $(element))) return;
    if (!('handlers' in element)) element['handlers'] = {};
    if (element['handlers'][eventName]) return;
    element['handlers'][eventName] = function() {
      var previousRequest = element['handlers'][eventName].ajaxRequest;
      if (previousRequest && previousRequest.transport) {
	previousRequest.transport.abort();
	element['handlers'][eventName].ajaxRequest = null;
      }
      if (!('userData' in params))  params.userData = {};
      if (arguments[0] && arguments[0].userData) {
	Object.extend(params.userData, arguments[0].userData);
	delete arguments[0].userData;
      }
      Object.extend(params, arguments[0]);
      if (params.emitOnce) {
        if (this[eventName]._emitted) return;
        this[eventName]._emitted = true;
      }

      if (params.userData.onStart)
	eventStart(params.userData.onStart).call(element, params.userData);

      var disable = params.disableView ? disableView.bind(element, {}) : Prototype.emptyFunction;
      var enable = params.disableView ? enableView : Prototype.emptyFunction;
      var cgiParams = {};
      Object.extend(cgiParams, params).userData = {};
      Object.extend(cgiParams.userData, params.userData);
      ['onComplete', 'onStart'].each(function(n) {
              delete cgiParams.userData[n];
      });
      if (typeof params.update === 'undefined') {
	element['handlers'][eventName].ajaxRequest = new Ajax.Request(url, {
	  onException: exceptionHandler,
	  onLoading: disable,
	  onComplete: function(or) {
	    var json = (or.responseText || '{}').evalJSON();
	    if (params.method && params.method in element) 
	      element[params.method].call(element, json, params);
	    if (params.onComplete && typeof params.onComplete === 'function') 
	      params.onComplete.call(element, json, params);
	    if (params.userData.onComplete) {
	      var callback = eventCompletion(params.userData.onComplete);
	      callback.call(element, json, params.userData);
	    }
	    enable();
	    element['handlers'][eventName].ajaxRequest = null;
	  },
          parameters: {IWLEvent: Object.toJSON({eventName: eventName, params: cgiParams})}
	});
      } else {
	var onComplete = params.userData.onComplete ? function(or) {
	  if (params.onComplete && typeof params.onComplete === 'function') 
	    params.onComplete.call(element, {}, params);
	  var callback = eventCompletion(params.userData.onComplete);
	  callback.call(element, {}, params.userData);
	  enable();
	  element['handlers'][eventName].ajaxRequest = null;
	} : function() {
	  if (params.onComplete && typeof params.onComplete === 'function') 
	    params.onComplete.call(element, {}, params);
	  enable();
	  element['handlers'][eventName].ajaxRequest = null
	};
	element['handlers'][eventName].ajaxRequest = new Ajax.Updater(params.update, url, {
	  onException: exceptionHandler,
	  onLoading: disable,
	  onComplete: onComplete,
	  insertion: eval(params.insertion || false),
	  evalScripts: params.evalScripts || false,
          parameters: {IWLEvent: Object.toJSON({eventName: eventName, params: cgiParams})}
	});
      }
    }
    return Event;
  },
  prepareEvents: function(element) {
    if (!(element = $(element))) return;
    if (element.preparedEvents) return element;
    var events = element.readAttribute('iwl:RPCEvents');
    if (events) {
      events = unescape(events).evalJSON();
      for (var name in events)
	Event.registerEvent(element, name, events[name][0], events[name][1]);
      element.preparedEvents = true;
      return Event;
    }
  },
  emitEvent: function(element, eventName, params) {
    if (!(element = $(element))) return;
    if (!('handlers' in element) || !(eventName in element['handlers'])) return;
    element['handlers'][eventName](params);
    return Event;
  },
  /* ================================================ */
          
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
  relatedElement: function(event) {
    if (event.type == 'mouseover')
      return $(event.relatedTarget || event.fromElement);
    else if (event.type == 'mouseout')
      return $(event.relatedTarget || event.toElement);
  },

  // This is more or less copied from mootools, changed to use prototype's functions, and with a few additions
  custom: {
    mouseenter: {
      real: 'mouseover',
      callback: function(event, element) {
	var target = Event.relatedElement(event);
	if (target == element || Element.descendantOf(target, element)) return;
	Event.emitSignal(element, 'mouseenter', event);
      }
    },
    mouseleave: {
      real: 'mouseout',
      callback: function(event, element) {
	var target = Event.relatedElement(event);
	if (target == element || Element.descendantOf(target, element)) return;
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
    },
    domready: {
      connect: function(element, observer) {
	if (window.loaded) {
	  observer.call(element);
	}
	if (document.readyState && (Prototype.Browser.WebKit || Prototype.Browser.KHTML)) {
	  window.domreadytimer = setInterval(function() {
	    if (['loaded', 'complete'].include(document.readyState))
	      Event.custom.domready._callback(element);
	  }, 50);
	} else if (document.readyState && Prototype.Browser.IE) {
	  if (!$('iedomready')) {
	    var src = (window.location.protocol == 'https:') ? '://0' : 'javascript:void(0)';
	    document.write('<script id="iedomready" defer src="' + src + '"></script>');
	    $('iedomready').onreadystatechange = function() {
	      if (this.readyState == 'complete') Event.custom.domready._callback(element);
	    };
	  }
	} else {
	  Event.observe(window, 'load', Event.custom.domready._callback.bind(Event, element));
	  Event.observe(document, 'DOMContentLoaded', Event.custom.domready._callback.bind(Event, element));
	}
      },
      _callback: function(element) {
	if (window.loaded) return;
	window.loaded = true;
	clearInterval(window.domreadytimer);
	window.domreadytimer = null;
	Event.emitSignal(element, 'domready');
      }
    }
  }
});

Object.extend(Position, {
  scrollOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      if (element.tagName == 'HTML')
	break;
      valueT += element.scrollTop  || 0;
      valueL += element.scrollLeft || 0;
      element = element.parentNode;
    } while (element);
    return [valueL, valueT];
  }
});

var ElementMethods = {
  removeChildren: function(element) {
    element = $(element);
    while (element.firstChild) {
      element.removeChild(element.firstChild);
    }
    return element;
  },
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
    var page_dim = pageDimensions();
    if (!relative)
      element.style.position = "absolute";
    element.style.left = (page_dim.width - dims.width)/2 + 'px';
    if ((page_dim.height - dims.height) < 0)
      element.style.top = '10px';
    else
      element.style.top = (page_dim.height - dims.height)/2 + 'px';
    return element;
  },
  changeClassName: function(element, oldClassName, newClassName) {
    if (!(element = $(element))) return;
    Element.classNames(element).change(oldClassName, newClassName);
    return element;
  },
  getScrollableParent: function(element) {
    if (!(element = $(element))) return;
    do {
      var dims = element.getDimensions();
      var scroll = {width: element.scrollWidth, height: element.scrollHeight};
      if (dims.width != scroll.width || dims.height != scroll.height)
	break;
      element = element.up();
    } while (element);
    return element;
  },
  /* = IWL RPC ======================================*/
  registerEvent: function(element, eventName, url, params) {
    if (Event.registerEvent.apply(Event, arguments))
      return $A(arguments).first();        
  },
  prepareEvents: function(element) {
    if (Event.prepareEvents.apply(Event, arguments))
      return $A(arguments).first();       
  },
  emitEvent: function(element, eventName, params) {
    if (Event.emitEvent.apply(Event, arguments))
      return $A(arguments).first();  
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

Object.extend(Element.ClassNames.prototype, {
  change: function(oldClassName, newClassName) {
    this.set($A(this).map(function($_) {
      return oldClassName === $_ ? newClassName : $_;
    }).join(' '));
  }
});
Object.extend(String.prototype, {
  createTextNode: function() {
    if (this == "")
      return document.createTextNode(this);
    var div = document.createElement('div');
    div.innerHTML = this.stripTags();
    return div.firstChild;
  }
});

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

function pageDimensions() {
    var width, height;

    if ('innerWidth' in window && 'scrollMaxX' in window) {	// With scrolling
	width = window.innerWidth + window.scrollMaxX;
    } else if ('innerWidth' in document) {
	width = document.innerWidth;
    } else if ('scrollWidth' in document.documentElement) {	// With scrolling
	width = document.documentElement.scrollWidth;
    } else if ('clientWidth' in document.documentElement) {
	width = document.documentElement.clientWidth;
    } else if (document.body) {
	width = document.body.clientWidth;
    }
    if ('innerHeight' in window && 'scrollMaxY' in window) {	// With scrolling
	height = window.innerHeight + window.scrollMaxY;
    } else if ('innerHeight' in document) {
	height = document.innerHeight;
    } else if ('scrollHeight' in document.documentElement) {	// With scrolling
	height = document.documentElement.scrollHeight;
    } else if ('clientHeight' in document.documentElement) {
	height = document.documentElement.clientHeight;
    } else if (document.body) {
	height = document.body.clientHeight;
    }
    return {width: width, height: height};
}

function eventStart(str) {
    return function(params) {
	eval(str);
    }
}

function eventCompletion(str) {
    return function(json, params) {
	eval(str);
    }
}

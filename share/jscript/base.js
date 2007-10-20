// vim: set autoindent shiftwidth=4 tabstop=8:
var loaded = false;
document.loaded = false;

Event.signalConnect(window, "load", function () { loaded = true; });
Event.signalConnect(document, "dom:loaded", function() {
    document.loaded = true;
    Event.signalConnect(document.body, "click", IWL.Focus.loseFocusCallback);
});

if (!window.IWL) var IWL = {};
Object.extend(IWL, {RPC: (function() {
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
          IWL.enableView();
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
              var disable = options.disableView ? IWL.disableView.bind(element, options.disableView) : Prototype.emptyFunction;

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
                      onException: IWL.exceptionHandler,
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
                      onException: IWL.exceptionHandler,
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
                  IWL.RPC.registerEvent(element, name, events[name][0], events[name][1], events[name][2]);
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
})()});
(function() {
    var ElementMethods = {
        registerEvent: function(element, eventName, url, params, options) {
            IWL.RPC.registerEvent.apply(Event, arguments);
            return $A(arguments).first();        
        },
        prepareEvents: function(element) {
            IWL.RPC.prepareEvents.apply(Event, arguments);
            return $A(arguments).first();       
        },
        emitEvent: function(element, eventName, params, options) {
            IWL.RPC.emitEvent.apply(Event, arguments);
            return $A(arguments).first();  
        },
        hasEvent: function(element, eventName) {
            return IWL.RPC.hasEvent.apply(Event, arguments);
        }
    };
    Element.addMethods(ElementMethods);
    Object.extend(Element, ElementMethods);
})();

/**
 * @class IWL.Widget is the base class for all IWL widgets
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
                    if (paren.tagName.toLowerCase() == 'style') {
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
                var attributes = Object.extend({}, obj.attributes);
                if (attributes.style) {
                    var time = new Date;
                    var style = $H(attributes.style);
                    attributes.style = style.keys().map(function(key) {
                        return [key, style.get(key)].join(": ");
                    }).join('; ');
                }
                element = new Element(obj.tag, attributes);
            }

            if (obj.text)
                element.appendChild(obj.text.createTextNode());

            if (before_el)
                paren.insertBefore(element, before_el);
            else
                paren.appendChild(element);

            // Internet explorer throws an error if an element is appended to a noscript element
            if (obj.children && obj.tag != 'noscript')
                obj.children.each(function(c) {
                    IWL.createHtmlElement(c, element);
                });

            if (obj.tailObjects)
                obj.tailObjects.each(function(t) {
                    IWL.createHtmlElement(t, paren);
                });

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
                    document.body.appendChild(container);
                    if (options.opacity < 1.0)
                        container.setOpacity(options.opacity);
                    container.setStyle({visibility: 'visible'});
                    Event.signalConnect(window, 'resize', function() {
                        var page_dims = document.viewport.getDimensions();
                        container.setStyle({
                            height: page_dims.height + 'px',
                            width: page_dims.width + 'px'
                        });
                    }.bind(this));
                }
                document.body.appendChild(rail);
                if (!options.fullCover && options.opacity < 1.0)
                    rail.setOpacity(options.opacity);
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
    
    function hideStatus(options) {
        if (options.duration)
            IWL.removeStatus.delay(options.duration);
    }

    return {
        /**
         * Shows a message in an animated status bar at the bottom of the screen
         * @param {String} text The text to be displayed
         * */
        displayStatus: function(text) {
            var options = Object.extend({
                duration: 10
            }, arguments[1]);
            text = text.toString();
            if (display_status_cnt++) {
                var status_bar = $('status_bar');
                if (!status_bar) {
                    display_status_cnt = 0;
                    IWL.displayStatus(text);
                    return;
                }
                status_bar.appendChild(new Element('br'));
                status_bar.appendChild(text.createTextNode());
                hideStatus(options);
            } else {
                var status_bar = new Element('div', {id: 'status_bar'});
                Element.hide(status_bar);
                status_bar.appendChild(text.createTextNode());
                appear = Effect.Appear(status_bar,
                    {duration: 0.2, afterFinish: hideStatus.bind(this, options)});
                document.body.appendChild(status_bar);
                status_bar.signalConnect('click', IWL.removeStatus);
            }
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
 * The IWL.exceptionHandler used when AJAX calls throw an error
 * @param 0 unused
 * @param error The error being thrown
 * */
IWL.exceptionHandler = function() {
    IWL.enableView();
    if (window.console) {
	console.dir(arguments[1]);
    } else {
        debugger;
	IWL.displayStatus("Error message: " + arguments[1].message);
	IWL.displayStatus(arguments[1].number & 0xFFFF);
	IWL.displayStatus(arguments[1].name);
    }
};

IWL.removeSelection = function() {
    if (window.getSelection) {
	var sel = window.getSelection();
        sel.removeAllRanges();
    } else if (document.selection) {
	try {
	    document.selection.empty();
	} catch(e) {
	}
    }
};

Object.extend(IWL, {Focus: {
    current: null,
    register: function(element) {
        if (!(element = $(element))) return;
        element.signalConnect('dom:mouseenter', function() {
            IWL.Focus.current = element});
        element.signalConnect('click', function() {
            IWL.Focus.current = element});
    },
    loseFocusCallback: function(event) {
        if (!Event.checkElement(event, IWL.Focus.current))
            IWL.Focus.current = null;
    }
}});

IWL.keyLogger = function(element, callback) {
    if (!(element = $(element))) return Prototype.emptyFunction;
    var callbackWrapper = function(event) {
        if (IWL.Focus.current != element)
            return;
        callback(event);
    };

    if (Prototype.Browser.IE)
        Event.signalConnect(document.body, 'keydown', callbackWrapper);
    else
        Event.signalConnect(window, 'keypress', callbackWrapper);
};

(function() {
    var b = Prototype.Browser;
    var class_name = b.IE7    ? 'ie7' :
		     b.IE     ? 'ie' :
		     b.Opera  ? 'opera' :
		     b.WebKit ? 'webkit' :
		     b.KHTML  ? 'khtml' :
		     b.Gecko  ? 'gecko' : 'other';
    var h = $(document.getElementsByTagName('html')[0]);
    h.addClassName(class_name);
})();

/* Deprecated */
var createHtmlElement = IWL.createHtmlElement;
var disableView = IWL.disableView;
var enableView = IWL.enableView;
var displayStatus = IWL.displayStatus;
var displayStatusRemove = IWL.removeStatus;
var checkElementValue = Element.checkElementValue;
var IWLRPC = IWL.RPC;
var IWLConfig = IWL.Config;
var exceptionHandler = IWL.exceptionHandler;
var removeSelection = IWL.removeSelection;
var keyLogEvent = IWL.keyLogger;
var registerFocus = IWL.Focus.register;
var loseFocus = IWL.Focus.loseFocusCallback;
var focused_widget = IWL.Focus.current;
var Widget = IWL.Widget;

// vim: set autoindent shiftwidth=4 tabstop=8:
var loaded = false;
document.loaded = false;

Event.signalConnect(window, "load", function () { window.loaded = true; });
document.observe("dom:loaded", function() {
    Event.signalConnect(document.body, "click", IWL.Focus.loseFocusCallback);
});

if (!window.IWL) var IWL = {};
Object.extend(IWL, {RPC: (function() {
  function eventStart(str) {
      return function(params) {
          eval(str);
      };
  }

  function eventCompletion(str, err) {
      return function(json, params, options) {
          if (json.extras && json.extras.error)
              eval(err);
          else
              eval(str);
      };
  }

  function eventFinalize (element, eventName, options) {
      if (options.disableView)
          IWL.View.enable();
      element['handlers'][eventName].ajaxRequest = null;
      if (options.emitOnce)
          delete element['handlers'][eventName];
  }

  return {
      registerEvent: function(element, eventName, url, originalParams, originalOptions) {
          if (!(element = $(element))) return;
          if (!('handlers' in element)) element['handlers'] = {};
          if (element['handlers'][eventName]) return;

          element['handlers'][eventName] = function() {
              IWL.RPC.abortCurrentEvent(element, eventName);

              var params = Object.extend(Object.extend({}, originalParams), arguments[0]);
              var options = Object.extend(Object.extend({}, originalOptions), arguments[1]);

              if (options.onStart)
                  eventStart(options.onStart).call(element, params);
              if (Object.isFunction(options.startCallback))
                  options.startCallback.call(element, eventName, params, options);
              var disable = options.disableView ? IWL.View.disable.bind(element, options.disableView) : Prototype.emptyFunction;

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
                          if (Object.isFunction(element[options.method]))
                              element[options.method].call(element, json, params, options);
                          if (Object.isFunction(options.responseCallback))
                              options.responseCallback.call(element, json, params, options);
                          if (options.onComplete || options.onError) {
                              var callback = eventCompletion(options.onComplete, options.onError);
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
                          if (options.onComplete || options.onError) {
                              var callback = eventCompletion(options.onComplete, options.onError);
                              callback.call(element, {}, params, options);
                          }
                          eventFinalize(element, eventName, options);
                      },
                      insertion: options.insertion || false,
                      evalScripts: options.evalScripts || false,
                      parameters: {IWLEvent: Object.toJSON({eventName: eventName, params: params, options: options})}
                  });
              }
              Object.extend(element['handlers'][eventName], {
                  params: params,
                  options: options
              });
          };
          return element;
      },
      prepareEvents: function(element, handlers) {
          if (!(element = $(element))) return;
          if (element.preparedEvents) return element;
          if (!handlers) {
              handlers = element.readAttribute('iwl:RPCEvents');
              if (handlers)
                  handlers = unescape(handlers).evalJSON();
          }
          if (handlers) {
              for (var name in handlers)
                  IWL.RPC.registerEvent(element, name, handlers[name][0], handlers[name][1], handlers[name][2]);
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
      },
      abortCurrentEvent: function(element, eventName) {
          var event = element['handlers'][eventName];
          var request = event.ajaxRequest;
          if (request && request.transport) {
              request.transport.abort();
              element.emitSignal('iwl:event_abort', eventName, event.params, event.options);
              event.ajaxRequest = null;
          }
      }
  };
})()});

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
            this.current._init.apply(this.current, $A(arguments).slice(1));

        this.current.emitSignal('iwl:init');
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

    function evalScript () {
        if (--script_urls > 0) return;
        scripts.each(function(s) {
            eval(s);
        });
        scripts = [];
    }

    return {
        /**
         * Creates an html element from IWL's json structure
         * @param json The json object
         * @param parentElement The parent element. Optional
         * @param previousElement A reference element. If given, the created element will appear before this one. Optional
         *
         * @returns The created element
         * */
        createHtmlElement: function(json, parentElement, previousElement) {
            var element;
            var flags = {disabled: true, multiple: true};
            if (!json || !(parentElement == $(parentElement))) return;
            previousElement = $(previousElement);
            if (!json.tag) {
                if ((json.text === undefined || json.text === null) && !json.environment) return false;
                if (parentElement.tagName.toLowerCase() == 'script') {
                    if (script_urls)
                        scripts.push(json.text);
                    else
                        eval(json.text);
                    return json.text.toString().createTextNode();
                }
                if (Prototype.Browser.IE && parentElement.tagName.toLowerCase() == 'style') {
                    parentElement.styleSheet.cssText = json.text;
                    return json.text.toString().createTextNode();
                } else {
                    var textNode = json.text.toString().createTextNode();
                    if (previousElement)
                        parentElement.insertBefore(textNode, previousElement);
                    else
                        parentElement.appendChild(textNode);
                    return textNode;
                }
            } else if (json.tag == 'script' && json.attributes && json.attributes.src) {
                var url = json.attributes.src;
                ++script_urls;
                return document.insertScript(url,
                    {onComplete: evalScript, removeScriptElement: !IWL.Config.DEBUG, skipCache: IWL.Config.DEBUG});
            } else {
                var attributes = {};
		for (var attr in json.attributes) {
		    var value = json.attributes[attr];
		    if (Object.isString(value))
			value = value.unescapeHTML();
		    attributes[attr] = value;
		}
                if (attributes.style) {
                    var style = $H(attributes.style);
                    attributes.style = style.keys().map(function(key) {
                        return [key, style.get(key)].join(": ");
                    }).join('; ');
                }
                element = new Element(json.tag, attributes);
            }

            if (json.text)
                element.appendChild(json.text.createTextNode());

            if (previousElement)
                parentElement.insertBefore(element, previousElement);
            else
                parentElement.appendChild(element);

            // Internet explorer throws an error if an element is appended to a noscript element
            if (json.children && json.tag != 'noscript')
                json.children.each(function(c) {
                    IWL.createHtmlElement(c, element);
                });

            if (json.tailObjects)
                json.tailObjects.each(function(t) {
                    IWL.createHtmlElement(t, parentElement);
                });

            return element;
        }
    };
})());

Object.extend(IWL, (function() {
    var disabled_view_cnt = 0;

    return {View: {
        /**
         * Used for the purpose of faking a 'busy' screen
         * @param options A options hash. The following keys are recognised:
         * 	noCover: boolean (default: true). True if the screen should be covered
         * 	opacity: number (default: 0.8). The opacity of the covering element
         * */
        disable: function() {
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
                var element = $(options.element);
                if (options.fullCover) {
                    var page_dims = document.viewport.getMaxDimensions();
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
                        var page_dims = document.viewport.getMaxDimensions();
                        container.setStyle({
                            height: page_dims.height + 'px',
                            width: page_dims.width + 'px'
                        });
                    }.bind(this));
                } else if (element && element.parentNode) {
                    var dims = element.getDimensions();
                    var container = new Element('div', {id: "disabled_view",
                                className: "disabled_view", style: 'visibility: hidden'});
                    container.addClassName('element_cover');
                    container.setStyle({
                        height: dims.height + 'px',
                        width: dims.width + 'px'
                    });
                    element.insert({after: container});
                    if (options.opacity < 1.0)
                        container.setOpacity(options.opacity);

                    var offset = [0, 0];
                    if (Element.extend(element.parentNode).getStyle('position') != 'absolute') {
                        offset = element.positionedOffset();
                        container.style.left = offset[0] + 'px';
                        container.style.top = offset[1] + 'px';
                    }
                    rail.style.left = "-1000px";
                    container.insert({after: rail});
                    var rail_dims = rail.getDimensions();
                    if (rail_dims.height < dims.height) {
                        rail.setStyle({
                            top: (dims.height - rail_dims.height) / 2 + offset[0] + 'px',
                            left: (dims.width - rail_dims.width) / 2 + offset[1] + 'px'
                        });
                    } else rail.remove();
                    container.setStyle({visibility: 'visible'});
                }
                if (!element || !element.parentNode) {
                    document.body.appendChild(rail);
                    rail.positionAtCenter();
                }
                if (!options.fullCover && !options.element && options.opacity < 1.0)
                    rail.setOpacity(options.opacity);
                rail.setStyle({visibility: 'visible'});
            }
        },
        /**
         * Restores the screen after it was disabled
         * @see IWL.View.disable
         * */
        enable: function() {
            disabled_view_cnt--;
            if (disabled_view_cnt <= 0) {
                document.body.setStyle({cursor: ''});
                disabled_view_cnt = 0;

                var rail = $('disabled_view_rail');
                if (rail)
                    rail.remove();
                var container = $('disabled_view');
                if (container)
                    container.remove();
            }
        }
    }};
})());

Object.extend(IWL, (function() {
    var display_status_cnt = 0;
    var appear;

    function hideStatus(options) {
        if (options.duration)
            IWL.Status.remove.delay(options.duration);
    }

    return {Status: {
        /**
         * Shows a message in an animated status bar at the bottom of the screen
         * @param {String} text The text to be displayed
         * */
        display: function(text) {
            var options = Object.extend({
                duration: 10
            }, arguments[1]);
            if (display_status_cnt++) {
                var status_bar = $('status_bar');
                if (!status_bar) {
                    display_status_cnt = 0;
                    IWL.Status.display(text);
                    return;
                }
                status_bar.appendChild(new Element('div').update(text));
                hideStatus(options);
            } else {
                var status_bar = new Element('div', {id: 'status_bar'});
                Element.hide(status_bar);
                status_bar.appendChild(new Element('div').update(text));
                appear = Effect.Appear(status_bar,
                    {duration: 0.2, afterFinish: hideStatus.bind(this, options)});
                document.body.appendChild(status_bar);
                status_bar.signalConnect('click', IWL.Status.remove);
            }
        },
        remove: function() {
            var status_bar = $('status_bar');
            if (!status_bar) return;
            if (display_status_cnt >= 2) {
                if (status_bar.firstChild)
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
    }};
})());

/**
 * The IWL.exceptionHandler used when AJAX calls throw an error
 * @param 0 unused
 * @param error The error being thrown
 * */
IWL.exceptionHandler = function() {
    IWL.View.enable();
    var error = arguments[1];
    if (window.console) {
	console.dir(error);
    } else {
	IWL.Status.display("Error message: " + error.message);
	IWL.Status.display(error.number & 0xFFFF);
	IWL.Status.display(error.name);
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
        element.signalConnect('dom:mouseenter', IWL.Focus.gainFocusCallback.bind(this, element));
        element.signalConnect('click', IWL.Focus.gainFocusCallback.bind(this, element));
    },
    gainFocusCallback: function(element) {
        if (!(element = $(element))) return;
        IWL.Focus.current = element;
    },
    loseFocusCallback: function(event) {
        if (!Event.checkElement(event, IWL.Focus.current))
            IWL.Focus.current = null;
    }
}});

IWL.keyLogger = function(element, callback) {
    if (!(element = $(element))) return;
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
        },
        abortCurrentEvent: function(element, eventName) {
            return IWL.RPC.abortCurrentEvent.apply(Event, arguments);
        },
        createHtmlElement: function(element, json, previousElement) {
            return IWL.createHtmlElement(json, element, previousElement);
        },
        registerFocus: function(element) {
            IWL.Focus.register.apply(IWL.Focus, arguments);
            return element;
        },
        keyLogger: function(element, callback) {
            IWL.keyLogger.apply(IWL, arguments);
            return element;
        },
        disableView: function(element) {
            IWL.View.disable({element: element});
        },
        enableView: function(element) {
            IWL.View.enable();
        }
    };
    Element.addMethods(ElementMethods);
    Object.extend(Element, ElementMethods);
})();

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

Object.extend(document.viewport, {
    disable: IWL.View.disable,
    enable: IWL.View.enable
});

document.insertScript = (function () {
  if (!document._urlCache)
    document._urlCache = {};

  if (Prototype.Browser.WebKit || Prototype.Browser.KHTML)
    Prototype._helpers = [];

  return function(url) {
    if (!Object.isString(url) || url.blank());

    var options = Object.extend({
      onComplete: Prototype.emptyFunction,
      skipCache: false,
      removeScriptElement: true 
    }, arguments[1]);

    var scripts = $$('script').pluck('src');
    scripts.each(function(src) {
        var match = src.match(/IWLStaticURI=([^&]+)/);
        if (match && match[1]) {
            match[1].split(',').each(function(u) {
                document._urlCache[u] = true;
            });
        };
    });
    var complete = false;
    var match = url.match(/IWLStaticURI=([^&]+)/);
    if (match && match[1]) {
        var urls = match[1].split(',');
        urls.clone().each(function(u) {
            if (document._urlCache[u]) {
                urls = urls.without(u);
            } else {
                document._urlCache[u] = true;
            }
        });
        if (urls.length) {
            url = url.replace(/IWLStaticURI=[^&]+/, 'IWLStaticURI=' + urls.join(','))
        } else complete = true;
    }

    if (complete || document._urlCache[url] || scripts.invoke('endsWith', url).any()) {
      document._urlCache[url] = true;
      if (options.onComplete)
        options.onComplete.bind(window, url).delay(0.1);
      return;
    }

    document._urlCache[url] = true;
    if (options.skipCache) {
      var query = {_: (new Date).valueOf()};
      var index = url.indexOf('?');
      if (index != -1) {
        Object.extend(query, url.substr(index).toQueryParams());
        url = url.substr(0, index);
      }
      url += '?' + Object.toQueryString(query);
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
      if (!options.removeScriptElement) script.remove();
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


/* Deprecated */
var createHtmlElement = IWL.createHtmlElement;
var disableView = IWL.View.disable;
var enableView = IWL.View.enable;
var displayStatus = IWL.Status.display;
var displayStatusRemove = IWL.Status.remove;
var checkElementValue = Element.checkValue;
var IWLRPC = IWL.RPC;
var IWLConfig = IWL.Config;
var exceptionHandler = IWL.exceptionHandler;
var removeSelection = IWL.removeSelection;
var keyLogEvent = IWL.keyLogger;
var registerFocus = IWL.Focus.register;
var loseFocus = IWL.Focus.loseFocusCallback;
var focused_widget = IWL.Focus.current;
var Widget = IWL.Widget;
var getKeyCode = Event.getKeyCode;

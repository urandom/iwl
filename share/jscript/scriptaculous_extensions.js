Object.extend(Effect, {
  Bounce: function(element) {
    element = $(element);
    var options = Object.extend({
	x: 200,
	y: 0,
	duration: 1
    }, arguments[1] || {});
    var oldStyle = {
	top: element.getStyle('top'),
	left: element.getStyle('left') };
    var f1 = function(effect) {
	new Effect.Move(effect.element,
	    { x: -options.x, y: -options.y, duration: options.duration, afterFinishInternal: delay2}) 
    }
    var f2 = function(effect) {
	new Effect.Move(effect.element,
	    { x: options.x, y: options.y, duration: options.duration, afterFinishInternal: delay1}) 
    }
    var delay1 = function(effect) {
	setTimeout(function() {f1(effect)}, 400);
    }
    var delay2 = function(effect) {
	setTimeout(function() {f2(effect)}, 400);
    }
    return new Effect.Move(element, 
	  { x: options.x, y: options.y, duration: options.duration, afterFinishInternal: delay1});
  },
  SmoothScroll: function() {
    if (window.loaded || !window.smoothScroll) {
      $$('a[href^=#]:not([href=#])').each(function(element) {
	element.observe('click', function(event) {
	  var target = $(this.hash.substr(1))
	    || document.getElementsByName(this.hash.substr(1))[0];
	  if (target) {
	    new Effect.ScrollTo(target);
	    Event.stop(event);
	  }
	}.bindAsEventListener(element))
      })
      window.smoothScroll = true;
    } else {
      Event.observe(window, "load", function () {
	Effect.SmoothScroll();
      });
    }
  }
});

Effect.Remove = Class.create();
Object.extend(Object.extend(Effect.Remove.prototype, Effect.Base.prototype), {
  initialize: function(element) {
    this.element = $(element);
    if(!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({}, arguments[1] || {});
    this.start(options);
  },
  finish: function() {
    if (this.element.parentNode)
      this.element.parentNode.removeChild(this.element);
  }
});

if ('Resizer' in window) {
    Object.extend(Resizer.prototype, {
      eventDown: function(event) {
	if (this.options.contentbox) {
	  if (this.options.contentbox.current_pointe_position)
	    this.resize = true;
	  else
	    this.resize = false;
	} else {
	  this.resize = true;
	}
      }
    });
}

function $s(style) {
  var cssText = '', selector = style;
  $A(document.styleSheets).reverse().each(function(styleSheet) {
    if (styleSheet.cssRules) cssRules = styleSheet.cssRules;
    else if (styleSheet.rules) cssRules = styleSheet.rules;
    $A(cssRules).reverse().each(function(rule) {
      if (selector == rule.selectorText) {
	cssText = rule.style.cssText;
	throw $break;
      }
    });
    if (cssText) throw $break;
  });
  return cssText.parseStyle();
}

Object.extend(Ajax.Autocompleter.prototype, {
  fixIEOverlapping: function() {
    Position.clone(this.update, this.iefix, {setTop:(!this.update.style.height)});
    this.iefix.style.zIndex = $s('iframe.completion').zIndex;
    this.update.style.zIndex = $s('ul.completion').zIndex;
    Element.show(this.iefix);
  }
});

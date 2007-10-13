// vim: set autoindent shiftwidth=2 tabstop=8:
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
    this.update.clone(this.iefix, {setTop:(!this.update.style.height)});
    this.iefix.style.zIndex = $s('iframe.completion').zIndex;
    this.update.style.zIndex = $s('ul.completion').zIndex;
    Element.show(this.iefix);
  }
});

Effect.ScrollElement = function(element, parent_element) {
  if (!(element = $(element)))
    return;
  if (!(parent_element = $(parent_element)) && !(parent_element = element.getScrollableParent()))
    return;

  var options = arguments[2] || {},
    parentHeight = parent_element.getHeight(),
    elementHeight = element.getHeight(),
    scrollOffsets = Element._returnOffset(parent_element.scrollLeft, parent_element.scrollTop),
    elementOffsets = Element._returnOffset(element.offsetLeft, element.offsetTop),
    elementTop = elementOffsets.top + elementHeight,
    to = elementTop > parentHeight + scrollOffsets.top ?
      elementTop - parentHeight : elementOffsets.top < scrollOffsets.top ?
      elementOffsets.top : scrollOffsets.top;

  if (options.offset) elementOffsets[1] += options.offset;
  if (scrollOffsets.top == to || 
      (scrollOffsets.top < elementOffsets.top
        && elementOffsets.top + elementHeight < scrollOffsets.top + parentHeight))
    return;

  return new Effect.Tween(null,
    scrollOffsets.top,
    to,
    options,
    function(p){ parent_element.scrollLeft = scrollOffsets.left, parent_element.scrollTop = p.round() }
  );
};


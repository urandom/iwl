// vim: set autoindent shiftwidth=2 tabstop=8:
Object.extend(Effect, {
  SmoothScroll: function() {
    if (window.smoothScroll) return;
    if (window.loaded) {
      $$('a[href^=#]:not([href=#])').each(function(element) {
	element.observe('click', function(event) {
	  var target = $(this.hash.substr(1))
	    || document.getElementsByName(this.hash.substr(1))[0];
	  if (target) {
	    new Effect.ScrollTo(target);
	    Event.stop(event);
	  }
        }.bindAsEventListener(element));
      });
      window.smoothScroll = true;
    } else {
      Event.observe(window, "load", function () {
        Effect.SmoothScroll();
      });
    }
  },
  ScrollElement: function(element, parent_element) {
    if (!(element = $(element)))
      return;
    if (!(parent_element = $(parent_element))
        && !(parent_element = element.getScrollableParent()))
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

    return new Effect.Tween(
      null,
      scrollOffsets.top,
      to,
      options,
      function(p) {
        parent_element.scrollLeft = scrollOffsets.left, parent_element.scrollTop = p.round()
      }
    );
  },
  Pulsate: function(element) {
    element = $(element);
    var options = Object.extend({
      distance: 20,
      duration: 0.5,
      afterFinish: Prototype.emptyFunction
    }, arguments[1] || {});
    var distance = parseFloat(options.distance);
    var split = parseFloat(options.duration) / 10.0;
    var oldStyle = {
      top: element.getStyle('top'),
      left: element.getStyle('left') };
      return new Effect.Move(element,
        { x:  distance, y: 0, duration: split, afterFinishInternal: function(effect) {
      new Effect.Move(effect.element,
        { x: -distance, y: 0, duration: split, afterFinish: options.afterFinish, afterFinishInternal: function(effect) {
          effect.element.undoPositioned().setStyle(oldStyle);
    }}) }});
  }
});

Object.extend(Ajax.Autocompleter.prototype, {
  fixIEOverlapping: function() {
    Position.clone(this.update, this.iefix, {setTop:(!this.update.style.height)});
    var completionIndex = $$('ul.completion')[0];
    completionIndex = completionIndex ? completionIndex.getStyle('zIndex') : 2;
    this.iefix.style.zIndex = completionIndex - 1;
    this.update.style.zIndex = completionIndex;
    Element.show(this.iefix);
  }
});

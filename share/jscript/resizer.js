// vim: set autoindent shiftwidth=2 tabstop=8:
//
var Resizer = Class.create((function() {
  function setup() {
    var eventMouseUp   = mouseUp.bindAsEventListener(this);
    var eventMouseDown = mouseDown.bindAsEventListener(this);
    var eventMouseMove = mouseMove.bindAsEventListener(this);
    var eventSelect    = selectElement.bindAsEventListener(this);

    this.prevPointerX = 0;
    this.prevPointerY = 0;

    this.resize = false;
    this.resizeType;

    this.elementPosition = {w: 0, h: 0, x: 0, y: 0};
    this.elementStyle    = {};

    if (this.element.getStyle('position') == 'static') {
      this.element.style.position = 'relative';
      this.elementStyle.position = 'static';
    }
    if (this.options.outline) {
      var dimensions = this.element.getDimensions();
      this.outline = new Element('div',
        {className: this.options.className + '_outline'});
      this.outline.setStyle({opacity: this.options.outlineOpacity, visibility: 'hidden'});
      this.element.appendChild(this.outline);
    }

    this.element.resizer = this;
    this.handlers = {};

    createHandles.call(this, eventMouseDown);
    var ok = true;

    this.options.togglers.each(function(toggler) {
        toggler = $(toggler);
        if (!toggler)
          return;
        toggler.observe("mousedown", eventSelect);
        ok = false;
    });
    Event.observe(document, "mouseup"  , eventMouseUp);
    Event.observe(document, "mousemove", eventMouseMove);
    if (ok)
      this.element.observe("mousedown", eventSelect);
  }

  function createHandles(observer) {
    if (!this.options.vertical && !this.options.horizontal) {
      ['tl', 'tr', 'bl', 'br'].each(function($_) {
          createHandle.call(this, $_, observer);
      }.bind(this));
    } 
    if (this.options.vertical || !this.options.horizontal) {
      ['t', 'b'].each(function($_) {
          createHandle.call(this, $_, observer);
      }.bind(this));
    }
    if (!this.options.vertical) {
      ['l', 'r'].each(function($_) {
          createHandle.call(this, $_, observer);
      }.bind(this));
    }
  }

  function destroyHandles() {
    for (var h in this.handlers) {
      if (h.remove)
        h.remove();
    }
    this.handlers = {};
  }

  function createHandle(type, observer) {
    if (this.handlers[type]) return;
    var handle = new Element('div', {
        className: this.options.className + '_handle '
          + this.options.className + '_handle_' + type,
        style: 'visibility: hidden;'
    });
    if (this.outline)
      this.handlers[type] = this.outline.appendChild(handle);
    else
      this.handlers[type] = this.element.appendChild(handle);
    handle.type = type;
    handle.observe('mousedown', observer);
  }
  
  function toggleHandles() {
    for (var h in this.handlers) {
      var v = this.handlers[h].getStyle('visibility');
      this.handlers[h].setStyle({visibility: v == 'hidden' ? 'visible' : 'hidden'});
    }
  }

  function toggleOutline() {
    if (this.outline) {
      var v = this.outline.getStyle('visibility');
      this.outline.setStyle({visibility: v == 'hidden' ? 'visible' : 'hidden'});
    }
  }

  function mouseUp(event) {
    if (this.resize && this.outline) {
      toggleOutline.call(this);

      this.element.style.width  = this.elementPosition.w + 'px';
      this.element.style.height = this.elementPosition.h + 'px';
      this.element.style.left   = this.elementPosition.x + 'px';
      this.element.style.top    = this.elementPosition.y + 'px';

      if (this.options.onResize)
        this.options.onResize(this.element, event, this.elementPosition);
    }
    this.resize = false;
    this.prevPointerX = 0;
    this.prevPointerY = 0;
  }

  function mouseDown(event) {
    if (this.options.onResizeStart
      && !(this.options.onResizeStart(this.element, event)))
      return;
    this.resize = true;
    this.resizeType = event.element().type || '';
    fillElementPosition.call(this);
    toggleOutline.call(this);
  }

  function mouseMove(event) {
    if (!this.resize) return;

    var pX = event.pointerX();
    var pY = event.pointerY();
    var dX = pX - (this.prevPointerX || pX);
    var dY = pY - (this.prevPointerY || pY);
    var ok = false;

    this.prevPointerX = pX;
    this.prevPointerY = pY;

    if (this.resizeType.indexOf('t') >= 0) {
      this.elementPosition.y += dY;
      this.elementPosition.h -= dY;
      ok = true;
    } else if (this.resizeType.indexOf('b') >= 0) {
      this.elementPosition.h += dY;
      ok = true;
    }

    if (this.resizeType.indexOf('l') >= 0) {
      this.elementPosition.x += dX;
      this.elementPosition.w -= dX;
      ok = true;
    } else if (this.resizeType.indexOf('r') >= 0) {
      this.elementPosition.w += dX;
      ok = true;
    }

    if (!ok) return;
    if (this.elementPosition.w > this.options.maxWidth)
      this.elementPosition.w = this.options.maxWidth;
    else if (this.elementPosition.w < this.options.minWidth)
      this.elementPosition.w = this.options.minWidth;

    if (this.elementPosition.h > this.options.maxHeight)
      this.elementPosition.h = this.options.maxHeight;
    else if (this.elementPosition.h < this.options.minHeight)
      this.elementPosition.h = this.options.minHeight;

    if (this.outline) {
      this.outline.style.width  = this.elementPosition.w + 'px';
      this.outline.style.height = this.elementPosition.h + 'px';
      this.outline.style.left   = this.elementPosition.x + 'px';
      this.outline.style.top    = this.elementPosition.y + 'px';
    } else {
      this.element.style.width  = this.elementPosition.w + 'px';
      this.element.style.height = this.elementPosition.h + 'px';
      this.element.style.left   = this.elementPosition.x + 'px';
      this.element.style.top    = this.elementPosition.y + 'px';

      if (this.options.onResize)
        this.options.onResize(this.element, event, this.elementPosition);
    }
  }

  function selectElement(event, outlineSelect) {
    var element = event.element();
    if (element.hasClassName(this.options.className + '_handle'))
      return;
    toggleHandles.call(this);

    fillElementPosition.call(this);
  }

  function fillElementPosition() {
    var dimensions = this.element.getDimensions();
    this.elementPosition.w = dimensions.width;
    this.elementPosition.h = dimensions.height;
    this.elementPosition.x = parseInt(this.element.style.left);
    this.elementPosition.y = parseInt(this.element.style.top);
    if (isNaN(this.elementPosition.x)) this.elementPosition.x = 0;
    if (isNaN(this.elementPosition.y)) this.elementPosition.y = 0;
  }


  return {
    initialize: function(element) {
      this.element = $(element);
      this.options = Object.extend({
        vertical: false,
        horizontal: false,
        maxHeight: 9999,
        minHeight: 10,
        maxWidth: 9999,
        minWidth: 10,
        className: 'resizer',
        outline: false,
        outlineOpacity: 0.6,
        togglers: [],
        onResizeStart: function() { return true; },
        onResize: Prototype.emptyFunction
      }, arguments[1] || {});
      if (!this.element)
        return;
      if (this.element.resizer && this.element.resizer.destroy)
        this.element.resizer.destroy();
      setup.call(this);
    },

    destroy: function() {
      destroyHandles.call(this);
      if (this.outline)
        this.outline.remove();

      this.element.setStyle(this.elementStyle);
      this.element.resizer = undefined;
    }
  }
})());

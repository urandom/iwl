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
      Event.observe(this.element, "mousedown", eventSelect);
  }

  function createHandles(observer) {
    if (!this.options.vertical && !this.options.horizontal) {
      ['tl', 'tr', 'bl', 'br'].each(function($_) {
          createHandle($_, observer);
      }.bind(this));
    } 
    if (this.options.vertical || !this.options.horizontal) {
      ['t', 'b'].each(function($_) {
          createHandle($_, observer);
      }.bind(this));
    }
    if (!this.options.vertical) {
      ['l', 'r'].each(function($_) {
          createHandle($_, observer);
      }.bind(this));
    }
  }

  function destroyHandles() {
    for (var h in this.handlers)
      h.remove();
    this.handlers = {};
  }

  function createHandle(type, observer) {
    if (this.handlers[type]) return;
    var handle = new Element('div', {
        className: this.options.className + ' '
          + this.options.className + '_' + type,
        style: 'visibility: hidden;'
    });
    this.handlers[type] = this.element.appendChild(handle);
    handle.type = type;
    handle.observe('mousedown', observer);
  }
  
  function toggleHandles() {
    for (var h in this.handlers) {
      var v = this.handlers[h].getStyle('visibility');
      this.handlers[h].setStyle({visibility: v == 'hidden' ? '' : 'hidden'});
    }
  }

  function mouseUp(event) {
    this.resize = false;
    this.prevPointerX = 0;
    this.prevPointerY = 0;
  }

  function mouseDown(event) {
    if (this.options.resizeStartCallback
      && !(this.options.resizeStartCallback(this.element, event)))
      return;
    this.resize = true;
    this.resizeType = event.element().type || '';
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

    this.element.style.width  = this.elementPosition.w + 'px';
    this.element.style.height = this.elementPosition.h + 'px';
    this.element.style.left   = this.elementPosition.x + 'px';
    this.element.style.top    = this.elementPosition.y + 'px';

    if (this.options.resizeCallback)
      this.options.resizeCallback(this.element, event, this.elementPosition);
  }

  function selectElement(event) {
    var element = event.element();
    if (element.hasClassName('resizer_handle'))
      return;
    toggleHandles();

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
        className: 'resizer_handle',
        togglers: [],
        resizeStartCallback: function() { return true; },
        resizeCallback: Prototype.emptyFunction,
      }, arguments[1] || {});
      if (!this.element)
        return;
      if (this.element.resizer && this.element.resizer.destroy)
        this.element.resizer.destroy();
      setup.call(this);
    },

    destroy: function() {
      destroyHandles.call(this);
      this.element.setStyle(this.elementStyle);
      this.element.resizer = undefined;
    }
  }
})());

// vim: set autoindent shiftwidth=2 tabstop=8:
//
var Resizer = Class.create((function() {
  var handles = {};

  var eventMouseUp   = Prototype.emptyFunction;
  var eventMouseDown = Prototype.emptyFunction;
  var eventMouseMove = Prototype.emptyFunction;
  var eventSelect    = Prototype.emptyFunction;

  var prevPointerX = 0;
  var prevPointerY = 0;

  var resize = false;
  var resizeType;
  var elementPosition = {w: 0, h: 0, x: 0, y: 0};
  var elementStyle = {};

  function setup() {
    eventMouseUp   = mouseUp.bindAsEventListener(this);
    eventMouseDown = mouseDown.bindAsEventListener(this);
    eventMouseMove = mouseMove.bindAsEventListener(this);
    eventSelect    = selectElement.bindAsEventListener(this);

    if (this.element.getStyle('position') == 'static') {
      this.element.style.position = 'relative';
      elementStyle.position = 'static';
    }
    this.element.resizer = this;

    createHandles.call(this);
    Event.observe(this.element, "mousedown", eventSelect);
    Event.observe(document,     "mouseup"  , eventMouseUp);
    Event.observe(document,     "mousemove", eventMouseMove);
  }

  function createHandles() {
    if (!this.options.vertical && !this.options.horizontal) {
      ['tl', 'tr', 'bl', 'br'].each(createHandle.bind(this));
    } 
    if (this.options.vertical || !this.options.horizontal) {
      ['t', 'b'].each(createHandle.bind(this));
    }
    if (!this.options.vertical) {
      ['l', 'r'].each(createHandle.bind(this));
    }
  }

  function destroyHandles() {
    for (var h in handles)
      h.remove();
    handles = {};
  }

  function createHandle(type) {
    if (handles[type]) return;
    var handle = new Element('div', {
        className: this.options.className + ' '
          + this.options.className + '_' + type,
        style: 'visibility: hidden;'
    });
    handles[type] = this.element.appendChild(handle);
    handle.type = type;
    handle.observe('mousedown', eventMouseDown);
  }
  
  function toggleHandles() {
    for (var h in handles) {
      var v = handles[h].getStyle('visibility');
      handles[h].setStyle({visibility: v == 'hidden' ? '' : 'hidden'});
    }
  }

  function mouseUp(event) {
    resize = false;
    prevPointerX = 0;
    prevPointerY = 0;
  }

  function mouseDown(event) {
    if (this.options.resizeStartCallback
      && !(this.options.resizeStartCallback(this.element, event)))
      return;
    resize = true;
    resizeType = event.element().type || '';
  }

  function mouseMove(event) {
    if (!resize) return;

    var pX = event.pointerX();
    var pY = event.pointerY();
    var dX = pX - (prevPointerX || pX);
    var dY = pY - (prevPointerY || pY);
    var ok = false;

    prevPointerX = pX;
    prevPointerY = pY;

    if (resizeType.indexOf('t') >= 0) {
      elementPosition.y += dY;
      elementPosition.h -= dY;
      ok = true;
    } else if (resizeType.indexOf('b') >= 0) {
      elementPosition.h += dY;
      ok = true;
    }

    if (resizeType.indexOf('l') >= 0) {
      elementPosition.x += dX;
      elementPosition.w -= dX;
      ok = true;
    } else if (resizeType.indexOf('r') >= 0) {
      elementPosition.w += dX;
      ok = true;
    }

    if (!ok) return;
    if (elementPosition.w > this.options.maxWidth)
      elementPosition.w = this.options.maxWidth;
    else if (elementPosition.w < this.options.minWidth)
      elementPosition.w = this.options.minWidth;

    if (elementPosition.h > this.options.maxHeight)
      elementPosition.h = this.options.maxHeight;
    else if (elementPosition.h < this.options.minHeight)
      elementPosition.h = this.options.minHeight;

    this.element.style.width  = elementPosition.w + 'px';
    this.element.style.height = elementPosition.h + 'px';
    this.element.style.left   = elementPosition.x + 'px';
    this.element.style.top    = elementPosition.y + 'px';

    if (this.options.resizeCallback)
      this.options.resizeCallback(this.element, event, elementPosition);
  }

  function selectElement(event) {
    var element = event.element();
    if (element.hasClassName('resizer_handle'))
      return;
    toggleHandles();

    var dimensions = this.element.getDimensions();
    elementPosition.w = dimensions.width;
    elementPosition.h = dimensions.height;
    elementPosition.x = parseInt(this.element.style.left);
    elementPosition.y = parseInt(this.element.style.top);
    if (isNaN(elementPosition.x)) elementPosition.x = 0;
    if (isNaN(elementPosition.y)) elementPosition.y = 0;
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
      this.element.setStyle(elementStyle);
      this.element.resizer = undefined;
    }
  }
})());

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.Draggable = Class.create(Draggable, (function() {
  function onStart(draggable, event) {
    draggable.element.emitSignal('iwl:drag_begin', draggable);
  }

  function onDrag(draggable, event) {
    var element = draggable.originalElement || draggable.element;
    var pseudo = draggable.originalElement ? draggable.element : null;
    if (pseudo) draggable.element = element;
    element.emitSignal('iwl:drag_motion', draggable);
    if (pseudo) draggable.element = pseudo;
  }

  function onEnd(draggable, event) {
    draggable.element.emitSignal('iwl:drag_end', draggable);
  }

  return {
    initialize: function($super, element) {
      element = $(element);
      var options = Object.extend({
        reverteffect: false,
        starteffect: false,
        endeffect: false,

        outlineOpacity: 0.6
      }, arguments[2] || {});
      options.onStart = onStart;
      options.onDrag = onDrag;
      options.onEnd = onEnd;
      $super(element, options);
    },

    startDrag: function($super, event, point) {
      $super(event);

      if (this.options.view) {
        this.view = Object.isFunction(this.options.view)
          ? new this.options.view(this.options.viewOptions)
          : Object.isElement(this.options.view)
            ? this.options.view
            : Object.isString(this.options.view)
              ? new IWL.Draggable.HTMLView(this.options.view)
              : undefined;

        if (this.view && Object.isElement(this.view.element))
          this.view = this.view.element;
        if (!Object.isElement(this.view))
          this.view = undefined;

        if (this.view) {
          this.dummy = new Element('div');
          Object.extend(this.view.style, {
            position: 'absolute',
            left: point.x + 'px',
            top: point.y + 'px'
          });
          this.dummy.originalElement = this.element;
          document.body.appendChild(this.view);
        }
      } else if (this.options.outline) {
        this.outline = new Element('div', {className: 'draggable_outline'});
        var dims = this.element.getDimensions();
        this.outline.style.position = 'absolute';
        this.outline.style.width = dims.width + 'px';
        this.outline.style.height = dims.height + 'px';
        if (this.options.zindex)
          this.outline.style.zIndex = this.options.zindex + 1;
        this.element.insert({after: this.outline});
        this.outline.setOpacity(this.options.outlineOpacity);
        this.outline.originalElement = this.element;
      }
    },

    updateDrag: function($super, event, point) {
      if(!this.dragging) this.startDrag(event, point);

      this.originalElement = this.element;
      if (this.view) {
        this.element = this.dummy;
        this.view.style.left = point[0] + 'px';
        this.view.style.top = point[1] + 'px';
      } else if (this.outline) {
        this.element = this.outline;
      }

      $super(event, point);

      this.element = this.originalElement;
    },

    finishDrag: function($super, event, success) {
      if (this.view) {
        if (!this.options.revert) {
          var absolute = this.element.getStyle('position') == 'absolute';
          if (!absolute)
            Position.absolutize(this.element);
          this.element.style.top = this.view.style.top;
          this.element.style.left = this.view.style.left;
          if (!absolute)
            Position.relativize(this.element);
        }
        this.view.remove();
        delete this.view;
      } else if (this.outline) {
        if (!this.options.revert) {
          var absolute = this.element.getStyle('position') == 'absolute';
          if (!absolute)
            Position.absolutize(this.element);
          this.element.style.top = this.outline.style.top;
          this.element.style.left = this.outline.style.left;
          if (!absolute)
            Position.relativize(this.element);
        }
        this.outline.remove();
        delete this.outline;
      }
      $super(event, success);
    }
  };
})());

IWL.Draggable.HTMLView = Class.create({
  initialize: function(string) {
    this.element = new Element('div', {className: 'draggable_view draggable_html_view', style: 'z-index: 1000'});

    this.element.update(string);
  }
});

IWL.Droppable = Class.create((function() {
  function onHover(dragElement, dropElement, overlap) {
    this.element.emitSignal('iwl:drag_hover', dragElement.originalElement || dragElement, dropElement, overlap)
  }

  function onDrop(dragElement, dropElement, dragEvent) {
    this.element.emitSignal('iwl:drag_drop', dragElement, dragEvent);
  }

  return {
    initialize: function(element) {
      var options = Object.extend({}, arguments[1] || {});
      options.onHover = onHover.bind(this);
      options.onDrop = onDrop.bind(this);

      this.element = $(element);
      this.options = options;
      Droppables.add(this.element, options);
    },
    destroy: function() {
      Droppables.remove(this.element);
    }
  }
})());

IWL.BoxSelection = Class.create(Draggable, (function() {
  function initDrag(event) {
    var pointer = [Event.pointerX(event), Event.pointerY(event)];
    var pos     = Position.cumulativeOffset(this.element);
    this.offset = [0,1].map( function(i) { return (pointer[i] - pos[i]) });
    Draggables.activate(this);
    Event.stop(event);
  }

  function startDrag(event, pointer) {
    this.dragging = true;

    var pos = this.element.cumulativeOffset();
    var dim = this.element.getDimensions();
    this.boundary = {tl: [pos[0], pos[1]], br: [pos[0] + dim.width, pos[1] + dim.height]};

    this.box = new Element('div', {className: 'draggable_box_selection'});
    this.options.parent.appendChild(this.box);
    this.box.style.left = pointer[0] + 'px';
    this.box.style.top = pointer[1] + 'px';
    this.box.setOpacity(this.options.boxOpacity);
    this.initialPosition = pointer;

    Draggables.notify('onStart', this, event);
    this.element.emitSignal('iwl:drag_begin', this, pointer);
  }

  function draw(pointer) {
    var delta = [this.initialPosition[0] - pointer[0],
                 this.initialPosition[1] - pointer[1]];
    if (delta[0] > 0) {
      this.box.style.left = pointer[0] + 'px';
      this.box.style.width = delta[0] + 'px';
    } else {
      this.box.style.width = -delta[0] + 'px';
    }
    if (delta[1] > 0) {
      this.box.style.top = pointer[1] + 'px';
      this.box.style.height = delta[1] + 'px';
    } else {
      this.box.style.height = -delta[1] + 'px';
    }
  }

  function finishDrag(event, success) {
    this.dragging = false;
    this.box.remove();

    Draggables.notify('onEnd', this, event);
    this.element.emitSignal('iwl:drag_end', this);

    Draggables.deactivate(this);
  }

  return {
    initialize: function(element) {
      this.element = $(element);
      this.options = Object.extend({
        boxOpacity: 0.6,
        parent: this.element
      }, arguments[1] || {});
      this.eventMouseDown = initDrag.bindAsEventListener(this);
      Event.observe(this.element, 'mousedown', this.eventMouseDown);
      Draggables.register(this);
    },
    destroy: function() {
      Event.stopObserving(this.element, 'mousedown', this.eventMouseDown);
      Draggables.unregister(this);
    },
    updateDrag: function(event, pointer) {
      if (!this.dragging) startDrag.call(this, event, pointer);

      if (   pointer[0] > this.boundary.tl[0]
          && pointer[0] < this.boundary.br[0]
          && pointer[1] > this.boundary.tl[1]
          && pointer[1] < this.boundary.br[1]
        )
        draw.call(this, pointer);

      Draggables.notify('onDrag', this, event);
      this.element.emitSignal('iwl:drag_motion', this, pointer);

      if(Prototype.Browser.WebKit) window.scrollBy(0,0);
      
      Event.stop(event);
    },
    endDrag: function(event) {
      if(!this.dragging) return;
      finishDrag.call(this, event, true);
      Event.stop(event);
    },
    keyPress: function(event) {
      if(event.keyCode != Event.KEY_ESC) return;
      finishDrag.call(this, event, false);
      Event.stop(event);
    },
  };
})());

(function() {
  var show = Droppables.show;

  Droppables.show = function(point, element) {
    if (element.originalElement)
      show.call(Droppables, point, element.originalElement);
    else
      show.call(Droppables, point, element);
  };
  Droppables.isContained = function(element, drop) {
    var containmentNode;
    if(drop.tree) {
      containmentNode = element.treeNode; 
    } else {
      containmentNode = element.parentNode;
    }
    return drop._containers.detect(function(c) { return element == c || containmentNode == c });
  };
})();

Element.addMethods({
  setDragSource: function(element, options) {
    if (!element.iwl) element.iwl = {};
    if (element.iwl.draggable)
      element.iwl.draggable.destroy();
    element.iwl.draggable = new IWL.Draggable(element, options);
    return element;
  },
  unsetDragSource: function(element) {
    if (!element.iwl || !element.iwl.draggable) return;
    element.iwl.draggable.destroy();
    return element;
  },
  setDragDest: function(element, options) {
    if (!element.iwl) element.iwl = {};
    if (element.iwl.droppable)
      element.iwl.droppable.destroy();
    element.iwl.droppable = new IWL.Droppable(element, options);
    return element;
  },
  unsetDragDest: function(element) {
    if (!element.iwl || !element.iwl.droppable) return;
    element.iwl.droppable.destroy();
    return element;
  },
  setDragData: function(element, data) {
    if (!element.iwl || !element.iwl.draggable) return;
    element.iwl.draggable.data = data;
    return element;
  },
  getDragData: function(element) {
    if (!element.iwl || !element.iwl.draggable) return;
    return element.iwl.draggable.data;
  }
});

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

  function eventOptions(event) {
    var options = {};
    var names = ['ctrlKey', 'altKey', 'shiftKey', 'metaKey', 'button', 'which', 'detail'];
    for (var i = 0, l = names.length; i < l; i++) {
      options[names[i]] = event[names[i]];
    }
    return new Event.Options(options);
  }

  return {
    initialize: function($super, element) {
      element = $(element);
      var options = Object.extend({
        reverteffect: false,
        starteffect: false,
        endeffect: false,
        outlineOpacity: 0.6,

        actions: IWL.Draggable.Actions.DEFAULT
      }, arguments[2] || {});
      options.onStart = onStart;
      options.onDrag = onDrag;
      options.onEnd = onEnd;
      $super(element, options);

      if (!element.iwl) element.iwl = {};
      element.iwl.draggable = this;
    },

    destroy: function($super) {
      $super();
      this.data = undefined;
      this.element.iwl.draggable = undefined;
    },

    initDrag: function($super, event) {
      var pointer = Event.pointer(event);
      var pos     = Element.cumulativeOffset(this.element);
      pointer = [pointer.x - pos[0], pointer.y - pos[1]];
      if ( this.element.clientWidth < pointer[0]
        || this.element.clientHeight < pointer[1])
        return;

      (Event.element(event) || this.element).emitSignal('iwl:drag_init', this, eventOptions.call(this, event));
      if (this.terminated) {
        delete this.terminated;
        return;
      }
      $super(event);
    },

    startDrag: function($super, event, point) {
      $super(event);

      if (this.options.view) {
        this.view = Object.isFunction(this.options.view)
          ? new this.options.view(this.options.viewOptions)
          : Object.isElement(this.options.view)
            ? this.options.view
            : Object.isString(this.options.view)
              ? new IWL.Draggable.HTMLView({string: this.options.view})
              : undefined;

        if (this.view && Object.isElement(this.view.element))
          this.view = this.view.element;
        if (!Object.isElement(this.view))
          this.view = undefined;

        if (this.view) {
          this.dummy = new Element('div'), style = this.view.style;
          style.position = 'absolute';
          style.left = (point.x || 0) + 'px';
          style.top = (point.y || 0) + 'px';
          this.dummy.originalElement = this.element;
          document.body.appendChild(this.view);
          document.body.appendChild(this.dummy);
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
        this.dummy.remove();
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
    },
    terminateDrag: function() {
      if(!this.dragging) return this.terminated = true;
      this.dragging = false;
      Draggables.deactivate(this);
    }
  };
})());

IWL.Draggable.HTMLView = Class.create({
  initialize: function() {
    this.options = Object.extend({
      opacity: 0.5
    }, arguments[0]);
    this.element = new Element('div', {className: 'draggable_view draggable_html_view', style: 'z-index: 1000'});

    this.element.update(this.options.string);
    Element.setOpacity(this.element, this.options.opacity);
  }
});

IWL.Draggable.Actions = {
  DEFAULT: 1 << 0,
  COPY:    1 << 1,
  MOVE:    1 << 2,
  LINK:    1 << 3,
  PRIVATE: 1 << 4,
  ASK:     1 << 5
}

IWL.Droppable = Class.create((function() {
  function onHover(sourceElement, destElement, overlap) {
    this.element.emitSignal('iwl:drag_hover', sourceElement.originalElement || sourceElement, destElement, overlap, this.options.actions)
  }

  function onDrop(sourceElement, destElement, sourceEvent) {
    this.element.emitSignal('iwl:drag_drop', sourceElement, destElement, sourceEvent, this.options.actions);
  }

  return {
    initialize: function(element) {
      var options = Object.extend({
        actions: IWL.Draggable.Actions.DEFAULT
      }, arguments[1] || {});
      options.onHover = onHover.bind(this);
      options.onDrop = onDrop.bind(this);

      this.element = $(element);
      this.options = options;
      Droppables.add(this.element, options);

      if (!element.iwl) element.iwl = {};
      element.iwl.droppable = this;
    },
    destroy: function() {
      Droppables.remove(this.element);
      this.element.iwl.droppable = undefined;
    }
  }
})());

IWL.BoxSelection = Class.create(Draggable, (function() {
  function initDrag(event) {
    var pointer = [Event.pointerX(event), Event.pointerY(event)];
    var pos     = Element.cumulativeOffset(this.element);
    this.offset = [0,1].map( function(i) { return (pointer[i] - pos[i]) });

    var dim = {width: this.element.scrollWidth, height: this.element.scrollHeight};
    this.boundary = {tl: [pos[0], pos[1]], br: [pos[0] + dim.width, pos[1] + dim.height]};
    pointer = [pointer[0] - pos[0], pointer[1] - pos[1]];
    if ( this.element.clientWidth < pointer[0]
      || this.element.clientHeight < pointer[1])
      return;

    (Event.element(event) || this.element).emitSignal('iwl:box_selection_init', this);
    if (this.terminated) {
      delete this.terminated;
      return;
    }

    Draggables.activate(this);
    Event.stop(event);
  }

  function startDrag(event, pointer) {
    this.dragging = true;

    this.box = new Element('div', {className: 'draggable_box_selection'});
    this.element.appendChild(this.box);
    pointer[0] += this.element.scrollLeft;
    pointer[1] += this.element.scrollTop;
    this.box.style.left = pointer[0] + 'px';
    this.box.style.top = pointer[1] + 'px';
    this.box.setOpacity(this.options.boxOpacity);

    this.initialPointer = pointer;

    Draggables.notify('onStart', this, event);
    this.element.emitSignal(
      'iwl:box_selection_begin',
      this,
      relativeCoordinates.call(this, this.initialPointer, pointer),
      eventOptions.call(this, event)
    );
  }

  function eventOptions(event) {
    var options = {};
    var names = ['ctrlKey', 'altKey', 'shiftKey', 'metaKey', 'button', 'which', 'detail'];
    for (var i = 0, l = names.length; i < l; i++) {
      options[names[i]] = event[names[i]];
    }
    return new Event.Options(options);
  }

  function draw(pointer) {
    pointer[0] += this.element.scrollLeft;
    pointer[1] += this.element.scrollTop;
    var delta = [this.initialPointer[0] - pointer[0],
                 this.initialPointer[1] - pointer[1]];
    var tl = this.boundary.tl;
    var br = this.boundary.br;
    if (pointer[0] > tl[0] && pointer[0] < br[0]) {
      if (delta[0] > 0) {
        this.box.style.left = pointer[0] - tl[0] + 'px';
        this.box.style.width = delta[0] + 'px';
      } else {
        this.box.style.left = this.initialPointer[0] - tl[0] + 'px';
        this.box.style.width = -delta[0] + 'px';
      }
    }
    if (pointer[1] > tl[1] && pointer[1] < br[1]) {
      if (delta[1] > 0) {
        this.box.style.top = pointer[1] - tl[1] + 'px';
        this.box.style.height = delta[1] + 'px';
      } else {
        this.box.style.top = this.initialPointer[1] - tl[1] + 'px';
        this.box.style.height = -delta[1] + 'px';
      }
    }
  }

  function finishDrag(event, success) {
    this.dragging = false;
    this.box.remove();

    var pointer = Event.pointer(event);
    pointer = [pointer.x, pointer.y];
    pointer[0] += this.element.scrollLeft;
    pointer[1] += this.element.scrollTop;
    Draggables.notify('onEnd', this, event);
    this.element.emitSignal(
      'iwl:box_selection_end',
      this,
      relativeCoordinates.call(this, this.initialPointer, pointer),
      success,
      eventOptions.call(this, event)
    );

    Draggables.deactivate(this);
  }

  function relativeCoordinates() {
    var pos = this.boundary.tl;
    var pointers = [];
    for (var i = 0; i < 2; i++) {
      pointers[i] = arguments[i].clone();
      pointers[i] = [pointers[i][0] - pos[0], pointers[i][1] - pos[1]];
    }
    var tlCoords = [
        pointers[0][0] < pointers[1][0] ? pointers[0][0] : pointers[1][0],
        pointers[0][1] < pointers[1][1] ? pointers[0][1] : pointers[1][1]
    ];
    var brCoords = [
        pointers[0][0] > pointers[1][0] ? pointers[0][0] : pointers[1][0],
        pointers[0][1] > pointers[1][1] ? pointers[0][1] : pointers[1][1]
    ];
    return [tlCoords, brCoords];
  }

  return {
    initialize: function(element) {
      this.element = $(element);
      this.options = Object.extend({
        boxOpacity: 0.5
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
      if (!this.dragging) startDrag.call(this, event, pointer.clone());

      draw.call(this, pointer);

      Draggables.notify('onDrag', this, event);
      this.element.emitSignal(
        'iwl:box_selection_motion',
        this,
        relativeCoordinates.call(this, this.initialPointer, pointer),
        eventOptions.call(this, event)
      );

      if(Prototype.Browser.WebKit) window.scrollBy(0,0);
      
      Event.stop(event);
    },
    endDrag: function(event) {
      if(!this.dragging) return;
      finishDrag.call(this, event, true);
      Event.stop(event);
    },
    terminateDrag: function() {
      if(!this.dragging) return this.terminated = true;
      finishDrag.call(this, {}, false);
      Event.stop(event);
    },
    keyPress: function(event) {
      if(event.keyCode != Event.KEY_ESC) return;
      finishDrag.call(this, event, false);
      Event.stop(event);
    }
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
  Droppables.isAffected = function(point, element, drop) {
    if (drop.element == element) return false;
    if (element.iwl && element.iwl.draggable) {
      if (!(element.iwl.draggable.options.actions & drop.actions))
        return false;
    }
    if (drop._containers) {
      var containmentNode;
      if(drop.tree) {
        containmentNode = element.treeNode; 
      } else {
        containmentNode = element.parentNode;
      }
      var contained = false;
      for (var i = 0, l = drop._containers.length; i < l; i ++) {
        var c = drop._containers[i];
        if (element == c || containmentNode ==c) {
          contained = true;
          break;
        }
      }
      if (!contained) return false;
    }

    if (drop.accept) {
      var classNames = element.className.split(/\s+/), accepted = false;
      for (var i = 0, l = classNames.length; i < l; i++) {
        if (drop.accept.indexOf(classNames[i]) > -1) {
          accepted = true;
          break;
        }
      }
      if (!accepted) return false;
    }

    return Position.within(drop.element, point[0], point[1]);
  };
})();

Element.addMethods({
  setDragSource: function(element, options) {
    if (!element.iwl) element.iwl = {};
    if (element.iwl.draggable)
      element.iwl.draggable.destroy();
    new IWL.Draggable(element, options);
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
    new IWL.Droppable(element, options);
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

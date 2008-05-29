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

(function() {
  var ElementMethods = {
    dragSourceSet: function(element, options) {
      if (!element.iwl) element.iwl = {};
      if (element.iwl.draggable)
        element.iwl.draggable.destroy();
      element.iwl.draggable = new IWL.Draggable(element, options);
      return element;
    },
    dragSourceUnset: function(element) {
      if (!element.iwl || !element.iwl.draggable) return;
      element.iwl.draggable.destroy();
      return element;
    },
    dragDestSet: function(element, options) {
      if (!element.iwl) element.iwl = {};
      if (element.iwl.droppable)
        element.iwl.droppable.destroy();
      element.iwl.droppable = new IWL.Droppable(element, options);
      return element;
    },
    dragDestUnset: function(element) {
      if (!element.iwl || !element.iwl.droppable) return;
      element.iwl.droppable.destroy();
      return element;
    },
    dragDataSet: function(element, data) {
      if (!element.iwl || !element.iwl.draggable) return;
      element.iwl.draggable.data = data;
      return element;
    },
    dragDataGet: function(element) {
      if (!element.iwl || !element.iwl.draggable) return;
      return element.iwl.draggable.data;
    },
    prepareDND: function(element, events) {
      if (element._preparedDND) return element;
      if (!events) {
        events = element.readAttribute('iwl:DNDEvents');
        events = unescape(events).evalJSON();
      }
      if (events) {
        if (events.source)
          element.dragSourceSet(events.source);
        if (events.dest)
          element.dragDestSet(events.dest);
        element._preparedDND = true;
        return element;
      }
    }
  };
  Element.addMethods(ElementMethods);
  Object.extend(Element, ElementMethods);
})();

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.Draggable = Class.create(Draggable, (function() {
  function currentDelta(element) {
    return([
      parseInt(Element.getStyle(element,'left') || '0'),
      parseInt(Element.getStyle(element,'top') || '0')]);
  }

  function initDrag(event) {
    if (!Event.isLeftClick(event)) return;
    var pointer = Event.pointer(event);
    this.initialPosition = Element.cumulativeOffset(this.element);
    this.offsetDelta = [0, 0];
    this.offset = [pointer.x - this.initialPosition[0], pointer.y - this.initialPosition[1]];
    // don't drag on the scrollbar
    if ( this.element.clientWidth < this.offset[0]
      || this.element.clientHeight < this.offset[1])
      return;

    (Event.element(event) || this.element).emitSignal('iwl:drag_init', this, eventOptions.call(this, event));
    if (this.terminated) {
      delete this.terminated;
      return;
    }

    // abort on form elements, fixes a Firefox issue
    var tagName = Event.element(event).tagName.toLowerCase(), tagNames = {
      input: true,
      select: true,
      button: true,
      option: true,
      textarea: true
    };
    if (!this.options.view && tagNames[tagName])
      return;
      
    if (this.options.snap) {
      if (Object.isFunction(this.options.snap))
        this.snapFunction = this.options.snap;
      else if (Object.isArray(this.options.snap))
        this.snapArray = this.options.snap;
    }

    Draggables.activate(this);
    Event.stop(event);
  }

  function startDrag(event, pointer) {
    this.dragging = true;
    if (!this.delta)
      this.delta = currentDelta(this.element);
    
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
        var style = this.view.style;
        style.position = 'absolute';
        style.left = (pointer[0] || 0) + 'px';
        style.top = (pointer[1] || 0) + 'px';
        document.body.appendChild(this.view);
        this.draggableElement = this.view;
      }
    } else if (this.options.outline) {
      this.outline = new Element('div', {className: 'draggable_outline'});
      var dims = this.element.getDimensions(), style = this.outline.style;
      style.position = 'absolute';
      style.width = dims.width + 'px';
      style.height = dims.height + 'px';
      style.left = '-10000px';
      if (this.options.zindex)
        this.outline.style.zIndex = this.options.zindex + 1;
      this.element.insert({after: this.outline});
      this.outline.setOpacity(this.options.outlineOpacity);
      this.draggableElement = this.outline;
    } else if (this.options.ghosting) {
      this._clone = this.element.cloneNode(true);
      this.element._originallyAbsolute = (this.element.getStyle('position') == 'absolute');
      if (!this.element._originallyAbsolute)
        Element.absolutize(this.element);
      this.element.parentNode.insertBefore(this._clone, this.element);
    }

    if (this.options.zindex) {
      this.originalZ = parseInt(Element.getStyle(this.element,'z-index') || 0);
      this.element.style.zIndex = this.options.zindex;
    }
    
    if (this.options.scroll) {
      if (this.options.scroll == window) {
        var where = this._getWindowScroll(this.options.scroll);
        this.originalScrollLeft = where.left;
        this.originalScrollTop = where.top;
      } else {
        this.originalScrollLeft = this.options.scroll.scrollLeft;
        this.originalScrollTop = this.options.scroll.scrollTop;
      }
    }

    if (this.options.within) {
      var within = this.options.within;
      if (Object.isElement(within)) {
        this.withinElement = within;
        this.withinPadding = [0, 0, 0, 0];
      } else {
        this.withinElement = within.element;
        var padding = within.padding;
        if (padding.length == 1) {
          padding = padding[0];
          this.withinPadding = [padding, padding, padding, padding];
        } else if (padding.length == 2)
          this.withinPadding = [padding[0], padding[1], padding[0], padding[1]];
        else if (padding.length == 4)
          this.withinPadding = [padding[0], padding[1], padding[2], padding[3]];
        else
          this.withinPadding = [0, 0, 0, 0];
      }
      var dim = {width: this.element.scrollWidth, height: this.element.scrollHeight};
      this.boundary = {
        tl: [
          this.initialPosition[0] + this.withinPadding[3],
          this.initialPosition[1] + this.withinPadding[0]
        ], br: [
          this.initialPosition[0] + dim.width - this.withinPadding[1],
          this.initialPosition[1] + dim.height - this.withinPadding[2]
        ]
      };
    }
    
    this.element.emitSignal('iwl:drag_begin', this);
        
    if (this.options.startEffect) this.options.startEffect(this.draggableElement);
  }
  
  function draw(element, pointer) {
    if (this.view) {
      var p = [pointer[0], pointer[1]];
    } else {
      var pos = [this.initialPosition[0] - this.offsetDelta[0], this.initialPosition[1] - this.offsetDelta[1]];
      if (this.options.ghosting) {
        var r   = Element.cumulativeScrollOffset(element);
        pos[0] += r[0] - Position.deltaX; pos[1] += r[1] - Position.deltaY;
      }
      
      var d = currentDelta(element);
      pos[0] -= d[0]; pos[1] -= d[1];
      
      if (this.options.scroll && this.options.scroll != window && this._isScrollChild) {
        pos[0] -= this.options.scroll.scrollLeft - this.originalScrollLeft;
        pos[1] -= this.options.scroll.scrollTop - this.originalScrollTop;
      }
      
      var p = [pointer[0] - pos[0] - this.offset[0], pointer[1] - pos[1] - this.offset[1]];
    }
    
    if (this.options.snap) {
      if (this.snapFunction)
        p = this.options.snap(p[0], p[1], this);
      else if (this.snapArray)
        p = [
          Math.round(p[0] / this.snapArray[0]) * this.snapArray[0],
          Math.round(p[1] / this.snapArray[1]) * this.snapArray[1]
        ];
      else
        p = [
          Math.round(p[0] / this.options.snap) * this.options.snap,
          Math.round(p[1] / this.options.snap) * this.options.snap
        ];
    }
    
    var style = element.style;
    if ((!this.options.constraint) || (this.options.constraint == 'horizontal'))
      style.left = p[0] + "px";
    if ((!this.options.constraint) || (this.options.constraint == 'vertical'))
      style.top  = p[1] + "px";
    
    this.offsetDelta = [this.initialPosition[0] - p[0], this.initialPosition[1] - p[1]];
    if (style.visibility == "hidden") style.visibility = ""; // fix gecko rendering
  }

  function eventOptions(event) {
    var options = {eventElement: Event.element(event)};
    var names = ['ctrlKey', 'altKey', 'shiftKey', 'metaKey', 'button', 'which', 'detail'];
    for (var i = 0, l = names.length; i < l; i++) {
      options[names[i]] = event[names[i]];
    }
    return new Event.Options(options);
  }

  return {
    initialize: function(element) {
      this.element = element = $(element);
      var self = this;
      this.options = Object.extend({
        handle: false,
        revertEffect: function(element, top_offset, left_offset) {
          var dur = Math.sqrt(Math.abs(top_offset ^ 2) + Math.abs(left_offset ^ 2)) * 0.02;
          new Effect.Move(element, {x: -left_offset, y: -top_offset, duration: dur,
            queue: {scope:'_draggable', position:'end'}
          });
        },
        startEffect: function(element) {
          self.__elementOpacity = Element.getOpacity(element);
          Element.setOpacity(element, 0.6);
        },
        endEffect: function(element) {
          if (isNaN(self.__elementOpacity)) return;
          Element.setOpacity(element, self.__elementOpacity);
        },
        zindex: 1000,
        revert: false,
        quiet: false,
        scroll: false,
        scrollSensitivity: 20,
        scrollSpeed: 15,
        snap: false,
        delay: 0,
        view: false,
        outline: false,
        ghosting: false,
        outlineOpacity: 0.6,

        actions: IWL.Draggable.Actions.DEFAULT
      }, arguments[1] || {});

      if (!element.iwl) element.iwl = {};
      element.iwl.draggable = this;

      if (this.options.handle && Object.isString(this.options.handle))
        this.handle = this.element.down('.' + this.options.handle, 0);
      
      if (!this.handle) this.handle = $(this.options.handle);
      if (!this.handle) this.handle = this.element;

      if (this.options.scroll
        && !this.options.scroll.scrollTo && !this.options.scroll.outerHTML) {
        this.options.scroll = $(this.options.scroll);
        this._isScrollChild = Element.childOf(this.element, this.options.scroll);
      }

      Element.makePositioned(this.element); // fix IE    

      this.dragging = false;   

      this.draggableElement = this.element;

      this.eventMouseDown = initDrag.bindAsEventListener(this);
      Event.observe(this.handle, "mousedown", this.eventMouseDown);
      
      Draggables.register(this);
    },

    destroy: function() {
      this.data = undefined;
      this.element.iwl.draggable = undefined;
      Event.stopObserving(this.handle, "mousedown", this.eventMouseDown);
      Draggables.unregister(this);
    },

    updateDrag: function(event, pointer) {
      if(!this.dragging) startDrag.call(this, event, pointer);

      if (!this.options.quiet) {
        Position.prepare();
        Droppables.show(pointer, this.element);
      }
      
      draw.call(this, this.draggableElement, pointer);
      
      this.element.emitSignal('iwl:drag_motion', this);
      
      if (this.options.scroll) {
        this.stopScrolling();
        
        var p;
        if (this.options.scroll == window) {
          with(this._getWindowScroll(this.options.scroll)) { p = [ left, top, left+width, top+height ]; }
        } else {
          p = Element.viewportOffset(this.options.scroll);
          p[0] += this.options.scroll.scrollLeft + Position.deltaX;
          p[1] += this.options.scroll.scrollTop + Position.deltaY;
          p.push(p[0]+this.options.scroll.offsetWidth);
          p.push(p[1]+this.options.scroll.offsetHeight);
        }
        var speed = [0,0];
        if(pointer[0] < (p[0]+this.options.scrollSensitivity)) speed[0] = pointer[0]-(p[0]+this.options.scrollSensitivity);
        if(pointer[1] < (p[1]+this.options.scrollSensitivity)) speed[1] = pointer[1]-(p[1]+this.options.scrollSensitivity);
        if(pointer[0] > (p[2]-this.options.scrollSensitivity)) speed[0] = pointer[0]-(p[2]-this.options.scrollSensitivity);
        if(pointer[1] > (p[3]-this.options.scrollSensitivity)) speed[1] = pointer[1]-(p[3]-this.options.scrollSensitivity);
        this.startScrolling(speed);
      }
      
      // fix AppleWebKit rendering
      if (Prototype.Browser.WebKit) window.scrollBy(0,0);
      
      Event.stop(event);
    },

    finishDrag: function(event, success) {
      this.dragging = false;

      if (this.options.quiet) {
        Position.prepare();
        var pointer = [Event.pointerX(event), Event.pointerY(event)];
        Droppables.show(pointer, this.element);
      }

      if(this.options.endEffect) 
        this.options.endEffect(this.draggableElement);
        
      if (this.view) {
        if (!this.options.revert || this.options.revertEffect) {
          var absolute = Element.getStyle(this.element, 'position') == 'absolute';
          if (!absolute)
            Element.absolutize(this.element);
          this.element.style.top = this.view.style.top;
          this.element.style.left = this.view.style.left;
          if (!absolute)
            Element.relativize(this.element);
        }
        Element.remove(this.view);
        delete this.view;
      } else if (this.outline) {
        if (!this.options.revert || this.options.revertEffect) {
          var absolute = Element.getStyle(this.element, 'position') == 'absolute';
          if (!absolute)
            Element.absolutize(this.element);
          this.element.style.top = this.outline.style.top;
          this.element.style.left = this.outline.style.left;
          if (!absolute)
            Element.relativize(this.element);
        }
        Element.remove(this.outline);
        delete this.outline;
      } else if (this.options.ghosting) {
        if (!this.element._originallyAbsolute)
          Element.relativize(this.element);
        this.element._originallyAbsolute = undefined;
        Element.remove(this._clone);
        delete this._clone;
      }

      var dropped = false; 
      if (success)
        dropped = Droppables.fire(event, this.element); 

      this.element.emitSignal('iwl:drag_end', this);

      var revert = this.options.revert;
      if(revert && Object.isFunction(revert)) revert = revert(this.element);
      
      var d = currentDelta(this.element);
      if (revert && this.options.revertEffect) {
        if (!dropped || revert != 'failure')
          this.options.revertEffect(this.element, d[1] - this.delta[1], d[0] - this.delta[0]);
      } else this.delta = d;

      if(this.options.zindex)
        this.element.style.zIndex = this.originalZ;

      Draggables.deactivate(this);
      Droppables.reset();
    },
    terminateDrag: function() {
      if(!this.dragging) return this.terminated = true;
      this.dragging = false;
      Draggables.deactivate(this);
    },
    scroll: function() {
      var current = new Date();
      var delta = current - this.lastScrolled;
      this.lastScrolled = current;
      if (this.options.scroll == window) {
        with (this._getWindowScroll(this.options.scroll)) {
          if (this.scrollSpeed[0] || this.scrollSpeed[1]) {
            var d = delta / 1000;
            this.options.scroll.scrollTo(
              left + d * this.scrollSpeed[0], top + d * this.scrollSpeed[1]
            );
          }
        }
      } else {
        this.options.scroll.scrollLeft += this.scrollSpeed[0] * delta / 1000;
        this.options.scroll.scrollTop  += this.scrollSpeed[1] * delta / 1000;
      }
      
      Position.prepare();
      Droppables.show(Draggables._lastPointer, this.element);
      if (this._isScrollChild) {
        Draggables._lastScrollPointer = Draggables._lastScrollPointer || $A(Draggables._lastPointer);
        Draggables._lastScrollPointer[0] += this.scrollSpeed[0] * delta / 1000;
        Draggables._lastScrollPointer[1] += this.scrollSpeed[1] * delta / 1000;
        if (Draggables._lastScrollPointer[0] < 0)
          Draggables._lastScrollPointer[0] = 0;
        if (Draggables._lastScrollPointer[1] < 0)
          Draggables._lastScrollPointer[1] = 0;
        draw.call(this, this.draggableElement, Draggables._lastScrollPointer);
      }

      this.element.emitSignal('iwl:drag_motion', this);
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
    this.element.emitSignal('iwl:drag_hover', sourceElement, destElement, overlap, this.options.actions)
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

    this.element.emitSignal(
      'iwl:box_selection_begin',
      this,
      relativeCoordinates.call(this, this.initialPointer, pointer),
      eventOptions.call(this, event)
    );
  }

  function eventOptions(event) {
    var options = {eventElement: Event.element(event)};
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

Resizer = Class.create();
Object.extend(Object.extend(Resizer.prototype), {
  initialize: function(element) {
    this.element = $(element);
    this.options = Object.extend({
        handle: element,
        vertical: false,
        horizontal: false,
        maxHeight: 1000,
        minHeight: 10,
        maxWidth:  1000,
        minWidth: 10,
        resizeCallback: Prototype.emptyFunction
    }, arguments[1] || {});
    this.setup() ;
  },
  setup: function() {
    this.eventMouseUp = this.eventUp.bindAsEventListener(this);
    this.eventMouseDown = this.eventDown.bindAsEventListener(this);
    this.eventMouseMove = this.eventMove.bindAsEventListener(this);
    var position = this.element.style.position ;
    this.element.style.position = 'absolute' ;
    this.top = this.element.offsetTop;
    this.left = this.element.offsetLeft;
    this.element.style.position = position ;
    this.resize = false ;
    
    Event.observe($(this.options.handle), "mousedown", this.eventMouseDown);
	Event.observe(document, "mouseup", this.eventMouseUp);
	Event.observe(document, "mousemove", this.eventMouseMove);
  },
  eventUp: function(event) {
    this.resize = false ;
  },
  eventDown: function(event) {
    this.resize = true ;
  },
  eventMove: function(event) {
    if(this.resize)
    {
        
        var d = {}; 
        if(this.options.horizontal) 
        {
            var width = ( Event.pointerX(event) - this.left ) ;
            if(width < this.options.maxWidth && width > this.options.minWidth)
		d.width = Math.round(width) + 'px';
        }
        if(this.options.vertical)
        {
            var height = ( Event.pointerY(event) - this.top ) ;
            if(height < this.options.maxHeight && height > this.options.minHeight)
		d.height = Math.round(height) + 'px';
        }
        this.element.setStyle(d);
	if (this.options.resizeCallback)
	    this.options.resizeCallback(this.element, d);
    }
  }
});

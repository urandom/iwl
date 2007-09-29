// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Tooltip is a class for creating information tooltips
 * @extends Widget
 * */
var Tooltip = {};
Object.extend(Object.extend(Tooltip, Widget), {
    /**
     * Shows the tooltip
     * @returns The object
     * */
    showTooltip: function() {
        this.placeAtElement();
        this.__appear = Effect.Appear(this);
	return this;
    },
    /**
     * Hides the tooltip
     * @returns The object
     * */
    hideTooltip: function() {
	if (this.__appear) this.__appear.cancel();
        Element.hide(this);
	return this;
    },
    /**
     * Sets the content of the tooltip
     * @param elements The elements to add. Can be HTML, a DOM object or an array of DOM objects
     * @returns The object
     * */
    setContent: function(elements) {
	this.content.update();
	if (typeof elements == 'string') {
	    this.content.update(unescape(elements));
	} else if (typeof elements == 'object') {
	    if ($A(elements).length && !(elements.nodeType == 3)) {
		$A(elements).each(function($_) {this.content.appendChild($_)}.bind(this));
	    } else {
		this.content.appendChild(elements);
	    }
	}
	return this;
    },
    /**
     * Places the tooltip at the bound element
     * @returns The object
     * */
    placeAtElement: function() {
	if (!this.element) return;
	var pos = this.element.cumulativeOffset();
	var scroll = this.element.cumulativeScrollOffset();
	pos[0] -= scroll[0];
	pos[1] -= scroll[1];
	pos[1] += this.element.getDimensions().height;

	if (this.options.centerOnElement)
	    pos[0] += this.element.getDimensions().width/2;
	this.__position(pos[0], pos[1]);

	return this;
    },
    /**
     * Removes the tooltip
     * @returns The object
     * */
    remove: function() {
        if (this.parentNode)
            this.parentNode.removeChild(this);
	this.element = null;
	return this;
    },
    /**
     * Binds the tooltip to an element. If the element emits the given signal, the tooltip will be shown
     * @param element The element to bind to
     * @param signal The signal name
     * @returns The object
     * */
    bindToWidget: function(element, signal) {
	this.element = $(element);
	if (!this.element) return;
        this.element.signalConnect(signal, function (event) {
            if (!this.visible()) {
                this.showTooltip();
                if (event.stop)
                    event.stop();
            }
        }.bind(this));
	if (!this.options.hidden)
	    this.showTooltip();
	return this;
    },
    /**
     * Binds the tooltip to an element. If the element emits the given signal, the tooltip will be hidden
     * @param element The element to bind to
     * @param signal The signal name
     * @returns The object
     * */
    bindHideToWidget: function(element, signal) {
	this.hideElement = $(element);
	if (!this.hideElement) return;
        this.hideElement.signalConnect(signal, function (event) {
            if (this.visible()) {
                this.hideTooltip();
                if (event.stop)
                    event.stop();
            }
        }.bind(this));
	return this;
    },

    _preInit: function(id) {
        this.options = Object.extend({
            width:      'auto',
            centerOnElement: true,
	    hidden: false,
            followMouse: false
        }, arguments[1] || {})
        if (!id) id = 'tooltip' + Math.random();
	this.__build(id);
	return true;
    },
    _init: function() {
        if (parseInt(this.options.width))
            this.options.width = parseInt(this.options.width) + 'px';
    },

    __build: function(id) {
        var container = new Element('div', {className: 'tooltip', id: id});
        var content = new Element('div', {className: 'tooltip_content'});
        var bubble1 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_1'});
        var bubble2 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_2'});
        var bubble3 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_3'});

        container.appendChild(bubble3);
        container.appendChild(bubble2);
        container.appendChild(bubble1);
        container.appendChild(content);

        bubble3.setStyle({width: '7px', height: '7px', left: '14px'});
        bubble2.setStyle({width: '10px', height: '10px', top: '-4px', left: '6px', 'z-index': 16});
        bubble1.setStyle({width: '14px', height: '14px', top: '-10px', left: '10px', 'z-index': 17});
        content.setStyle({top: '-18px', width: this.options.width});
        container.setStyle({width: this.options.width, display: 'none'});

        this.current.parentNode.appendChild(container);
        if (this.options.followMouse)
            Event.observe(document, 'mousemove', this.__move.bindAsEventListener(this), false);
        this.current = container;
        this.content = content;
    },
    __move: function(e) {
        var l = Event.pointerX(e) - 16;
        var t = Event.pointerY(e);
        return this.__position(l, t);
    },
    __position: function(x, y) {
        if (x >= 24) x -= 16;
//        if (ie4) {
//            x += 8;
//            y += 16;
//        }
	return this.setStyle({top: y + 'px', left: x + 'px'});
    }
});

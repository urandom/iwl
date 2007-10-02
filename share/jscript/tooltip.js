// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class Tooltip is a class for creating information tooltips
 * @extends Widget
 * */
var Tooltip = {};
Object.extend(Object.extend(Tooltip, Widget), (function() {
    function build(id) {
        var container;
        if (container = $(id)) {
            if (container.setContent)
                this.current = container;
            else
                throw new Error('An element with id "' + id + '" already exists!');
            return;
        }
        
        container = new Element('div', {className: 'tooltip', id: id});
        var content = new Element('div', {className: 'tooltip_content'});
        var bubble1 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_1'});
        var bubble2 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_2'});
        var bubble3 = new Element('div', {className: 'tooltip_bubble tooltip_bubble_3'});

        container.appendChild(bubble3);
        container.appendChild(bubble2);
        container.appendChild(bubble1);
        container.appendChild(content);
        container.style.display = 'none';

        var script = $(id + '_script');
        pivot = $(this.options.pivot);
        if (script)
            script.parentNode.appendChild(container);
        else if (pivot)
            pivot.parentNode.appendChild(container);
        else
            document.body.appendChild(container);

        if (this.options.followMouse) {
            container.setStyle({marginTop: '5px'});
            Event.observe(document, 'mousemove', move.bindAsEventListener(container), false);
        }

        this.current = container;
        this.content = content;
        this.bubbles = new Array(bubble1, bubble2, bubble3);

        return this;
    }

    function draw(x, y) {
        var bubbles = [{width: 14, left: 10}, {width: 10, left: 6}, {width: 7, left: 14}];
        if (typeof x == 'undefined') {
            this.bubbles[0].setStyle({width: bubbles[0].width + 'px', height: '14px', top: '-10px', left: bubbles[0].left + 'px', 'z-index': 17});
            this.bubbles[1].setStyle({width: bubbles[1].width + 'px', height: '10px', top: '-4px', left: bubbles[1].left + 'px', 'z-index': 16});
            this.bubbles[2].setStyle({width: bubbles[2].width + 'px', height: '7px', left: bubbles[2].left + 'px'});
            this.content.setStyle({top: '-18px', width: this.options.width});
            this.style.width = this.options.width;

            return this;
        }

        var vdims = document.viewport.getDimensions();
        var tdims = this.getDimensions();
        var compensation = this.options.followMouse ? 2.5 : 0;
        var margins = 5;
        var left = x;
        var top = y;
        if (x < margins) left = margins;
        if (x + tdims.width > vdims.width - margins)
            left = vdims.width - tdims.width - margins;
        if (y < margins) top = margins;
        if (y + tdims.height > vdims.height - margins)
            top = vdims.height - tdims.height - margins;

        var const_offset = bubbles[2].left + bubbles[2].width + compensation;
        var offset_x = x - left - const_offset;
        if (offset_x > tdims.width) offset_x = tdims.width;
        var offset_ratio = offset_x / tdims.width;
        if (offset_ratio < 0) offset_ratio = 0;

        var bubble0_x = (tdims.width - 2 * bubbles[0].left - bubbles[0].width + const_offset) * offset_ratio + bubbles[0].left;
        var bubble1_x = (tdims.width - 2 * bubbles[1].left - bubbles[1].width + const_offset) * offset_ratio + bubbles[1].left;
        var bubble2_x = (tdims.width - 2 * bubbles[2].left - bubbles[2].width + const_offset) * offset_ratio + bubbles[2].left;

        this.bubbles[0].style.left = bubble0_x + 'px';
        this.bubbles[1].style.left = bubble1_x + 'px';
        this.bubbles[2].style.left = bubble2_x + 'px';

        if (offset_x < 0)
            this.setStyle({left: left + offset_x + 'px', top: top + 'px'});
        else {
            this.setStyle({left: left + 'px', top: top + 'px'});
        }
    }

    function move(e) {
        var x = Event.pointerX(e);
        var y = Event.pointerY(e);

        return draw.call(this, x, y);
    }

    return {
        /**
         * Shows the tooltip
         * @returns The object
         * */
        showTooltip: function() {
            this.placeAtElement();
            if (this.__fade) this.__fade.cancel();
            this.__appear = Effect.Appear(this, {duration: 0.25});
            return this;
        },
        /**
         * Hides the tooltip
         * @returns The object
         * */
        hideTooltip: function() {
            if (this.__appear) this.__appear.cancel();
            this._fade = Effect.Fade(this, {duration: 0.5});
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
            if (Prototype.Browser.Opera) {
                if (scroll[0] != pos[0])
                    pos[0] -= scroll[0];
                if (scroll[1] != pos[1])
                    pos[1] -= scroll[1];
            } else {
                pos[0] -= scroll[0];
                pos[1] -= scroll[1];
            }
            pos[1] += this.element.getDimensions().height;

            if (this.options.centerOnElement)
                pos[0] += this.element.getDimensions().width/2;
            draw.call(this, pos[0], pos[1]);

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
                pivot: false,
                followMouse: false
            }, arguments[1] || {})
            if (!id) id = 'tooltip' + Math.random();
            build.call(this, id);
            return true;
        },
        _init: function() {
            if (parseInt(this.options.width))
                this.options.width = parseInt(this.options.width) + 'px';
            draw.call(this);
        }
    }
})());

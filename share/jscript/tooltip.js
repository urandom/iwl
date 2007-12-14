// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Tooltip is a class for creating information tooltips
 * @extends IWL.Widget
 * */
IWL.Tooltip = Object.extend(Object.extend({}, IWL.Widget), (function() {
    function build(id) {
        var container;
        if ((container = $(id)) && !container.hasClassName('tooltip')) {
            throw new Error('An element with id "' + id + '" already exists!');
            return false;
        }

        if (!container)
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
        container.style.visibility = this.options.visibility || '';

        if (this.options.followMouse) {
            container.setStyle({marginTop: '5px'});
            Event.observe(document, 'mousemove', move.bindAsEventListener(container), false);
        }

        this.current = container;
        this.content = content;
        this.bubbles = new Array(bubble1, bubble2, bubble3);

        return true;
    }

    function append() {
        parentNode = this.options.parent == 'document.body' ? document.body : $(this.options.parent);
        if (parentNode || !this.parentNode)
            (parentNode || document.body).appendChild(this);
        if (this.options.content)
            this.setContent(this.options.content);
        if (this.options.bind)
            this.bindToWidget.apply(this, this.options.bind);
        if (this.options.bindHide)
            this.bindHideToWidget.apply(this, this.options.bindHide);
    }

    function draw(x, y) {
        var bubbles = [{width: 14, height: 14, left: 10, top: -10}, {width: 10, height: 10, left: 6, top: -4}, {width: 7, height: 7, left: 14, top: 0}];
        var content_top = -18;
        if (typeof x == 'undefined') {
            this.bubbles[0].setStyle({width: bubbles[0].width + 'px',
                    height: bubbles[0].height + 'px',
                    top: bubbles[0].top + 'px', left: bubbles[0].left + 'px', 'z-index': 17});
            this.bubbles[1].setStyle({width: bubbles[1].width + 'px',
                    height: bubbles[1].height + 'px',
                    top: bubbles[1].top + 'px', left: bubbles[1].left + 'px', 'z-index': 16});
            this.bubbles[2].setStyle({width: bubbles[2].width + 'px',
                    height: bubbles[2].height + 'px',
                    left: bubbles[2].left + 'px'});
            this.content.setStyle({top: content_top + 'px', width: this.options.width});
            this.style.width = this.options.width;

            return this;
        }

        var viewport_dims = document.viewport.getDimensions();
        var scroll_offset = document.viewport.getScrollOffsets();
        var tooltip_dims = this.getDimensions();
        var element_top = elementRealPosition.call(this)[1];
        var compensation = this.options.followMouse ? 2.5 : 0;
        var margins = 5;
        var left = x;
        var top = y;
        if (Prototype.Browser.Gecko) {
            var max_dims = document.viewport.getMaxDimensions();
            var scroll_size = document.viewport.getScrollbarSize();
            viewport_dims.width -= max_dims.height > viewport_dims.height ? scroll_size : 0;
            viewport_dims.height -= max_dims.width > viewport_dims.width ? scroll_size : 0;
        }

        if (x < margins + scroll_offset.left) left = margins + scroll_offset.left;
        if (x + tooltip_dims.width > viewport_dims.width + scroll_offset.left - margins)
            left = viewport_dims.width + scroll_offset.left - margins - tooltip_dims.width;
        if (y < margins + scroll_offset.top) top = margins + scroll_offset.top;
        if (y + tooltip_dims.height > viewport_dims.height + scroll_offset.top - margins)
            top = element_top
                ? element_top - tooltip_dims.height
                : viewport_dims.height + scroll_offset.top - margins - tooltip_dims.height;

        /* Vertical offset */
        if (top < y) {
            var old_visibility = this.style.visibility;
            var old_display = this.style.display;
            this.style.visibility = this.visible() ? '' : 'hidden';
            this.style.display = '';

            var cheight = this.content.getHeight();
            var height  = cheight - 2 * content_top - bubbles[2].height;
            this.bubbles[2].style.top = height + 'px';
            height -= (bubbles[2].height + bubbles[1].height);
            this.bubbles[1].style.top = height + 'px';
            height -= (bubbles[1].height + bubbles[0].height);
            this.bubbles[0].style.top = height + 'px';

            this.style.display = old_display;
            this.style.visibility = old_visibility;
        } else {
            this.bubbles[2].style.top = bubbles[2].top + 'px';
            this.bubbles[1].style.top = bubbles[1].top + 'px';
            this.bubbles[0].style.top = bubbles[0].top + 'px';
        }

        /* Horizontal offset */
        var const_offset = bubbles[2].left + bubbles[2].width + compensation;
        var offset_x = x - left - const_offset;
        if (offset_x > tooltip_dims.width) offset_x = tooltip_dims.width;
        var offset_ratio = offset_x / tooltip_dims.width;
        if (offset_ratio < 0) offset_ratio = 0;

        var bubble0_x = (tooltip_dims.width - 2 * bubbles[0].left - bubbles[0].width + const_offset) * offset_ratio + bubbles[0].left;
        var bubble1_x = (tooltip_dims.width - 2 * bubbles[1].left - bubbles[1].width + const_offset) * offset_ratio + bubbles[1].left;
        var bubble2_x = (tooltip_dims.width - 2 * bubbles[2].left - bubbles[2].width + const_offset) * offset_ratio + bubbles[2].left;

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
        if (!this.__positioned) return;

        return draw.call(this, x, y);
    }

    function placeAtElement() {
        this.__positioned = false;
        if (!this.element) return false;

        var viewport_scroll = document.viewport.getScrollOffsets();
        var viewport_dims = document.viewport.getDimensions();
        pos = elementRealPosition.call(this);
        pos[1] += this.element.getHeight();

        if (this.options.centerOnElement)
            pos[0] += this.element.getWidth()/2;

        if (pos[0] > viewport_dims.width + viewport_scroll.left ||
            pos[1] > viewport_dims.height + viewport_scroll.height)
            return false;

        this.__positioned = true;
        draw.call(this, pos[0], pos[1]);
        return true;
    }

    function elementRealPosition() {
        if (!this.element) return [0, 0];
        var pos = this.element.cumulativeOffset();
        var scroll = this.element.cumulativeScrollOffset();
        var viewport_scroll = document.viewport.getScrollOffsets();
        if (scroll[0] || (Prototype.Browser.Opera && scroll[0] != pos[0]))
            scroll[0] -= viewport_scroll.left;
        if (scroll[1] || (Prototype.Browser.Opera && scroll[1] != pos[1]))
            scroll[1] -= viewport_scroll.top;

        if (Prototype.Browser.Opera) {
            if (scroll[0] != pos[0])
                pos[0] -= scroll[0];
            if (scroll[1] != pos[1])
                pos[1] -= scroll[1];
        } else {
            pos[0] -= scroll[0];
            pos[1] -= scroll[1];
        }

        return pos;
    }

    function bindEvent(event, toggle) {
        if (!this.visible() || this.__fade) {
            this.showTooltip();
            Event.stop(event);
        } else if (toggle && (this.visible() || this.__appear)) {
            this.hideTooltip();
            Event.stop(event);
        }
    }

    return {
        /**
         * Shows the tooltip
         * @returns The object
         * */
        showTooltip: function() {
            if (!placeAtElement.call(this)) return;
            if (this.__fade) {
                this.__fade.cancel();
                this.__fade = undefined;
            }
            this.__appear = new Effect.Appear(this, {
                    duration: 0.25,
                    afterFinish: function() { this.__appear = undefined; this.emitSignal('iwl:show') }.bind(this)
            });
            return this;
        },
        /**
         * Hides the tooltip
         * @returns The object
         * */
        hideTooltip: function() {
            if (this.__appear) {
                this.__appear.cancel();
                this.__appear = undefined;
            }
            this._fade = new Effect.Fade(this, {
                    duration: 0.5,
                    afterFinish: function() { this.__fade = undefined; this.emitSignal('iwl:hide') }.bind(this)
            });
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
                if (Object.isElement(elements))
                    this.content.appendChild(elements);
                else
                    $A(elements).each(function($_) {
                        if (Object.isElement($_)) this.content.appendChild($_)
                    }.bind(this));
            }
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
         * @param {Boolean} toggle True, if the signal should toggle the visibility state of the tooltip
         * @returns The object
         * */
        bindToWidget: function(element, signal, toggle) {
            this.element = $(element);
            if (!this.element) return;
            this.element.signalConnect(signal, bindEvent.bindAsEventListener(this, toggle));
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
            if (!(element = $(element))) return;
            element.signalConnect(signal, function (event) {
                if (this.visible() || this.__appear) {
                    this.hideTooltip();
                    Event.stop(event);
                }
            }.bind(this));
            return this;
        },

        _preInit: function(id) {
            this.options = Object.extend({
                width:      'auto',
                centerOnElement: true,
                hidden: false,
                parent: false,
                followMouse: false,
                content: false,
                bind: false,
                bindHide: false
            }, arguments[1] || {});
            if (!id) id = 'tooltip_' + Math.random();
            return build.call(this, id);
        },
        _init: function() {
            if (parseInt(this.options.width))
                this.options.width = parseInt(this.options.width) + 'px';

            if (document.loaded)
                append.call(this);
            else
                document.observe('dom:loaded', append.bind(this));

            draw.call(this);
        }
    }
})());

/* Deprecated */
var Tooltip = IWL.Tooltip;

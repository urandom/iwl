// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.PageControl is a class for adding paging functionality to widgets
 * @extends IWL.Widget
 * */
IWL.PageControl = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function initEvents() {
        this.firstButton.signalConnect('click', function() {
            this.setCurrentPage('first');
        }.bind(this));
        this.prevButton.signalConnect('click', function() {
            this.setCurrentPage('prev');
        }.bind(this));
        this.nextButton.signalConnect('click', function() {
            this.setCurrentPage('next');
        }.bind(this));
        this.lastButton.signalConnect('click', function() {
            this.setCurrentPage('last');
        }.bind(this));
        this.input.signalConnect('keydown', function(event) {
            if (event.keyCode == Event.KEY_RETURN && this.input.value != this.currentPage) {
                if (!this.input.checkValue({reg:/^\d*$/, range: $R(1, Infinity)})) return;
                this.setCurrentPage(parseInt(this.input.value));
            }
        }.bind(this));
    }

    function onEventComplete(json, params, options) {
        if (options.update) {
            var page = {
                input: params.value,
                first: 1,
                prev: params.page - 1 || 1,
                next: params.page + 1 > params.pageCount ? params.pageCount : params.page + 1,
                last: params.pageCount
            };
            var page_options = {page: page[params.type]};
        } else {
            var page_options = json.extras;
        }
        if (page_options) {
            if (page_options.page)
                this.currentPage = page_options.page;
            if (page_options.pageSize)
                this.setPageSize(page_options.pageSize);

            if (page_options.pageCount) {
                this.setPageCount(page_options.pageCount);
            } else {
                refresh.call(this);
            }
        } else {
            refresh.call(this);
        }
        this.emitSignal('iwl:current_page_change');
    }

    function refresh() {
        if (!this.loaded) return;
        if (!this.options.bound || this.options.pageCount <= 1) {
            var hidden = {visibility: 'hidden'};
            this.setStyle(hidden);
            this.firstButton.setStyle(hidden);
            this.prevButton.setStyle(hidden);
            this.nextButton.setStyle(hidden);
            this.lastButton.setStyle(hidden);
            this.labelContainer.setStyle(hidden);
        } else {
            var dims = this.getDimensions();
            this.setStyle({width: dims.width + 'px', height: dims.height + 'px', visibility: 'visible'});
            this.labelContainer.style.visibility = 'visible';
            toggleButtons.call(this);
            this.input.value = this.currentPage;
        }
    }

    function toggleButtons() {
        var visible = {visibility: 'visible'};
        var hidden = {visibility: 'hidden'};
        if (this.currentPage == 1) {
            this.firstButton.setStyle(hidden);
            this.prevButton.setStyle(hidden);
        } else {
            this.firstButton.setStyle(visible);
            this.prevButton.setStyle(visible);
        }
        if (this.currentPage == this.options.pageCount) {
            this.nextButton.setStyle(hidden);
            this.lastButton.setStyle(hidden);
        } else {
            this.nextButton.setStyle(visible);
            this.lastButton.setStyle(visible);
        }
    }

    function alignLabels() {
        var height = this.nextButton.getHeight() + (parseFloat(this.nextButton.getStyle('margin-top')) || 0) + 'px';
        this.labelContainer.select('span').each(function(span) {
            span.style.lineHeight = height;
        }.bind(this));
    }

    return {
        /**
         * Binds an element to the page control widget
         * @param element The element to bind to
         * @param event_name The event name associated with the page. Example: 'IWL-Tree-refresh'
         * @returns The object
         * */
        bindToWidget: function(element, event_name) {
            if (this.element) return;
            this.element = $(element);
            this.eventName = event_name;
            if (!this.element || !this.eventName)
                return;
            this.options.bound = true;
            refresh.call(this);
            return this;
        },
        /**
         * Unbinds the page control from the current bound element
         * @returns The object
         * */
        unbind: function() {
            if (!this.element) return;

            this.options.bound = false;
            this.element = null;
            this.eventName = '';
            refresh.call(this);
            return this;
        },
        /**
         * Sets the page count for the page control widget
         * @param {int} count The number of pages
         * @returns The object
         * */
        setPageCount: function(count) {
            if (this.options.pageCount != count)
                this.label.update(count);
            this.options.pageCount = count;
            refresh.call(this);
            return this;
        },
        /**
         * Sets the page size for the page control widget
         * @param {int} size The number of elements for each page
         * @returns The object
         * */
        setPageSize: function(size) {
            this.options.pageSize = size;
            return this;
        },
        /**
         * Changes the current page to the requested one
         * @param page The page to change to. Can be either an integer, or one of the following strings:
         *                 first: Goes to the first page
         *                 prev: Goes to the previous page
         *                 next: Goes to the next page
         *                 last: Goes to the last page
         * @param parameters Additional parameters to pass to the when changing the page.
         * @returns The object
         * */
        setCurrentPage: function(page) {
            if (!this.element) return;

            var parameters = Object.extend({}, arguments[1]);
            if (typeof page == 'number' && page > 0)
                Object.extend(parameters, {type: 'input', value: page});
            else if (["first", "prev", "next", "last"].include(page))
                Object.extend(parameters, {type: page});
            else return;
            this.emitSignal('iwl:current_page_is_changing', parameters);
            this.element.emitEvent(this.eventName, Object.extend(parameters, {
                page: this.currentPage,
                pageSize: this.options.pageSize,
                pageCount: this.options.pageCount
            }), {responseCallback: onEventComplete.bind(this)});
            return this;
        },
        /**
         * @ignore
         * */
        getDimensions: function() {
            var dims = {width: 0, height: 0};
            [this.firstButton, this.prevButton, this.nextButton, this.lastButton].concat(this.labelContainer.childElements()).each(
                function(n) {
                    n = Element.extend(n);
                    var d = n.getDimensions();
                    var m = [n.getStyle('margin-top'), n.getStyle('margin-right'), n.getStyle('margin-bottom'), n.getStyle('margin-left')];
                    dims.width += d.width + parseInt(m[1] || 0) + parseInt(m[3] || 0);

                    dims.height = Math.max(d.height + parseInt(m[0] || 0) + parseInt(m[2] || 0), dims.height);
                }.bind(this)
            );
            /* 3px gap bug */
            if (Prototype.Browser.IE)
                dims.width += 3 * this.labelContainer.select('span').length + 3;
            /* 1px+ in Gecko 1.9 */
            if (Prototype.Browser.Gecko)
                dims.width += 1;
            return dims;
        },

        _init: function(id) {
            var buttonCount = 5;
            var visibility = this.getStyle('visibility');
            this.style.visibility = 'hidden';
            this.loaded = false;
            var buttonLoad = function(event) {
                event.stop();
                if (--buttonCount === 0) {
                    this.loaded = true;
                    refresh.call(this);
                    alignLabels.call(this);
                    this.style.visibility = visibility; 
                    this.emitSignal('iwl:load');
                }
            };
            this.firstButton = $(this.id + '_first').signalConnect('iwl:load', buttonLoad.bindAsEventListener(this));
            this.prevButton = $(this.id + '_prev').signalConnect('iwl:load', buttonLoad.bindAsEventListener(this));
            this.labelContainer = $(this.id + '_label');
            this.input = $(this.id + '_page_entry_text');
            this.label = $(this.id + '_page_count');
            this.nextButton = $(this.id + '_next').signalConnect('iwl:load', buttonLoad.bindAsEventListener(this));
            this.lastButton = $(this.id + '_last').signalConnect('iwl:load', buttonLoad.bindAsEventListener(this));
            $(this.id + '_page_entry').signalConnect('iwl:load', buttonLoad.bindAsEventListener(this));
            this.options = Object.extend({
                bound: false,
                page: 1
            }, arguments[1] || {});
            this.input.value = this.currentPage = this.options.page;
            this.show();

            initEvents.call(this);
        }
    }
})());

/* Deprecated */
var PageControl = IWL.PageControl;

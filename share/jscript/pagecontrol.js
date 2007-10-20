// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.PageControl is a class for adding paging functionality to widgets
 * @extends IWL.Widget
 * */
IWL.PageControl = Object.extend(Object.extend({}, IWL.Widget), {
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
	this.__refresh();
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
	this.__refresh();
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
     * @ignore
     * */
    getDimensions: function() {
	var dims = {width: 0, height: 0};
	[this.firstButton, this.prevButton, this.labelContainer, this.nextButton, this.lastButton].each(
	    function(n) {
		var d = n.getDimensions();
		var m = [n.getStyle('margin-top'), n.getStyle('margin-right'), n.getStyle('margin-bottom'), n.getStyle('margin-left')];
		dims.width += d.width + parseInt(m[1] || 0) + parseInt(m[3] || 0);

		dims.height = Math.max(d.height + parseInt(m[0] || 0) + parseInt(m[2] || 0), dims.height);
	    }.bind(this)
	);
	// FIXME: why does IE need this additional width?
	if (Prototype.Browser.IE)
	    dims.width += 3;
	return dims;
    },

    _init: function(id) {
	this._buttonCount = 4;
	this.loaded = false;
	var buttonLoad = function() {
	    if (--this._buttonCount === 0) {
		this.loaded = true;
		this.__refresh();
		this.emitSignal('iwl:load');
	    }
	};
	this.firstButton = $(this.id + '_first').signalConnect('load', buttonLoad.bind(this));
	this.prevButton = $(this.id + '_prev').signalConnect('load', buttonLoad.bind(this));
	this.labelContainer = $(this.id + '_label');
	this.input = $(this.id + '_page_entry_text');
	this.label = $(this.id + '_page_count');
	this.nextButton = $(this.id + '_next').signalConnect('load', buttonLoad.bind(this));
	this.lastButton = $(this.id + '_last').signalConnect('load', buttonLoad.bind(this));
	this.options = Object.extend({
	    bound: false,
	    page: 1
	}, arguments[1] || {});
	this.input.value = this.currentPage = this.options.page;
	this.show();

	this.__initEvents();
    },
    __initEvents: function() {
	this.firstButton.signalConnect('click', function() {
	    if (!this.element) return;
	    this.emitSignal('iwl:current_page_is_changing', {type: 'first'});
	    this.element.emitEvent(this.eventName, {
		page: this.currentPage, type: 'first',
		pageSize: this.options.pageSize, pageCount: this.options.pageCount
	    }, {responseCallback: this.__onEventComplete.bind(this)});
	}.bind(this));
	this.prevButton.signalConnect('click', function() {
	    if (!this.element) return;
	    this.emitSignal('iwl:current_page_is_changing', {type: 'prev'});
	    this.element.emitEvent(this.eventName, {
		page: this.currentPage, type: 'prev',
		pageSize: this.options.pageSize, pageCount: this.options.pageCount
	    }, {responseCallback: this.__onEventComplete.bind(this)});
	}.bind(this));
	this.nextButton.signalConnect('click', function() {
	    if (!this.element) return;
	    this.emitSignal('iwl:current_page_is_changing', {type: 'next'});
	    this.element.emitEvent(this.eventName, {
		page: this.currentPage, type: 'next',
		pageSize: this.options.pageSize, pageCount: this.options.pageCount
	    }, {responseCallback: this.__onEventComplete.bind(this)});
	}.bind(this));
	this.lastButton.signalConnect('click', function() {
	    if (!this.element) return;
	    this.emitSignal('iwl:current_page_is_changing', {type: 'last'});
	    this.element.emitEvent(this.eventName, {
		page: this.currentPage, type: 'last',
		pageSize: this.options.pageSize, pageCount: this.options.pageCount
	    }, {responseCallback: this.__onEventComplete.bind(this)});
	}.bind(this));
	this.input.signalConnect('keydown', function(event) {
	    if (!this.element) return;
	    if (event.keyCode == 13 && this.input.value != this.currentPage) {
		if (!this.input.checkElementValue({reg:/^\d*$/})) return;
		this.emitSignal('iwl:current_page_is_changing', {type: 'input', value: this.input.value});
		this.element.emitEvent(this.eventName, {
		    page: this.currentPage, type: 'input',
		    value: this.input.value, pageSize: this.options.pageSize, pageCount: this.options.pageCount
		}, {responseCallback: this.__onEventComplete.bind(this)});
	    }
	}.bind(this));
    },
    __refresh: function() {
	if (!this.loaded) return;
	if (!this.options.bound || this.options.pageCount <= 1) {
	    var hidden = {visibility: 'hidden'};
	    this.setStyle(hidden);
	    this.firstButton.setStyle(hidden);
	    this.prevButton.setStyle(hidden);
	    this.nextButton.setStyle(hidden);
	    this.lastButton.setStyle(hidden);
	} else {
	    var dims = this.getDimensions();
	    this.setStyle({width: dims.width + 'px', height: dims.height + 'px', visibility: 'visible'});
	    this.__toggleButtons();
	    this.input.value = this.currentPage;
	}
    },
    __onEventComplete: function(json, params, options) {
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
		this.__refresh();
	    }
	} else {
	    this.__refresh();
	}
	this.emitSignal('iwl:current_page_change');
    },
    __toggleButtons: function() {
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
});

/* Deprecated */
var PageControl = IWL.PageControl;

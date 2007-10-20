// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.Upload is a class for adding custom styled file upload widgets
 * @extends IWL.Widget
 * */
IWL.Upload = Object.extend(Object.extend({}, IWL.Widget), (function () {
    function adjust() {
        var button_width = parseInt(this.button.style.width);
        var file_width = Element.getDimensions(this.file).width;
        if (!button_width || !file_width) {
            adjust.bind(this).delay(0.5);
            return;
        }

        if (!Prototype.Browser.WebKit)
            Element.setStyle(this.file, {left: -1 * (file_width - button_width) + 'px'});
        this.file.setStyle({opacity: 0.001, visibility: 'visible'});
        this.file.onchange = uploadFile.bindAsEventListener(this);
        this.file.onkeypress = function() {return false;};
        this.file.onpaste = function() {return false;};
    }

    function uploadFile() {
        this.submit();
        this.tooltip = IWL.Tooltip.create(this.id + '_tooltip', {centerOnElement: false, pivot: this});
        this.tooltip.bindToWidget(this.button);
        this.tooltip.setContent('Uploading ...');

        Event.observe(this.frame, 'load', frameLoad.bind(this));
        Event.observe(this.frame, 'readystatechange', frameReadyStateChange.bind(this));
    }

    function frameLoad() {
        var doc;
        if (this.frame.contentDocument) {
            doc = this.frame.contentDocument;
        } else if (this.frame.contentWindow) {
            doc = this.frame.contentWindow.document;
        } else if (this.frame.document) {
            doc = this.frame.document;
        }
        if (doc.document) doc = doc.document;
        var json = eval('(' + unescape(doc.body.firstChild.nodeValue) + ')');

        if (json && json.message)
            this.tooltip.setContent(json.message);
        setTimeout(function() {
            Effect.Fade(this.tooltip, {duration: 1,
                queue: {position: 'start', scope: 'upload_queue'}});
            setTimeout(function() {
                if (!this.tooltip) return;
                this.tooltip.remove();
                this.tooltip = null;
            }.bind(this), 1000);
        }.bind(this), 2000);
        if (this.options.uploadCallback && this.options.uploadCallback.apply)
            this.options.uploadCallback.apply(this, [json]);
    }

    function frameReadyStateChange() {
        if (this.frame.readyState == 'complete')
            frameLoad.call(this);
    }

    return {
        _init: function(id, form) {
            var button = $(id + '_button');
            if (!button) {
                var args = arguments;
                setTimeout(function () {this._init.apply(this, args)}.bind(this), 500);
                return;
            }
            this.options = Object.extend({
                uploadCallback: Prototype.emptyFunction
            }, arguments[2] || {});
            IWL.createHtmlElement(form, button);
            this.file = $(id + '_file');
            this.button = button;
            this.frame = $(id + '_frame');
            this.tooltip = null;
            adjust.call(this);
        }
    }
})());

/* Deprecated */
var Upload = IWL.Upload;

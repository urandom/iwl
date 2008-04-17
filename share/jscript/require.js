document.require = (function() {
    if (!document._urlCache)
        document._urlCache = {};

    return function(url) {
        if (!Object.isString(url) || url.blank()) return false;
        if (document._urlCache[url]) return true;

        var scripts = $$('script').pluck('src');
        if (scripts.invoke('endsWith', url).any())
            return document._urlCache[url] = true;

        var status = false;
        new Ajax.Request(url, {
            method: 'get',
            asynchronous: false, 
            evalJS: false,
            evalJSON: false,
            onSuccess: function(or) {
                document._urlCache[url] = status = true;
                var parent = document.getElementsByTagName('head')[0] || document.body,
                    script = new Element('script', {type: 'text/javascript'});

                script.text = or.responseText;
                parent.appendChild(script);
            }
        });
        return status;
    }
})();

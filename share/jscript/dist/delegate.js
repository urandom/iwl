/* Homepage: http://kendsnyder.com/sandbox/delegate/ */
Object.extend(Event, (function() {
	var cache = { };
	return {
		delegate: function(element, eventName) {
			if (arguments[3]) {
				var rules = { };
				rules[arguments[2]] = arguments[3];
			} else {
				var rules = Object.extend({ }, arguments[2]);
			}
			var el = $(element), ev = eventName, id = el.identify ? el.identify() : 'document';
			if (!cache[id]) {
				cache[id] = {'$observer': function(event) {
					var el = event.element();
					if (cache[id][event.type])
						for (var i = 0, len = cache[id][event.type].length; i < len; i++)
							for (var selector in cache[id][event.type][i])
								if (cache[id][event.type][i][selector][1].match(el))
									cache[id][event.type][i][selector][0](event);
				}};				
			}
			if (!cache[id][ev]) {
				cache[id][ev] = [];
				el.observe(ev, cache[id]['$observer']);
			}
			for (var selectorStr in rules)
				rules[selectorStr] = [rules[selectorStr], new Selector(selectorStr)];
			cache[id][ev].push(rules);
			return el;
		},
		stopDelegating: function(element, eventName) {
			if (element === undefined) {
				for (var id in cache)
					Event.stopDelegating(id == '$document' ? document : id);
				cache = { };
				return true;
			}
			if (Object.isString(arguments[2])) {
				var rules = { };
				rules[arguments[2]] = true;
			} else if (arguments[2]) {
				var rules = arguments[2];
			} else {
				var rules = false;
			}
			var el = $(element), ev = eventName, id = el.identify ? el.identify() : '$document';
			if (cache[id]) {
				if (ev && cache[id][ev]) {
					for (var i = 0, len = cache[id][ev].length; i < len; i++) {
						if (rules) {
							for (var selector in rules)
								delete cache[id][ev][i][selector];
						}
						if (!rules || $H(cache[id][ev][i]).size() == 0) {
							el.stopObserving(ev, cache[id]['$observer']);
							cache[id][ev][i] = 'r';
						}
					}
					cache[id][ev] = cache[id][ev].without('r');
				} else {
					for (var evName in cache[id])
						if (evName != '$observer')
							el.stopObserving(evName, cache[id]['$observer']);
					delete cache[id];
				}
			}
			return el;
		}
	};
})());
Element.addMethods({delegate: Event.delegate, stopDelegating: Event.stopDelegating});
document.delegate = Event.delegate.curry(document);
document.stopDelegating = Event.stopDelegating.curry(document);
Event.observe(window, 'unload', Event.stopDelegating);

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.ObservableModel = Class.create(Enumerable, (function() {
  return {
    initialize: function() {
      this.frozen = false;
      this._emitter = new Element('div', {style: "display: none"});
      document.body.appendChild(this._emitter);
    },
    
    freeze: function() {
      this.frozen++;
      return this;
    },
    thaw: function() {
      this.frozen--;
      if (this.frozen < 1) this.frozen = false;
      return this;
    },
    isFrozen: function() {
      return this.frozen;
    },

    signalConnect: function(name, observer) {
      this._emitter.signalConnect(name, observer);
      return this;
    },
    signalDisconnect: function(name, observer) {
      this._emitter.signalDisconnect(name, observer);
      return this;
    },
    emitSignal: function() {
      if (this.frozen) return;
      var args = $A(arguments);
      var name = args.shift();
      Event.fire(this._emitter, name, args);
      return this;
    },
    registerEvent: function() {
      this._emitter.registerEvent.apply(this._emitter, arguments);
      return this;
    },
    prepareEvents: function() {
      this._emitter.prepareEvents.apply(this._emitter, arguments);
      return this;
    },
    emitEvent: function() {
      this._emitter.emitEvent.apply(this._emitter, arguments);
      return this;
    },
    hasEvent: function() {
      return this._emitter.hasEvent.apply(this._emitter, arguments);
    }
  };
})());

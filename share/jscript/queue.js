// vim: set autoindent shiftwidth=2 tabstop=8:
if (!window.IWL) window.IWL = {};

IWL.Queue = Class.create((function() {
  var map = {};
  return {
    initialize: function() {
      this.options = Object.extend({
        id: Math.random()
      }, arguments[0] || {});
      
      map[this.options.id] = {processes: [], flags: {running: false}};
    },

    add: function(callback) {
      var localMap = map[this.options.id];
      localMap.processes.push(callback);
      if (localMap.processes.length == 1) {
        localMap.flags.running = true;
        callback(this);
      }
      return this;
    },
    end: function() {
      var localMap = map[this.options.id];
      if (!localMap.flags.running) return;
      localMap.processes.shift();
      if (localMap.processes.length > 0)
        localMap.processes[0](this);
      else
        localMap.flags.running = false;
      return this;
    }
  }
})());

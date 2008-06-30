// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.ListModel = Class.create(IWL.ObservableModel, (function() {
  function sortResponse(response, params, options) {
    this.freeze().loadData(response.data);
    this.thaw().emitSignal('iwl:sort_column_change');
  }

  function loadNodes(nodes, options) {
    if ('preserve' in options && !options.preserve)
      this.rootNodes = [];

    var length = nodes.length;
    for (var i = 0; i < length; i++) {
      var n = nodes[i], node = this.insertNode(options.index);
      if (n.values && n.values.length)
        node.values = n.values.slice(0, this.columns.length);
      if (n.attributes)
        node.attributes = Object.extend({}, n.attributes);
    }
  }

  function getNodes() {
    var ret = [];

    for (var i = 0, l = this.rootNodes.length; i < l; i++) {
      var n = this.rootNodes[i], node = {};
      node.values = n.values;
      node.attributes = n.attributes;
      ret.push(node);
    }
    
    return ret;
  }

  function RPCStartCallback(event, params, options) {
    if (event.endsWith('refresh')) {
      options.totalCount = this.options.totalCount;
      options.limit = this.options.limit;
      options.offset = this.options.offset;
      options.columns = this.columns;
      options.id = this.options.id;
    }
  }

  function refreshResponse(json, params, options) {
    this.loadData(json.data);
  }

  return {
    initialize: function($super, columns, data) {
      $super();
      if (Object.isObject(columns) && columns.columns) {
        data = columns;
        columns = columns.columns;
      }

      this.rootNodes = [];
      this.columns = new Array(columns.length);
      this.sortMethods = [];
      for (var i = 0, l = columns.length; i < l; i++) {
        this.setColumn(i, columns[i]);
      }
      this.options = {};
      this.loadData(data);
      this._emitter._refreshResponse = refreshResponse.bind(this);
    },

    addColumnType: function() {
      IWL.ListModel.addColumnType.apply(this, arguments);
      return this;
    },
    getColumnType: function(index) {
      return this.columns[index] ? this.columns[index].type : undefined;
    },
    getColumnName: function(index) {
      return this.columns[index] ? this.columns[index].name : undefined;
    },
    getColumnCount: function() {
      return this.columns.length;
    },
    setColumn: function(index, type, name) {
      if (Object.isObject(type))
        this.columns[index] = type;
      else
        this.columns[index] = {
          type: type,
          name: name
        };
    },

    getFirstNode: function() {
      return this.rootNodes[0];
    },
    getRootNodes: function() {
      return this.rootNodes;
    },
    getNodeByPath: function(path) {
      if (Object.isArray(path)) path = path[0];
      return this.rootNodes[path];
    },

    /* Sortable Interface */
    setSortMethod: function(index, options) {
      this.sortMethods[index] = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-ListModel-sortColumn', options.url, {}, {
          responseCallback: sortResponse.bind(this),
          id: this.options.id
        });
      }
      return this;
    },
    setDefaultOrderMethod: function(options) {
      this.defaultOrderMethod = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-ListModel-sortColumn', options.url, {}, {
          responseCallback: sortResponse.bind(this),
          id: this.options.id
        });
      }
      return this;
    },
    getSortColumn: function() {
      return this.sortColumn || {index: -1};
    },
    setSortColumn: function(index, sortType) {
      var options;
      if (index == -1)
        options = this.defaultOrderMethod;
      else
        options = this.sortMethods[index];

      if (!options) return;
      this.sortColumn = {index: index, sortType: sortType || IWL.ListModel.SortTypes.DESCENDING};
      var asc = this.sortColumn.sortType == IWL.ListModel.SortTypes.ASCENDING;

      if (Object.isString(options.url) && !options.url.blank()) {
        var emitOptions = {};
        if (index == -1)
          emitOptions.defaultOrder = 1;

        emitOptions.ascending = asc ? 1 : 0;
        return this.emitEvent('IWL-ListModel-sortColumn', {}, emitOptions);
      } else if (!Object.isFunction(options.sortable)) return;

      var wrapper = function(a, b) {
        var ret = options.sortable(a.values[index], b.values[index]);
        return asc ? ret * -1 : ret;
      };
      sortDepth.call(this, this.rootNodes, wrapper);

      return this.emitSignal('iwl:sort_column_change');
    },
    /* !Sortable Interface */

    removeNode: function(node) {
      return node.remove();
    },

    insertNode: function(index) {
      return new IWL.ListModel.Node(this, index);
    },

    insertNodeBefore: function(sibling) {
      return new IWL.ListModel.Node(this, sibling.getIndex());
    },

    insertNodeAfter: function(sibling) {
      return new IWL.ListModel.Node(this, sibling.getIndex() + 1);
    },

    prependNode: function() {
      return new IWL.ListModel.Node(this, 0);
    },

    appendNode: function() {
      return new IWL.ListModel.Node(this, -1);
    },

    clear: function() {
      this.freeze();
      this.rootNodes.invoke('remove');
      return this.thaw().emitSignal('iwl:clear');
    },

    reorder: function(order) {
      if (!Object.isArray(order)) return;
      this.freeze();

      var children = this.rootNodes,
          length = order.length;
      if (length != children.length) return;
      for (var i = 0; i < length; i++) {
        var child = children[order[i]];
        child.insert(this, i);
      }

      return this.thaw().emitSignal('iwl:nodes_reorder');
    },

    swap: function(node1, node2) {
      this.freeze();

      var index1 = node1.getIndex(),
          index2 = node2.getIndex();
      node1.insert(this, index2);
      node2.insert(this, index1);

      return this.thaw().emitSignal('iwl:nodes_swap', node1, node2);
    },

    move: function(node, index) {
      this.freeze();

      node.insert(this, index);
      return this.thaw().emitSignal('iwl:node_move', node);
    },

    loadData: function(data) {
      if (!Object.isObject(data)) return;
      if (!Object.isObject(data.options)) data.options = {};
      Object.extend(this.options, {
        totalCount: data.options.totalCount,
        limit: data.options.limit,
        offset: data.options.offset,
        id: data.options.id
      });
      if ('preserve' in data.options)
        this.options.preserve = !!data.options.preserve;
      if (this.options.id)
        this._emitter.id = this.options.id;
      if (data.options.handlers) {
        var events = data.options.handlers;
        for (var name in events) {
          var options = Object.extend(events[name][2] || {}, {
            startCallback: RPCStartCallback.bind(this)
          });
          IWL.RPC.registerEvent(this._emitter, name, events[name][0], events[name][1], options);
        }
      }

      this.freeze();
      if (Object.isArray(data.nodes))
        loadNodes.call(this, data.nodes, this.options);

      return this.thaw().emitSignal('iwl:load_data');
    },

    getData: function() {
      var data = Object.extend({}, arguments[0]);

      data.nodes = getNodes.call(this);

      return data;
    },

    _each: function(iterator) {
      for (var i = 0, l = this.rootNodes.length; i < l; i++) {
        iterator(this.rootNodes[i]);
      }
    },
    _localSort: function(nodes, wrapper) {
      var previous;

      nodes.sort(wrapper);
      for (var i = 0, l = nodes.length; i < l; i++) {
        var node = nodes[i];
        if (previous) {
          previous.nextSibling = node;
          node.previousSibling = previous;
        }
        node.nextSibling = undefined;

        previous = node;
      }
    }
  };
})());

Object.extend(IWL.ListModel, (function() {
  var index = -1;
  return {
    SortTypes: {
      DESCENDING: 1,
      ASCENDING:  2
    },
    DataType: {
      NONE:     ++index,
      STRING:   ++index,
      INT:      ++index,
      FLOAT:    ++index,
      BOOLEAN:  ++index,
      COUNT:    ++index,
      IMAGE:    ++index
    },
    addColumnType: function() {
      var types = $A(arguments);
      while (types)
        IWL.ListModel.Types[types.shift()] = ++index;
    },
    overrideDefaultDataTypes: function(types) {
      IWL.ListModel.DataType = types;
      index = Math.max.apply(Math, Object.values(types));
    }
  }
})());

IWL.ListModel.Node = Class.create(Enumerable, (function() {
  var counter = 0;

  function RPCStartCallback(event, params, options) {
    if (event.endsWith('refresh')) {
      options.totalCount = this.model.options.totalCount;
      options.limit = this.model.options.limit;
      options.offset = this.model.options.offset;
      options.columns = this.model.columns;
      options.id = this.model.options.id;
    }
  }

  function compareColumns(column1, column2) {
    if (column1.length != column2.length) return false;
    for (var i = 0, l = column1.length; i < l; i++) {
      if (column1[i].type != column2[i].type)
        return false;
    }

    return true;
  }

  return {
    initialize: function(model, index) {
      this.values = [], this.attributes = {id: ++counter};

      if (model)
        this.insert.apply(this, $A(arguments));
    },

    insert: function(model, index) {
      if (!model) return;

      this.remove();
      if (this.model != model)
        this._addModel(model);

      if (isNaN(index) || index < 0)
        index = -1;

      this._addNodeRelationship(index, model.rootNodes);

      this.columns = model.columns.clone();

      this.model.emitSignal('iwl:node_insert', this);

      return this;
    },

    remove: function() {
      var model = this.model;
      if (!model) return;
      this._removeNodeRelationship();
      model.rootNodes = model.rootNodes.without(this);

      if (!model.frozen)
        this._removeModel();

      model.emitSignal('iwl:node_remove', this);

      return this;
    },

    next: function(index) {
      if (!this.model) return;
      var ret = this.nextSibling;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.nextSibling;
        }
      return ret;
    },
    previous: function(index) {
      if (!this.model) return;
      var ret = this.previousSibling;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.previousSibling;
        }
      return ret;
    },

    getValues: function() {
      if (!this.model) return;
      var args = $A(arguments);
      if (!args.length)
        return this.values;
      var ret = [];
      while (args.length)
        ret.push(this.values[args.shift()]);
      return ret;
    },
    setValues: function() {
      if (!this.model) return;
      var args = $A(arguments);
      var v = this.values;
      while (args.length) {
        var tuple = args.splice(0, 2);
        if (!this.columns[tuple[0]])
          continue;
        v[tuple[0]] = tuple[1];
      }

      this.model.emitSignal('iwl:node_change', this);

      return this;
    },

    getAttributes: function() {
      var args = $A(arguments);
      if (!args.length)
        return this.attributes;
      var ret = [];
      while(args.length) {
        var key = args.shift();
        ret.push(this.attributes[key]);
      }

      return ret;
    },

    setAttributes: function() {
      var args = $A(arguments);
      var attrs = {};
      if (args.length == 1 && Object.isObject(args[0]))
        attrs = args[0];
      else while (args.length) {
        var pair = args.splice(0, 2);
        attrs[pair[0]] = pair[1];
      }
      Object.extend(this.attributes, attrs);
      return this;
    },

    getIndex: function() {
      if (!this.model) return -1;
      return this.model.rootNodes.indexOf(this);
    },
    getPath: function() {
      if (!this.model) return [];
      return [this.getIndex()];
    },

    clone: function() {
      var clone = new IWL.ListModel.Node;

      clone.values = this.values.clone();
      clone.attributes = Object.clone(this.attributes);

      clone.attributes.id = Math.random();

      return clone;
    },

    _each: Prototype.emptyFunction,

    _addModel: function(model) {
      this.model = model;
      if (this.columns) {
        if (!compareColumns.call(this, this.columns, model.columns))
          this.values = [];
      }
    },
    _removeModel: function() {
      this.model = undefined;
    },
    _addNodeRelationship: function(index, nodes) {
      var previous, next;

      index > -1
        ? nodes.splice(index, 0, this)
        : nodes.push(this);
      if (index > -1) {
        previous = nodes[index - 1];
        next = nodes[index + 1];
      } else previous = nodes[nodes.length - 2];

      if (previous) {
        previous.nextSibling = this;
        this.previousSibling = previous;
      }

      if (next) {
        next.previousSibling = this;
        this.nextSibling = next;
      }

    },
    _removeNodeRelationship: function() {
      var next = this.nextSibling, previous = this.previousSibling;
      if (next) next.previousSibling = previous;
      if (previous) previous.nextSibling = next;

      this.parentNode = this.nextSibling = this.previousSibling = undefined;
    }
  };
})());

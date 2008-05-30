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

IWL.TreeModel = Class.create(IWL.ObservableModel, (function() {
  function sortDepth(nodes, wrapper) {
    var previous;

    nodes.sort(wrapper);
    nodes.each(function(node) {
      if (previous) {
        previous.nextSibling = node;
        node.previousSibling = previous;
      }
      node.nextSibling = undefined;

      previous = node;
      if (node.childCount)
        sortDepth.call(this, node.childNodes, wrapper);
    });
  }

  /*
   *  [value, [children]]
   */
  function getColumnValues(index, nodes) {
    var ret = [];
    nodes.each(function(node) {
      var r = node.values[index];
      if (node.hasChildren())
        r.push(getColumnValues.call(this, index, node.children()));
      ret.push(r);
    });
    return ret;
  }

  function sortResponse(response, params, options) {
    this.freeze().loadData(response.data);
    this.thaw().emitSignal('iwl:sort_column_change');
  }

  function loadNodes(nodes, parentNode, options) {
    if ('preserve' in options && !options.preserve)
      parentNode ? parentNode.childNodes = [] : this.rootNodes.invoke('remove');

    var length = nodes.length;
    if (parentNode && length == 0) parentNode.childCount = 0;
    for (var i = 0; i < length; i++) {
      var n = nodes[i], node = this.insertNode(parentNode, options.index);
      if (n.childCount == 0)
        node.childCount = 0;
      if (n.values && n.values.length)
        node.values = n.values.slice(0, this.columns.length);
      if (n.attributes)
        node.attributes = Object.extend({}, n.attributes);
      if (n.childNodes && n.childCount)
        loadNodes.call(this, n.childNodes, node, {});
    }
  }

  function getNodes(parentNode) {
    var childNodes = parentNode ? parentNode.childNodes : this.rootNodes;
    var ret = [];

    childNodes.each(function(n) {
      var node = {};
      node.values = n.values;
      node.attributes = n.attributes;
      node.childCount = n.childCount;
      if (n.childNodes && n.childCount)
        node.childNodes = getNodes.call(this, n);
      ret.push(node);
    }.bind(this));

    return ret;
  }

  function flatIterator(node) {
    return node.childCount != 0;
  }

  function flatLocalIterator(node) {
    return node.childCount > 0;
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
      this._emitter._requestChildrenResponse = refreshResponse.bind(this);
    },

    addColumnType: function() {
      IWL.TreeModel.addColumnType.apply(this, arguments);
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
      if (!Object.isArray(path)) return;
      var node = this.rootNodes[path.shift()];
      for (var i = 0, l = path.length; node && i < l; i++)
        node = node.childNodes[path[i]];

      return node;
    },
    isFlat: function() {
      return this.hasEvent('IWL-TreeModel-requestChildren')
        ? !this.rootNodes.any(flatIterator)
        : !this.rootNodes.any(flatLocalIterator);
    },

    /* Sortable Interface */
    setSortMethod: function(index, options) {
      this.sortMethods[index] = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-TreeModel-sortColumn', options.url, {}, {
          responseCallback: sortResponse.bind(this),
          id: this.options.id
        });
      }
      return this;
    },
    setDefaultOrderMethod: function(options) {
      this.defaultOrderMethod = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-TreeModel-sortColumn', options.url, {}, {
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
      this.sortColumn = {index: index, sortType: sortType || IWL.TreeModel.SortTypes.DESCENDING};
      var asc = this.sortColumn.sortType == IWL.TreeModel.SortTypes.ASCENDING;

      if (Object.isString(options.url) && !options.url.blank()) {
        var emitOptions = {};
        if (index == -1)
          emitOptions.defaultOrder = 1;

        emitOptions.ascending = asc ? 1 : 0;
        return this.emitEvent('IWL-TreeModel-sortColumn', {}, emitOptions);
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

    insertNode: function(parentNode, index) {
      return new IWL.TreeModel.Node(this, parentNode, index);
    },

    insertNodeBefore: function(parentNode, sibling) {
      return new IWL.TreeModel.Node(this, parentNode, sibling.getIndex());
    },

    insertNodeAfter: function(parentNode, sibling) {
      return new IWL.TreeModel.Node(this, parentNode, sibling.getIndex() + 1);
    },

    prependNode: function(parentNode) {
      return new IWL.TreeModel.Node(this, parentNode, 0);
    },

    appendNode: function(parentNode) {
      return new IWL.TreeModel.Node(this, parentNode, -1);
    },

    clear: function() {
      this.freeze();
      this.rootNodes.invoke('remove');
      return this.thaw().emitSignal('iwl:load_data');
    },

    reorder: function(parentNode, order) {
      if (Object.isArray(parentNode)) {
        order = parentNode;
        parentNode = undefined;
      } else if (!Object.isArray(order)) return;
      this.freeze();

      var children = parentNode ? parentNode.childNodes : this.rootNodes,
          length = order.length;
      if (length != children.length) return;
      for (var i = 0; i < length; i++) {
        var child = children[order[i]];
        child.insert(this, parentNode, i);
      }

      return this.thaw().emitSignal('iwl:nodes_reorder', parentNode);
    },

    swap: function(node1, node2) {
      if (node2.isDescendant(node1) || node1.isDescendant(node2)) return;
      this.freeze();

      var index1 = node1.getIndex(), parent1 = node1.parentNode,
          index2 = node2.getIndex(), parent2 = node2.parentNode;
      node1.insert(this, parent2, index2);
      node2.insert(this, parent1, index1);

      return this.thaw().emitSignal('iwl:nodes_swap', node1, node2);
    },

    move: function(node, parentNode, index) {
      this.freeze();

      var previous = node.parentNode;
      node.insert(this, parentNode, index);
      return this.thaw().emitSignal('iwl:node_move', parentNode, previous);
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
      var parentNode = this.getNodeByPath(data.options.parentNode);

      this.freeze();
      if (Object.isArray(data.nodes))
        loadNodes.call(this, data.nodes, parentNode, this.options);

      return this.thaw().emitSignal('iwl:load_data', parentNode);
    },

    getData: function() {
      var data = Object.extend({}, arguments[0]);
      if (Object.isArray(data.parentNode))
        data.parentNode = this.getNodeByPath(data.parentNode);

      data.nodes = getNodes.call(this, data.parentNode);

      return data;
    },

    _each: function(iterator) {
      for (var i = 0, l = this.rootNodes.length; i < l; i++) {
        iterator(this.rootNodes[i]);
        this.rootNodes[i]._each(iterator);
      }
    }
  };
})());

Object.extend(IWL.TreeModel, (function() {
  var index = -1;
  return {
    SortTypes: {
      DESCENDING: 1,
      ASCENDING:  2
    },
    DataTypes: {
      NONE:     ++index,
      STRING:   ++index,
      INT:      ++index,
      FLOAT:    ++index,
      BOOLEAN:  ++index,
      COUNT:    ++index
    },
    addColumnType: function() {
      var types = $A(arguments);
      while (types)
        IWL.TreeModel.Types[types.shift()] = ++index;
    },
    overrideDefaultDataTypes: function(types) {
      IWL.TreeModel.DataTypes = types;
      index = Math.max.apply(Math, Object.values(types));
    }
  }
})());

IWL.TreeModel.Node = Class.create(Enumerable, (function() {
  function addModel(model, node) {
    node.model = model;
    if (node.columns) {
      if (!compareColumns(node.columns, model.columns))
        node.values = [];
    }
  }

  function removeModel(node) {
    node.model = undefined;
  }

  function compareColumns(columns1, columns2) {
    if (columns1.length != columns2.length) return false;
    for (var i = 0, l = columns1.length; i < l; i++) {
      if (columns1[i].type != columns2[i].type)
        return false;
    }

    return true;
  }

  function RPCStartCallback(event, params, options) {
    if (event.endsWith('refresh')) {
      options.totalCount = this.model.options.totalCount;
      options.limit = this.model.options.limit;
      options.offset = this.model.options.offset;
      options.columns = this.model.columns;
      options.id = this.model.options.id;
    }
  }


  return {
    initialize: function(model, parentNode, index) {
      this.childNodes = [], this.values = [],
      this.attributes = {}, this.childCount = null;

      if (model)
        this.insert(model, parentNode, index);
    },

    insert: function(model, parentNode, index) {
      if (!model) return;

      if (this.childCount == null
          && !model.hasEvent('IWL-TreeModel-requestChildren'))
        this.childCount = 0;

      this.remove();
      if (this.model != model) {
        addModel(model, this);
        this.each(addModel.bind(this, model));
      }

      var previous, next, nodes;
      if (isNaN(index) || index < 0)
        index = -1;

      if (parentNode) {
        this.parentNode = parentNode;
        nodes = parentNode.childNodes;
        parentNode.childCount++;
      } else nodes = model.rootNodes;

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

      this.columns = model.columns.clone();

      this.model.emitSignal('iwl:node_insert', this, parentNode);
      if ((parentNode && parentNode.childCount == 1) || this.model.rootNodes.length == 1)
        this.model.emitSignal('iwl:node_has_child_toggle', parentNode);

      return this;
    },

    remove: function() {
      var model = this.model;
      if (!model) return;
      var parentNode = this.parentNode;
      if (parentNode) {
        parentNode.childNodes = parentNode.childNodes.without(this);
        if (--parentNode.childCount < 0) parentNode.childCount = 0;
      } else
        model.rootNodes = model.rootNodes.without(this);

      var next = this.nextSibling, previous = this.previousSibling;
      if (next) next.previousSibling = previous;
      if (previous) previous.nextSibling = next;

      this.parentNode = this.nextSibling = this.previousSibling = undefined;
      if (!model.frozen) {
        removeModel(this);
        this.each(removeModel);
      }

      model.emitSignal('iwl:node_remove', this, parentNode);
      if ((parentNode && !parentNode.childCount) || !model.rootNodes.length)
        model.emitSignal('iwl:node_has_child_toggle', parentNode);

      return this;
    },

    clear: function() {
      this.model.freeze();
      this.childNodes.invoke('remove');
      return this.model.thaw().emitSignal('iwl:load_data', this);
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
    down: function(index) {
      if (!this.model) return;
      var ret = this.childNodes[0];
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.childNodes[0];
        }
      return ret;
    },
    up: function(index) {
      if (!this.model) return;
      var ret = this.parentNode;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.childNodes[0];
        }
      return ret;
    },
    children: function() {
      if (!this.model) return;
      return this.childNodes;
    },
    hasChildren: function() {
      if (!this.model) return -1;
      return this.childCount;
    },
    requestChildren: function() {
      if (this.childCount != null
       || !this.model
       || !this.model.hasEvent('IWL-TreeModel-requestChildren'))
         return;
      this.model.emitSignal('iwl:request_children', this);
      var emitOptions = {
        columns: this.model.columns,
        id: this.model.options.id,
        parentNode: this.getPath(),
        values: this.values
      };

      return this.model.emitEvent('IWL-TreeModel-requestChildren', {}, emitOptions);
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

    isAncestor: function(descendant) {
      var ret = false;
      this.each(function(node) {
        if (node == descendant) {
          ret = true;
          throw $break;
        }
      });

      return ret;
    },
    isDescendant: function(ancestor) {
      var node = this.parentNode;
      if (!node) return;
      do {
        if (node == ancestor) return true;
      } while (node = node.parentNode)
      return false;
    },

    getIndex: function() {
      if (!this.model) return -1;
      return this.parentNode
        ? this.parentNode.childNodes.indexOf(this)
        : this.model.rootNodes.indexOf(this);
    },
    getDepth: function() {
      if (!this.model) return -1;
      var depth = 0, node = this;
      while (node = node.parentNode)
        depth++;

      return depth;
    },
    getPath: function() {
      if (!this.model) return [];
      var path = [this.getIndex()], node = this.parentNode;
      if (node)
        do {
          path.unshift(node.getIndex());
        } while (node = node.parentNode);

      return path;
    },

    _each: function(iterator) {
      for (var i = 0, l = this.childNodes.length; i < l; i++) {
        iterator(this.childNodes[i]);
        this.childNodes[i]._each(iterator);
      }
    }
  };
})());

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.ObservableModel = Class.create(Enumerable, (function() {
  return {
    initialize: function() {
      this.__emitter = new Element('div');
    },
    
    signalConnect: function(name, observer) {
      this.__emitter.signalConnect(name, observer);
      return this;
    },
    signalDisconnect: function(name, observer) {
      this.__emitter.signalDisconnect(name, observer);
      return this;
    },
    emitSignal: function() {
      var args = $A(arguments);
      var name = args.shift();
      Event.fire(this.__emitter, name, args);
      return this;
    },
    registerEvent: function() {
      this.__emitter.registerEvent.apply(this.__emitter, arguments);
      return this;
    },
    prepareEvents: function() {
      this.__emitter.prepareEvents.apply(this.__emitter, arguments);
      return this;
    },
    emitEvent: function() {
      this.__emitter.emitEvent.apply(this.__emitter, arguments);
      return this;
    },
    hasEvent: function() {
      return this.__emitter.hasEvent.apply(this.__emitter, arguments);
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
      if (node.childNodes.length)
        sortDepth.call(this, node.childNodes, wrapper);
    });
  }

  /*
   *  [value, [children]]
   */
  function getColumnValues(index, nodes) {
    var ret = [];
    nodes.each(function(node) {
      var r = node.getValues(index);
      if (node.hasChildren())
        r.push(getColumnValues.call(this, index, node.children()));
      ret.push(r);
    });
    return ret;
  }

  function sortResponse(response, params, options) {
    this.loadData(response.data);
    this.emitSignal('iwl:sort_column_change');
  }

  function loadNodes(nodes, parentNode, options) {
    if ('preserve' in options && !options.preserve)
      parentNode ? parentNode.childNodes = [] : this.clear();

    nodes.each(function(n) {
      var node = this.insertNode(parentNode, options.index);
      if (n.values && n.values.length) {
        for (var i = 0, l = n.values.length; i < l; i++)
          node.setValues(i, n.values[i]);
      }
      if (n.children && n.children.length)
        loadNodes.call(this, n.children, node, {});
    }.bind(this))
  }

  return {
    initialize: function($super) {
      $super();
      var args = $A(arguments), index = -1;
      args.shift();

      this.options = Object.extend({
      }, args.length % 2 ? args.pop() : {});

      this.rootNodes = [];
      this.frozen = false;
      this.columns = new Array(parseInt(args.length / 2));
      this.sortMethods = [];
      while (args.length) {
        var tuple = args.splice(0, 2);
        this.setColumn(++index, tuple[0], tuple[1]);
      }
    },

    addColumnType: function(type) {
      IWL.TreeModel.addColumnType(type);
      return this;
    },
    getColumnType: function(index) {
      return this.columns[index] ? this.columns[index].type : undefined;
    },
    getColumnName: function(index) {
      return this.columns[index] ? this.columns[index].name : undefined;
    },
    setColumn: function(index, type, name) {
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
      for (var i = 0, l = path.length; i < l; i++)
        node = node.childNodes[path[i]];

      return node;
    },

    freeze: function() {
      this.frozen = true;
      return this;
    },
    thaw: function() {
      this.frozen = false;
      return this;
    },
    isFrozen: function() {
      return this.frozen;
    },

    /* Sortable Interface */
    setSortMethod: function(index, options) {
      this.sortMethods[index] = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-TreeModel-sortColumn', options.url, {}, {responseCallback: sortResponse.bind(this)});
      }
      return this;
    },
    setDefaultOrderMethod: function(options) {
      this.defaultOrderMethod = options;
      if (Object.isString(options.url) && !options.url.blank()) {
        this.registerEvent('IWL-TreeModel-sortColumn', options.url, {}, {responseCallback: sortResponse.bind(this)});
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
        var ret = options.sortable(a.getValues(index), b.getValues(index));
        return asc ? ret * -1 : ret;
      };
      sortDepth.call(this, this.rootNodes, wrapper);

      this.emitSignal('iwl:sort_column_change');
      return this;
    },
    /* !Sortable Interface */

    removeNode: function(node) {
      return node.remove();
    },

    insertNode: function(parent, index) {
      return new IWL.TreeModel.Node(this, parent, index);
    },

    insertNodeBefore: function(parent, sibling) {
      return new IWL.TreeModel.Node(this, parent, sibling.getIndex());
    },

    insertNodeAfter: function(parent, sibling) {
      return new IWL.TreeModel.Node(this, parent, sibling.getIndex() + 1);
    },

    prependNode: function(parent) {
      return new IWL.TreeModel.Node(this, parent, 0);
    },

    appendNode: function(parent) {
      return new IWL.TreeModel.Node(this, parent, -1);
    },

    clear: function() {
      this.freeze();
      this.rootNodes.invoke('remove');
      this.emitSignal('iwl:nodes_reorder');
      return this.thaw();
    },

    reorder: function(parent, order) {
      if (Object.isArray(parent)) {
        order = parent;
        parent = undefined;
      } else if (!Object.isArray(order)) return;
      this.freeze();

      var children = parent ? parent.childNodes : this.rootNodes,
          length = order.length;
      if (length != children.length) return;
      for (var i = 0; i < length; i++) {
        var child = children[order[i]];
        child.insert(this, parent, i);
      }

      this.emitSignal('iwl:nodes_reorder', parent);
      return this.thaw();
    },

    swap: function(node1, node2) {
      if (node2.isDescendant(node1) || node1.isDescendant(node2)) return;
      this.freeze();

      var index1 = node1.getIndex(), parent1 = node1.parentNode,
          index2 = node2.getIndex(), parent2 = node2.parentNode;
      node1.insert(this, parent2, index2);
      node2.insert(this, parent1, index1);

      this.emitSignal('iwl:nodes_swap', node1, node2);
      return this.thaw();
    },

    move: function(node, parent, index) {
      this.freeze();

      var previous = node.parentNode;
      node.insert(this, parent, index);
      this.emitSignal('iwl:node_move', parent, previous);

      return this.thaw();
    },

    loadData: function(data) {
      if (!Object.isObject(data) || !Object.isArray(data.nodes)) return;
      var options = {
        totalCount: data.totalCount,
        size: data.size,
        offset: data.offset,
        index: data.index,
        parentNode: this.getNodeByPath(data.parentNode)
      };
      if ('preserve' in data)
        options.preserve = !!data.preserve;

      this.freeze();
      loadNodes.call(this, data.nodes, options.parentNode, options);

      this.emitSignal('iwl:load_data', options);
      return this.thaw();
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
    DataTypes: {
      NONE:     ++index,
      STRING:   ++index,
      INT:      ++index,
      FLOAT:    ++index,
      BOOLEAN:  ++index,
      COUNT:    ++index,
      CHECKBOX: ++index,
      RADIO:    ++index
    },
    addColumnType: function(type) {
      IWL.TreeModel.Types[type] = ++index;
    },
    SortTypes: {
      DESCENDING: 1,
      ASCENDING:  2
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

  return {
    initialize: function(model, parent, index) {
      this.childNodes = [], this.values = [];

      if (model)
        this.insert(model, parent, index);
    },

    insert: function(model, parent, index) {
      if (!model) return;

      this.remove();
      if (this.model != model) {
        addModel(model, this);
        this.each(addModel.bind(this, model));
      }

      var previous, next, nodes;
      if (isNaN(index) || index < 0)
        index = -1;

      if (parent) {
        this.parentNode = parent;
        nodes = parent.childNodes;
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

      if (!this.model.isFrozen()) {
        this.model.emitSignal('iwl:node_insert', this);
        if ((parent && parent.childNodes.length == 1) || this.model.rootNodes.length == 1)
          this.model.emitSignal('iwl:node_has_child_toggle', parent);
      }

      return this;
    },

    remove: function() {
      if (!this.model) return;
      var parent = this.parentNode;
      if (parent)
        parent.childNodes = parent.childNodes.without(this);
      else
        this.model.rootNodes = this.model.rootNodes.without(this);

      var next = this.nextSibling, previous = this.previousSibling;
      if (next) next.previousSibling = previous;
      if (previous) previous.nextSibling = previous;

      this.parentNode = this.nextSibling = this.previousSibling = undefined;
      if (!this.model.frozen) {
        removeModel(this);
        this.each(removeModel);
      }

      if (!this.model.isFrozen()) {
        this.model.emitSignal('iwl:node_remove', this);
        if ((parent && !parent.childNodes.length) || !this.model.rootNodes.length)
          this.model.emitSignal('iwl:node_has_child_toggle', parent);
      }

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
      return this.childNodes.length;
    },

    getValues: function() {
      if (!this.model) return;
      var args = $A(arguments);
      if (!args.length)
        return this.values;
      var index, ret = [];
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

      if (!this.model.isFrozen())
        this.model.emitSignal('iwl:node_change', this);

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

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.TreeModel = Class.create(IWL.ListModel, (function() {
  function loadNodes(nodes, parentNode, options) {
    if ('preserve' in options && !options.preserve)
      parentNode ? parentNode.childNodes.invoke('remove') : this.rootNodes.invoke('remove');

    var length = nodes.length;
    if (parentNode && length == 0) parentNode.childCount = 0;
    for (var i = 0; i < length; i++) {
      var n = nodes[i], node = this.insertNode(options.index, parentNode);
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

  function RPCStartCallback(event, params, options) {
    if (event.endsWith('refresh')) {
      options.totalCount = this.options.totalCount;
      options.limit = this.options.limit;
      options.offset = this.options.offset;
      options.columns = this.columns;
      options.id = this.options.id;
    }
  }

  function requestChildrenResponse(json, params, options) {
    this.freeze();
    var parentNode = json.data && json.data.options ? this.getNodeByPath(json.data.options.parentNode) : undefined;
    this.loadData(json.data, parentNode);
    this.thaw().emitSignal('iwl:request_children_response', parentNode);
  }

  return {
    initialize: function($super, columns, data) {
      $super(columns, data);

      this._emitter._requestChildrenResponse = requestChildrenResponse.bind(this);
    },

    getNodeByPath: function(path) {
      if (!Object.isArray(path)) return;
      var node = this.rootNodes[path.shift()];
      for (var i = 0, l = path.length; node && i < l; i++)
        node = node.childNodes[path[i]];

      return node;
    },

    insertNode: function(index, parentNode) {
      return new IWL.TreeModel.Node(this, index, parentNode);
    },

    insertNodeBefore: function(sibling, parentNode) {
      return new IWL.TreeModel.Node(this, sibling.getIndex(), parentNode);
    },

    insertNodeAfter: function(sibling, parentNode) {
      return new IWL.TreeModel.Node(this, sibling.getIndex() + 1, parentNode);
    },

    prependNode: function(parentNode) {
      return new IWL.TreeModel.Node(this, 0, parentNode);
    },

    appendNode: function(parentNode) {
      return new IWL.TreeModel.Node(this, -1, parentNode);
    },

    reorder: function(order, parentNode) {
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
        child.insert(this, i, parentNode);
      }

      return this.thaw().emitSignal('iwl:nodes_reorder', parentNode);
    },

    swap: function(node1, node2) {
      if (node2.isDescendant(node1) || node1.isDescendant(node2)) return;
      this.freeze();

      var index1 = node1.getIndex(), parent1 = node1.parentNode,
          index2 = node2.getIndex(), parent2 = node2.parentNode;
      node1.insert(this, index2, parent2);
      node2.insert(this, index1, parent1);

      return this.thaw().emitSignal('iwl:nodes_swap', node1, node2);
    },

    move: function(node, index, parentNode) {
      this.freeze();

      var previous = node.parentNode;
      node.insert(this, index, parentNode);
      return this.thaw().emitSignal('iwl:node_move', node, parentNode, previous);
    },

    loadData: function(data, parentNode) {
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
      if (!parentNode)
        parentNode = this.getNodeByPath(data.options.parentNode);

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
    },
    _localSort: function(nodes, wrapper) {
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
          this._localSort(node.childNodes, wrapper);
      });
    }
  };
})());

IWL.TreeModel.Node = Class.create(IWL.ListModel.Node, (function() {
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
    initialize: function($super, model, index, parentNode) {
      this.childNodes = [];
      this.childCount = null;
      $super(model, index, parentNode);
    },

    insert: function(model, index, parentNode) {
      if (!model) return;

      if (this.childCount === null
          && !model.hasEvent('IWL-TreeModel-requestChildren'))
        this.childCount = 0;

      this.remove();
      if (this.model != model) {
        this._addModel(model);
        this.each(this._addModel.bind(this, model));
      }

      var nodes;
      if (isNaN(index) || index < 0)
        index = -1;

      if (parentNode) {
        this.parentNode = parentNode;
        nodes = parentNode.childNodes;
        parentNode.childCount++;
      } else nodes = model.rootNodes;

      this._addNodeRelationship(index, nodes);

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

        this._removeNodeRelationship();

      this.parentNode = undefined;
      if (!model.frozen) {
        this._removeModel();
        this.each(this._removeModel.bind(this));
      }

      model.emitSignal('iwl:node_remove', this, parentNode);
      if ((parentNode && !parentNode.childCount) || !model.rootNodes.length)
        model.emitSignal('iwl:node_has_child_toggle', parentNode);

      return this;
    },

    clear: function() {
      this.model.freeze();
      this.childNodes.invoke('remove');
      return this.model.thaw().emitSignal('iwl:clear', this);
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
      if (this.childCount !== null
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

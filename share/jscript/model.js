// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.TreeModel = Class.create(Enumerable, (function() {
  return {
    initialize: function() {
      this.rootNodes = [];
      this.columns = [];
    },

    addColumnType: function(type, id) {
      IWL.TreeModel.Types[type] = id;
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
      var node = this.rootNodes[path.shift()];
      for (var i = 0, l = path.length; i < l; i++)
        node = node.childNodes[path[i]];

      return node;
    },

    _each: function(iterator) {
      for (var i = 0, l = this.rootNodes.length; i < l; i++)
        this.rootNodes[i]._each(iterator);
    }
  };
})());

IWL.TreeModel.Types = {
  NONE:   0,
  STRING: 1,
  INT:    2,
  FLOAT:  3
};


/*
 * {
 *   childNodes: [child1, child2, ...],
 *   parentNode: parent,
 *   nextSibling: sibling,
 *   previousSibling: sibling
 * }
 */
IWL.TreeModel.Node = Class.create(Enumerable, (function() {
  return {
    initialize: function(model, parent, index) {
      this.model = model;
      this.childNodes = [];
      this.values = new Array(model.columns.length);

      var previous, next, nodes;
      if (!Object.isNumber(index) || !index || index < 0)
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
    },

    next: function(index) {
      var ret = this.nextSibling;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.nextSibling;
        }
      return ret;
    },
    previous: function(index) {
      var ret = this.previousSibling;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.previousSibling;
        }
      return ret;
    },
    down: function(index) {
      var ret = this.childNodes[0];
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.childNodes[0];
        }
      return ret;
    },
    up: function(index) {
      var ret = this.parentNode;
      if (index > 0)
        while (index--) {
          if (!ret) break;
          ret = ret.childNodes[0];
        }
      return ret;
    },
    children: function() {
      return this.childNodes;
    },
    hasChildren: function() {
      return this.childNodes.length;
    },

    getValues: function() {
      var args = $A(arguments);
      if (!args.length)
        return this.values;
      var index, ret = [];
      while (args.length)
        ret.push(this.values[args.shift()]);
      return ret;
    },
    setValues: function() {
      var args = $A(arguments);
      var v = this.values;
      while (args.length) {
        var tuple = args.splice(0, 2);
        v[tuple[0]] = tuple[1];
      }

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
      do {
        if (node == ancestor) return true;
      } while (node = node.parentNode)
      return false;
    },

    getIndex: function() {
      return this.parentNode
        ? this.parentNode.childNodes.indexOf(this)
        : this.model.rootNodes.indexOf(this);
    },
    getDepth: function() {
      var depth = 0, node = this;
      while (node = node.parentNode)
        depth++;

      return depth;
    },
    getPath: function() {
      var path = [this.getIndex()], node = this.parentNode;
      if (node)
        do {
          path.unshift(node.getIndex());
        } while (node = node.parentNode);

      return path;
    },

    _each: function(iterator) {
      iterator(this);
      for (var i = 0, l = this.childNodes.length; i < l; i++) {
        iterator(this.childNodes[i]);
        this.childNodes[i]._each(iterator);
      }
    }
  };
})());

IWL.TreeStore = Class.create(IWL.TreeModel, (function() {
  return {
    initialize: function($super) {
      var args = $A(arguments), index = -1;
      args.shift();
      $super();

      this.columns = new Array(parseInt(args.length / 2));
      while (args.length) {
        var tuple = args.splice(0, 2);
        this.setColumn(++index, tuple[0], tuple[1]);
      }
    },

    removeNode: function(node) {
      if (node.parentNode)
        node.parentNode.childNodes = node.parentNode.childNodes.without(node);
      else
        this.rootNodes = this.rootNodes.without(node);

      var next = node.nextSibling, previous = node.previousSibling;
      if (next) next.previousSibling = previous;
      if (previous) previous.nextSibling = previous;

      return node;
    },

    insertNode: function(parent, position) {
      if (!Object.isNumber(position) || !position)
        position = 0;

      return new IWL.TreeModel.Node(this, parent, position);
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
      this.rootNodes = [];
      return this;
    }
  };
})());

// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.CellRenderer = Class.create((function() {
  return {
    render: function(cell, value, node) {}
  };
})());

IWL.CellTemplateRenderer = Class.create((function() {
  var editable = new Template(
    '<p class="iwl-cell-value">#{value}</p><input style="display: none" class="iwl-cell-editable" onblur="Element.hide(this); Element.show(this.previousSibling);"/>'
  );
  return {
    initialize: function() {
      this.options = Object.extend({}, arguments[0] || {});

      if (this.options.editable && this.options.view) {
        var view = this.options.view;
        Event.delegate(view, 'click', '.iwl-cell-value', function(event) {
            var va = Event.element(event),
                en = va.nextSibling;
            en.value = Element.getText(va);
            Element.show(en);
            Element.hide(va);
            en.focus();
            en.select();
            view._focusedElement = en;
            var parent = Element.up(en, '.iwl-node');
            Event.emitSignal(view, 'iwl:edit_begin', parent, parent.node, en.value);
        });
        Event.delegate(view, 'keypress', '.iwl-cell-editable', function(event) {
            if (event.keyCode != Event.KEY_ESC && event.keyCode != Event.KEY_RETURN) return;
            var en = Event.element(event),
                va = en.previousSibling;
            if (event.keyCode == Event.KEY_RETURN)
              va.innerHTML = en.value;
            Element.hide(en);
            Element.show(va);
            if (event.keyCode == Event.KEY_RETURN) {
              var parent = Element.up(en, '.iwl-node');
              Event.emitSignal(view, 'iwl:edit_end', parent, parent.node, en.value);
            }
        });
      }
    },
    render: function(value, node) {
      return this.options.editable
        ? editable.evaluate({value: value.toString()})
        : value.toString();
    }
  };
})());

IWL.CellTemplateRenderer.String = Class.create(IWL.CellTemplateRenderer);

IWL.CellTemplateRenderer.Int = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
      return this.options.editable
        ? editable.evaluate({value: parseInt(value)})
        : parseInt(value);
    }
  };
})());

IWL.CellTemplateRenderer.Float = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
      return this.options.editable
        ? editable.evaluate({value: parseFloat(value)})
        : parseFloat(value);
    }
  };
})());

IWL.CellTemplateRenderer.Boolean = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
      var bool = (!!value).toString();
      return this.options.editable
        ? editable.evaluate({value: bool})
        : bool;
    }
  };
})());

IWL.CellTemplateRenderer.Count = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
      return node.getIndex() + 1 + (node.model.options.offset || 0);
    }
  };
})());

IWL.CellTemplateRenderer.Image = Class.create(IWL.CellTemplateRenderer, (function() {
  var imageTemplate = new Template('<img class="iconview_node_image" src="#{src}" alt="#{alt}" />');
  return {
    render: function(value, node) {
      return imageTemplate.evaluate(value);
    }
  };
})());

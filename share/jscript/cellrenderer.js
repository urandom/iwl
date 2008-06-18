// vim: set autoindent shiftwidth=2 tabstop=8:
IWL.CellRenderer = Class.create((function() {
  return {
    render: function(cell, value, node) {}
  };
})());

IWL.CellTemplateRenderer = Class.create((function() {
  return {
    render: function(value, node) {
        return value.toString();
    }
  };
})());

IWL.CellTemplateRenderer.String = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
        return value.toString();
    }
  };
})());

IWL.CellTemplateRenderer.Int = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
        return parseInt(value);
    }
  };
})());

IWL.CellTemplateRenderer.Float = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
        return parseFloat(value);
    }
  };
})());

IWL.CellTemplateRenderer.Boolean = Class.create(IWL.CellTemplateRenderer, (function() {
  return {
    render: function(value, node) {
        return (!!value).toString();
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

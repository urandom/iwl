// vim: set autoindent shiftwidth=4 tabstop=8:
/**
 * @class IWL.TextEditor is a class for rich text editors
 * @extends IWL.Widget
 * */
IWL.TextEditor = Object.extend(Object.extend({}, IWL.Widget), (function () {

    return {

        _init: function(id) {
            this.options = Object.extend({
                iconsPath: IWL.Config.IMAGE_DIR + '/texteditor/nicEditorIcons.gif',
                panel: false,
                editors: []
            }, arguments[1] || {});
            this.control = new nicEditor(this.options);
            if (this.options.panel) {
                this.control.setPanel(this.options.panel);
                this.control.addInstance(this);
                this.options.editors.each(function($_) {
                    this.control.addInstance($_);
                }.bind(this));
            } else {
                this.control.panelInstance(this);
            }
            this.setStyle({visibility: 'visible'});

            this.control.addEvent('add'              , this.emitSignal.bind(this, 'iwl:add_editor'));
            this.control.addEvent('blur'             , this.emitSignal.bind(this, 'iwl:blur'));
            this.control.addEvent('buttonActivate'   , this.emitSignal.bind(this, 'iwl:button_activate'));
            this.control.addEvent('buttonClick'      , this.emitSignal.bind(this, 'iwl:button_click'));
            this.control.addEvent('buttonDeactivate' , this.emitSignal.bind(this, 'iwl:button_deactivate'));
            this.control.addEvent('buttonOut'        , this.emitSignal.bind(this, 'iwl:button_out'));
            this.control.addEvent('buttonOver'       , this.emitSignal.bind(this, 'iwl:button_over'));
            this.control.addEvent('focus'            , this.emitSignal.bind(this, 'iwl:focus'));
            this.control.addEvent('get'              , this.emitSignal.bind(this, 'iwl:get_content'));
            this.control.addEvent('key'              , this.emitSignal.bind(this, 'iwl:key'));
            this.control.addEvent('panel'            , this.emitSignal.bind(this, 'iwl:set_panel'));
            this.control.addEvent('removeInstance'   , this.emitSignal.bind(this, 'iwl:remove_editor'));
            this.control.addEvent('save'             , this.emitSignal.bind(this, 'iwl:save_content'));
            this.control.addEvent('selected'         , this.emitSignal.bind(this, 'iwl:selected'));
            this.control.addEvent('set'              , this.emitSignal.bind(this, 'iwl:set_content'));
        }
    }
})());

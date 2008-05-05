// vim: set autoindent shiftwidth=2 tabstop=8:
/**
 * @class IWL.Google.Map is a class for adding google maps
 * @extends IWL.Widget
 * */
if (!IWL.Google)
  IWL.Google = {};

IWL.Google.Map = Object.extend(Object.extend({}, IWL.Widget), (function() {
  function initialize() {
    this.control = new google.maps.Map2(this);
    this.setCenter(this.options.latitude, this.options.longitude, this.options.zoom);
    this.setMapType(this.options.mapType);

    if (this.options.scaleView != 'none')
      this.control.addControl(new GScaleControl());

    if (this.options.mapControl != 'none') {
      var type = {
        small: GSmallMapControl,
        large: GLargeMapControl,
        smallZoom: GSmallZoomControl
      };
      this.control.addControl(new (type[this.options.mapControl] || GSmallMapControl)());
    }

    if (this.options.mapTypeControl != 'none') {
      var type = {
        normal: GMapTypeControl,
        menu: GMenuMapTypeControl,
        hierarchical: GHierarchicalMapTypeControl
      };
      this.control.addControl(new (type[this.options.mapTypeControl] || GMapTypeControl)());
    }

    if (this.options.overview != 'none')
      this.control.addControl(new GOverviewMapControl());

    Event.observe(document.body, 'unload', google.maps.Unload);
    this.emitSignal('iwl:load');
  }
  return {
    /*
     * Sets the center of the map
     * @param {Float} latitude The new latitude of the map center
     * @param {Float} longitude The new longitude of the map center
     * @param {Int} zoom The zoom level of the map
     * @returns The object
     * */
    setCenter: function(latitude, longitude, zoom) {
      this.control.setCenter(new google.maps.LatLng(latitude, longitude), zoom);
      this.control[(this.options.dragging ? 'enable' : 'disable') + 'Dragging']();
      this.control[(this.options.infoWindow ? 'enable' : 'disable') + 'InfoWindow']();
      this.control[(this.options.doubleClickZoom ? 'enable' : 'disable') + 'DoubleClickZoom']();
      this.control[(this.options.scrollWheelZoom ? 'enable' : 'disable') + 'ScrollWheelZoom']();
      this.control[(this.options.googleBar ? 'enable' : 'disable') + 'GoogleBar']();
      return this;
    },
    
    /*
     * @returns The latitude of the map
     * */
    getLatitude: function() {
      return this.control.getCenter().lat();
    },

    /*
     * @returns The longitude of the map
     * */
    getLongitude: function() {
      return this.control.getCenter().lng();
    },

    /*
     * @returns The zoom level of the map
     * */
    getZoom: function() {
      return this.control.getZoom();
    },

    /*
     * Sets the map type
     * @param {String} type The new map type, one of:
     *                      normal - street map
     *                      satellite - satellite map
     *                      hybrid - mixed normal/satellite map
     *                      physical - physical map
     * @returns The object
     * */
    setMapType: function(type) {
      var types = {
        normal:    G_NORMAL_MAP,
        satellite: G_SATELLITE_MAP,
        hybrid:    G_HYBRID_MAP,
        physical:  G_PHYSICAL_MAP
      };
      this.control.setMapType(types[type] || G_NORMAL_MAP);
      return this;
    },

    _init: function(id) {
      this.options = Object.extend({
        latitude: 0,
        longitude: 0,
        zoom: 1,
        dragging: true,
        infoWindow: true,
        doubleClickZoom: true,
        scrollWheelZoom: true,
        googleBar: false,
        language: 'en',
        mapType: 'normal',
        scaleView: 'none',
        mapControl: 'none',
        mapTypeControl: 'none',
        overview: 'none'
      }, arguments[1] || {});
      
      google.load("maps", "2", {callback: initialize.bind(this), language: this.options.language});
    }
  }
})());

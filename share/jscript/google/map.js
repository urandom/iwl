// vim: set autoindent shiftwidth=2 tabstop=8:
/**
 * @class IWL.Google.Map is a class for adding google maps
 * @extends IWL.Widget
 * */
if (!IWL.Google)
  IWL.Google = {};

IWL.Google.Map = Object.extend(Object.extend({}, IWL.Widget), (function() {
  function createPoint(latitude, longitude) {
    if (latitude instanceof google.maps.LatLng) return latitude;
    if (isNaN(latitude)) latitude = this.getLatitude();
    if (isNaN(longitude)) longitude = this.getLongitude();
    return new google.maps.LatLng(latitude, longitude);
  }

  function initialize() {
    this.control = new google.maps.Map2(this);
    this.setCenter(this.options.latitude, this.options.longitude, this.options.zoom);
    this.setMapType(this.options.mapType);

    this.control[(this.options.dragging ? 'enable' : 'disable') + 'Dragging']();
    this.control[(this.options.infoWindow ? 'enable' : 'disable') + 'InfoWindow']();
    this.control[(this.options.doubleClickZoom ? 'enable' : 'disable') + 'DoubleClickZoom']();
    this.control[(this.options.scrollWheelZoom ? 'enable' : 'disable') + 'ScrollWheelZoom']();
    this.control[(this.options.googleBar ? 'enable' : 'disable') + 'GoogleBar']();

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

    this.options.markers.each(function(marker) {
      this.addMarker.apply(this, marker);
    }.bind(this));

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
      this.control.setCenter(createPoint.call(this, latitude, longitude), zoom);
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

    /*
     * Creates and returns a new marker on the map
     * @param content An optional content that will appear in an information window, if the marker is clicked
     * @param {Float} latitude The latitude of the map marker. The current latitude will be used, if none is supplied.
     * @param {Float} longitude The longitude of the map marker. The current longitude will be used, if none is supplied.
     * @returns The creater marker
     * */
    addMarker: function(content, latitude, longitude) {
      var point = createPoint.call(this, latitude, longitude);
      var marker = new google.maps.Marker(point);
      this.control.addOverlay(marker);

      if (Object.isElement(content) || Object.isString(content))
        GEvent.addListener(marker, "click", this.openInfoWindow.bind(this, content, point));
      return marker;
    },

    /*
     * Removes a given marker
     * @param {Marker} marker The marker to remove from the map
     * @returns The removed marker
     * */
    removeMarker: function(marker) {
      this.control.removeOverlay(marker);
      return marker;
    },

    /*
     * Opens an information window on the map
     * @param content The window contents. Can be either a DOM element or an (html) string
     * @param {Float} latitude The latitude of the window. The current latitude will be used, if none is supplied.
     * @param {Float} longitude The longitude of the window. The current longitude will be used, if none is supplied.
     * @returns The object
     * */
    openInfoWindow: function(content, latitude, longitude) {
      if (Object.isElement(content))
        this.control.openInfoWindow(createPoint.call(this, latitude, longitude), content);
      else if (Object.isString(content))
        this.control.openInfoWindowHtml(createPoint.call(this, latitude, longitude), content);
      else return;

      return this;
    },

    /*
     * Closes the currently open information window
     * @returns The object
     * */
    closeInfoWindow: function() {
      this.control.closeInfoWindow();
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
        overview: 'none',
        markers: []
      }, arguments[1] || {});
      
      google.load("maps", "2", {callback: initialize.bind(this), language: this.options.language});
    }
  }
})());

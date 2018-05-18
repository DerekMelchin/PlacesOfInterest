class ViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs, :places

  def init
    @location_manager = CLLocationManager.alloc.init
    @region_radius = 1000
    @started_loading_POIs = false
    @places = []
    super
  end

  def viewDidLoad
    super
    self.view = MKMapView.alloc.init
    @location_manager.delegate = self
    @location_manager.desiredAccuracy = 1000 # kCLLocationAccuracyNearestTenMeters
    @location_manager.startUpdatingLocation()
    @location_manager.requestWhenInUseAuthorization()
    # @@location_manager.requestWhenInUseAuthorization
    # initial_location = CLLocation.alloc.initWithLatitude(21.282778, longitude: -157.829444)
    # center_map_on_location(initial_location)
  end

  def locationManager(manager, didUpdateLocations: locations)
    if locations.count > 0
      location = locations.last
      puts "Accuracy: #{location.horizontalAccuracy}"

      if location.horizontalAccuracy < 100
        @location_manager.stopUpdatingLocation
        span = MKCoordinateSpanMake(0.014, 0.014)
        region = MKCoordinateRegionMake(location.coordinate, span)
        view.setRegion(region, true)
        unless @started_loading_POIs
          @started_loading_POIs = true
          loader = PlacesLoader.alloc.init
          loader.load_POIs(location, 1000)
        end
      end
    end
  end

  # def center_map_on_location(location)
    # coordinate_region = MKCoordinateRegionMakeWithDistance(location.coordinate, @@region_radius, @@region_radius)
    # view.setRegion(coordinate_region, false)
  # end

end
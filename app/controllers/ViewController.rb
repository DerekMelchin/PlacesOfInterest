class ViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :ar_view_controller, :camera_button_view

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
    view.showsUserLocation = true
    view.delegate = self
    width = 100
    height = 60
    frame = CGRectMake(UIScreen.mainScreen.bounds.size.width - width,
                       UIScreen.mainScreen.bounds.size.height - height,
                       width, height)
    @camera_button_view = UIView.alloc.initWithFrame(frame)
    @camera_button_view.backgroundColor = UIColor.blackColor
    view.addSubview(@camera_button_view)
    camera = UILabel.new
    camera.font = UIFont.systemFontOfSize(16)
    camera.text = 'Camera'
    camera.textAlignment = UITextAlignmentCenter
    camera.textColor = UIColor.alloc.initWithRed(0.25, green: 0.51, blue: 0.93, alpha: 1.0)
    camera.frame = [[0, 0], [width, height]]
    @camera_button_view.addSubview(camera)
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
          loader = PlacesLoader.alloc.init()
          loader.load_POIs(self, location, 1000)
        end
      end
    end
  end

  def center_map_on_location(location)
    coordinate_region = MKCoordinateRegionMakeWithDistance(location.coordinate, @region_radius, @region_radius)
    view.setRegion(coordinate_region, false)
  end

  def touchesEnded(touches, withEvent: event)
    if event.touchesForView(@camera_button_view)
      puts 'Opening Camera'
    end
  end
end
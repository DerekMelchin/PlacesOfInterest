class ViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :camera_button, :scene_view, :map_button

  def init
    @location_manager = CLLocationManager.alloc.init
    @region_radius = 1000
    @started_loading_POIs = false
    @places = []
    super
  end

  def viewDidLoad
    super
    display_map
    @location_manager.delegate = self
    @location_manager.desiredAccuracy = 1000 # kCLLocationAccuracyNearestTenMeters
    @location_manager.requestWhenInUseAuthorization
  end

  def display_map
    self.view = MKMapView.alloc.init
    view.showsUserLocation = true
    view.delegate = self
    @location_manager.startUpdatingLocation
    if @started_loading_POIs
      @places.each {|a| Dispatch::Queue.main.async {view.addAnnotation(a)}}
    end
    @camera_button = create_toggle_button('Camera')
    view.addSubview(@camera_button)
  end

  def display_AR
    @scene_view = ARSCNView.alloc.init
    @scene_view.delegate = self
    @scene_view.session.runWithConfiguration(ARWorldTrackingConfiguration.alloc.init)
    @scene_view.showsStatistics = true
    self.view = @scene_view
    @map_button = create_toggle_button('Map')
    view.addSubview(@map_button)
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
          loader.load_POIs(self, location, 1000)
        end
      end
    end
  end

  def create_toggle_button(title)
    width = 100
    height = 60
    frame = CGRectMake(UIScreen.mainScreen.bounds.size.width - width,
                       UIScreen.mainScreen.bounds.size.height - height,
                       width, height)
    background = UIView.alloc.initWithFrame(frame)
    background.backgroundColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 0.7)
    words = UILabel.new
    words.font = UIFont.systemFontOfSize(16)
    words.text = title
    words.textAlignment = UITextAlignmentCenter
    words.textColor = UIColor.alloc.initWithRed(0.25, green: 0.51, blue: 0.93, alpha: 1.0)
    words.frame = [[0, 0], [width, height]]
    background.addSubview(words)
    background
  end

  def center_map_on_location(location)
    coordinate_region = MKCoordinateRegionMakeWithDistance(location.coordinate, @region_radius, @region_radius)
    view.setRegion(coordinate_region, false)
  end

  def touchesEnded(touches, withEvent: event)
    display_AR if event.touchesForView(@camera_button)
    display_map if event.touchesForView(@map_button)
  end
end
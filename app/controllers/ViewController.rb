class Numeric
  def degrees
    self * Math::PI / 180
  end
  def meters
    self * 10000 #/ 1.1
  end
end

class ViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :camera_button, :scene_view, :map_button, :map_message_box,
                :start_button, :exit_button, :curr_location, :destination

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
    if @location_manager.headingAvailable
      @location_manager.startUpdatingHeading
    else
      UIAlertView.alloc.initWithTitle('Heading Unavailable',
                                      message: 'Sorry, the AR won\'t work for your device.',
                                      delegate: nil,
                                      cancelButtonTitle: 'Ok',
                                      otherButtonTitles: nil).show
    end
  end

  def display_map
    self.view = MKMapView.alloc.init
    view.showsUserLocation = true
    view.delegate = self
    @location_manager.startUpdatingLocation
    if @started_loading_POIs
      @places.each {|a| Dispatch::Queue.main.async {view.addAnnotation(a)}}
    end
  end

  def display_AR
    @scene_view = ARSCNView.alloc.init
    @scene_view.autoenablesDefaultLighting = true
    @scene_view.delegate = self
    @scene_view.session.runWithConfiguration(ARWorldTrackingConfiguration.alloc.init)
    self.view = @scene_view
    addCones

    height = 80
    ar_message_box = make_message_box(height)
    distance = UILabel.new
    distance.font = UIFont.systemFontOfSize(18)
    distance.text = "#{@curr_location.distanceFromLocation(@destination).round}m away"
    distance.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 1)
    distance.frame = [[20, 0], [UIScreen.mainScreen.bounds.size.width, height]]
    ar_message_box.addSubview(distance)

    exit_width   = 50
    exit_frame   = [[UIScreen.mainScreen.bounds.size.width - exit_width, 0],
                     [exit_width, height]]
    @exit_button = UIView.alloc.initWithFrame(exit_frame)
    exit = UILabel.new
    exit.font = UIFont.systemFontOfSize(18)
    exit.text = 'Exit'
    exit.textColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 1.0)
    exit.frame = [[0, 0], [exit_width, height]]
    @exit_button.addSubview(exit)
    ar_message_box.addSubview(@exit_button)

    view.addSubview(ar_message_box)
  end

  def locationManager(manager, didUpdateLocations: locations)
    if locations.count > 0
      location = @curr_location = locations.last
      puts "Longitude: #{location.coordinate.longitude}   Latitude: #{location.coordinate.latitude}"
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

  def center_map_on_location(location)
    coordinate_region = MKCoordinateRegionMakeWithDistance(location.coordinate, @region_radius, @region_radius)
    view.setRegion(coordinate_region, false)
  end

  def touchesEnded(touches, withEvent: event)
    display_AR if event.touchesForView(@start_button)
    if event.touchesForView(@exit_button)
      @scene_view.session.pause
      display_map
    end
  end

  def addCones
    scene = SCNScene.scene

    guide_geometry = SCNPyramid.pyramidWithWidth(0.1, height: 0.2, length: 0.1)
    guide_material = SCNMaterial.material
    guide_material.diffuse.contents = NSColor.colorWithRed(0, green: 1, blue: 1, alpha: 0.8)
    guide_material.doubleSided = true
    guide_geometry.materials = [guide_material]
    guide = SCNNode.nodeWithGeometry(guide_geometry)
    guide.position = SCNVector3Make(0, 0.3, -1)

    target_geometry = SCNPyramid.pyramidWithWidth(2, height: 6, length: 2)
    target_material = SCNMaterial.material
    target_material.diffuse.contents = NSColor.colorWithRed(0, green: 1, blue: 0, alpha: 0.8)
    target_material.doubleSided = true
    target_geometry.materials = [target_material]
    target = SCNNode.nodeWithGeometry(target_geometry)
    target.position = getTargetVecLocation#SCNVector3Make(0, 0, -2)

    constraint = SCNLookAtConstraint.lookAtConstraintWithTarget(target)
    constraint.localFront = SCNVector3Make(0, 0.2, 0)
    guide.constraints = [constraint]

    @scene_view.pointOfView.addChildNode(guide)
    scene.rootNode.addChildNode(target)
    @scene_view.scene = scene
  end

  def getTargetVecLocation
    c_lon = -112.800494 #@curr_location.coordinate.longitude #
    c_lat = 49.735486 #@curr_location.coordinate.latitude #

    d_lon = -112.799703 #@destination.coordinate.longitude #
    d_lat = 49.735644 #@destination.coordinate.latitude #

    c = Math.atan((d_lat - c_lat) / (d_lon - c_lon)).degrees
    d = 90 - @location_manager.heading.trueHeading - c
    e = Math.sqrt((d_lat - c_lat)**2 + (d_lon - c_lon)**2)
    x = e * Math.sin(d).degrees
    z = Math.sqrt(e**2 - x**2)

    SCNVector3Make(x.meters, -1, -z.meters)
  end

  def make_message_box(height)
    frame = [[0, UIScreen.mainScreen.bounds.size.height - height],
             [UIScreen.mainScreen.bounds.size.width, height]]
    message_box = UIView.alloc.initWithFrame(frame)
    message_box.backgroundColor = UIColor.alloc.initWithRed(0, green: 0.7, blue: 0, alpha: 0.92)
    message_box
  end

  # Called when an annotation is selected
  def mapView(mapView, didSelectAnnotationView: view)
    if view.class.to_s == 'NSKVONotifying_MKModernUserLocationView'
      return
    end
    @map_message_box.removeFromSuperview unless @map_message_box.nil?
    @destination = CLLocation.alloc.initWithLatitude(view.coordinate.latitude, longitude: view.coordinate.longitude)

    height = 80
    @map_message_box = make_message_box(height)
    distance = UILabel.new
    distance.font = UIFont.systemFontOfSize(18)
    distance.text = "#{@curr_location.distanceFromLocation(@destination).round}m away"
    distance.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 1)
    distance.frame = [[20, 0], [UIScreen.mainScreen.bounds.size.width, height]]
    @map_message_box.addSubview(distance)

    start_width   = 60
    start_frame   = [[UIScreen.mainScreen.bounds.size.width - start_width, 0],
                     [start_width, height]]
    @start_button = UIView.alloc.initWithFrame(start_frame)
    start = UILabel.new
    start.font = UIFont.systemFontOfSize(18)
    start.text = 'Start'
    start.textColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 1.0)
    start.frame = [[0, 0], [start_width, height]]
    @start_button.addSubview(start)
    @map_message_box.addSubview(@start_button)

    self.view.addSubview(@map_message_box)
  end

  def mapView(mapView, didDeselectAnnotationView: view)
    @map_message_box.removeFromSuperview unless @map_message_box.nil?
  end
end
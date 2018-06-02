class Numeric
  def degrees
    self * Math::PI / 180
  end
end

class ViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :camera_button, :scene_view, :map_message_box,
                :start_button, :exit_button, :curr_location, :destination,
                :target_pos, :distance, :destination_altitude, :map_center

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
    @location_manager.desiredAccuracy = 1000 #kCLLocationAccuracyNearestTenMeters
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
    configuration = ARWorldTrackingConfiguration.alloc.init
    configuration.worldAlignment = ARWorldAlignmentGravityAndHeading
    @scene_view.session.runWithConfiguration(configuration)
    @scene_view.session.delegate = self
    self.view = @scene_view
    add_cones
    add_message_box('Exit', 50)
  end

  def add_message_box(button_str, button_width)
    height = 70
    left_padding = 20
    vert_padding = 5
    message_box_frame = [[0, UIScreen.mainScreen.bounds.size.height - height],
                         [UIScreen.mainScreen.bounds.size.width, height]]
    @message_box = UIView.alloc.initWithFrame(message_box_frame)
    @message_box.backgroundColor = UIColor.alloc.initWithRed(0, green: 0.8, blue: 0.8, alpha: 0.9)
    button_frame   = [[UIScreen.mainScreen.bounds.size.width - button_width, 0],
                    [button_width, height]]
    button_label = UILabel.new
    button_label.font = UIFont.systemFontOfSize(18)
    button_label.text = button_str
    button_label.textColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 1.0)
    button_label.frame = [[0, 0], [button_width, height]]
    if button_str == 'Exit'
      @exit_button = UIView.alloc.initWithFrame(button_frame)
      @exit_button.addSubview(button_label)
      @message_box.addSubview(@exit_button)
    else
      @start_button = UIView.alloc.initWithFrame(button_frame)
      @start_button.addSubview(button_label)
      @message_box.addSubview(@start_button)
    end
    name = UILabel.new
    name.font = UIFont.systemFontOfSize(16)
    name.text = "#{@destination.title}"
    name.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 1)
    name.frame = [[left_padding, vert_padding],
                  [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(name)
    @distance = UILabel.new
    @distance.font = UIFont.systemFontOfSize(18)
    @distance.text = "#{@curr_location.distanceFromLocation(@destination.location).round}m away"
    @distance.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 0.5)
    @distance.frame = [[left_padding, height / 2 - vert_padding],
                       [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(@distance)
    view.addSubview(@message_box)
  end

  def add_cones
    scene = SCNScene.scene
    guide_geometry = SCNPyramid.pyramidWithWidth(0.1, height: 0.2, length: 0.1)
    guide_material = SCNMaterial.material
    guide_material.diffuse.contents = NSColor.colorWithRed(0, green: 0.8, blue: 0.8, alpha: 0.9)
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
    target.position = @target_pos = get_target_vec_location
    constraint = SCNLookAtConstraint.lookAtConstraintWithTarget(target)
    constraint.localFront = SCNVector3Make(0, 0.2, 0)
    guide.constraints = [constraint]
    @scene_view.pointOfView.addChildNode(guide)
    scene.rootNode.addChildNode(target)
    @scene_view.scene = scene
  end

  def get_target_vec_location
    curr_lon = @curr_location.coordinate.longitude
    curr_lat = @curr_location.coordinate.latitude
    dest_lon = @destination.longitude
    dest_lat = @destination.latitude
    radian_lat = curr_lat * Math::PI / 180
    meters_per_deg_lat = 111132.92 - 559.82 * Math.cos(2 * radian_lat) + 1.175 * Math.cos(4 * radian_lat)
    meters_per_deg_lon = 111412.84 * Math.cos(radian_lat) - 93.5 * Math.cos(3 * radian_lat)
    x = (dest_lon - curr_lon) * meters_per_deg_lon
    z = (curr_lat - dest_lat) * meters_per_deg_lat

    api_url = 'https://maps.googleapis.com/maps/api/elevation/'
    api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'
    uri       = api_url + "json?locations=#{dest_lat},#{dest_lon}&key=#{api_key}"
    url       = NSURL.URLWithString(uri)
    config    = NSURLSessionConfiguration.defaultSessionConfiguration
    session   = NSURLSession.sessionWithConfiguration(config)
    completion_handler = lambda do |data, response, error|
      if error.class != NilClass
        puts error
      elsif response.statusCode == 200
        error_ptr = Pointer.new(:object)
        response_object = NSJSONSerialization.JSONObjectWithData(data,
                                                                 options: NSJSONReadingAllowFragments,
                                                                 error: error_ptr)
        if response_object.class == NilClass # An error occurred with previous line
          error_handler(nil, error_ptr[0])
        elsif response_object.class != Hash
          return
        else
          error_handler(response_object, nil)
        end
      end
    end
    data_task = session.dataTaskWithURL(url, completionHandler: completion_handler)
    data_task.resume
    while @destination_altitude.nil?
    end
    y = @destination_altitude - @curr_location.altitude
    SCNVector3Make(x, y, z)
  end

  def error_handler(dict, error)
    unless dict.nil?
      results = dict['results'][0]
      return if results.nil?
      @destination_altitude = results['elevation']
    end
  end

  # Called when the user moves locations
  def locationManager(manager, didUpdateLocations: locations)
    if locations.count > 0
      location = @curr_location = locations.last
      if location.horizontalAccuracy < 100
        if @map_center.nil? or @map_center.distanceFromLocation(location) > 100
          @map_center = location
          span = MKCoordinateSpanMake(0.014, 0.014)
          region = MKCoordinateRegionMake(location.coordinate, span)
          view.setRegion(region, true)
          @started_loading_POIs = false
        end
        unless @started_loading_POIs
          @started_loading_POIs = true
          loader = PlacesLoader.alloc.init
          loader.load_POIs(self, location, 1000)
        end
      end
      unless @distance.nil?
        @distance.text = "~#{@curr_location.distanceFromLocation(@destination.location).round}m away"
      end
    end
  end

  # Called when the user touches the screen
  def touchesEnded(touches, withEvent: event)
    if event.touchesForView(@start_button)
      @location_manager.stopUpdatingLocation
      @map_center = nil
      display_AR
    end
    if event.touchesForView(@exit_button)
      @scene_view.session.pause
      display_map
    end
  end

  # Called when a map annotation is selected
  def mapView(mapView, didSelectAnnotationView: view)
    return if view.class.to_s == 'NSKVONotifying_MKModernUserLocationView'
    @destination = nil
    @places.each do |place|
      if place.longitude == view.coordinate.longitude && place.latitude == view.coordinate.latitude
        @destination = place
        break
      end
    end
    if @destination.nil?
      UIAlertView.alloc.initWithTitle('Out of Range',
                                      message: 'The place of interest needs to be within 1km to enable AR.',
                                      delegate: nil,
                                      cancelButtonTitle: 'Ok',
                                      otherButtonTitles: nil).show
      return
    end
    add_message_box('Start', 60)
  end

  # Called when a map annotation is deselected
  def mapView(mapView, didDeselectAnnotationView: view)
    @message_box.removeFromSuperview unless @message_box.nil?
  end

  # Called with every AR frame update
  def session(session, didUpdateFrame: frame)
    me = @scene_view.pointOfView.position
    @distance.text = "#{Math.sqrt((@target_pos.x - me.x)**2 + (@target_pos.z - me.z)**2).round}m away"
  end

  # Called when the AR session is interrupted
  def sessionInterruptionEnded(session)
    UIAlertView.alloc.initWithTitle('AR Session Interrupted',
                                    message: 'Restart the AR experience to ensure target placement accuracy',
                                    delegate: nil,
                                    cancelButtonTitle: 'Ok',
                                    otherButtonTitles: nil).show
    @scene_view.session.pause
    display_map
  end
end
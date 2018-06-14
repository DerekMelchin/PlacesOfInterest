class ARViewController < UIViewController
  attr_accessor :scene_view, :scene_config

  def init
    @api_url = 'https://maps.googleapis.com/maps/api/elevation/'
    @api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'
    super
  end

  def viewDidLoad
    super
    @scene_view = ARSCNView.alloc.init
    @scene_view.autoenablesDefaultLighting = true
    @scene_view.delegate = self
    @scene_config = ARWorldTrackingConfiguration.alloc.init
    @scene_config.worldAlignment = ARWorldAlignmentGravityAndHeading
    @scene_view.session.runWithConfiguration(@scene_config)
    @scene_view.session.delegate = self
    self.view = @scene_view
    add_cones
  end

  def add_cones
    @scene = SCNScene.scene
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

    @scene.rootNode.addChildNode(target)
    @scene_view.pointOfView.addChildNode(guide)
    @scene_view.scene = @scene
  end

  def get_target_vec_location
    curr_lon = parentViewController.curr_location.coordinate.longitude
    curr_lat = parentViewController.curr_location.coordinate.latitude
    dest_lon = parentViewController.destination.longitude
    dest_lat = parentViewController.destination.latitude

    radian_lat = curr_lat * Math::PI / 180
    meters_per_deg_lat = 111132.92 - 559.82 * Math.cos(2 * radian_lat) + 1.175 * Math.cos(4 * radian_lat)
    meters_per_deg_lon = 111412.84 * Math.cos(radian_lat) - 93.5 * Math.cos(3 * radian_lat)
    x = (dest_lon - curr_lon) * meters_per_deg_lon
    z = (curr_lat - dest_lat) * meters_per_deg_lat

    uri       = @api_url + "json?locations=#{dest_lat},#{dest_lon}&key=#{@api_key}"
    url       = NSURL.URLWithString(uri)
    config    = NSURLSessionConfiguration.defaultSessionConfiguration
    session   = NSURLSession.sessionWithConfiguration(config)

    completion_handler = lambda do |data, response, error|
      if !error.nil?
        puts error
      elsif response.statusCode == 200
        error_ptr = Pointer.new(:object)
        response_object = NSJSONSerialization.JSONObjectWithData(data,
                                                                 options: NSJSONReadingAllowFragments,
                                                                 error: error_ptr)
        if response_object.nil? # An error occurred with previous line
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
    while @destination_altitude.nil?; end
    y = @destination_altitude - parentViewController.curr_location.altitude
    SCNVector3Make(x, y, z)
  end

  def error_handler(dict, _)
    unless dict.nil?
      results = dict['results'][0]
      return if results.nil?
      @destination_altitude = results['elevation']
    end
  end

  def session(_, didUpdateFrame: _)
    me = @scene_view.pointOfView.position
    parentViewController.distance.text = "#{Math.sqrt((@target_pos.x - me.x)**2 + (@target_pos.z - me.z)**2).round}m away"
  end

  def sessionInterruptionEnded(_)
    pause_AR_session
    @scene_view.session.runWithConfiguration(@scene_config, options: ARSessionRunOptionResetTracking)
    add_cones
  end

  def pause_AR_session
    @scene_view.pointOfView.childNodes.each {|node| node.removeFromParentNode}
    @scene.rootNode.childNodes.each {|node| node.removeFromParentNode}
    @scene_view.session.pause
  end
end
class MapViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :map_center, :did_follow_user

  def init
    @location_manager = CLLocationManager.alloc.init
    @region_radius = 1000
    @started_loading_POIs = false
    @places = []
    super
  end

  def location_manager
    @location_manager
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
      alert = UIAlertController.alertControllerWithTitle('Heading Unavailable',
                                                         message: 'Sorry, the AR won\'t work for your device.',
                                                         preferredStyle: UIAlertControllerStyleAlert)
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault,
                                             handler: nil)
      alert.addAction(action)
      self.presentViewController(alert, animated: true, completion: nil)
    end
  end

  def display_map
    self.view = MKMapView.alloc.init
    view.rotateEnabled = true
    view.showsCompass = false
    view.showsUserLocation = true
    view.delegate = self
    camera = MKMapCamera.camera
    view.setCamera(camera, animated: false)
    @location_manager.startUpdatingLocation
    if @started_loading_POIs
      @places.each {|a| Dispatch::Queue.main.async {view.addAnnotation(a)}}
    end
  end

  # Called when the user moves locations
  def locationManager(manager, didUpdateLocations: locations)
    if locations.count > 0
      location = self.parentViewController.current_location = locations.last
      if location.horizontalAccuracy < 100
        if @map_center.nil? or @map_center.distanceFromLocation(location) > 100
          @map_center = location
          span = MKCoordinateSpanMake(0.014, 0.014)
          region = MKCoordinateRegionMake(location.coordinate, span)
          view.setRegion(region, false)
          @started_loading_POIs = false
        end
        unless @started_loading_POIs
          @started_loading_POIs = true
          loader = PlacesLoader.alloc.init
          loader.load_POIs(self, location, 1000)
        end
      end
      unless self.parentViewController.distance.nil?
        self.parentViewController.distance.text = "#{self.parentViewController.current_location.distanceFromLocation(self.parentViewController.destination.location).round}m away"
      end
    end
  end

  def stop_updating_location
    @location_manager.stopUpdatingLocation
    @map_center = nil
  end

  # Called when a map annotation is selected
  def mapView(mapView, didSelectAnnotationView: view)
    return if view.class.to_s == 'NSKVONotifying_MKModernUserLocationView'
    self.parentViewController.destination = nil
    @places.each do |place|
      if place.longitude == view.coordinate.longitude && place.latitude == view.coordinate.latitude
        self.parentViewController.destination = place
        break
      end
    end
    if self.parentViewController.destination.nil?
      alert = UIAlertController.alertControllerWithTitle('Out of Range',
                                                         message: 'The place of interest needs to be within 1km to enable AR.',
                                                         preferredStyle: UIAlertControllerStyleAlert)
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault,
                                             handler: nil)
      alert.addAction(action)
      self.presentViewController(alert, animated: true, completion: nil)
      return
    end
    self.parentViewController.add_message_box('Start', 60)
  end

  # Called when a map annotation is deselected
  def mapView(mapView, didDeselectAnnotationView: view)
    self.parentViewController.message_box.removeFromSuperview unless self.parentViewController.message_box.nil?
  end

  def mapView(mapView, regionDidChangeAnimated: animated)
    # if !did_follow_user
    #   puts 'called'
    #   did_follow_user = true
    #   view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: true)
    # end
  end

  def mapViewDidFinishLoadingMap(mapView)
    view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: true)
  end

end
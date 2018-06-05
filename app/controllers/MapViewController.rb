class MapViewController < UIViewController
  attr_accessor :location_manager, :region_radius, :started_loading_POIs,
                :places, :map_center, :did_follow_user, :map_camera, :loader

  def init
    @region_radius = 1000
    @started_loading_POIs = false
    @places = []
    super
  end

  def map_center
    @map_center
  end

  def map_center=(new_center)
    @map_center = new_center
  end

  def started_loading_POIs
    @started_loading_POIs
  end

  def started_loading_POIs=(new_value)
    @started_loading_POIs = new_value
  end

  def loader
    @loader
  end

  def viewDidLoad
    super
    self.view = MKMapView.alloc.init
    view.rotateEnabled = true
    view.scrollEnabled = false
    view.showsCompass = false
    view.showsUserLocation = true
    view.delegate = self
    @map_camera = MKMapCamera.camera
    view.setCamera(@map_camera, animated: false)
    @loader = PlacesLoader.alloc.init
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

  def mapViewDidFinishLoadingMap(mapView)
    view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: true)
  end

end
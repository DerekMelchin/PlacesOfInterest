class MapViewController < UIViewController
  attr_accessor :region_radius, :started_loading_POIs, :places, :did_follow_user, :map_camera, :loader

  def loader; @loader; end
  def started_loading_POIs; @started_loading_POIs; end
  def started_loading_POIs=(new_value); @started_loading_POIs = new_value; end
  def places; @places; end

  def init
    @region_radius = 1000
    @started_loading_POIs = false
    @places = []
    super
  end

  def viewDidLoad
    super
    self.view = MKMapView.alloc.init
    view.showsUserLocation = true
    view.rotateEnabled     = true
    view.scrollEnabled     = false
    view.showsCompass      = false
    view.delegate          = self
    @map_camera = MKMapCamera.camera
    view.setCamera(@map_camera, animated: false)
    @loader = PlacesLoader.alloc.init
  end

  # Called when a map annotation is selected
  def mapView(mapView, didSelectAnnotationView: view)
    return if view.class.to_s == 'NSKVONotifying_MKModernUserLocationView'
    parentViewController.destination = nil
    @places.each do |place|
      if place.longitude == view.coordinate.longitude && place.latitude == view.coordinate.latitude
        parentViewController.destination = place
        break
      end
    end
    if parentViewController.destination.nil?
      alert = UIAlertController.alertControllerWithTitle('Out of Range',
                                                         message: 'You need to be closer to enable AR.',
                                                         preferredStyle: UIAlertControllerStyleAlert)
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault,
                                             handler: nil)
      alert.addAction(action)
      presentViewController(alert, animated: true, completion: nil)
      return
    end
    parentViewController.add_message_box('Start')
  end

  # Called when a map annotation is deselected
  def mapView(mapView, didDeselectAnnotationView: view)
    parentViewController.message_box.removeFromSuperview unless parentViewController.message_box.nil?
  end

  def mapViewDidFinishLoadingMap(mapView)
    view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: false)
  end
end
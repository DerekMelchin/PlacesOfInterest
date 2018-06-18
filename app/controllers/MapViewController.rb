class MapViewController < UIViewController
  attr_accessor :started_loading_POIs, :places, :map_camera, :loader

  def init
    @started_loading_POIs = false
    @places = []
    super
  end

  def viewDidLoad
    super
    self.view = MKMapView.alloc.init
    view.showsUserLocation = true
    view.rotateEnabled     = false
    view.scrollEnabled     = false
    view.showsCompass      = false
    view.delegate          = self
    @loader = PlacesLoader.alloc.init
  end

  def mapView(mapView, didSelectAnnotationView: view)
    return if view.annotation.is_a?(MKUserLocation)
    view.pinTintColor = UIColor.greenColor
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
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault, handler: nil)
      alert.addAction(action)
      presentViewController(alert, animated: true, completion: nil)
      return
    end
    parentViewController.add_message_box('Start')
  end

  def mapView(mapView, didDeselectAnnotationView: view)
    return if view.annotation.is_a?(MKUserLocation)
    view.pinTintColor = UIColor.blackColor
    parentViewController.message_box.removeFromSuperview unless parentViewController.message_box.nil?
  end

  def mapView(mapView, viewForAnnotation: view)
    return nil if view.is_a?(MKUserLocation)
    an_view = MKPinAnnotationView.alloc.initWithAnnotation(view, reuseIdentifier: nil)
    an_view.pinTintColor = UIColor.blackColor
    an_view
  end

  def mapViewDidFinishLoadingMap(_)
    view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: false)
  end
end
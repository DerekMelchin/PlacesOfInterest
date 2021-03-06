class MapViewController < UIViewController
  attr_accessor :started_loading_POIs, :places, :loader

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
    view.zoomEnabled       = false
    view.delegate          = self
    @loader = PlacesLoader.alloc.init(self)
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
    Dispatch.once do
      Dispatch::Queue.new('set_map_region_and_tracking_mode').async do
        while parentViewController.curr_location.nil?; end
        span = MKCoordinateSpanMake(0.0125, 0.0125)
        region = MKCoordinateRegionMake(parentViewController.curr_location.coordinate, span)
        view.setRegion(region, animated: false)
        view.setUserTrackingMode(MKUserTrackingModeFollowWithHeading, animated: false)
      end
    end
  end
end
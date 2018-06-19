class PlacesLoader
  def init(map_controller)
    @map_controller = map_controller
    @master_view_controller = @map_controller.parentViewController
    @api_url = 'https://maps.googleapis.com/maps/api/place/'
    @api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'
    self
  end

  def load_POIs(location, radius = 30)
    latitude  = location.coordinate.latitude
    longitude = location.coordinate.longitude
    uri       = @api_url + "nearbysearch/json?location=#{latitude},#{longitude}"\
                "&radius=#{radius}&sensor=true&types=establishment&key=#{@api_key}"
    url       = NSURL.URLWithString(uri)
    config    = NSURLSessionConfiguration.defaultSessionConfiguration
    session   = NSURLSession.sessionWithConfiguration(config)
    data_task = session.dataTaskWithURL(url, completionHandler: completion_handler(radius))
    data_task.resume
  end

  def completion_handler(radius)
    lambda do |data, response, error|
      if !error.nil?
        puts error
      elsif response.statusCode == 200
        error_ptr = Pointer.new(:object)
        response_object = NSJSONSerialization.JSONObjectWithData(data,
                                                                 options: NSJSONReadingAllowFragments,
                                                                 error: error_ptr)
        if response_object.nil? # An error occurred with previous line
          alert_loading_POIs_failed(error_ptr[0])
        elsif response_object.class != Hash
          return
        else
          update_places(response_object, radius)
        end
      end
    end
  end

  def alert_loading_POIs_failed(error)
    alert = UIAlertController.alertControllerWithTitle('Error',
                                                       message: "Loading places of interest failed: #{error}",
                                                       preferredStyle: UIAlertControllerStyleAlert)
    action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault, handler: nil)
    alert.addAction(action)
    self.presentViewController(alert, animated: true, completion: nil)
  end

  def update_places(places_dict, radius)
    places_array = places_dict['results']
    return if places_array.nil?
    new_places = []
    places_to_remove = []
    @map_controller.places.each {|place| places_to_remove << place}

    places_array.each do |place_dict|
      latitude    = place_dict['geometry']['location']['lat']
      longitude   = place_dict['geometry']['location']['lng']
      name        = place_dict['name']
      place       = Place.alloc.init(latitude, longitude, name)
      if @master_view_controller.curr_location.distanceFromLocation(place.location) <= radius
        new_places << place
      end
    end

    places_to_remove.delete_if {|place| true if new_places.map {|p| p.title}.include?(place.title)}
    @map_controller.places.delete_if {|place| true if places_to_remove.map {|p| p.title}.include?(place.title)}
    new_places.delete_if {|place| true if @map_controller.places.map {|p| p.title}.include?(place.title)}
    @map_controller.places += new_places

    unless @master_view_controller.destination.nil?
      removing_destination = places_to_remove.map {|p| p.title}.include?(@master_view_controller.destination.title)
    end

    Dispatch::Queue.main.async do
      @map_controller.view.removeAnnotations(places_to_remove)
      @map_controller.view.addAnnotations(new_places)
    end

    alert_out_of_range if removing_destination && in_AR_mode
  end

  def in_AR_mode
    @master_view_controller.view.subviews.map {|view| view.class}.include?(ARSCNView)
  end

  def alert_out_of_range
    alert = UIAlertController.alertControllerWithTitle('Out of Range',
                                                       message: 'You need to be closer to the location to enable AR.',
                                                       preferredStyle: UIAlertControllerStyleAlert)
    handler = lambda  do |action|
      @master_view_controller.display_map
      @master_view_controller.view.subviews[1].removeFromSuperview
    end
    action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault, handler: handler)
    alert.addAction(action)
    @master_view_controller.presentViewController(alert, animated: true, completion: nil)
  end
end
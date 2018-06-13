class PlacesLoader
  attr_accessor :api_url, :api_key, :caller

  def init
    @api_url = 'https://maps.googleapis.com/maps/api/place/'
    @api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'
    super
  end

  def load_POIs(caller, location, radius = 30)
    @caller   = caller
    latitude  = location.coordinate.latitude
    longitude = location.coordinate.longitude
    uri       = @api_url + "nearbysearch/json?location=#{latitude},#{longitude}"\
                "&radius=#{radius}&sensor=true&types=establishment&key=#{@api_key}"
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
          error_handler(nil, error_ptr[0], radius)
        elsif response_object.class != Hash
          return
        else
          error_handler(response_object, nil, radius)
        end
      end
    end
    data_task = session.dataTaskWithURL(url, completionHandler: completion_handler)
    data_task.resume
  end

  def error_handler(places_dict, error, radius)
    unless error.nil?
      alert = UIAlertController.alertControllerWithTitle('Error',
                                                         message: "Loading places of interest failed: #{error}",
                                                         preferredStyle: UIAlertControllerStyleAlert)
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault, handler: nil)
      alert.addAction(action)
      self.presentViewController(alert, animated: true, completion: nil)
    end
    unless places_dict.nil?
      places_array = places_dict['results']
      return if places_array.nil?
      new_places = []
      places_to_remove = []
      places_array.each do |place_dict|
        latitude    = place_dict['geometry']['location']['lat']
        longitude   = place_dict['geometry']['location']['lng']
        reference   = place_dict['reference']
        name        = place_dict['name']
        address     = place_dict['vicinity']
        place       = Place.alloc.init(latitude, longitude, reference, name, address)
        if @caller.parentViewController.current_location.distanceFromLocation(place.location) < radius
          new_places << place
        end
      end
      @caller.places.each {|place| places_to_remove << place}
      places_to_remove -= new_places
      @caller.places -= places_to_remove
      new_places -= @caller.places
      @caller.places += new_places
      Dispatch::Queue.main.async do
        @caller.view.removeAnnotations(places_to_remove)
        @caller.view.addAnnotations(new_places)
        @caller.parentViewController.add_message_box('Start') unless @caller.parentViewController.destination.nil?
      end
    end
  end
end
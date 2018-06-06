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
  end

  def error_handler(places_dict, error)
    unless places_dict.nil?
      places_array = places_dict['results']
      return if places_array.nil?
      places_array.each do |place_dict|
        latitude    = place_dict['geometry']['location']['lat']
        longitude   = place_dict['geometry']['location']['lng']
        reference   = place_dict['reference']
        name        = place_dict['name']
        address     = place_dict['vicinity']
        place       = Place.alloc.init(latitude, longitude, reference, name, address)
        @caller.places << place
        Dispatch::Queue.main.async {@caller.view.addAnnotation(place)}
      end
    end
  end
end
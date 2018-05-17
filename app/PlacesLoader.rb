class PlacesLoader
  @@api_url = 'https://maps.googleapis.com/maps/api/place/'
  @@api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'

  def load_POIs(location, radius = 30)
    puts 'Load POIs'
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude
    uri = @@api_url + "nearbysearch/json?location=#{latitude},#{longitude}&radius=#{radius}&sensor=true&types=establishment&key=#{@@api_key}"
    url = NSURL.URLWithString(uri)
    config = NSURLSessionConfiguration.defaultSessionConfiguration
    session = NSURLSession.sessionWithConfiguration(config)
    completion_handler = lambda do |data, response, error|
      if error.class != NilClass
        puts error
      elsif response.statusCode == 200
        puts data
        error_ptr = Pointer.new(:object)
        response_object = NSJSONSerialization.JSONObjectWithData(data, options:0, error:error_ptr)
        # if error_ptr points to an error, handler(nil, error)


        ### Getting Swifty
        # do {
        #   let responseObject = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
        #   guard let responseDict = responseObject as? NSDictionary else {
        #     return
        #   }
        #   handler(responseDict, nil)
        # } catch let error as NSError {
        #     handler(nil, error)
        #   }


      end
    end
    data_task = session.dataTaskWithURL(url, completionHandler: completion_handler)
    data_task.resume
  end
end
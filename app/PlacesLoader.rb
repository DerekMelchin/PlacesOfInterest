class PlacesLoader
  @@api_url = 'https://maps.googleapis.com/maps/api/place/'
  @@api_key = 'AIzaSyB8MZxrd9TRDvGBrAWJnFEtbQtrzgT2h7I'

  def load_POIs(location, radius = 30)
    puts 'Load POIs'
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude

    uri = @@api_url + "nearbysearch/json?location=#{latitude},#{longitude}&radius=#{radius}&sensor=true&types=establishment&key=#{@@api_key}"
    #url = URL.init(string: uri)
    #puts url
  end
end
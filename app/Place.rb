class Place
  attr_accessor :latitude, :longitude, :location, :title

  def coordinate; @location.coordinate; end

  def init(latitude, longitude, name)
    @latitude   = latitude
    @longitude  = longitude
    @title      = name
    @location   = CLLocation.alloc.initWithLatitude(latitude, longitude: longitude)
    self
  end
end
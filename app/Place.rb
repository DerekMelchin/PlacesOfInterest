class Place
  attr_accessor :reference, :place_name, :address, :phone_number, :website, :location,
                :latitude, :longitude

  def title; @place_name; end
  def coordinate; @location.coordinate; end
  def location; @location; end
  def latitude; @latitude; end
  def longitude; @longitude; end

  def init(latitude, longitude, reference, name, address)
    @latitude   = latitude
    @longitude  = longitude
    @place_name = name
    @reference  = reference
    @address    = address
    @location   = CLLocation.alloc.initWithLatitude(latitude, longitude: longitude)
    self
  end
end
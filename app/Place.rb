class Place
  attr_accessor :reference, :place_name, :address, :phone_number, :website, :location,
                :latitude, :longitude

  def info_text
    info = "Address: #{@address}"
    info += "\nPhone: #{@phone_number}" unless @phone_number.nil?
    info += "\nWebsite: #{@website}" unless @website.nil?
    info
  end

  def init(latitude, longitude, reference, name, address)
    @latitude   = latitude
    @longitude  = longitude
    @place_name = name
    @reference  = reference
    @address    = address
    @location   = CLLocation.alloc.initWithLatitude(latitude, longitude: longitude)
    self
  end

  def title
    @place_name
  end

  def coordinate
    @location.coordinate
  end

  def location
    @location
  end

  def latitude
    @latitude
  end

  def longitude
    @longitude
  end
end
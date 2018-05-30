class Place
  attr_accessor :reference, :place_name, :address, :phone_number, :website, :title, :location

  def info_text
    info = "Address: #{@address}"
    info += "\nPhone: #{@phone_number}" unless @phone_number.nil?
    info += "\nWebsite: #{@website}" unless @website.nil?
    info
  end

  def init(location, reference, name, address)
    @place_name = name
    @reference  = reference
    @address    = address
    @location   = location
    self
  end

  def title
    @place_name
  end

  def coordinate
    @location.coordinate
  end
end
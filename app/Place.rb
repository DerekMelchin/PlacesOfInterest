class Place < ARAnnotation
  attr_accessor :reference, :place_name, :address, :phone_number, :website

  def info_text
    info = "Address: #{@address}"
    info += "\nPhone: #{@phone_number}" unless @phone_number.nil?
    info += "\nWebsite: #{@website}" unless @website.nil?
    info
  end

  def init(location, reference, name, address)
    @place_name = name
    @reference = reference
    @address = address
    # super
    @location = location
  end

  def description
    @place_name
  end
end
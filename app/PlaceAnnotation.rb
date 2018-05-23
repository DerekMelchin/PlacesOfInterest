class PlaceAnnotation < MKPlacemark
  attr_accessor :coordinate, :title

  def init(location, title)
    @coordinate = location
    @title = title
    self
    #super
  end

  def coordinate
    @coordinate
  end
end
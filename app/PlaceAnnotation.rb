class PlaceAnnotation
  attr_accessor :coordinate, :title

  def init(location, title)
    @coordinate = location
    @title = title
  end
end
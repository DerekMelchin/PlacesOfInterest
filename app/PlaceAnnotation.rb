class PlaceAnnotation # < MKAnnotation
  attr_accessor :coordinate, :title

  def init(location, title)
    @coordinate = location
    @title = title
    #super
  end
end
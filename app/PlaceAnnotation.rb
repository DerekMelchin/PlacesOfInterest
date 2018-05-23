class PlaceAnnotation # < Placemark
  attr_accessor :coordinate, :title

  def init(location, title)
    @coordinate = location
    @title = title
    #super
  end

  def coordinate
    @coordinate
  end
end
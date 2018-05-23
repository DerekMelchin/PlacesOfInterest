class ARAnnotation < NSObject
  attr_accessor :title, :location, :annotation_view

  distance_from_user = 0
  azimuth = 0
  vertical_level = 0
  active = false

  def init
    super
  end

end
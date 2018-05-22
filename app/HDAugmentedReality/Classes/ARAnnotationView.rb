class ARAnnotationView < UIView
  @@annotation = nil
  @@initialized = false

  def init
    super.init(frame: CGRect.zero)
    initialize_internal
  end

  def init_with_coder(coder)
    super.init(coder: coder)
    initialize_internal
  end

  def init_with_frame(frame)
    super.init(frame: frame)
    initialize_internal
  end

  def initialize_internal
    if @@initialized
      return
    end
    @@initialized = true
    initialize
  end

  def awakeFromNib
    bind_ui
  end

  def initialize
  end

  def bind_ui
  end
end
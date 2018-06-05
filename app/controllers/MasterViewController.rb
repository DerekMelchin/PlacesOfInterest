class Numeric
  def degrees
    self * Math::PI / 180
  end
end

class MasterViewController < UIViewController
  attr_accessor :map_controller, :AR_controller, :curr_location, :destination,
                :distance, :message_box

  def init
    super
  end

  def viewDidLoad
    super
    @map_controller = MapViewController.alloc.init
    self.addChildViewController(@map_controller)
    self.view.addSubview(@map_controller.view)
    @map_controller.view.frame = [[0, 0], [UIScreen.mainScreen.bounds.size.width,
                                           UIScreen.mainScreen.bounds.size.height]]
    @map_controller.didMoveToParentViewController(self)
  end

  def display_map
    @AR_controller.willMoveToParentViewController(nil)
    @AR_controller.view.removeFromSuperview
    self.view.addSubview(@map_controller.view)
    @map_controller.didMoveToParentViewController(self)
    add_message_box('Start', 70) unless @destination.nil?
  end

  def display_AR
    @map_controller.willMoveToParentViewController(nil)
    @map_controller.view.removeFromSuperview
    @AR_controller = ARViewController.alloc.init
    self.addChildViewController(@AR_controller)
    self.view.addSubview(@AR_controller.view)
    @AR_controller.view.frame = [[0, 0], [UIScreen.mainScreen.bounds.size.width,
                                          UIScreen.mainScreen.bounds.size.height]]
    @AR_controller.didMoveToParentViewController(self)
    add_message_box('Exit', 50)
  end

  def current_location
    @curr_location
  end

  def current_location=(new_location)
    @curr_location = new_location
  end

  def destination
    @destination
  end

  def destination=(new_location)
    @destination = new_location
  end

  def distance
    @distance
  end

  def distance=(new_distance)
    @distance = new_distance
  end

  def message_box
    @message_box
  end

  def add_message_box(button_str, button_width)
    height = 70
    left_padding = 20
    vert_padding = 5
    message_box_frame = [[0, UIScreen.mainScreen.bounds.size.height - height],
                         [UIScreen.mainScreen.bounds.size.width, height]]
    @message_box = UIView.alloc.initWithFrame(message_box_frame)
    @message_box.backgroundColor = UIColor.alloc.initWithRed(0, green: 0.8, blue: 0.8, alpha: 0.9)
    button_frame   = [[UIScreen.mainScreen.bounds.size.width - button_width, 0],
                      [button_width, height]]
    button_label = UILabel.new
    button_label.font = UIFont.systemFontOfSize(18)
    button_label.text = button_str
    button_label.textColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 1.0)
    button_label.frame = [[0, 0], [button_width, height]]
    if button_str == 'Exit'
      @exit_button = UIView.alloc.initWithFrame(button_frame)
      @exit_button.addSubview(button_label)
      @message_box.addSubview(@exit_button)
    else
      @start_button = UIView.alloc.initWithFrame(button_frame)
      @start_button.addSubview(button_label)
      @message_box.addSubview(@start_button)
    end
    name = UILabel.new
    name.font = UIFont.systemFontOfSize(16)
    name.text = "#{@destination.title}"
    name.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 1)
    name.frame = [[left_padding, vert_padding],
                  [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(name)
    @distance = UILabel.new
    @distance.font = UIFont.systemFontOfSize(18)
    @distance.text = "#{@curr_location.distanceFromLocation(@destination.location).round}m away"
    @distance.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 0.5)
    @distance.frame = [[left_padding, height / 2 - vert_padding],
                       [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(@distance)
    view.addSubview(@message_box)
  end

  # Called when the user touches the screen
  def touchesEnded(touches, withEvent: event)
    if event.touchesForView(@start_button)
      @map_controller.stop_updating_location
      display_AR
    end
    if event.touchesForView(@exit_button)
      @AR_controller.scene_view.session.pause
      @map_controller.location_manager.startUpdatingLocation
      display_map
    end
  end
end
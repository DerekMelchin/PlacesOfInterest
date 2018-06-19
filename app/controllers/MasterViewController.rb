class Numeric
  def degrees
    self * Math::PI / 180
  end
end

class MasterViewController < UIViewController
  attr_accessor :curr_location, :destination, :distance, :message_box

  def init
    @location_manager = CLLocationManager.alloc.init
    @location_manager.startUpdatingLocation
    @location_manager.delegate = self
    @location_manager.desiredAccuracy = KCLLocationAccuracyBestForNavigation
    @location_manager.requestAlwaysAuthorization
    super
  end

  def viewDidLoad
    super
    view.backgroundColor = UIColor.whiteColor
    @map_controller = MapViewController.alloc.init
    self.addChildViewController(@map_controller)
    display_map
    @AR_controller = ARViewController.alloc.init
    self.addChildViewController(@AR_controller)
    Dispatch::Queue.main.after(3) { check_heading }
  end

  def check_heading
    if @location_manager.headingAvailable
      @location_manager.startUpdatingHeading
    else
      alert = UIAlertController.alertControllerWithTitle('Heading Unavailable',
                                                         message: 'Sorry, the AR won\'t work for your device.',
                                                         preferredStyle: UIAlertControllerStyleAlert)
      action = UIAlertAction.actionWithTitle('Ok', style: UIAlertActionStyleDefault, handler: nil)
      alert.addAction(action)
      self.presentViewController(alert, animated: true, completion: nil)
    end
  end

  def display_map
    unless @AR_controller.nil?
      message_box.removeFromSuperview
      @AR_controller.pause_AR_session
      @AR_controller.willMoveToParentViewController(nil)
      @AR_controller.view.removeFromSuperview
    end
    self.view.addSubview(@map_controller.view)
    @map_controller.view.translatesAutoresizingMaskIntoConstraints = false
    @map_controller.view.leftAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.leftAnchor).active = true
    @map_controller.view.rightAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.rightAnchor).active = true
    @map_controller.view.topAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.topAnchor).active = true
    @map_controller.view.bottomAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.bottomAnchor).active = true
    @map_controller.didMoveToParentViewController(self)
    add_message_box('Start') unless @destination.nil?
  end

  def display_AR
    message_box.removeFromSuperview
    @map_controller.willMoveToParentViewController(nil)
    @map_controller.view.removeFromSuperview
    self.view.addSubview(@AR_controller.view)
    @AR_controller.view.translatesAutoresizingMaskIntoConstraints = false
    @AR_controller.view.widthAnchor.constraintEqualToConstant(UIScreen.mainScreen.bounds.size.width).active = true
    @AR_controller.view.topAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.topAnchor).active = true
    @AR_controller.view.bottomAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.bottomAnchor).active = true
    @AR_controller.didMoveToParentViewController(self)
    add_message_box('Exit')
    @AR_controller.scene_view.session.runWithConfiguration(@AR_controller.scene_config,
                                                           options: ARSessionRunOptionResetTracking)
    @AR_controller.add_cones
  end

  def add_message_box(button_str)
    height       = 70
    button_width = button_str == 'Exit' ? 50 : 60
    left_padding = 20
    vert_padding = 5

    @message_box = UIView.alloc.init
    view.addSubview(@message_box)
    @message_box.translatesAutoresizingMaskIntoConstraints = false
    @message_box.widthAnchor.constraintEqualToConstant(UIScreen.mainScreen.bounds.size.width).active = true
    @message_box.heightAnchor.constraintEqualToConstant(height).active = true
    @message_box.bottomAnchor.constraintEqualToAnchor(view.safeAreaLayoutGuide.bottomAnchor).active = true
    @message_box.backgroundColor = UIColor.alloc.initWithRed(1, green: 1, blue: 1, alpha: 0.9)

    button_frame           = [[UIScreen.mainScreen.bounds.size.width - button_width, 0], [button_width, height]]
    button_label           = UILabel.new
    button_label.font      = UIFont.systemFontOfSize(18)
    button_label.text      = button_str
    button_label.textColor = UIColor.colorWithRed(0, green: 0.8, blue: 0.8, alpha: 0.9)
    button_label.frame     = [[0, 0], [button_width, height]]
    if button_str == 'Exit'
      @exit_button = UIView.alloc.initWithFrame(button_frame)
      @exit_button.addSubview(button_label)
      @message_box.addSubview(@exit_button)
    else
      @start_button = UIView.alloc.initWithFrame(button_frame)
      @start_button.addSubview(button_label)
      @message_box.addSubview(@start_button)
    end

    name           = UILabel.new
    name.font      = UIFont.systemFontOfSize(16)
    name.text      = "#{@destination.title}"
    name.textColor = UIColor.blackColor
    name.frame     = [[left_padding, vert_padding],
                      [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(name)

    @distance           = UILabel.new
    @distance.font      = UIFont.systemFontOfSize(18)
    @distance.text      = "#{@curr_location.distanceFromLocation(@destination.location).round}m away"
    @distance.textColor = UIColor.alloc.initWithRed(0, green: 0, blue: 0, alpha: 0.5)
    @distance.frame     = [[left_padding, height / 2 - vert_padding],
                           [UIScreen.mainScreen.bounds.size.width - 2 * left_padding - button_width, height / 2]]
    @message_box.addSubview(@distance)
  end

  def locationManager(_, didUpdateLocations: locations)
    @curr_location = locations.last
    if @curr_location.horizontalAccuracy < 100 && (!@map_controller.started_loading_POIs ||
        @curr_location.distanceFromLocation(@previous_update_location) > 50)
        @map_controller.started_loading_POIs = true
        @previous_update_location = @curr_location
        @map_controller.loader.load_POIs(@curr_location, 500)
    end
    self.view.subviews.each do |view|
      if view.is_a?(MKMapView) && !@distance.nil?
        @distance.text = "#{@curr_location.distanceFromLocation(@destination.location).round}m away"
      end
    end
  end

  def touchesEnded(_, withEvent: event)
    display_AR if event.touchesForView(@start_button)
    display_map if event.touchesForView(@exit_button)
  end
end
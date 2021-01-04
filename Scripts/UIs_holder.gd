extends Node2D

#######################
#      PARAMS
#######################

# UIs
onready var slider_theta = $VSlider_theta
onready var slider_rho = $VSlider_rho

onready var minus_pi_text = $VSlider_theta/Label_minusPi
onready var plus_pi_text = $VSlider_theta/Label_plusPi
onready var minus_one_text = $VSlider_rho/Label_minusOne
onready var plus_one_text = $VSlider_rho/Label_plusOne
onready var theta_label = $VSlider_theta/Label_theta
onready var rho_label = $VSlider_rho/Label_rho

onready var joystick_a_text = $joystick_ab/joystick_background/Label_a
onready var joystick_b_text = $joystick_ab/joystick_background/Label_b
onready var joystick_devx_text = $joystick_deviations/joystick_background2/Label_dev_x
onready var joystick_devy_text = $joystick_deviations/joystick_background2/Label_dev_z

################################

func _ready():
	# set the location of sliders
	slider_theta.set_global_position(Vector2(45,100))
	slider_rho.set_global_position(Vector2(45,240))

	slider_theta.step = 0.01
	slider_theta.min_value = -PI
	slider_theta.max_value = PI
	slider_theta.value = 0
	slider_theta.rect_size = Vector2(16,100)
	
	slider_rho.step = 0.01
	slider_rho.min_value = -1
	slider_rho.max_value = 1
	slider_rho.value = 0
	slider_rho.rect_size = Vector2(16,100)

	# set a font
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://Fonts/HussarBd.otf")
	dynamic_font.size = 30
	dynamic_font.outline_color = ColorN("Black")

	# set the location of slider labels
	# slider theta	
	minus_pi_text.text = "-Pi"
	minus_pi_text.add_color_override("font_color", ColorN("Red"))
	minus_pi_text.set_global_position(Vector2(28,190))

	plus_pi_text.text = "+Pi"
	plus_pi_text.add_color_override("font_color", ColorN("Red"))
	plus_pi_text.set_global_position(Vector2(26.5,95))
	
	theta_label.text = "Theta"
	theta_label.add_color_override("font_color", ColorN("Red"))
	theta_label.set_global_position(Vector2(26,80))
	
	# slider rho
	minus_one_text.text = "-1"
	minus_one_text.add_color_override("font_color", ColorN("Red"))
	minus_one_text.set_global_position(Vector2(31,328))	

	plus_one_text.text = "+1"
	plus_one_text.add_color_override("font_color", ColorN("Red"))
	plus_one_text.set_global_position(Vector2(29.5,240))		

	rho_label.text = "Rho"
	rho_label.add_color_override("font_color", ColorN("Red"))
	rho_label.set_global_position(Vector2(27,223))
	
	# set the location of joystick labels
	joystick_a_text.text = "a"
	joystick_a_text.add_font_override("font",dynamic_font)
	joystick_a_text.add_color_override("font_color", ColorN("Black"))
	joystick_a_text.set_global_position(Vector2(192,145))

	joystick_b_text.text = "b"
	joystick_b_text.add_font_override("font",dynamic_font)
	joystick_b_text.add_color_override("font_color", ColorN("Black"))
	joystick_b_text.set_global_position(Vector2(132,82))

	joystick_devx_text.text = "Sigma x"
	joystick_devx_text.add_font_override("font",dynamic_font)
	joystick_devx_text.add_color_override("font_color", ColorN("Black"))
	joystick_devx_text.set_global_position(Vector2(204,264))	
	joystick_devx_text.rect_rotation = 90

	joystick_devy_text.text = "Sigma y"
	joystick_devy_text.add_font_override("font",dynamic_font)
	joystick_devy_text.add_color_override("font_color", ColorN("Black"))
	joystick_devy_text.set_global_position(Vector2(111,221))

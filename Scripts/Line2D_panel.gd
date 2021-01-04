extends Line2D

#################
#    PARAMS
#################
# title
var screen_size
# var rect_color = Color(0.94,0.97,1,0.8)   # option 1, aliceblue
var rect_color = Color(0.96,0.96,0.86,0.8)  # option 2, beige
#var rect_color = Color(0.68,0.85,0.9,0.8)   # option 3, lightblue

var rect_width_title = 200
var rect_height_title = 35
var rect_y_title = 20
var rect_x_layout = 15
var rect_x_title

var node_title
var title_adjust_x = 16.5
var title_adjust_y = -3

# panel 2
var padding_top = 20
var rect_width_gesture = rect_width_title
var rect_height_gesture = 280
var rect_y_gesture = rect_y_title + rect_height_title + padding_top
var rect_x_gesture

var node_gesture
var gesture_adjust_x = 6
var gesture_adjust_y = 6

# panel 3
var rect_width_parameters = rect_width_gesture
var rect_height_parameters = 205
var rect_y_parameters = rect_y_gesture + rect_height_gesture + padding_top
var rect_x_parameters

var node_parameters
var opt_node
var parameter_title_adjust_x = 6
var parameter_title_adjust_y = 6
var parameter_adjust_x = 23
var parameter_adjust_each_line = 24

var text_variance_xz = Label.new()
#var text_variance_z = Label.new()
var text_theta = Label.new()
var text_mean_xz = Label.new()
#var text_mean_z = Label.new()
var text_covariance = Label.new()
var text_ab = Label.new()
#var text_b = Label.new()
var text_camera = Label.new()
var variance_x
var variance_z
var mean_x = 0
var mean_z = 0
var theta
var a
var b
onready var camera_panel = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_panel/Viewport_panel/Camera")
onready var camera =  get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")

onready var gesture_para = get_tree().get_root().find_node("Line2D_Gaussian_Contour",true,false)
var Gaussian_covariance

# drag input
var rotation_delta = 100
var rot_error = 0.2
var origin = Vector3(0,0,0)
var position_start_1 
var position_end_1 
var position_start_2 
var position_end_2 

# draw variables
var draw_type_flag
var draw_10 = Vector2()
var draw_11 = Vector2()
var draw_20 = Vector2()
var draw_21 = Vector2()
var center
var radius
var x_scale
var z_scale

# camera rotation
var rotation_direction
var angle_rotated = 0
#signal rotation_status(angle, direction)
#var camera_angle_convert_ratio = 240.0/120.0

# multi-inputs
var events = {}

###################################################

func _ready():
# get default parameters, create text labels
	x_scale = gesture_para.x_scale
	z_scale = gesture_para.z_scale

	# param group 1
	add_child(text_mean_xz)
	#add_child(text_mean_z)
	add_child(text_ab)
	#add_child(text_b)
	add_child(text_theta)
	# param group 2		
	add_child(text_variance_xz)
	#add_child(text_variance_z)
	add_child(text_covariance)
	# param group 3
	add_child(text_camera)


func _process(_delta):
# update parameters
	# fetch param group 1
	mean_x = stepify(gesture_para.mean_x.x/x_scale,0.01)  # the real mean
	mean_z = stepify(gesture_para.mean_z.z/z_scale,0.01)
	theta = stepify(gesture_para.contour_theta,0.01)
	a = stepify(gesture_para.a,0.01)
	b = stepify(gesture_para.b,0.01)
	# fectch param group 2
	variance_x = stepify(gesture_para.std_deviation_x,0.01)
	variance_z = stepify(gesture_para.std_deviation_z,0.01)
	Gaussian_covariance = stepify(gesture_para.covariance_Gaussian,0.01)
	
	# param group 1
	text_mean_xz.text = "Mean: (" + str(mean_x) + "," + str(mean_z) + ")"
	#text_mean_z.text = "Mean Z: " + str(mean_z)
	text_theta.text = "Theta of Ellipse: " + str(theta)
	text_ab.text = "Ellipse axes a,b: (" + str(a) + "," + str(b) + ")"
	#text_b.text = "Axis b: " + str(b)
	# param group 2
	text_variance_xz.text = "Std deviation: (" + str(variance_x) + "," + str(variance_z) + ")"
	#text_variance_z.text = "Variance Z: " + str(variance_z)	
	text_covariance.text = "Covariance: " + str(Gaussian_covariance)	
	# param group 3
	text_camera.text = "Camera Rotation: " + str(camera.camera_rotation)

	
func _draw():
	screen_size = get_viewport_rect().size
	rect_x_title = screen_size.x - rect_width_title - rect_x_layout
	rect_x_gesture = rect_x_title
	rect_x_parameters = rect_x_gesture
	
	# draw the title rectangle + put the title text in it
	draw_rect(Rect2(rect_x_title, rect_y_title, rect_width_title, rect_height_title),rect_color,true)

	if !get_node_or_null("label_title"):
		node_title = Label.new()
		node_title.name = "label_title"
		add_child(node_title)

	node_title.text = "2D Gaussian Visualization"
	node_title.add_color_override("font_color", ColorN("Black"))
	node_title.set_position(Vector2(rect_x_title+title_adjust_x, rect_height_title+title_adjust_y))

	# draw the joystick+slider rectangle 
	draw_rect(Rect2(rect_x_gesture, rect_y_gesture, rect_width_gesture, rect_height_gesture),rect_color,true)

#	if !get_node_or_null("label_gesture"):
#		node_gesture = Label.new()
#		node_gesture.name = "label_gesture"
#		add_child(node_gesture)	

#	node_gesture.text = "Gesture region:"
#	node_gesture.add_color_override("font_color", ColorN("Black"))
#	node_gesture.set_position(Vector2(rect_x_gesture + gesture_adjust_x, rect_y_gesture + gesture_adjust_y))

#	text_camera.add_color_override("font_color", ColorN("Brown"))
#	text_camera.set_global_position(Vector2(rect_x_gesture + parameter_adjust_x,rect_y_gesture + parameter_adjust_each_line))

	# draw the parameter rectangle + set the location of texts
	draw_rect(Rect2(rect_x_parameters, rect_y_parameters, rect_width_parameters, rect_height_parameters),rect_color,true)
	
	if !get_node_or_null("label_parameters"):
		node_parameters = Label.new()
		node_parameters.name = "label_parameters"
		add_child(node_parameters)		

#	# title
#	node_parameters.text = "Parameters: "
#	node_parameters.add_color_override("font_color", ColorN("Black"))	
#	node_parameters.set_position(Vector2(rect_x_parameters + parameter_title_adjust_x, rect_y_parameters + parameter_title_adjust_y))

	# param group 1
	text_ab.add_color_override("font_color", ColorN("Brown"))
	text_ab.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line))
	
#	text_b.add_color_override("font_color", ColorN("Brown"))
#	text_b.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line*3))
#
	text_theta.add_color_override("font_color", ColorN("Brown"))
	text_theta.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *2))
		
	text_mean_xz.add_color_override("font_color", ColorN("Brown"))
	text_mean_xz.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *3))
#
#	text_mean_z.add_color_override("font_color", ColorN("Brown"))
#	text_mean_z.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *6))
#
	# param group 2
	text_variance_xz.add_color_override("font_color", ColorN("Brown"))
	text_variance_xz.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *4.5))

#	text_variance_z.add_color_override("font_color", ColorN("Brown"))
#	text_variance_z.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *9))

	text_covariance.add_color_override("font_color", ColorN("Brown"))
	text_covariance.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *5.5))

	# param group 3
	text_camera.add_color_override("font_color", ColorN("Brown"))
	text_camera.set_global_position(Vector2(rect_x_parameters + parameter_adjust_x,rect_y_parameters + parameter_adjust_each_line *7))


############################################################################

func calculate_angle(vec1, vec2):
	var cos_angle = vec1.dot(vec2)/(calculate_length(vec1)*calculate_length(vec2))
	return cos_angle

func calculate_length(vec):
	if typeof(vec) == TYPE_VECTOR2:
		vec = Vector3(vec.x, vec.y, 0)
	var length = sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z)
	return length


extends Line2D

########################
#     PARAMS
########################

# LAYOUT PARAMS
onready var script_parameter_axes = get_node("../..")

var origin = Vector3()
var x_scale = 0
var z_scale = 0

# key parameters
export var covariance_Gaussian = 0
export (float) var std_deviation_x = 1
export (float) var std_deviation_z = 1
export var mean_x = Vector3(1,0,0)
export var mean_z = Vector3(0,0,1)   # the value of real mean * scale
export (float) var a = 1
export (float) var b = 1

# drawing parameters
var ellipse_drawing_step = 500
var correction_point = 20
var ellipse_x_array = Array()
var ellipse_z_array = Array()

var anti_aliasing_transparent = 0.2
var anti_aliasing_linewidth = 1.2

var margin_right_viewport = get_viewport_rect().size.x
var list_parameters = [1.0,1.0,3]
export var contour_theta = 0

# shading and contour decoration
var mat = load("res://Shading/material_Gaussian.tres")
var shader_param = 50
var bottom_contour_color = Color(1,1,0)  # yellow
var upper_contour_color = Color(1,0.08,0.58)  # dark pink
var bottom_contour_back_color = Color(0.68, 1, 0.18, 1)  # green-yellow
var upper_contour_back_color = Color(0.65,0.16,0.16,1)   # brown
var contour_ring_up_distance = 0.6

# screen-world coordinate switch
var position10 = Vector2()
var position11 = Vector2()
var position20 = Vector2()
var position21 = Vector2()

onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")
var intersection_plane = Plane(Vector3(0,1,0), 0)
var ray_length = 1000

var position_3d_1 = Vector3()
var position_3d_2 = Vector3()

# multi-input parameter
var events = {}

# one-input parameters
var location_mean_2d
var location_mean_3d

# drawing parameter
var drawing_type_flag = "slider_change_ab_theta"

# interactive cross-control
export var slider_changed_by_gesture = false

#####################################

func _ready():
	x_scale=script_parameter_axes.x_scale.x  
	z_scale=script_parameter_axes.z_scale.z
	origin = Vector3(mean_x.x, 0, mean_z.z)  # the drawing origin
	position_3d_1 = Vector3(std_deviation_x, 0,0)
	position_3d_2 = Vector3(0,0,std_deviation_z)
	
	# change the Gaussian scale_up param
	mat.set_shader_param("Gaussian_scale_up",shader_param)
		
func _process(_delta):
	# the origin of mesh
	origin = Vector3(mean_x.x, 0, mean_z.z)
	# two vectors about the finger-inputs
	a = get_tree().get_root().find_node("HSlider_a", true, false).value
	b = get_tree().get_root().find_node("HSlider_b", true, false).value
	contour_theta = get_tree().get_root().find_node("HSlider_theta", true, false).value # counter-clockwise, in rad
	position_3d_1 = Vector3(a*cos(contour_theta),0,a*sin(contour_theta))
	position_3d_2 = Vector3(-b*sin(contour_theta),0,b*cos(contour_theta))
	

func _input(event):
	var x_limit = script_parameter_axes.x_end.x # a 3d value
	var z_limit = script_parameter_axes.z_end.z
# take the most recent two finger-touch inputs
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)
	
#	if event.position.x < margin_right_viewport:
	if event.position.x < 766 and event.position.y > 200:
		if event is InputEventScreenDrag:
			events[event.index] = event
			# one-finger mean change
			if events.size() == 1:
				if events[0].position.y > 200:
					location_mean_2d = events[0].position                
				
					var ray_from = camera.project_ray_origin(location_mean_2d)
					var ray_to = ray_from + camera.project_ray_normal(location_mean_2d)*ray_length
					location_mean_3d = intersection_plane.intersects_ray(ray_from, ray_to)					
				
					if location_mean_3d.x > -x_limit and location_mean_3d.x < x_limit and \
						location_mean_3d.z > -z_limit and location_mean_3d.z < z_limit:
						mean_x.x = 1.0*location_mean_3d.x # the drawing mean
						mean_z.z = 1.0*location_mean_3d.z 
						mat.set_shader_param("mean_x", mean_x.x)
						mat.set_shader_param("mean_z", mean_z.z)
				
						drawing_type_flag = "mean_change"
						update()
				
			# two-finger contour change	
			elif events.size() == 2:	
				position10 = events[0].position
				position20 = events[1].position
	
				ellipse_x_array.clear()
				ellipse_z_array.clear()
				# convert position1 and position2 to 3d space.
				var ray_from = camera.project_ray_origin(position10)
				var ray_to = ray_from + camera.project_ray_normal(position10)*ray_length
				position_3d_1 = intersection_plane.intersects_ray(ray_from, ray_to)			
			
				ray_from = camera.project_ray_origin(position20)
				ray_to = ray_from + camera.project_ray_normal(position20)*ray_length
				position_3d_2 = intersection_plane.intersects_ray(ray_from, ray_to)			
			
				if position_3d_1.x > -x_limit and position_3d_1.x < x_limit and position_3d_1.z > - z_limit and position_3d_1.z < z_limit \
				   and position_3d_2.x > -x_limit and position_3d_2.x < x_limit and position_3d_2.z > - z_limit and position_3d_2.z < z_limit:
					drawing_type_flag = "two-finger-input"
					update()
					
	update()   # when it is not one-finger/two-finger input
			   # for slider input

# use two finger-touch positions to draw
func _draw():
	var calculate_2d_origin = Vector2(origin.x, origin.z) # real space
	var finger_vector1
	var finger_vector2
	slider_changed_by_gesture = false
	draw_circle(camera.unproject_position(origin), 2.0, ColorN("Yellow"))
			
	# draw the contour by two finger-inputs
	if drawing_type_flag == "two-finger-input":
		# position_3d_1 and 2 are finger positions in the world
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z) - calculate_2d_origin 
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z) - calculate_2d_origin
		list_parameters = calculate_ab_of_ellipse(finger_vector1, finger_vector2)
		a = list_parameters[0]
		b = list_parameters[1]
		get_tree().get_root().find_node("HSlider_a", true, false).value = list_parameters[0]
		get_tree().get_root().find_node("HSlider_b", true, false).value = list_parameters[1]
		draw_circle(camera.unproject_position(position_3d_1), 5.0, ColorN("Blue"))
		draw_circle(camera.unproject_position(position_3d_2), 5.0, ColorN("Blue"))
		
	# draw the contour by the mean value and std deviations
	elif drawing_type_flag == "mean_change":
		# position_3d_1 and 2 are calculatd from a,b,theta, from (0,0,0)
		slider_changed_by_gesture = true
		finger_vector1 = Vector2(position_3d_1.x,position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)
		get_tree().get_root().find_node("HSlider_mean_x", true, false).value = mean_x.x
		get_tree().get_root().find_node("HSlider_mean_z", true, false).value = mean_z.z
		list_parameters[0] = get_tree().get_root().find_node("HSlider_a", true, false).value *x_scale
		list_parameters[1] = get_tree().get_root().find_node("HSlider_b", true, false).value *z_scale
		# set the main axis
		if list_parameters[0] > list_parameters[1]:
			list_parameters[2] = 1
		elif list_parameters[0] < list_parameters[1]:
			list_parameters[2] = 2
			var temp = list_parameters[0]
			list_parameters[0] = list_parameters[1]
			list_parameters[1] = temp
		else:
			list_parameters[2] = 3
			
		a = list_parameters[0]
		b = list_parameters[1]
		
	elif drawing_type_flag == "slider_change_ab_theta":
		# position_3d_1 and 2 are calculatd from a,b,theta, from(0,0,0)
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)
		list_parameters[0] = get_tree().get_root().find_node("HSlider_a", true, false).value *x_scale
		list_parameters[1] = get_tree().get_root().find_node("HSlider_b", true, false).value *z_scale
		# set the main axis
		if list_parameters[0] > list_parameters[1]:
			list_parameters[2] = 1
		elif list_parameters[0] < list_parameters[1]:
			list_parameters[2] = 2
			var temp = list_parameters[0]
			list_parameters[0] = list_parameters[1]
			list_parameters[1] = temp
		else:
			list_parameters[2] = 3

		a = list_parameters[0]
		b = list_parameters[1]
		
			
	var middle_matrix = Transform2D()
	middle_matrix.x.x = pow(list_parameters[0],2)    # list_parameter two times the real value, but coefficient doesn't matter
	middle_matrix.x.y = 0
	middle_matrix.y.x = 0
	middle_matrix.y.y = pow(list_parameters[1],2)


# three scenarios, index of finger as the main axis of ellipse
###################################################################
	
	if list_parameters[2] == 1: 
	# calculate rotation matrix
		if finger_vector1.x < 0 and finger_vector1.y > 0:
			finger_vector1 = - finger_vector1
		if finger_vector1.x > 0 and finger_vector1.y > 0:
			finger_vector1 = - finger_vector1
		
		var cos_rotation = finger_vector1.dot(Vector2(1,0)) / length_of_vector(finger_vector1)
		if drawing_type_flag == "slider_change_ab_theta":
			cos_rotation = cos(get_tree().get_root().find_node("HSlider_theta", true, false).value)

		contour_theta = acos(cos_rotation)
		var sin_rotation = sqrt(1-cos_rotation*cos_rotation)
		var rotation_matrix = Transform2D()
		rotation_matrix.x.x = cos_rotation
		rotation_matrix.x.y = -sin_rotation
		rotation_matrix.y.x = sin_rotation
		rotation_matrix.y.y = cos_rotation
	
	# calculate the transpose = inverse of rotation matrix
		var rotation_matrix_inverse = rotation_matrix
		rotation_matrix_inverse.x.y = rotation_matrix.y.x
		rotation_matrix_inverse.y.x = rotation_matrix.x.y
				
	# calculate covariance matrix
		var covariance_matrix = rotation_matrix * middle_matrix * rotation_matrix_inverse
		covariance_Gaussian = covariance_matrix.x.y / (x_scale * z_scale)
		
	# draw ellipse with a,b,theta.
		var start = rotation_matrix * Vector2(-abs(list_parameters[0]),0)
		var delta = abs(2*list_parameters[0]) / (ellipse_drawing_step-1)


	# find points behind Gaussian
		var ellipse_x_pre = start.x
		var ellipse_z1_pre = start.y
		var canvas_contour_bottom = PoolVector2Array()
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)))
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y

		ellipse_x_pre = start.x
		var ellipse_z2_pre = start.y
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre)))

		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y
		
		var x_value_min = canvas_contour_bottom[0].x
		var x_value_max = canvas_contour_bottom[0].x
		var y_value_min = canvas_contour_bottom[0].y
		var y_value_max = canvas_contour_bottom[0].y
		for j in range(canvas_contour_bottom.size()-1):
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x < x_value_min:
					x_value_min = canvas_contour_bottom[j+1].x
					y_value_min = canvas_contour_bottom[j+1].y
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x > x_value_max:
					x_value_max = canvas_contour_bottom[j+1].x
					y_value_max = canvas_contour_bottom[j+1].y
		var slope = (y_value_max - y_value_min) / (x_value_max - x_value_min)
						
# draw contour
		start = rotation_matrix * Vector2(-abs(list_parameters[0]),0)
		ellipse_x_pre = start.x
		ellipse_z1_pre = start.y			
		ellipse_x_array = Array()
		ellipse_z_array = Array()

		# calculate the number of contours to draw on the Gaussian
		var contour_space_index = 0.25
		var each_contour_height
		var number_of_contour = 0
		var height = calculate_Gaussian_probability(origin.x + contour_space_index*ellipse_x_pre, origin.z + contour_space_index*ellipse_z1_pre)
		while height > 0.5:
			number_of_contour += 1
			height = calculate_Gaussian_probability(origin.x + contour_space_index*(number_of_contour+1)*ellipse_x_pre, origin.z + contour_space_index*(number_of_contour+1)*ellipse_z1_pre)
		var contour_back_bending_index = 6
														
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			
			var draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)) 
			var draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2 - contour_back_bending_index && draw1.y >= reference_y_1 - contour_back_bending_index:
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z1_pre)
						if m!=4:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)								

		
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y
			ellipse_x_array.append(ellipse_x_pre)
			ellipse_z_array.append(ellipse_z1_pre)	

# draw another half contour			
		ellipse_x_pre = start.x
		ellipse_z2_pre = start.y
		
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			var draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre))
			var draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2-contour_back_bending_index && draw1.y >= reference_y_1-contour_back_bending_index:
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z2_pre)
						if m!=4:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)										

							
			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y
			ellipse_x_array.append(ellipse_x_pre)
			ellipse_z_array.append(ellipse_z2_pre)	
			
		var checkpoint = Array()
		for i in range(ellipse_x_array.size()):
			if is_nan(ellipse_x_array[i]):	
				checkpoint.append(i)
			elif is_nan(ellipse_z_array[i]):
				checkpoint.append(i)
		for j in range(checkpoint.size()):
			ellipse_x_array.remove(checkpoint[j])
			ellipse_z_array.remove(checkpoint[j])

		std_deviation_x = (ellipse_x_array.max() - ellipse_x_array.min())/(2.0*x_scale)
		std_deviation_z = (ellipse_z_array.max() - ellipse_z_array.min())/(2.0*z_scale)
		covariance_Gaussian = covariance_Gaussian / (std_deviation_x*std_deviation_z)		
			
		mat.set_shader_param("variance_x", std_deviation_x)	
		mat.set_shader_param("variance_z", std_deviation_z)
		mat.set_shader_param("covariance", covariance_Gaussian)

#########################################################################################
			
	elif list_parameters[2] == 2:
	# calculate rotation matrix
		if finger_vector2.x < 0 and finger_vector2.y > 0:
			finger_vector2 = - finger_vector2
		if finger_vector2.x > 0 and finger_vector2.y > 0:
			finger_vector2 = - finger_vector2
		
		var cos_rotation = finger_vector2.dot(Vector2(1,0)) / length_of_vector(finger_vector2)
		if drawing_type_flag == "slider_change_ab_theta":
			cos_rotation = cos(get_tree().get_root().find_node("HSlider_theta", true, false).value)
		contour_theta = acos(cos_rotation)
		var sin_rotation = sqrt(1-cos_rotation*cos_rotation)
		var rotation_matrix = Transform2D()
		rotation_matrix.x.x = cos_rotation
		rotation_matrix.x.y = -sin_rotation
		rotation_matrix.y.x = sin_rotation
		rotation_matrix.y.y = cos_rotation

	# calculate the transpose = inverse of rotation matrix
		var rotation_matrix_inverse = rotation_matrix
		rotation_matrix_inverse.x.y = rotation_matrix.y.x
		rotation_matrix_inverse.y.x = rotation_matrix.x.y
				
	# calculate covariance matrix
		var covariance_matrix = rotation_matrix * middle_matrix * rotation_matrix_inverse
		covariance_Gaussian = covariance_matrix.x.y / (x_scale * z_scale)
	
	# draw ellipse
		ellipse_x_array = Array()
		ellipse_z_array = Array()
		var start = rotation_matrix * Vector2(-abs(list_parameters[0]),0)
		var delta = abs(2*list_parameters[0]) / (ellipse_drawing_step-1)

	# find points behind Gaussian
		var ellipse_x_pre = start.x
		var ellipse_z1_pre = start.y
		var canvas_contour_bottom = PoolVector2Array()
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)))

		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y

		ellipse_x_pre = start.x
		var ellipse_z2_pre = start.y
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre)))

		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y
		
		var x_value_min = canvas_contour_bottom[0].x
		var x_value_max = canvas_contour_bottom[0].x
		var y_value_min = canvas_contour_bottom[0].y
		var y_value_max = canvas_contour_bottom[0].y
		for j in range(canvas_contour_bottom.size()-1):
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x < x_value_min:
					x_value_min = canvas_contour_bottom[j+1].x
					y_value_min = canvas_contour_bottom[j+1].y
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x > x_value_max:
					x_value_max = canvas_contour_bottom[j+1].x
					y_value_max = canvas_contour_bottom[j+1].y
		var slope = (y_value_max - y_value_min) / (x_value_max - x_value_min)

# draw the contour		
		ellipse_x_array.append(ellipse_x_pre)
		ellipse_z_array.append(ellipse_z1_pre)
		ellipse_x_pre = start.x
		ellipse_z1_pre = start.y
				
		# calculate the number of contours to draw on the Gaussian
		var contour_space_index = 0.25
		var each_contour_height
		var number_of_contour = 0
		var height = calculate_Gaussian_probability(origin.x + contour_space_index*ellipse_x_pre, origin.z + contour_space_index*ellipse_z1_pre)
		while height > 0.5:
			number_of_contour += 1
			height = calculate_Gaussian_probability(origin.x + contour_space_index*(number_of_contour+1)*ellipse_x_pre, origin.z + contour_space_index*(number_of_contour+1)*ellipse_z1_pre)
		var contour_back_bending_index = 6							

		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			var draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre))
			var draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2-contour_back_bending_index && draw1.y >= reference_y_1-contour_back_bending_index:
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z1_pre)
						if m!=4:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)
					
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y
			ellipse_x_array.append(ellipse_x_pre)
			ellipse_z_array.append(ellipse_z1_pre)
			
		ellipse_x_pre = start.x
		ellipse_z2_pre = start.y
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			var draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre))
			var draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2-contour_back_bending_index && draw1.y >= reference_y_1-contour_back_bending_index:			
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z2_pre)
						if m!=4:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0.75,0.75,0.75,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,1), 1.0, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)									

					
			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y
			ellipse_x_array.append(ellipse_x_pre)
			ellipse_z_array.append(ellipse_z2_pre)	
					
		var checkpoint = Array()
		for i in range(ellipse_x_array.size()):
			if is_nan(ellipse_x_array[i]):	
				checkpoint.append(i)
			elif is_nan(ellipse_z_array[i]):
				checkpoint.append(i)
		for j in range(checkpoint.size()):
			ellipse_x_array.remove(checkpoint[j])
			ellipse_z_array.remove(checkpoint[j])			
		
		std_deviation_x = (ellipse_x_array.max() - ellipse_x_array.min())/(2.0*x_scale)
		std_deviation_z = (ellipse_z_array.max() - ellipse_z_array.min())/(2.0*z_scale)
		covariance_Gaussian = covariance_Gaussian / (std_deviation_x*std_deviation_z)

		mat.set_shader_param("variance_x", std_deviation_x)	
		mat.set_shader_param("variance_z", std_deviation_z)
		mat.set_shader_param("covariance", covariance_Gaussian)

######################################################################################3
			
	elif list_parameters[2] == 3:
		var pre_vector = Vector3(list_parameters[0],0,0)
		var delta = 2*PI/(ellipse_drawing_step - 1)
		contour_theta = 0

	# find points behind Gaussian
		var canvas_contour_bottom = PoolVector2Array()
		canvas_contour_bottom.append(camera.unproject_position(origin + pre_vector))
				
		for n in range(1, ellipse_drawing_step+correction_point):
			var theta = 0 + n*delta
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(list_parameters[0] * cos(theta), 0, list_parameters[0] * sin(theta))))

		
		var x_value_min = canvas_contour_bottom[0].x
		var x_value_max = canvas_contour_bottom[0].x
		var y_value_min = canvas_contour_bottom[0].y
		var y_value_max = canvas_contour_bottom[0].y
		for j in range(canvas_contour_bottom.size()-1):
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x < x_value_min:
					x_value_min = canvas_contour_bottom[j+1].x
					y_value_min = canvas_contour_bottom[j+1].y
			if !is_nan(canvas_contour_bottom[j+1].x):
				if canvas_contour_bottom[j+1].x > x_value_max:
					x_value_max = canvas_contour_bottom[j+1].x
					y_value_max = canvas_contour_bottom[j+1].y
		var slope = (y_value_max - y_value_min) / (x_value_max - x_value_min)


	# draw the contour

		# calculate the number of contours to draw on the Gaussian
		var contour_space_index = 0.25
		var each_contour_height
		var number_of_contour = 0
		var height = calculate_Gaussian_probability(origin.x + contour_space_index*list_parameters[0], origin.z)
		while height > 0.5:
			number_of_contour += 1
			height = calculate_Gaussian_probability(origin.x + contour_space_index*(number_of_contour+1)*list_parameters[0], origin.z)
		var contour_back_bending_index = 6

		for n in range(0, ellipse_drawing_step+correction_point):
			var theta = 0 + n*delta
			var draw1 = camera.unproject_position(origin + Vector3(list_parameters[0] * cos(theta), 0, list_parameters[0] * sin(theta)))
			var draw2 = camera.unproject_position(origin + pre_vector)
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2 && draw1.y-contour_back_bending_index >= reference_y_1-contour_back_bending_index:		
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*list_parameters[0], origin.z)
						if m!=4:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(0.75,0.75,0.75,1), 1.0, true)
							draw_line(camera.unproject_position(origin+Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(0.75,0.75,0.75,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(1,0,0,1), 1.0, true)
							draw_line(camera.unproject_position(origin+Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(1,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)									

				
			pre_vector = Vector3(list_parameters[0] * cos(theta),0, list_parameters[0]*sin(theta))

		covariance_Gaussian = 0
		std_deviation_x = list_parameters[0]/x_scale   # half of the full width=2sigma
		std_deviation_z = std_deviation_x

		mat.set_shader_param("variance_x", std_deviation_x)	
		mat.set_shader_param("variance_z", std_deviation_z)
		mat.set_shader_param("covariance", covariance_Gaussian)

###############################################################################################

# function to get the length of a vector
func length_of_vector(vector):
	var length = sqrt(pow(vector.x,2)+pow(vector.y,2))
	return length
	
# calculate b of an ellipse, and the main axis index
func calculate_ab_of_ellipse(finger_vector1, finger_vector2):
	var dist1 = length_of_vector(finger_vector1)
	var dist2 = length_of_vector(finger_vector2)
	var cos_angle = finger_vector1.dot(finger_vector2) / (dist1 * dist2)
	var sin_angle = sqrt(1 - pow(cos_angle,2))
	if dist1 > dist2 and abs(dist1-dist2) > 0.2*x_scale:
		var a_value = dist1
		var main_axis_index = 1
		
		var new_x = dist2 * cos_angle
		var new_y = dist2 * sin_angle
		
		var b_value = sqrt(pow(new_y,2) / (1 - pow(new_x,2)/pow(a,2)))
		
		return [a_value,b_value,main_axis_index]
		
	elif dist1 < dist2 and abs(dist1-dist2) > 0.2*x_scale:
		var a_value = dist2
		var main_axis_index = 2
		
		var new_x = dist1 * cos_angle
		var new_y = dist1 * sin_angle
		
		var b_value = sqrt(pow(new_y,2) / (1 - pow(new_x,2)/pow(a,2)))
		
		return [a_value,b_value,main_axis_index]

	else: 
		return [dist1, dist1, 3]   # 3 for a circle

func calculate_Gaussian_probability(x, z):
	var coefficient = 1.0/(2*PI*std_deviation_x*std_deviation_z*sqrt(1-covariance_Gaussian*covariance_Gaussian))
	var power_index_coefficient = -1.0/(2*(1-covariance_Gaussian*covariance_Gaussian))
	var power_index_main = pow(x-mean_x.x,2.0)/pow(std_deviation_x,2.0) - \
						   2.0*covariance_Gaussian*(x-mean_x.x)*(z-mean_z.z)/(std_deviation_x*std_deviation_z) + \
						   pow(z-mean_z.z,2.0)/pow(std_deviation_z,2.0)
	var probability_density = coefficient*exp(power_index_coefficient*power_index_main)
	return probability_density*shader_param

func reference_y_value(slope, x, x_value_min, y_value_min):
	return slope * (x - x_value_min) + y_value_min

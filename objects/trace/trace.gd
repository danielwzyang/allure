extends Line2D

@export var spacing = 5

var drawing = false

func _input(event):
	if event.is_action_pressed("draw"):
		clear_points()
		drawing = true
	elif event.is_action_released("draw"):
		clear_points()
		drawing = false

func _process(delta):
	if drawing:
		var point = get_global_mouse_position()
		
		# if the last point is at least a certain distance away, we can add the new point
		if get_point_count() == 0 or get_point_position(get_point_count() - 1).distance_to(point) >= spacing:
			add_point(point)

extends Node2D

@export_group("Tracing")
@export var max_distance = 3
@export var strictness = 0.5

func _ready():
	var tracing_manager = get_node("Comparison/Viewport/Trace")
	tracing_manager.connect("finished_tracing", handle_tracing)

func handle_tracing():
	var accuracy = compare_paths(%Reference, %Comparison, max_distance, strictness)
	%Accuracy.text = "%.2f%%" % (accuracy * 100)

## this takes two subviewportcontainers where the two paths are stored and returns an accuracy value from 0 to 1
## max_distance is how far a pixel can be to count as a match
## strictness is a float from 0 (lenient) to 1 (exact match only) for non exact match scoring
func compare_paths(
	reference: SubViewportContainer, 
	comparison: SubViewportContainer,
	max_distance: int,
	strictness: float,
) -> float:
	var ref = (reference.get_child(0) as SubViewport).get_texture().get_image()
	var comp = (comparison.get_child(0) as SubViewport).get_texture().get_image()
	
	var width = ref.get_width()
	var height = ref.get_height()
	
	# these will be used for the f1 score
	var true_positives = 0.0
	var false_positives = 0.0
	var false_negatives = 0.0
	
	# this is a map of which reference pixels were matched
	var ref_matched = []
	for i in range(width * height):
		ref_matched.append(false)
	
	for x in range(width):
		for y in range(height):
			if comp.get_pixel(x, y).a > 0:
				# find the nearest pixel in the reference image within max_distance
				var best_distance = max_distance + 1
				var best_match = null
				for dx in range(-max_distance, max_distance + 1):
					var new_x = x + dx
					if new_x < 0 or new_x >= width:
						continue
					
					# the limit for dy is max_distance^2 - dx^2 since dx^2 + dy^2 <= max_distance^2
					var dy_limit = int(sqrt(max_distance*max_distance - dx*dx))
					
					for dy in range(-dy_limit, dy_limit + 1):
						var new_y = y + dy
						if new_y < 0 or new_y >= height:
							continue
						
						# if we found a reference pixel then we store the distance
						if ref.get_pixel(new_x, new_y).a > 0:
							var distance = sqrt(dx*dx + dy*dy)
							if distance < best_distance:
								best_distance = distance
								best_match = Vector2(new_x, new_y)
				
				# we found at least one reference pixel within max_distance
				if best_distance <= max_distance:
					# gaussian decay score from 0 to 1 on how close the match is
					var sigma = max_distance / 2.0
					var score = exp(-(best_distance*best_distance)/(2*sigma*sigma))
					
					# if strictness is 0.0 it always matches (lenient)
					# if strictness is 1.0 we only accept exact matches (strict)
					if score >= strictness:
						# mark the reference pixel as matched
						ref_matched[best_match.x + best_match.y * width] = true
						true_positives += 1
					else:
						false_positives += 1
				else:
					# a pixel in the comparison path doesn't exist in the reference path
					false_positives += 1
	
	for x in range(width):
		for y in range(height):
			# a pixel in the reference path didn't match
			if ref.get_pixel(x, y).a > 0 and not ref_matched[x + y * width]:
				false_negatives += 1
	
	var f1_score = true_positives / (true_positives + 0.5*(false_positives + false_negatives))

	return f1_score

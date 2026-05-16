class_name GameTimer

var is_time_running = false
var current_time: float = 0.0

func reset_timer() -> void:
	current_time = 0.0
	is_time_running = false
	
func tick(elapsed_time: float) -> void:
	if is_time_running:
		current_time += elapsed_time

func start_timer() -> void:
	is_time_running = true
	
func stop_timer() -> void:
	is_time_running = false
	
func formatted_time() -> String:
	var minutes := int(current_time) / 60
	var seconds := int(current_time) % 60
	
	return "%02d:%02d" % [minutes, seconds]
	

extends Node2D

func _ready():
	var gpu_particles = $GPUParticles2D
	
	# Start emission immediately
	gpu_particles.restart()
	
	# Create timer to remove this node after particles finish
	var timer = Timer.new()
	timer.wait_time = 2.0  # Adjust based on your particle settings
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_timer_timeout():
	queue_free()
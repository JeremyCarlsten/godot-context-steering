extends CharacterBody2D

var max_speed := 100
var steer_force := 0.1
var look_ahead := 100
var segments = 6;

var ray_directions = []
var interest = []
var danger = []

var chosen_dir = Vector2.ZERO
var acceleration = Vector2.ZERO
@onready var debug = $debug

func _ready():
	interest.resize(segments)
	danger.resize(segments)
	ray_directions.resize(segments)
	
	for i in segments:
		var angle = i * 2 * PI / segments
		ray_directions[i] = Vector2.RIGHT.rotated(angle)

func createLine(start:Vector2, direction:Vector2, length:float):
	var instance = Line2D.new()
	
	instance.add_point(start)
	instance.add_point(direction * length)
	return instance
	
func _physics_process(_delta):
	set_interest(get_global_mouse_position())
	set_danger()
	choose_direction()
	
	#print('interest: ', interest)
	#print('danger: ', danger)
	
	var desired_velocity = chosen_dir.rotated(rotation) * max_speed
	velocity = velocity.lerp(desired_velocity, steer_force)
	rotation = velocity.angle()
	
	move_and_slide()
	generate_debug()


func createDebug(start, end, length, isDanger:bool = false):
	var ray = Line2D.new()
	ray.add_point(start)
	ray.add_point(end * length)
	
	if(isDanger):
		ray.modulate = Color.RED
	else:
		ray.modulate = Color.GREEN
	return ray
	
func generate_debug():
	for child in debug.get_children():
		child.queue_free()
	for i in segments:
		if danger[i] > 0.0:
			var d = ray_directions[i].rotated(rotation)
			var ray = createDebug(self.global_position, d, danger[i], true)
			debug.add_child(ray)
		else:
			var d = ray_directions[i].rotated(rotation)
			var ray = createDebug(self.global_position, d, interest[i])
			debug.add_child(ray)

func set_interest(target):
	if target:
		for i in segments:
			var d = ray_directions[i].rotated(rotation).dot(target)
			interest[i] = max(0, d)

func set_danger():
	var space_state = get_world_2d().direct_space_state
	for i in segments:
		var params = PhysicsRayQueryParameters2D.create(self.global_position, self.global_position + ray_directions[i].rotated(rotation) * look_ahead)
		var result = space_state.intersect_ray(params)
		danger[i] = 1.0 if result else 0.0
	
func choose_direction():
	for i in segments:
		if danger[i] > 0.0:
			interest[i] = 0.0
	chosen_dir = Vector2.ZERO
	
	for i in segments:
		chosen_dir += ray_directions[i] * interest[i]
	
	chosen_dir = chosen_dir.normalized()	

#func getWeight(normal, away_vector):
	#var dot = away_vector.dot(normal)
#
	#var weight = 1.0 - abs(dot - 0.65)
#
	#return weight

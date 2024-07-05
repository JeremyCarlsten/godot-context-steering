extends CharacterBody2D

@export var max_speed := 300
@export var target:Node2D
var oldTarget:Node2D
var steer_force := 0.1
var look_ahead := 200
var segments = 16;

var ray_directions = []
var ray_length := 128;
var interest = []
var danger = []

var chosen_dir = Vector2.ZERO
var acceleration = Vector2.ZERO
@onready var debug = $debug

var is_in_range := false

func _ready():
	interest.resize(segments)
	danger.resize(segments)
	ray_directions.resize(segments)
	
	for i in segments:
		var angle = i * 2 * PI / segments
		ray_directions[i] = Vector2.RIGHT.rotated(angle)
	
func _physics_process(delta):
	set_interest()
	set_danger()
	choose_direction()
	
	var desired_velocity = chosen_dir * max_speed

	velocity = velocity.lerp(desired_velocity, steer_force)
	rotation = velocity.angle()
	
	move_and_collide(velocity * delta)
	generate_debug()


func createDebug(end, length, isDanger:bool = false):
	var ray = Line2D.new()
	ray.add_point(Vector2.ZERO)
	if(length > 0):
		ray.add_point(end * length * ray_length)
		if(isDanger):
			ray.modulate = Color.RED
		else:
			ray.modulate = Color.GREEN
	#else: 
		#ray.add_point(end * 0.5 * ray_length)
		#ray.modulate = Color.BURLYWOOD

	return ray
	
func generate_debug():
	for child in debug.get_children():
		child.queue_free()
	for i in segments:
		if danger[i] > 0.0:
			var d = ray_directions[i]
			var ray = createDebug(d, danger[i], true)
			debug.add_child(ray)
		else:
			var d = ray_directions[i]
			var ray = createDebug(d, interest[i])
			debug.add_child(ray)

func set_interest():
	if target:
		var direction_to_target = target.global_position - self.global_position
		for i in segments:
			interest[i] = getWeight(direction_to_target.normalized(), ray_directions[i].rotated(rotation))

	else:
		set_default_interest()
			
func set_default_interest():
	for i in segments:
		var d = ray_directions[i].rotated(rotation).dot(transform.x)
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
			interest[i] = interest[i] - danger[i]
	chosen_dir = Vector2.ZERO
	
	for i in segments:
		chosen_dir += ray_directions[i] * interest[i]

	chosen_dir = chosen_dir.rotated(rotation).normalized()	

func getWeight(normal, away_vector):
	var dot = away_vector.dot(normal)

	var weight = 1.0 - abs(dot - 0.65)

	return weight

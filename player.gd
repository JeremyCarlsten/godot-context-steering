class_name Player
extends CharacterBody2D

var speed = 400  # speed in pixels/sec

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed

	move_and_slide()

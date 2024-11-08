extends CharacterBody2D

@export var speed := 200.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	velocity = direction.normalized() * speed

	# Rotate the player to face the mouse cursor
	look_at(get_global_mouse_position())

	move_and_slide()

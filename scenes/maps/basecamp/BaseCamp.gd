extends Map

@export var camera_speed: int = 600

@onready var camera: Camera2D = $Camera2D

@onready var astar: AStarComponent = $AStarComponent


func _physics_process(delta):
	if multiplayer_connection.is_server():
		var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		camera.position += input_direction * camera_speed * delta

extends World

@export var camera_speed: int = 600

@onready var camera: Camera2D = $Camera2D


func _ready():
	map_to_sync = $Entities/Map
	enemies_to_sync = $Entities/Enemies
	npcs_to_sync = $Entities/NPCs
	player_respawn_locations = $PlayerRespawnLocations
	portals_to_sync = $Portals

	super()

	# To avoid duplicates, remove these placeholders, they are only used in the editor
	$Entities.queue_free()


func _physics_process(delta):
	if G.is_server():
		var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		camera.position += input_direction * camera_speed * delta

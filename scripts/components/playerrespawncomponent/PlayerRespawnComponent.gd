extends Node

var target_node: Node

@export var stats: StatsSynchronizerComponent
@export var respawn_time: float = 10

var respawn_timer: Timer


func _ready():
	target_node = get_parent()

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if not G.is_server():
		return

	stats.died.connect(_on_died)

	respawn_timer = Timer.new()
	respawn_timer.name = "RespawnTimer"
	respawn_timer.autostart = false
	respawn_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func respawn(location: Vector2):
	target_node.position = location
	stats.reset_hp()


func _on_died():
	respawn_timer.start()


func _on_respawn_timer_timeout():
	var respawn_location: Vector2 = G.world.find_player_respawn_location(target_node.position)
	respawn(respawn_location)

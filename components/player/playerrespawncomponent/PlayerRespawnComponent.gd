extends Node

class_name PlayerRespawnComponent

@export var stats_synchronizer: StatsSynchronizerComponent
@export var respawn_time: float = 10

var _target_node: Node

var _respawn_timer: Timer


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# Don't run on client, but also not free as the value of respawn_time is used in the death popup screen
	if not _target_node.multiplayer_connection.is_server():
		return

	if _target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	stats_synchronizer.died.connect(_on_died)

	_respawn_timer = Timer.new()
	_respawn_timer.name = "RespawnTimer"
	_respawn_timer.autostart = false
	_respawn_timer.one_shot = true
	_respawn_timer.wait_time = respawn_time
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(_respawn_timer)


func respawn(location: Vector2):
	GodotLogger.info("Respawning=[%s]" % _target_node.name)
	_target_node.position = location
	stats_synchronizer.reset_hp()
	stats_synchronizer.reset_energy()


func _on_died():
	GodotLogger.info("%s died, starting respawn timer" % _target_node.name)
	_respawn_timer.start()


func _on_respawn_timer_timeout():
	var respawn_location: Vector2 = (
		_target_node.multiplayer_connection.map.find_player_respawn_location(_target_node.position)
	)
	respawn(respawn_location)

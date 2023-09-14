extends Node2D

const INTERPOLATION_OFFSET = 0.1
const INTERPOLATION_INDEX = 2

var parent: Node2D

var last_sync_timestamp = 0.0
var server_syncs_buffer = []

var state_buffer = []

var bodies_in_view = []
var watchers = []


# Called when the node enters the scene tree for the first time.
func _ready():
	parent = $"../"

	stop()

	if Gmf.is_server() and parent.entity_type == Gmf.ENTITY_TYPE.PLAYER:
		var network_view_area = Area2D.new()
		network_view_area.name = "NetworkViewArea"
		var cs_network_view_area = CollisionShape2D.new()
		cs_network_view_area.name = "NetworkViewAreaCollisionShape2D"
		network_view_area.add_child(cs_network_view_area)

		var cs_network_view_circle = CircleShape2D.new()

		cs_network_view_circle.radius = 512.0
		cs_network_view_area.shape = cs_network_view_circle

		add_child(network_view_area)

		network_view_area.body_entered.connect(_on_network_view_area_body_entered)
		network_view_area.body_exited.connect(_on_network_view_area_body_exited)


func stop():
	set_physics_process(false)


func start():
	set_physics_process(true)


func _physics_process(_delta):
	if Gmf.is_server():
		var timestamp = Time.get_unix_time_from_system()

		sync.rpc_id(parent.peer_id, timestamp, parent.position, parent.velocity)

		for body in bodies_in_view:
			body.server_synchronizer.sync.rpc_id(
				parent.peer_id, timestamp, body.position, body.velocity
			)

	else:
		calculate_position()
		check_if_state_updated()


func calculate_position():
	var render_time = Gmf.client.clock - INTERPOLATION_OFFSET

	while (
		server_syncs_buffer.size() > 2
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		server_syncs_buffer.remove_at(0)

	if server_syncs_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = calculate_interpolation_factor(render_time)
		parent.position = interpolate(interpolation_factor, "position")
		parent.velocity = interpolate(interpolation_factor, "velocity")
	elif (
		server_syncs_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = calculate_extrapolation_factor(render_time)
		parent.position = extrapolate(extrapolation_factor, "position")
		parent.velocity = extrapolate(extrapolation_factor, "velocity")


func calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


func send_new_state(new_state: String):
	var timestamp = Time.get_unix_time_from_system()
	state_changed.rpc_id(parent.peer_id, timestamp, new_state)

	for watcher in watchers:
		state_changed.rpc_id(watcher.peer_id, timestamp, new_state)


func check_if_state_updated():
	for i in range(state_buffer.size() - 1, -1, -1):
		if state_buffer[i]["timestamp"] <= Gmf.client.clock:
			parent.state = state_buffer[i]["new_state"]
			parent.state_changed.emit(parent.state)
			state_buffer.remove_at(i)
			return true


@rpc("call_remote", "authority", "unreliable")
func sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < last_sync_timestamp:
		return

	last_sync_timestamp = timestamp
	server_syncs_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})


@rpc("call_remote", "any_peer", "reliable") func move(pos: Vector2):
	if not Gmf.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	if id == parent.peer_id:
		Gmf.signals.server.player_moved.emit(id, pos)


@rpc("call_remote", "authority", "reliable") func state_changed(timestamp: float, new_state: String):
	state_buffer.append({"timestamp": timestamp, "new_state": new_state})


func _on_network_view_area_body_entered(body):
	if body != parent and not bodies_in_view.has(body):
		match body.entity_type:
			Gmf.ENTITY_TYPE.PLAYER:
				Gmf.rpcs.player.add_other_player.rpc_id(
					parent.peer_id, body.username, body.position
				)
			Gmf.ENTITY_TYPE.ENEMY:
				Gmf.rpcs.enemy.add_enemy.rpc_id(parent.peer_id, body.name, body.enemy_class, body.position)

		bodies_in_view.append(body)

	if body != parent and parent not in body.server_synchronizer.watchers:
		body.server_synchronizer.watchers.append(parent)


func _on_network_view_area_body_exited(body):
	if bodies_in_view.has(body):
		bodies_in_view.erase(body)

	if body.server_synchronizer.watchers.has(parent):
		body.server_synchronizer.watchers.erase(parent)

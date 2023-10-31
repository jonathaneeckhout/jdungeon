extends Node

class_name AnimationSynchronizerComponent

enum TYPE { LOOP, ACTION }

signal loop_animation_changed(animation: String)
signal action_animation_changed(animation: String)

@export var watcher_synchronizer: WatcherSynchronizerComponent
@export var animation_player: AnimationPlayer

var target_node: Node

var current_loop_animation: String = "Idle"
var get_loop_animation_timer: Timer
var server_buffer: Array[Dictionary] = []


func _physics_process(_delta):
	check_server_buffer()


func _ready():
	target_node = get_parent()

	if not J.is_server():
		# This timer is needed to give the client some time to setup its multiplayer connection
		get_loop_animation_timer = Timer.new()
		get_loop_animation_timer.name = "GetLoopAnimationTimer"
		get_loop_animation_timer.wait_time = 0.1
		get_loop_animation_timer.autostart = false
		get_loop_animation_timer.one_shot = true
		get_loop_animation_timer.timeout.connect(_on_get_loop_animation_timer_timeout)
		add_child(get_loop_animation_timer)

		loop_animation_changed.connect(_on_loop_animation_changed)
		action_animation_changed.connect(_on_action_animation_changed)

		get_loop_animation_timer.start()

		animation_player.animation_finished.connect(_on_animation_finished)


func check_server_buffer():
	for i in range(server_buffer.size() - 1, -1, -1):
		var entry = server_buffer[i]
		if entry["timestamp"] <= J.client.clock:
			match entry["type"]:
				TYPE.LOOP:
					current_loop_animation = entry["animation"]
					loop_animation_changed.emit(entry["animation"])
				TYPE.ACTION:
					action_animation_changed.emit(entry["animation"])
			server_buffer.remove_at(i)


func send_new_loop_animation(animation: String):
	if current_loop_animation != animation:
		current_loop_animation = animation
		sync_loop_animation(current_loop_animation)


func send_new_action_animation(animation: String):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watcher_synchronizer.watchers:
		action_animation.rpc_id(watcher.peer_id, timestamp, animation)

	action_animation_changed.emit(animation)


func sync_loop_animation(animation: String):
	var timestamp: float = Time.get_unix_time_from_system()

	for watcher in watcher_synchronizer.watchers:
		loop_animation.rpc_id(watcher.peer_id, timestamp, animation)

	loop_animation_changed.emit(animation)


func _on_loop_animation_changed(animation: String):
	if animation_player.has_animation(animation):
		animation_player.play(animation)


func _on_action_animation_changed(animation: String):
	animation_player.stop()
	animation_player.play(animation)


func _on_get_loop_animation_timer_timeout():
	get_loop_animation.rpc_id(1)


func _on_animation_finished(_anim_name: String):
	animation_player.play(current_loop_animation)


@rpc("call_remote", "authority", "reliable")
func loop_animation(timestamp: float, animation: String):
	server_buffer.append({"timestamp": timestamp, "type": TYPE.LOOP, "animation": animation})


@rpc("call_remote", "authority", "reliable")
func action_animation(timestamp: float, animation: String):
	server_buffer.append({"timestamp": timestamp, "type": TYPE.ACTION, "animation": animation})


@rpc("call_remote", "any_peer", "reliable") func get_loop_animation():
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	var timestamp: float = Time.get_unix_time_from_system()

	loop_animation.rpc_id(id, timestamp, current_loop_animation)

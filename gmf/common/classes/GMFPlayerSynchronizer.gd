extends Node2D

class_name GMFPlayerSynchronizer

signal moved(target_position: Vector2)
signal interacted(target_name: String)

@export var player: GMFPlayerBody2D
@export var synchronizer: GMFSynchronizer
@export var network_sync_area_size: float = 1024.0

var bodies_in_view: Array[GMFBody2D] = []


func _ready():
	if Gmf.is_server():
		var network_view_area = Area2D.new()
		network_view_area.name = "NetworkViewArea"
		var cs_network_view_area = CollisionShape2D.new()
		cs_network_view_area.name = "NetworkViewAreaCollisionShape2D"
		network_view_area.add_child(cs_network_view_area)

		var cs_network_view_circle = CircleShape2D.new()

		cs_network_view_circle.radius = network_sync_area_size
		cs_network_view_area.shape = cs_network_view_circle

		add_child(network_view_area)

		network_view_area.body_entered.connect(_on_network_view_area_body_entered)
		network_view_area.body_exited.connect(_on_network_view_area_body_exited)

		# Add the player to it's own watchers
		synchronizer.watchers.append(player)


func _on_network_view_area_body_entered(body: GMFBody2D):
	if body == player:
		return

	if not bodies_in_view.has(body):
		match body.entity_type:
			Gmf.ENTITY_TYPE.PLAYER:
				Gmf.rpcs.player.add_other_player.rpc_id(
					player.peer_id, body.username, body.position
				)
			Gmf.ENTITY_TYPE.ENEMY:
				Gmf.rpcs.enemy.add_enemy.rpc_id(
					player.peer_id, body.name, body.enemy_class, body.position
				)

		bodies_in_view.append(body)

	if player not in body.synchronizer.watchers:
		body.synchronizer.watchers.append(player)


func _on_network_view_area_body_exited(body: GMFBody2D):
	if bodies_in_view.has(body):
		match body.entity_type:
			Gmf.ENTITY_TYPE.PLAYER:
				Gmf.rpcs.player.remove_other_player.rpc_id(player.peer_id, body.username)
			Gmf.ENTITY_TYPE.ENEMY:
				Gmf.rpcs.enemy.remove_enemy.rpc_id(player.peer_id, body.name)
		bodies_in_view.erase(body)

	if body.synchronizer.watchers.has(player):
		body.synchronizer.watchers.erase(player)


@rpc("call_remote", "any_peer", "reliable") func move(pos: Vector2):
	if not Gmf.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	if id == player.peer_id:
		moved.emit(pos)


@rpc("call_remote", "any_peer", "reliable") func interact(target: String):
	if not Gmf.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	if id == player.peer_id:
		interacted.emit(target)

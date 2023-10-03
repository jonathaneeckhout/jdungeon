extends Node2D

class_name JPlayerSynchronizer

signal moved(target_position: Vector2)
signal interacted(target_name: String)

@export var player: JPlayerBody2D
@export var synchronizer: JSynchronizer
@export var network_sync_area_size: float = 2048.0

var bodies_in_view: Array[JBody2D] = []
var items_in_view: Array[JItem] = []


func _ready():
	if J.is_server():
		var cs_network_view_circle = CircleShape2D.new()
		cs_network_view_circle.radius = network_sync_area_size

		var cs_body_network_view_area = CollisionShape2D.new()
		cs_body_network_view_area.name = "BodyNetworkViewAreaCollisionShape2D"
		cs_body_network_view_area.shape = cs_network_view_circle

		var body_network_view_area = Area2D.new()
		body_network_view_area.name = "BodyNetworkViewArea"
		body_network_view_area.collision_layer = 0
		body_network_view_area.collision_mask = (
			J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_ENEMIES + J.PHYSICS_LAYER_NPCS
		)
		body_network_view_area.add_child(cs_body_network_view_area)

		add_child(body_network_view_area)

		body_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		body_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)

		var cs_item_network_view_area = CollisionShape2D.new()
		cs_item_network_view_area.name = "ItemNetworkViewAreaCollisionShape2D"
		cs_item_network_view_area.shape = cs_network_view_circle

		var item_network_view_area = Area2D.new()
		item_network_view_area.name = "ItemNetworkViewArea"
		item_network_view_area.collision_layer = 0
		item_network_view_area.collision_mask = J.PHYSICS_LAYER_ITEMS
		item_network_view_area.add_child(cs_item_network_view_area)

		add_child(item_network_view_area)

		item_network_view_area.body_entered.connect(_on_item_network_view_area_body_entered)
		item_network_view_area.body_exited.connect(_on_item_network_view_area_body_exited)

		# Add the player to it's own watchers
		synchronizer.watchers.append(player)


func _on_body_network_view_area_body_entered(body: JBody2D):
	if body == player:
		return

	if not bodies_in_view.has(body):
		match body.entity_type:
			J.ENTITY_TYPE.PLAYER:
				J.rpcs.player.add_other_player.rpc_id(player.peer_id, body.username, body.position)
			J.ENTITY_TYPE.ENEMY:
				J.rpcs.enemy.add_enemy.rpc_id(
					player.peer_id, body.name, body.enemy_class, body.position
				)
			J.ENTITY_TYPE.NPC:
				J.rpcs.npc.add_npc.rpc_id(player.peer_id, body.name, body.npc_class, body.position)
		bodies_in_view.append(body)

	if player not in body.synchronizer.watchers:
		body.synchronizer.watchers.append(player)


func _on_body_network_view_area_body_exited(body: JBody2D):
	if bodies_in_view.has(body):
		if player.peer_id in multiplayer.get_peers():
			match body.entity_type:
				J.ENTITY_TYPE.PLAYER:
					J.rpcs.player.remove_other_player.rpc_id(player.peer_id, body.username)
				J.ENTITY_TYPE.ENEMY:
					J.rpcs.enemy.remove_enemy.rpc_id(player.peer_id, body.name)
				J.ENTITY_TYPE.NPC:
					J.rpcs.npc.remove_npc.rpc_id(player.peer_id, body.name)

		bodies_in_view.erase(body)

	if body.synchronizer.watchers.has(player):
		body.synchronizer.watchers.erase(player)


func _on_item_network_view_area_body_entered(body: JItem):
	if body == player:
		return

	if not items_in_view.has(body):
		J.rpcs.item.add_item.rpc_id(player.peer_id, body.name, body.item_class, body.position)

		items_in_view.append(body)


func _on_item_network_view_area_body_exited(body: JItem):
	if items_in_view.has(body):
		if player.peer_id in multiplayer.get_peers():
			J.rpcs.item.remove_item.rpc_id(player.peer_id, body.name)

		items_in_view.erase(body)


@rpc("call_remote", "any_peer", "reliable") func move(pos: Vector2):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	if id == player.peer_id:
		moved.emit(pos)


@rpc("call_remote", "any_peer", "reliable") func interact(target: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	if id == player.peer_id:
		interacted.emit(target)

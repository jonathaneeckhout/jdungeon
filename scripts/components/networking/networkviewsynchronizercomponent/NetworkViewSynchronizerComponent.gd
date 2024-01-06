extends Node2D

class_name NetworkViewSynchronizerComponent

signal body_entered(body: Node2D)
signal body_exited(body: Node2D)

signal player_added(username: String, pos: Vector2)
signal player_removed(username: String)

signal enemy_added(enemy_name: String, enemy_class: String, pos: Vector2)
signal enemy_removed(enemy_name: String)

signal npc_added(npc_name: String, npc_class: String, pos: Vector2)
signal npc_removed(npc_name: String)

signal item_added(item_uuid: String, item_class: String, pos: Vector2)
signal item_removed(item_uuid: String)

@export var network_sync_area_size: float = 2048.0

var target_node: Node
var bodies_in_view: Array[Node2D] = []

var delay_timer: Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["networkview_synchronizer"] = self

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return

	if G.is_server():
		var cs_network_view_square = RectangleShape2D.new()
		cs_network_view_square.size = Vector2(2048, 1208)

		var cs_body_network_view_area = CollisionShape2D.new()
		cs_body_network_view_area.name = "BodyNetworkViewAreaCollisionShape2D"
		cs_body_network_view_area.shape = cs_network_view_square

		var body_network_view_area = Area2D.new()
		body_network_view_area.name = "BodyNetworkViewArea"
		body_network_view_area.collision_layer = J.PHYSICS_LAYER_NETWORKING
		body_network_view_area.collision_mask = (
			J.PHYSICS_LAYER_PLAYERS
			+ J.PHYSICS_LAYER_ENEMIES
			+ J.PHYSICS_LAYER_NPCS
			+ J.PHYSICS_LAYER_ITEMS
		)
		body_network_view_area.add_child(cs_body_network_view_area)

		add_child(body_network_view_area)

		body_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		body_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)

	elif G.is_own_player(target_node):
		# This timer is needed to give the client some time to setup its multiplayer connection
		delay_timer = Timer.new()
		delay_timer.name = "DelayTimer"
		delay_timer.wait_time = 0.1
		delay_timer.autostart = true
		delay_timer.one_shot = true
		delay_timer.timeout.connect(_on_delay_timer_timeout)
		add_child(delay_timer)


func handle_body(body: Node2D):
	match body.entity_type:
		J.ENTITY_TYPE.PLAYER:
			if body.get("username") == null:
				GodotLogger.info("Body does not contain username")
				return

			G.sync_rpc.networkviewsynchronizer_add_player.rpc_id(
				target_node.peer_id, target_node.name, body.username, body.position
			)
			player_added.emit(body.username, body.position)
		J.ENTITY_TYPE.ENEMY:
			if body.get("enemy_class") == null:
				GodotLogger.info("Body does not contain enemy_class")
				return

			G.sync_rpc.networkviewsynchronizer_add_enemy.rpc_id(
				target_node.peer_id, target_node.name, body.name, body.enemy_class, body.position
			)
			enemy_added.emit(body.name, body.enemy_class, body.position)
		J.ENTITY_TYPE.NPC:
			if body.get("npc_class") == null:
				GodotLogger.info("Body does not contain npc_class")
				return

			G.sync_rpc.networkviewsynchronizer_add_npc.rpc_id(
				target_node.peer_id, target_node.name, body.name, body.npc_class, body.position
			)
			npc_added.emit(body.name, body.npc_class, body.position)

		J.ENTITY_TYPE.ITEM:
			if body.get("item_class") == null:
				GodotLogger.info("Body does not contain item_class")
				return

			G.sync_rpc.networkviewsynchronizer_add_item.rpc_id(
				target_node.peer_id, target_node.name, body.name, body.item_class, body.position
			)
			item_added.emit(body.name, body.item_class, body.position)


func _on_body_network_view_area_body_entered(body: Node2D):
	# Don't handle the player as we hardcoded it to be added to the watchers
	if body == target_node:
		return

	if body.get("entity_type") == null:
		GodotLogger.info("Body does not contain entity_type")
		return

	if body.get("position") == null:
		GodotLogger.info("Body does not contain position")
		return

	if not bodies_in_view.has(body):
		handle_body(body)
		bodies_in_view.append(body)

		body_entered.emit(body)


func _on_body_network_view_area_body_exited(body: Node2D):
	# Make sure that the player is never removed from the watchers
	if body == target_node:
		return

	if body.get("entity_type") == null:
		GodotLogger.info("Body does not contain entity_type")
		return

	if bodies_in_view.has(body):
		if target_node.peer_id in multiplayer.get_peers():
			match body.entity_type:
				J.ENTITY_TYPE.PLAYER:
					if body.get("username") == null:
						GodotLogger.info("Body does not contain username")
						return

					player_removed.emit(body.username)
					G.sync_rpc.networkviewsynchronizer_remove_player.rpc_id(
						target_node.peer_id, target_node.name, body.username
					)
				J.ENTITY_TYPE.ENEMY:
					enemy_removed.emit(body.name)
					G.sync_rpc.networkviewsynchronizer_remove_enemy.rpc_id(
						target_node.peer_id, target_node.name, body.name
					)
				J.ENTITY_TYPE.NPC:
					npc_removed.emit(body.name)
					G.sync_rpc.networkviewsynchronizer_remove_npc.rpc_id(
						target_node.peer_id, target_node.name, body.name
					)
				J.ENTITY_TYPE.ITEM:
					item_removed.emit(body.name)
					G.sync_rpc.networkviewsynchronizer_remove_item.rpc_id(
						target_node.peer_id, target_node.name, body.name
					)

		bodies_in_view.erase(body)

		body_exited.emit(body)


func _on_delay_timer_timeout():
	G.sync_rpc.networkviewsynchronizer_sync_bodies_in_view.rpc_id(1)
	delay_timer.queue_free()


func add_player(username: String, pos: Vector2):
	player_added.emit(username, pos)


func remove_player(username: String):
	player_removed.emit(username)


func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	enemy_added.emit(enemy_name, enemy_class, pos)


func remove_enemy(enemy_name: String):
	enemy_removed.emit(enemy_name)


func add_npc(npc_name: String, npc_class: String, pos: Vector2):
	npc_added.emit(npc_name, npc_class, pos)


func remove_npc(npc_name: String):
	npc_removed.emit(npc_name)


func add_item(item_uuid: String, item_class: String, pos: Vector2):
	item_added.emit(item_uuid, item_class, pos)


func remove_item(item_uuid: String):
	item_removed.emit(item_uuid)


func sync_bodies_in_view():
	for body in bodies_in_view:
		handle_body(body)

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

# Reference to the NetworkViewSynchronizerRPC component for RPC calls.
var _network_view_synchronizer_rpc: NetworkViewSynchronizerRPC = null


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("component_list") != null:
		target_node.component_list["networkview_synchronizer"] = self

	# Get the NetworkViewSynchronizerRPC component.
	_network_view_synchronizer_rpc = (
		target_node
		. multiplayer_connection
		. component_list
		. get_component(NetworkViewSynchronizerRPC.COMPONENT_NAME)
	)

	assert(
		_network_view_synchronizer_rpc != null, "Failed to get NetworkViewSynchronizerRPC component"
	)

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return

	if target_node.multiplayer_connection.is_server():
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
			+ J.PHYSICS_LAYER_PASSABLE_ENTITIES
		)
		body_network_view_area.add_child(cs_body_network_view_area)

		add_child(body_network_view_area)

		body_network_view_area.body_entered.connect(_on_body_network_view_area_body_entered)
		body_network_view_area.body_exited.connect(_on_body_network_view_area_body_exited)

	elif target_node.multiplayer_connection.is_own_player(target_node):
		# Wait until the connection is ready to synchronize stats.
		if not target_node.multiplayer_connection.multiplayer_api.has_multiplayer_peer():
			await target_node.multiplayer_connection.multiplayer_api.connected_to_server

		# Wait an additional frame so others can get set.
		await get_tree().process_frame

		# Some entities take a bit to get added to the tree, do not update them until then.
		if not is_inside_tree():
			await tree_entered

		# Synchronize bodies in view.
		_network_view_synchronizer_rpc.sync_bodies_in_view()
	else:
		queue_free()


func handle_body(body: Node2D):
	match body.entity_type:
		J.ENTITY_TYPE.PLAYER:
			if body.get("username") == null:
				GodotLogger.info("Body does not contain username")
				return

			_network_view_synchronizer_rpc.add_player(
				target_node.peer_id, target_node.name, body.peer_id, body.username, body.position
			)
			player_added.emit(body.username, body.position)
		J.ENTITY_TYPE.ENEMY:
			if body.get("enemy_class") == null:
				GodotLogger.info("Body does not contain enemy_class")
				return

			_network_view_synchronizer_rpc.add_enemy(
				target_node.peer_id, target_node.name, body.name, body.enemy_class, body.position
			)
			enemy_added.emit(body.name, body.enemy_class, body.position)
		J.ENTITY_TYPE.NPC:
			if body.get("npc_class") == null:
				GodotLogger.info("Body does not contain npc_class")
				return

			_network_view_synchronizer_rpc.add_npc(
				target_node.peer_id, target_node.name, body.name, body.npc_class, body.position
			)
			npc_added.emit(body.name, body.npc_class, body.position)

		J.ENTITY_TYPE.ITEM:
			if body.get("item_class") == null:
				GodotLogger.info("Body does not contain item_class")
				return

			_network_view_synchronizer_rpc.add_item(
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
		if target_node.peer_id in target_node.multiplayer_connection.multiplayer_api.get_peers():
			match body.entity_type:
				J.ENTITY_TYPE.PLAYER:
					if body.get("username") == null:
						GodotLogger.info("Body does not contain username")
						return

					player_removed.emit(body.username)
					_network_view_synchronizer_rpc.remove_player(
						target_node.peer_id, target_node.name, body.username
					)
				J.ENTITY_TYPE.ENEMY:
					enemy_removed.emit(body.name)
					_network_view_synchronizer_rpc.remove_enemy(
						target_node.peer_id, target_node.name, body.name
					)
				J.ENTITY_TYPE.NPC:
					npc_removed.emit(body.name)
					_network_view_synchronizer_rpc.remove_npc(
						target_node.peer_id, target_node.name, body.name
					)
				J.ENTITY_TYPE.ITEM:
					item_removed.emit(body.name)
					_network_view_synchronizer_rpc.remove_item(
						target_node.peer_id, target_node.name, body.name
					)

		bodies_in_view.erase(body)

		body_exited.emit(body)


func add_player(peer_id: int, username: String, pos: Vector2):
	player_added.emit(username, pos)

	target_node.multiplayer_connection.map.client_add_player(peer_id, username, pos, false)


func remove_player(username: String):
	player_removed.emit(username)

	target_node.multiplayer_connection.map.client_remove_player(username)


func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	enemy_added.emit(enemy_name, enemy_class, pos)

	target_node.multiplayer_connection.map.client_add_enemy(enemy_name, enemy_class, pos)


func remove_enemy(enemy_name: String):
	enemy_removed.emit(enemy_name)

	target_node.multiplayer_connection.map.client_remove_enemy(enemy_name)


func add_npc(npc_name: String, npc_class: String, pos: Vector2):
	npc_added.emit(npc_name, npc_class, pos)

	target_node.multiplayer_connection.map.client_add_npc(npc_name, npc_class, pos)


func remove_npc(npc_name: String):
	npc_removed.emit(npc_name)

	target_node.multiplayer_connection.map.client_remove_npc(npc_name)


func add_item(item_uuid: String, item_class: String, pos: Vector2):
	item_added.emit(item_uuid, item_class, pos)

	target_node.multiplayer_connection.map.client_add_item(item_uuid, item_class, pos)


func remove_item(item_uuid: String):
	item_removed.emit(item_uuid)

	target_node.multiplayer_connection.map.client_remove_item(item_uuid)


func sync_bodies_in_view():
	for body in bodies_in_view:
		handle_body(body)

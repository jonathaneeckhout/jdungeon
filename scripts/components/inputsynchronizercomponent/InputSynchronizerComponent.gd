extends Node2D

class_name InputSynchronizerComponent

signal primary_action_activated(target_position: Vector2)
signal secondary_action_activated(target_position: Vector2)
signal slot_chosen(slot: int)

#Signals for use with other UI elements
#These MAY not be usable in collision related logic due to not being synchronized with physics
signal hovered_enemy(node: Node2D)
signal hovered_npc(node: Node2D)
signal hovered_item(node: Node2D)
signal hovered_player(node: Node2D)

const CursorGraphics: Dictionary = {
	DEFAULT = preload("res://assets/images/ui/cursors/DefaultCursor.png"),
	ATTACK = preload("res://assets/images/ui/cursors/AttackCursor.png"),
	TALK = preload("res://assets/images/ui/cursors/TalkCursor.png"),
	PICKUP = preload("res://assets/images/ui/cursors/LootCursor.png")
}

##Node that is using this component
var target_node: Node2D:
	set(val):
		target_node = val
		if not J.is_server():
			target_node.draw.connect(draw_controller_cursor)

##If false, cursor_position_global is not updated with mouse movement.
@export var use_mouse: bool = true

var target_current: Node2D
var cursor_position_global: Vector2
var cursor_texture_current: Texture:
	get:
		if cursor_texture_current == null:
			return CursorGraphics.DEFAULT
		else:
			return cursor_texture_current

#Privates
var pointParams := PhysicsPointQueryParameters2D.new()
var lastHoverTarget: Node2D


func _ready():
	target_node = get_parent()

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return

	if J.is_server():
		set_process_input(false)
		set_process(false)

	else:
		#Set parameters for point-casting (can use ShapeParameters instead if necessary)
		pointParams.collide_with_areas = false
		pointParams.collide_with_bodies = true
		pointParams.collision_mask = (
			J.PHYSICS_LAYER_PLAYERS
			+ J.PHYSICS_LAYER_ENEMIES
			+ J.PHYSICS_LAYER_NPCS
			+ J.PHYSICS_LAYER_ITEMS
		)
		set_cursor(CursorGraphics.DEFAULT)

		#Set the cursor back to default if this object is deleted for any reasons
		tree_exiting.connect(set_cursor.bind(CursorGraphics.DEFAULT))


func _physics_process(_delta: float) -> void:
	#Updates what the cursor is pointing at
	update_target(cursor_position_global, false)


func _process(_delta: float) -> void:
	#Updates cursor visuals
	update_cursor()


func draw_controller_cursor():
	target_node.draw_texture(
		cursor_texture_current, cursor_position_global - target_node.global_position
	)


func _input(event: InputEvent):
	use_mouse = not (event is InputEventJoypadButton or event is InputEventJoypadMotion)

	# Don't do anything when above ui
	if JUI.above_ui:
		return

	if use_mouse:
		cursor_position_global = get_global_mouse_position()
	else:
		var aimVector2: Vector2 = Input.get_vector(
			"j_aim_left", "j_aim_right", "j_aim_up", "j_aim_down"
		)
		cursor_position_global = target_node.global_position + aimVector2

	if event.is_action_pressed("j_left_click"):
		handle_primary_click(cursor_position_global)
	elif event.is_action_pressed("j_right_click"):
		handle_secondary_click(cursor_position_global)

	elif event.is_action_pressed("j_slot1"):
		handle_slot_change(1)
	elif event.is_action_pressed("j_slot2"):
		handle_slot_change(2)
	elif event.is_action_pressed("j_slot3"):
		handle_slot_change(3)
	elif event.is_action_pressed("j_slot4"):
		handle_slot_change(4)
	elif event.is_action_pressed("j_slot5"):
		handle_slot_change(5)


func update_cursor():
	#If it isn't touching something, set it to default
	if target_current == null:
		cursor_texture_current = CursorGraphics.DEFAULT

	#Otherwise set it to the appropiate cursor
	else:
		match target_current.get("entity_type"):
			J.ENTITY_TYPE.NPC:
				cursor_texture_current = CursorGraphics.TALK
				hovered_npc.emit(target_current)

			J.ENTITY_TYPE.ITEM:
				cursor_texture_current = CursorGraphics.PICKUP
				hovered_item.emit(target_current)

			J.ENTITY_TYPE.ENEMY:
				cursor_texture_current = CursorGraphics.ATTACK
				hovered_enemy.emit(target_current)

			J.ENTITY_TYPE.PLAYER:
				cursor_texture_current = CursorGraphics.DEFAULT
				hovered_player.emit(target_current)

	if use_mouse:
		#Set the cursor
		set_cursor(cursor_texture_current)

	lastHoverTarget = target_current


#Movement order and other non-targted actions
func handle_primary_click(clickGlobalPos: Vector2):
	primary_action.rpc_id(1, clickGlobalPos)
	primary_action_activated.emit(clickGlobalPos)


#Actions
func handle_secondary_click(clickGlobalPos: Vector2):
	#Ensure there is a target
	if target_current:
		#Ignore if it was self
		secondary_action.rpc_id(1, clickGlobalPos)
		secondary_action_activated.emit(clickGlobalPos)
	pass


func handle_slot_change(slot: int):
	slot_chosen.emit(slot)


#Updates currentTarget based on a given point.
func update_target(atGlobalPoint: Vector2, includeUser: bool = false):
	#Do not proceed if outside the tree
	if not is_inside_tree():
		return

	if JUI.above_ui:
		target_current = null
		return

	#Get the world's space
	var directSpace: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	#Set the target position
	pointParams.position = atGlobalPoint

	#Unless specified, do not check for the user of this component.
	if not includeUser and target_node is CollisionObject2D:
		pointParams.exclude.append(target_node.get_rid())

	#Update collisions from point
	var collisions: Array[Dictionary] = directSpace.intersect_point(pointParams)

	if collisions.is_empty():
		target_current = null
	else:
		target_current = collisions.front().get("collider")


func set_cursor(graphic: Texture):
	DisplayServer.cursor_set_custom_image(graphic)


@rpc("call_remote", "any_peer", "reliable") func primary_action(pos: Vector2):
	if not J.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		primary_action_activated.emit(pos)


@rpc("call_remote", "any_peer", "reliable") func secondary_action(pos: Vector2):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		secondary_action_activated.emit(pos)


@rpc("call_remote", "any_peer", "reliable") func slot_choice(slot: int):
	if not J.is_server():
		return

	var id: int = multiplayer.get_remote_sender_id()

	if not J.server.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		slot_chosen.emit(slot)

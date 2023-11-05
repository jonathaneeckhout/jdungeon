extends Node2D

class_name InputSynchronizerComponent

signal primary_action_activated(target_position: Vector2)
signal secondary_action_activated(target_position: String)

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

var pointParams := PhysicsPointQueryParameters2D.new()
var targetCurrent: Node2D
var lastHoverTarget: Node2D

#Node that is using this component
var target_node: Node


func _ready():
	target_node = get_parent()

	if target_node.get("peer_id") == null:
		J.logger.error("target_node does not have the peer_id variable")
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


func _input(event: InputEvent):
	# Don't do anything when above ui
	if JUI.above_ui:
		return

	if event.is_action_pressed("j_left_click"):
		handle_primary_click(get_global_mouse_position())
	elif event.is_action_pressed("j_right_click"):
		handle_secondary_click(get_global_mouse_position())


func _physics_process(delta: float) -> void:
	#Updates what the cursor is pointing at
	update_target(get_global_mouse_position(), false)

func _process(_delta: float) -> void:
	#Updates cursor visuals
	update_cursor()
	
func update_cursor():
	#Initialize empty variable
	var cursorToUse: Texture

	#If it isn't touching something, set it to default
	if targetCurrent == null:
		cursorToUse = CursorGraphics.DEFAULT

	#Otherwise set it to the appropiate cursor
	else:
		match targetCurrent.get("entity_type"):
			J.ENTITY_TYPE.NPC:
				cursorToUse = CursorGraphics.TALK
				hovered_npc.emit(targetCurrent)

			J.ENTITY_TYPE.ITEM:
				cursorToUse = CursorGraphics.PICKUP
				hovered_item.emit(targetCurrent)

			J.ENTITY_TYPE.ENEMY:
				cursorToUse = CursorGraphics.ATTACK
				hovered_enemy.emit(targetCurrent)

			J.ENTITY_TYPE.PLAYER:
				cursorToUse = CursorGraphics.DEFAULT
				hovered_player.emit(targetCurrent)

	#Set the cursor
	set_cursor(cursorToUse)
	lastHoverTarget = targetCurrent

#Movement order and other non-targted actions
func handle_primary_click(clickGlobalPos: Vector2):
	primary_action.rpc_id(1, pointParams.position)
	primary_action_activated.emit(pointParams.position)

#Actions
func handle_secondary_click(clickGlobalPos: Vector2):
	if targetCurrent != null:
		#Ignore if it was self
		secondary_action.rpc_id(1, targetCurrent.get_name())
		secondary_action_activated.emit(clickGlobalPos)
	pass

#Updates currentTarget based on a given point.
func update_target(atGlobalPoint: Vector2, includeUser: bool = false):
	#Do not proceed if outside the tree
	if not is_inside_tree():
		return

	if JUI.above_ui:
		targetCurrent = null
		return

	#Get the world's space
	var directSpace: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	#Set the target position
	pointParams.position = atGlobalPoint
	
	#Unless specified, do not check for the user of this component.
	if not includeUser and target_node is CollisionObject2D:
		pointParams.exclude.append( target_node.get_rid() )
	
	#Update collisions from point
	var collisions: Array[Dictionary] = directSpace.intersect_point(pointParams)

	if collisions.is_empty():
		targetCurrent = null
	else:
		targetCurrent = collisions.front().get("collider")


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


@rpc("call_remote", "any_peer", "reliable") func secondary_action(target: String):
	if not J.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not J.server.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		secondary_action_activated.emit(target)

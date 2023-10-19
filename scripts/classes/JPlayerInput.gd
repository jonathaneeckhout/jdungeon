extends Node2D

class_name JPlayerInput

signal move(target_position: Vector2)
signal interact(target_name: String)

#Signals for use with other UI elements
#These MAY not be usable in collision related logic due to not being synchronized with physics
signal hovered_enemy(node: Node2D)
signal hovered_npc(node: Node2D)
signal hovered_item(node: Node2D)
signal hovered_player(node: Node2D)

const CursorGraphics: Dictionary = {
	DEFAULT = preload("res://assets/ui/cursors/DefaultCursor.png"),
	ATTACK = preload("res://assets/ui/cursors/AttackCursor.png"),
	TALK = preload("res://assets/ui/cursors/TalkCursor.png"),
	PICKUP = preload("res://assets/ui/cursors/LootCursor.png")
}

var pointParams := PhysicsPointQueryParameters2D.new()
var targetCurrent: Node2D
var lastHoverTarget: Node2D


func _ready():
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

	if event.is_action_pressed("j_right_click"):
		_handle_right_click(get_global_mouse_position())


func _process(_delta: float) -> void:
	#This update is frame based as to update the cursor visually on the client
	update_target(get_global_mouse_position())
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


func _handle_right_click(clickGlobalPos: Vector2):
	#Fetch targets under the cursor
	update_target(clickGlobalPos)

	#Either move or interact depending on wether something was there or not.
	if targetCurrent == null:
		move.emit(pointParams.position)

	else:
		#Ignore if it was self
		if targetCurrent != self:
			interact.emit(targetCurrent.get_name())


func update_target(atGlobalPoint: Vector2):
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

	#Update collisions from point
	var collisions: Array[Dictionary] = directSpace.intersect_point(pointParams)

	if collisions.is_empty():
		targetCurrent = null
	else:
		targetCurrent = collisions.front().get("collider")


func set_cursor(graphic: Texture):
	DisplayServer.cursor_set_custom_image(graphic)

extends Node

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

@export var player_synchronizer: PlayerSynchronizer

var target_node: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return

	if (
		target_node.multiplayer_connection.is_server()
		or not target_node.multiplayer_connection.is_own_player(target_node)
	):
		queue_free()

	set_cursor(CursorGraphics.DEFAULT)


func _process(_delta):
	#Initialize empty variable
	var cursorToUse: Texture

	#If it isn't touching something, set it to default
	if player_synchronizer.current_target == null:
		cursorToUse = CursorGraphics.DEFAULT

	#Otherwise set it to the appropiate cursor
	else:
		match player_synchronizer.current_target.get("entity_type"):
			J.ENTITY_TYPE.NPC:
				cursorToUse = CursorGraphics.TALK
				hovered_npc.emit(player_synchronizer.current_target)

			J.ENTITY_TYPE.ITEM:
				cursorToUse = CursorGraphics.PICKUP
				hovered_item.emit(player_synchronizer.current_target)

			J.ENTITY_TYPE.ENEMY:
				cursorToUse = CursorGraphics.ATTACK
				hovered_enemy.emit(player_synchronizer.current_target)

			J.ENTITY_TYPE.PLAYER:
				cursorToUse = CursorGraphics.DEFAULT
				hovered_player.emit(player_synchronizer.current_target)

	set_cursor(cursorToUse)


func set_cursor(graphic: Texture):
	DisplayServer.cursor_set_custom_image(graphic)

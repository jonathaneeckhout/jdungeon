extends Node2D

class_name Portal

@export var destination_server: String = ""
@export var destination_portal: String = ""

@onready var portal_area: Area2D = $PortalArea2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if G.is_server():
		portal_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D):
	if body.get("entity_type") == null:
		return

	if body.entity_type != J.ENTITY_TYPE.PLAYER:
		return

	GodotLogger.info("Player=[%s] entered portal=[%s]" % [body.name, name])

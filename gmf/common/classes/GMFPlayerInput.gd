extends Node2D

class_name GMFPlayerInput

signal move(target_position: Vector2)
signal interact(target_name: String)

var mouse_area: Area2D


func _ready():
	if GMF.is_server():
		set_process_input(false)
	else:
		mouse_area = Area2D.new()
		mouse_area.name = "MouseArea"
		mouse_area.collision_layer = 0
		mouse_area.collision_mask = (
			GMF.PHYSICS_LAYER_PLAYERS
			+ GMF.PHYSICS_LAYER_ENEMIES
			+ GMF.PHYSICS_LAYER_NPCS
			+ GMF.PHYSICS_LAYER_ITEMS
		)
		var cs_mouse_area = CollisionShape2D.new()
		cs_mouse_area.name = "MouseAreaCollisionShape2D"
		mouse_area.add_child(cs_mouse_area)

		var cs_mouse_area_circle = CircleShape2D.new()

		cs_mouse_area_circle.radius = 1.0
		cs_mouse_area.shape = cs_mouse_area_circle

		add_child(mouse_area)


func _input(event):
	if event.is_action_pressed("gmf_right_click"):
		_handle_right_click()


func _handle_right_click():
	mouse_area.set_global_position(get_global_mouse_position())

	#The following awaits ensure that the collision cycle has occurred before calling
	#the get_overlapping_bodies function
	await get_tree().physics_frame
	await get_tree().physics_frame

	#Get the bodies under the mouse area
	var bodies = mouse_area.get_overlapping_bodies()

	#Move if nothing is under the mouse area
	if bodies.is_empty():
		move.emit(get_global_mouse_position())
	else:
		#TODO: not sure if this needs to be improved, just take the first
		var target = bodies[0]
		if target != self:
			interact.emit(target.name)

extends JPlayerBody2D

@onready var animation_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale

@onready var equipment_sprites = {
	"Head": $Sprites/Head,
	"Body": $Sprites/Body,
	"Legs": [$Sprites/RightLeg, $Sprites/LeftLeg],
	"Arms": [$Sprites/RightArm, $Sprites/LeftArm],
	"RightHand": $Sprites/RightHand,
	"LeftHand": $Sprites/LeftHand
}


func _ready():
	super()

	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	synchronizer.attacked.connect(_on_attacked)
	synchronizer.healed.connect(_on_healed)

	animation_player.play(loop_animation)

	$JInterface.display_name = username

	if J.is_server() or peer_id != multiplayer.get_unique_id():
		set_process_input(false)
		$Camera2D.queue_free()
	else:
		$Camera2D/UILayer/GUI/Inventory.register_signals()
		$Camera2D/UILayer/GUI/Equipment.register_signals()

		equipment.item_added.connect(_on_item_equiped)
		equipment.item_removed.connect(_on_item_unequiped)


func _physics_process(_delta):
	if loop_animation == "Move":
		update_face_direction(velocity.x)


func update_face_direction(direction: float):
	if direction < 0:
		skeleton.scale = original_scale
		return
	if direction > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)
		return


func focus_camera():
	$Camera2D.make_current()


func _on_loop_animation_changed(animation: String, direction: Vector2):
	loop_animation = animation

	animation_player.play(loop_animation)

	update_face_direction(direction.x)


func _on_attacked(target: String, _damage: int):
	animation_player.stop()
	animation_player.play("Attack")

	var enemy: JEnemyBody2D = J.world.enemies.get_node(target)
	if enemy == null:
		return

	update_face_direction(position.direction_to(enemy.position).x)


func _on_healed(_from: String, _hp: int, _max_hp: int, healing: int):
	print("Healed %d" % healing)


func equipment_changed():
	for child in equipment_sprites["RightHand"].get_children():
		child.queue_free()

	if equipment.items["RightHand"]:
		var item = equipment.items["RightHand"].duplicate()
		item.scale = item.scale / skeleton.scale
		item.get_node("Sprite").hide()
		item.get_node("EquipmentSprite").show()
		equipment_sprites["RightHand"].add_child(item)

	for child in equipment_sprites["LeftHand"].get_children():
		child.queue_free()


func _on_item_equiped(_item_uuid: String, _item_class: String):
	equipment_changed()


func _on_item_unequiped(_item_uuid: String):
	equipment_changed()

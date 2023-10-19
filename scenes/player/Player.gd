extends JPlayerBody2D

@onready var animation_player = $AnimationPlayer

@onready var floating_text_scene = preload("res://scenes/templates/JFloatingText/JFloatingText.tscn")
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

@onready var original_sprite_textures = {
	"Head": $Sprites/Head.texture,
	"Body": $Sprites/Body.texture,
	"Legs": [$Sprites/RightLeg.texture, $Sprites/LeftLeg.texture],
	"Arms": [$Sprites/RightArm.texture, $Sprites/LeftArm.texture],
	"RightHand": $Sprites/RightHand.texture,
	"LeftHand": $Sprites/LeftHand.texture
}


func _ready():
	stats.update_all_stats()
	stats.hp_reset()
	
	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	synchronizer.attacked.connect(_on_attacked)
	synchronizer.healed.connect(_on_healed)
	synchronizer.got_hurt.connect(_on_got_hurt)

	equipment.item_added.connect(_on_item_equiped)
	equipment.item_removed.connect(_on_item_unequiped)

	animation_player.play(loop_animation)

	$JInterface.display_name = username

	if J.is_server() or peer_id != multiplayer.get_unique_id():
		set_process_input(false)
		$Camera2D.queue_free()
		# Make sure to load equipment on server side
		equipment_changed()
	else:
		$Camera2D/UILayer/GUI/Inventory.register_signals()
		$Camera2D/UILayer/GUI/Equipment.register_signals()

		# Get the current stats of the player
		stats.synced.connect(_on_stats_synced)
		stats.get_sync.rpc_id(1, peer_id)

		# Get the current equipment of the player:
		equipment.loaded.connect(_on_equipment_loaded)
		equipment.sync_equipment.rpc_id(1)

		synchronizer.experience_gained.connect(_on_experience_gained)
		synchronizer.level_gained.connect(_on_level_gained)

		synchronizer.died.connect(_on_died)
		synchronizer.respawned.connect(_on_respawned)


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


func _on_got_hurt(_from: String, hp: int, hp_max: int, damage: int):
	$JInterface.update_hp_bar(hp, hp_max)
	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)



func _on_healed(_from: String, _hp: int, _hp_max: int, healing: int):
	print("Healed %d" % healing)



func load_equipment_single_sprite(equipment_slot: String):
	for child in equipment_sprites[equipment_slot].get_children():
		child.queue_free()

	if equipment.items[equipment_slot]:
		equipment_sprites[equipment_slot].texture = null

		var item = equipment.items[equipment_slot].duplicate()
		item.scale = item.scale / original_scale
		item.get_node("Sprite").hide()
		item.get_node("EquipmentSprite").show()
		equipment_sprites[equipment_slot].add_child(item)
	else:
		equipment_sprites[equipment_slot].texture = original_sprite_textures[equipment_slot]


func load_equipment_double_sprites(equipment_slot: String):
	for equipment_sprite in equipment_sprites[equipment_slot]:
		for child in equipment_sprite.get_children():
			child.queue_free()

	if equipment.items[equipment_slot]:
		equipment_sprites[equipment_slot][0].texture = null
		equipment_sprites[equipment_slot][1].texture = null

		var item_right = equipment.items[equipment_slot].duplicate()
		item_right.scale = item_right.scale / original_scale
		item_right.get_node("Sprite").hide()
		item_right.get_node("EquipmentSpriteRight").show()
		equipment_sprites[equipment_slot][0].add_child(item_right)

		var item_left = equipment.items[equipment_slot].duplicate()
		item_left.scale = item_left.scale / original_scale
		item_left.get_node("Sprite").hide()
		item_left.get_node("EquipmentSpriteLeft").show()
		equipment_sprites[equipment_slot][1].add_child(item_left)

	else:
		equipment_sprites[equipment_slot][0].texture = original_sprite_textures[equipment_slot][0]
		equipment_sprites[equipment_slot][1].texture = original_sprite_textures[equipment_slot][1]


func equipment_changed():
	load_equipment_single_sprite("Head")
	load_equipment_single_sprite("Body")
	load_equipment_double_sprites("Arms")
	load_equipment_double_sprites("Legs")
	load_equipment_single_sprite("RightHand")
	load_equipment_single_sprite("LeftHand")


func update_exp_bar():
	var progress: float = float(stats.stat_get(JStats.Keys.EXPERIENCE)) / stats.level_get_experience_to_next()

	$Camera2D/UILayer/GUI/ExpBar.value = progress


func update_level():
	$JInterface.display_name = username + " (%d)" % stats.level


func _on_equipment_loaded():
	equipment_changed()


func _on_item_equiped(_item_uuid: String, _item_class: String):
	equipment_changed()


func _on_item_unequiped(_item_uuid: String):
	equipment_changed()


func _on_stats_synced():
	$JInterface.update_hp_bar(stats.stat_get(JStats.Keys.HP), stats.stat_get(JStats.Keys.HP_MAX))
	update_exp_bar()
	update_level()


func _on_experience_gained(_from: String, _current_exp: int, amount: int):
	var text = floating_text_scene.instantiate()
	text.amount = amount
	text.type = text.TYPES.EXPERIENCE
	add_child(text)

	update_exp_bar()


func _on_level_gained(_current_level: int, _amount: int, _experience_needed: int):
	update_level()


func _on_died():
	$Camera2D/UILayer/GUI/DeathPopup.show_popup()
	animation_player.stop()
	animation_player.play("Die")


func _on_respawned():
	$Camera2D/UILayer/GUI/DeathPopup.hide()
	# Fetch your new hp
	stats.get_sync.rpc_id(1, peer_id)
	loop_animation = "Idle"
	animation_player.play(loop_animation)

extends GMFBody2D

class_name GMFEnemyBody2D

@export var enemy_class: String = "":
	set(new_class):
		enemy_class = new_class
		Gmf.register_enemy_scene(enemy_class, scene_file_path)

		if interface:
			interface.set_new_name(enemy_class)


func _init():
	entity_type = Gmf.ENTITY_TYPE.ENEMY


func _ready():
	super()

	collision_layer += Gmf.PHYSICS_LAYER_ENEMIES

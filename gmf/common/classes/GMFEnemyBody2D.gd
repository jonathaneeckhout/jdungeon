extends GMFBody2D

class_name GMFEnemyBody2D


func _init():
	entity_type = Gmf.ENTITY_TYPE.ENEMY


var enemy_class: String = "":
	set(new_class):
		enemy_class = new_class
		Gmf.register_enemy_scene(enemy_class, scene_file_path)


func _ready():
	super()

	collision_layer += Gmf.PHYSICS_LAYER_ENEMIES

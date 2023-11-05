extends Resource
class_name SkillComponentResource

@export var displayed_name: String = "Skidadle Skidoodle" #Failsafe name
@export var energy_usage: int = 0
@export var hitbox_shape: PackedVector2Array
@export var hit_range: float


func effect(targets: Array[Node]):
	for target in targets:
		_effect(target)

func target_filter(targets: Array[Node])->bool:
	for target in targets:
		if not _target_filter(target):
			return false
	return true

func _target_filter(target: Node)->bool:
	return true

func _effect(target: Node):
	pass
	

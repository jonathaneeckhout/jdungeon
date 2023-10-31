extends Control

class_name FloatingText

enum TYPES { DAMAGE, HEALING, EXPERIENCE }

var amount: int = 0
var type = TYPES.DAMAGE


func _ready():
	position += Vector2(0, -128)

	match type:
		TYPES.DAMAGE:
			$Label.text = "- " + str(amount)
		TYPES.HEALING:
			$Label.text = "+ " + str(amount)
		TYPES.EXPERIENCE:
			$Label.text = "+ " + str(amount) + "exp"

	var tween = create_tween().set_parallel(true)
	tween.tween_property($Label, "position", Vector2(128, -64), 1.0)
	tween.tween_property($Label, "scale", Vector2(2.0, 2.0), 0.2)
	tween.chain().tween_interval(0.1)
	tween.chain().tween_property($Label, "scale", Vector2(1.0, 1.0), 0.7)
	tween.tween_callback(self.queue_free)

extends ProgressBar

@export var stats: StatsSynchronizerComponent


# Called when the node enters the scene tree for the first time.
func _ready():
	stats.stats_changed.connect(_on_stats_changed)
	renew_values()


func renew_values():
	if stats.experience_needed <= 0:
		return

	var progress: float = float(stats.experience) / stats.experience_needed * 100
	if progress >= 100:
		progress = 0

	value = progress


func _on_stats_changed(type: StatsSynchronizerComponent.TYPE):
	match type:
		StatsSynchronizerComponent.TYPE.EXPERIENCE:
			renew_values()
		StatsSynchronizerComponent.TYPE.EXPERIENCE_NEEDED:
			renew_values()

extends Panel

signal respawn_player
var respawn_time: int = 10
var counter = respawn_time

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func show_popup():
	self.show()
	$Timer.set_wait_time(respawn_time)
	$Timer.start()

func _on_timer_timeout():
	emit_signal("respawn_player")
	self.hide()
	
func _process(_delta):
	if !self.visible:
		return
		
	if counter > 0:
		counter -= 1
		$CountdownLabel.text = "%d:%02d" % [floor($Timer.time_left / 60), int($Timer.time_left) % 60]
	else:
		counter = respawn_time

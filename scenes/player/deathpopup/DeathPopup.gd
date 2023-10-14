extends Control

signal respawn_player
var respawn_time: float = J.PLAYER_RESPAWN_TIME
var counter = respawn_time
var timer: Timer
@onready var count_down_label: Label = $Panel/CountdownLabel


func _ready():
	timer = Timer.new()
	timer.name = "Timer"
	timer.autostart = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


func show_popup():
	self.show()
	timer.start(respawn_time)


func _on_timer_timeout():
	emit_signal("respawn_player")
	self.hide()


func _process(_delta):
	if !self.visible:
		return

	if counter > 0:
		counter -= 1
		count_down_label.text = (
			"%d:%02d" % [floor(timer.time_left / 60), int(timer.time_left) % 60]
		)
	else:
		counter = respawn_time

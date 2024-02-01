extends Control

var respawn_time: float = J.PLAYER_RESPAWN_TIME

var timer: Timer
var countdown_timer: Timer

@onready var count_down_label: Label = $Panel/CountdownLabel


func _ready():
	timer = Timer.new()
	timer.name = "Timer"
	timer.autostart = false
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

	countdown_timer = Timer.new()
	countdown_timer.name = "CountDownTimer"
	countdown_timer.autostart = false
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	add_child(countdown_timer)


func show_popup():
	self.show()
	timer.start(respawn_time)
	countdown_timer.start(0.1)
	update_counter()


func update_counter():
	count_down_label.text = ("%d:%02d" % [floor(timer.time_left / 60), int(timer.time_left) % 60])


func _on_timer_timeout():
	countdown_timer.stop()
	self.hide()


func _on_countdown_timer_timeout():
	update_counter()

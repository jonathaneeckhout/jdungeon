extends Control

@onready var quit_button := $Panel/VBoxContainer/MarginContainer/QuitButton

@onready var panel = $Panel

func _ready():
	quit_button.pressed.connect(_on_quit_button_pressed)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		if self.is_visible_in_tree():
			self.hide()
			JUI.above_ui=false
		else :
			self.show()
			JUI.above_ui=true
	
	if (event is InputEventMouseButton) and event.pressed:
		var event_local = make_input_local(event)
		if !Rect2(Vector2(panel.position.x,panel.position.y),Vector2(panel.size.x,panel.size.y)).has_point(event_local.position):
			self.hide()



func  _on_quit_button_pressed():
	var quit_game_callable :Callable = Callable(self,"quit_game")
	JUI.confirmationbox("Are you sure you want to quit the game?",self,"Quit Game?",quit_game_callable)

func quit_game():
	get_tree().quit()

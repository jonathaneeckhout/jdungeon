extends Control

@onready var quit_button := $Panel/VBoxContainer/MarginContainer/QuitButton

func _ready():
	quit_button.pressed.connect(_on_quit_button_pressed)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		if self.is_visible_in_tree():
			self.hide()
		else :
			self.show()

func  _on_quit_button_pressed():
	var quit_game_callable :Callable = Callable(self,"quit_game")
	JUI.confirmationbox("Are you sure you want to quit the game?",self,"Quit Game?",quit_game_callable)

func quit_game():
	get_tree().quit()

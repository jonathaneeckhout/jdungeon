extends GMFWorld


func _ready():
	super()

	# To avoid duplicates, remove these placeholders, they are only used in the editor
	$Entities.queue_free()

	if not Gmf.is_server():
		var client = load("res://game/scenes/world/Client.gd").new()
		client.name = "Client"
		add_child(client)
		$UI/LoginPanel.show()

extends JWorld


func _ready():
	super()

	# To avoid duplicates, remove these placeholders, they are only used in the editor
	$Entities.queue_free()

	if not J.is_server():
		var client = load("res://scenes/world/Client.gd").new()
		client.name = "Client"
		add_child(client)
		$UI/LoginPanel.show()

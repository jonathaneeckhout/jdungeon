extends JWorld


func _ready():
	super()

	# To avoid duplicates, remove these placeholders, they are only used in the editor
	$Entities.queue_free()

	if not J.is_server():
		var client = load("res://scenes/world/clientfsm.gd").new()
		client.name = "ClientFSM"
		add_child(client)
		$UI/LoginPanel.show()

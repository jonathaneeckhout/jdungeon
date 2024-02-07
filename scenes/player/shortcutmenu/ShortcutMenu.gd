extends PanelContainer

@export var game_menu: GameMenu = null
@export var stats_display: StatsDisplay = null
@export var equipment: Equipment = null
@export var inventory: Inventory = null


# Called when the node enters the scene tree for the first time.
func _ready():
	%GameMenuButton.pressed.connect(game_menu.show)
	%StatsButton.pressed.connect(_on_stats_pressed)
	%EquipmentButton.pressed.connect(_on_equipment_pressed)
	%BagButton.pressed.connect(_on_bag_pressed)


func _on_stats_pressed():
	stats_display.visible = !stats_display.visible


func _on_equipment_pressed():
	equipment.visible = !equipment.visible


func _on_bag_pressed():
	inventory.visible = !inventory.visible

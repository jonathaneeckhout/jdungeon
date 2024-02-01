extends Node2D
class_name Tooltip

enum PopupDirections {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
const TAG_START: String = '[url="{0}"]'
const TAG_END: String = "[/url]"

const INVISIBLE_RECT: Rect2 = Rect2()

signal visibility_update_required

@export_category("Settings")
@export var allow_sub_tooltips: bool = true
@export var pin_action: String = "ui_accept"

@export_category("Appereance")
@export var auto_choose_direction: bool = true

@export var popup_dir: PopupDirections = PopupDirections.UP

@export var text: String = "Placeholder":
	set(value):
		if label:
			text = value
			label.text = text
			if not sub:
				visibility_update_required.emit()

@export var width: float = 120

@export
var sub_tooltips_to_display: Dictionary = {"help": "Every 'help' word will invoke this tooltip."}

var target_hovered: bool:
	set(val):
		target_hovered = val
		visibility_update_required.emit()

var pinned: bool = false:
	set(val):
		pinned = val
		visibility_update_required.emit()

#var keyword_rect_dict: Dictionary
var panel := Panel.new()
var label := RichTextLabel.new()

var sub_tooltip: Tooltip
var sub: bool = false


func _init() -> void:
	hide()
	visibility_update_required.connect(on_visibility_update_required)


func _ready() -> void:
	add_child(panel)
	panel.add_child(label)
	panel.clip_contents = false
	panel.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.meta_hover_started.connect(on_label_meta_hover_change.bind(true))
	label.meta_hover_ended.connect(on_label_meta_hover_change.bind(false))
	label.bbcode_enabled = true
	label.clip_contents = false
	label.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED

	if sub:
		assert(get_parent() is RichTextLabel)
		assert(get_parent().get_parent().get_parent() is Tooltip)

		set_name("SubTooltip")
		sub_tooltips_to_display.clear()
		allow_sub_tooltips = false
		auto_choose_direction = false
		popup_dir = get_parent().get_parent().get_parent().popup_dir
		update_size()
		update_input_processing()
		return

	sub_tooltip = add_to_control(label, true)

	pinned = pinned
	connect_target_signals(get_target())

	visibility_update_required.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(pin_action) and not target_hovered:
		pinned = false


func connect_target_signals(target: Control):
	if not target is Control:
		return

	target.gui_input.connect(on_target_gui_input)
	target.mouse_entered.connect(on_mouse_hover_changed.bind(true))
	target.mouse_exited.connect(on_mouse_hover_changed.bind(false))


func get_target() -> Control:
	return get_parent() if get_parent() is Control else null


func get_auto_direction() -> PopupDirections:
	var viewport_rect: Rect2 = get_viewport_rect()

	var direction_dist_dict: Dictionary = {
		PopupDirections.UP:
		global_position.distance_to(
			Vector2(viewport_rect.position.x + viewport_rect.size.x / 2, viewport_rect.position.y)
		),
		PopupDirections.DOWN:
		global_position.distance_to(
			Vector2(viewport_rect.position.x + viewport_rect.size.x / 2, viewport_rect.end.y)
		),
		PopupDirections.LEFT:
		global_position.distance_to(
			Vector2(viewport_rect.position.x, viewport_rect.position.y + viewport_rect.size.y / 2)
		),
		PopupDirections.RIGHT:
		global_position.distance_to(
			Vector2(viewport_rect.end.x, viewport_rect.position.y + viewport_rect.size.y / 2)
		),
	}

	var closest_dir_to_border: PopupDirections
	var smallest_value: float = INF

	for direction: PopupDirections in direction_dist_dict:
		var value: float = direction_dist_dict[direction]
		if value < smallest_value:
			closest_dir_to_border = direction
			smallest_value = value

	match closest_dir_to_border:
		PopupDirections.UP:
			return PopupDirections.DOWN
		PopupDirections.DOWN:
			return PopupDirections.UP
		PopupDirections.LEFT:
			return PopupDirections.RIGHT
		PopupDirections.RIGHT:
			return PopupDirections.LEFT
		_:
			push_error("Could not determine a direction automatically, returning the current one.")
			return popup_dir


func adjust_position(direction: PopupDirections):
	var target_size: Vector2 = get_target().size

	match direction:
		PopupDirections.UP:
			position = Vector2(target_size.x / 2, 0)
			panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

		PopupDirections.DOWN:
			position = Vector2(target_size.x / 2, target_size.y)
			panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			panel.grow_vertical = Control.GROW_DIRECTION_END

		PopupDirections.LEFT:
			position = Vector2(0, target_size.y / 2)
			panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			panel.grow_vertical = Control.GROW_DIRECTION_BOTH

		PopupDirections.RIGHT:
			position = Vector2(target_size.x, target_size.y / 2)
			panel.grow_horizontal = Control.GROW_DIRECTION_END
			panel.grow_vertical = Control.GROW_DIRECTION_BOTH

		_:
			push_error("Invalid direction." + str(direction))


func update_size():
	var minimum_size: Vector2 = Vector2(width, label.get_content_height())
	panel.custom_minimum_size = minimum_size
	label.custom_minimum_size = minimum_size


func update_input_processing():
	set_process_input.call_deferred(pinned)
	if allow_sub_tooltips and not sub:
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pass


func update_rich_text():
	var enriched_text: String
	#var word_ranges: Array[Vector2i]

	var words: PackedStringArray = text.split(" ")
	var resulting_words: PackedStringArray = words.duplicate()
	var index: int = 0
	for word: String in words:
		var tooltip_text: String = sub_tooltips_to_display.get(word, "")

		if tooltip_text == "":
			index += 1
			continue

		word = word.insert(0, TAG_START.format([tooltip_text]))
		word = word.insert(word.length(), TAG_END)

		resulting_words[index] = word

		index += 1

	enriched_text = " ".join(resulting_words)

	label.parse_bbcode(enriched_text)


#func update_keyword_rects():
#var to_fill: Array[Rect2]
#
#for keyword: String in sub_tooltips_to_display.keys():
#var last_find_index: int = 0
#while last_find_index != -1:
#last_find_index = label.text.find(keyword, last_find_index + 1)
#
#if last_find_index == -1:
#continue
#
#var text_rect: Rect2 = calculate_word_position(label, last_find_index, last_find_index + keyword.length())
#
#to_fill.append(text_rect)
#
#keyword_rect_dict[keyword] = to_fill
#print(keyword_rect_dict)


func on_target_gui_input(event: InputEvent):
	if event.is_action_pressed(pin_action):
		pinned = !pinned


func on_mouse_hover_changed(inside: bool):
	target_hovered = inside


func on_visibility_update_required():
	if not is_node_ready():
		await ready

	if pinned:
		show()
	elif target_hovered:
		show()
	elif not target_hovered:
		hide()

	if auto_choose_direction:
		popup_dir = get_auto_direction()

	adjust_position(popup_dir)
	update_size()
	update_input_processing()
	update_rich_text()
	#update_keyword_rects()

	queue_redraw()
	label.queue_redraw()


func on_label_meta_hover_change(meta, hovered: bool):
	assert(meta is String)
	if hovered:
		sub_tooltip.text = meta
		sub_tooltip.on_visibility_update_required()
		sub_tooltip.show()
	else:
		sub_tooltip.hide()


static func add_to_control(target: Control, sub: bool = false) -> Tooltip:
	var new_tooltip := Tooltip.new()
	new_tooltip.sub = sub
	if sub:
		target.add_child(new_tooltip, false, Node.INTERNAL_MODE_FRONT)
	else:
		target.add_child(new_tooltip)
	return new_tooltip

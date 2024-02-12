extends PanelContainer

@export var player: Player = null

var buffer_window: float = 60.0

var _network_message_handler: NetworkMessageHandler = null

var _clock_synchronizer: ClockSynchronizer = null

var _my_plot_in: Graph2D.PlotItem = null
var _my_plot_out: Graph2D.PlotItem = null

var _in_buffer: Array = []
var _out_buffer: Array = []
var _plot_timer: Timer = null


# Called when the node enters the scene tree for the first time.
func _ready():
	if player.multiplayer_connection.is_server():
		queue_free()
		return

	# Get the NetworkMessageHandler component.
	_network_message_handler = player.multiplayer_connection.component_list.get_component(
		NetworkMessageHandler.COMPONENT_NAME
	)

	assert(_network_message_handler != null, "Failed to get NetworkMessageHandler component")

	# Get the ClockSynchronizer component.
	_clock_synchronizer = player.multiplayer_connection.component_list.get_component(
		ClockSynchronizer.COMPONENT_NAME
	)

	assert(_clock_synchronizer != null, "Failed to get ClockSynchronizer component")

	_plot_timer = Timer.new()
	_plot_timer.name = "PlotTimer"
	_plot_timer.autostart = true
	_plot_timer.wait_time = 1.0
	_plot_timer.timeout.connect(_on_plot_timer_timeout)
	add_child(_plot_timer)

	_my_plot_in = %Graph2D.add_plot_item("Kbps in", Color.GREEN, 1.0)
	_my_plot_out = %Graph2D.add_plot_item("Kpbs out", Color.RED, 1.0)


func _input(event):
	if JUI.chat_active:
		return

	if event.is_action_pressed("j_toggle_debug_menu"):
		if visible:
			hide()
		else:
			show()


func _physics_process(_delta):
	var time_offset: float = _clock_synchronizer.client_clock - buffer_window

	while _in_buffer.size() > 0 and _in_buffer[0][1] < time_offset:
		_in_buffer.remove_at(0)

	while _out_buffer.size() > 0 and _out_buffer[0][1] < time_offset:
		_out_buffer.remove_at(0)

	_in_buffer.append(
		[_network_message_handler.bytes_per_second_in / 1000, _clock_synchronizer.client_clock]
	)
	_out_buffer.append(
		[_network_message_handler.bytes_per_second_out / 1000, _clock_synchronizer.client_clock]
	)


func _on_plot_timer_timeout():
	if not visible:
		return

	_my_plot_in.clear()
	_my_plot_out.clear()

	for i in range(_in_buffer.size() - 1, -1, -1):
		var element: Array = _in_buffer[i]
		_my_plot_in.add_point(Vector2(_clock_synchronizer.client_clock - element[1], element[0]))

	for i in range(_out_buffer.size() - 1, -1, -1):
		var element: Array = _out_buffer[i]
		_my_plot_out.add_point(Vector2(_clock_synchronizer.client_clock - element[1], element[0]))

	%Ping.text = "Ping: %.2f" % (_clock_synchronizer.latency * 500)  # 1000/2 = 500

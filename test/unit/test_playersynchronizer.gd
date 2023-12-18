extends GutTest

var double_player_synchronizer: PlayerSynchronizer = null


func before_each():
	double_player_synchronizer = double(PlayerSynchronizer).new()


func test_server_sync_input():
	# Stub the function to the normal function
	stub(double_player_synchronizer, "server_sync_input").to_call_super()

	# Check that the default values
	assert_eq(double_player_synchronizer._current_frame, 0)
	assert_eq(double_player_synchronizer.mouse_global_pos, Vector2.ZERO)
	assert_eq(double_player_synchronizer._input_buffer.size(), 0)

	# Execute the function with valid values
	double_player_synchronizer.server_sync_input(1, Vector2.LEFT, 0.1, Vector2.ONE)

	# The new values should be set
	assert_eq(double_player_synchronizer._current_frame, 1)
	assert_eq(double_player_synchronizer.mouse_global_pos, Vector2.ONE)
	assert_eq(double_player_synchronizer._input_buffer.size(), 1)

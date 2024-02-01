extends Node
class_name SoundManager
## System for optimally managing sounds
## These use the [member AudioStreamSettings] sub-class to set themselves, you may get an empty one with [method new_settings] these support a factory-pattern like this:
##[codeblock]
## var settings := SoundManager.new_settings().set_seek(20.3).set_attenuation(0.5).set_volume(-1.3)
##[/codeblock]
## You may use [method play_sound] or any of it's variants to play an AudioStream, [method play_sound] is the slowest.
## Playing example:
##[codeblock]
##	var audioSettings := SoundManager.new_settings().set_position_2D(Vector2.RIGHT*500).set_max_distance(9999)
##	var player: AudioStreamPlayer2D = SoundManager.main_instance.play_sound_pos_2d(load("res://assets/audio/ui/login_panel/ui_click/ui_click.mp3"), audioSettings)
##	player.stop()
##[/codeblock]
## Controlling after playing trough an identifier:
##[codeblock]
##	SoundManager.main_instance.play_sound_mono(load("res://assets/audio/ui/login_panel/ui_click/ui_click.mp3"), audioSettings, "ClickSound1")
##	var player: AudioStreamPlayer = SoundManager.main_instance.get_player_from_identifier("ClickSound1")
##	if player != null:
##	    player.start(0.2)
##[/codeblock]

enum CHANNEL_TYPE { MONO, POSITIONAL_2D, POSITIONAL_3D }

## All AudioStreamPlayer nodes will be added as children of this node
@export var player_parent: Node

## Used in case of errors, specially if [method get_registered_stream] fails.
## If not set, this will be null.
@export var failsafe_stream: AudioStream = null

## Max amount of players that may be created per type.
@export var max_channels: int = 16

## A reference to the main instance, as to use it statically.
## [codeblock] SoundManager.main_instance.play_sound(...)[/codeblock]
static var main_instance: SoundManager

## For internal use, holds non-positional AudioStreamPlayers
var channels_mono: Array[AudioStreamPlayer]
## For internal use, holds AudioStreamPlayers2D
var channels_2D: Array[AudioStreamPlayer2D]
## For internal use, holds AudioStreamPlayers3D
var channels_3D: Array[AudioStreamPlayer3D]

## Internal. Holds AudioStreams as a String:AudioStream pair.
## Set by [method set_registered_stream] and retrieved by [method get_registered_stream]
var registered_audio_streams: Dictionary  #String:AudioStream

## Internal. Holds AudioStreamPlayers as a String:AudioStreamPlayer pair.
## Used by [method get_player_from_identifier]
var registered_players: Dictionary


func play_sound(
	stream: AudioStream,
	type: CHANNEL_TYPE,
	settings: StreamPlayerSettings = StreamPlayerSettings.new(),
	identifier: String = ""
) -> Node:
	match type:
		CHANNEL_TYPE.MONO:
			return play_sound_mono(stream, settings, identifier)

		CHANNEL_TYPE.POSITIONAL_2D:
			return play_sound_pos_2d(stream, settings, identifier)

		CHANNEL_TYPE.POSITIONAL_3D:
			return play_sound_pos_3D(stream, settings, identifier)

	return null


## Adds a new AudioStreamPlayer of the appropiate type to a channel [Array] and returns it.
func add_channel(type: CHANNEL_TYPE) -> Node:
	match type:
		CHANNEL_TYPE.MONO:
			if channels_mono.size() >= max_channels:
				GodotLogger.warn("Could not add more non-positional channels, limit reached.")
				return null

			var player := AudioStreamPlayer.new()
			channels_mono.append(player)
			return player

		CHANNEL_TYPE.POSITIONAL_2D:
			if channels_2D.size() >= max_channels:
				GodotLogger.warn("Could not add more 2D channels, limit reached.")
				return null

			var player := AudioStreamPlayer2D.new()
			channels_2D.append(player)
			return player

		CHANNEL_TYPE.POSITIONAL_3D:
			if channels_3D.size() >= max_channels:
				GodotLogger.warn("Could not add more 3D channels, limit reached.")
				return null

			var player := AudioStreamPlayer3D.new()
			channels_3D.append(player)
			return player

	return null


## Removes a given AudioStreamPlayer of the appropiate type from it's channel [Array].
func remove_channel(player: Node):
	if player is AudioStreamPlayer:
		channels_mono.erase(player)
	elif player is AudioStreamPlayer2D:
		channels_2D.erase(player)
	elif player is AudioStreamPlayer3D:
		channels_3D.erase(player)


## Removes all AudioStreamPlayers that are not currently playing anything or are simply invalid.
func clear_unused_channels():
	var keepPlayingPlayersFilter: Callable = func(player: Node): return (
		player.playing and is_instance_valid(player)
	)

	channels_mono.assign(channels_mono.filter(keepPlayingPlayersFilter))
	channels_2D.assign(channels_2D.filter(keepPlayingPlayersFilter))
	channels_3D.assign(channels_3D.filter(keepPlayingPlayersFilter))


func add_player_to_tree(player: Node):
	#If in the tree, reparent it
	if player.is_inside_tree():
		player.reparent(player_parent)
	else:
		player_parent.add_child(player)


func remove_player_from_tree(player: Node):
	#Cannot remove if not in the tree
	if not player.is_inside_tree():
		GodotLogger.warn("The AudioStreamPlayer is not inside the tree. Cannot remove.")
		return

	player_parent.remove_child(player)


## If a sound was played with an identifier, it's AudioStreamPlayer can be retrieved with this function if done before it finishes playing.
## Returns null otherwise.
func get_player_from_identifier(identifier: String) -> Node:
	var player: Node = registered_players.get(identifier, null)
	if is_instance_valid(player):
		return player
	else:
		(
			GodotLogger
			. warn(
				(
					"No AudioStreamPlayer was found with identifier '{0}'. It may have finished already."
					. format([identifier])
				)
			)
		)
		return null


func stop_player_from_identifier(identifier: String):
	var player: Node = get_player_from_identifier(identifier)
	if player != null:
		player.stop()


## Retrieves an audio stream with the given identifier as set by [method set_registered_stream]
func get_registered_stream(streamClass: String) -> AudioStream:
	return registered_audio_streams.get(streamClass, failsafe_stream)


## Stores an audio stream under an identifier, to retrieve with [method get_registered_stream].
func set_registered_stream(streamClass: String, stream: AudioStream):
	registered_audio_streams[streamClass] = stream


## Fetches the first available AudioStreamPlayer or creates one if [param allowNew] is true
func get_available_channel(type: CHANNEL_TYPE, allowNew: bool = true) -> Node:
	match type:
		CHANNEL_TYPE.MONO:
			for player in channels_mono:
				if not player.playing:
					return player

			if allowNew:
				return add_channel(CHANNEL_TYPE.MONO)

		CHANNEL_TYPE.POSITIONAL_2D:
			for player in channels_2D:
				if not player.playing:
					return player

			if allowNew:
				return add_channel(CHANNEL_TYPE.POSITIONAL_2D)

		CHANNEL_TYPE.POSITIONAL_3D:
			for player in channels_3D:
				if not player.playing:
					return player

			if allowNew:
				return add_channel(CHANNEL_TYPE.POSITIONAL_3D)

	GodotLogger.error("Something went wrong when trying to add a channel.")
	return null


func play_sound_mono(
	stream: AudioStream,
	settings: StreamPlayerSettings = StreamPlayerSettings.new(),
	identifier = ""
) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = get_available_channel(CHANNEL_TYPE.MONO)

	if player == null:
		return null

	add_player_to_tree(player)

	player.stream = stream
	player.bus = settings.bus
	player.pitch_scale = settings.pitch_scale
	player.volume_db = settings.volume
	player.play(settings.seek)

	player.finished.connect(on_player_finished.bind(player, settings))

	if identifier != "":
		registered_players[identifier] = player

	return player


func play_sound_pos_2d(
	stream: AudioStream,
	settings: StreamPlayerSettings = StreamPlayerSettings.new(),
	identifier = ""
) -> AudioStreamPlayer2D:
	var player: AudioStreamPlayer2D = get_available_channel(CHANNEL_TYPE.POSITIONAL_2D)

	if player == null:
		return null

	add_player_to_tree(player)

	player.stream = stream
	player.bus = settings.bus
	player.pitch_scale = settings.pitch_scale
	player.volume_db = settings.volume
	player.attenuation = settings.attenuation
	player.max_distance = settings.max_distance
	player.position = settings.position_2D
	player.play(settings.seek)

	player.finished.connect(on_player_finished.bind(player, settings))

	if identifier != "":
		registered_players[identifier] = player

	return player


func play_sound_pos_3D(
	stream: AudioStream,
	settings: StreamPlayerSettings = StreamPlayerSettings.new(),
	identifier = ""
) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = get_available_channel(CHANNEL_TYPE.POSITIONAL_3D)

	if player == null:
		return null

	add_player_to_tree(player)

	player.stream = stream
	player.bus = settings.bus
	player.pitch_scale = settings.pitch_scale
	player.volume_db = settings.volume
	player.attenuation = settings.attenuation
	player.max_distance = settings.max_distance
	player.position = settings.position_3D
	player.play(settings.seek)

	player.finished.connect(on_player_finished.bind(player, settings))

	if identifier != "":
		registered_players[identifier] = player

	return player


func on_player_finished(player: Node, settings: StreamPlayerSettings):
	assert(
		(
			player is AudioStreamPlayer
			or player is AudioStreamPlayer2D
			or player is AudioStreamPlayer3D
		)
	)
	if settings.loop:
		player.play(settings.seek)
	else:
		remove_player_from_tree(player)


static func new_settings() -> StreamPlayerSettings:
	return StreamPlayerSettings.new()


class StreamPlayerSettings:
	extends RefCounted

	## Position for 2D players, in global coordinates
	var position_2D: Vector2

	## Position for 3D players, in global coordinates
	var position_3D: Vector3

	## The Audio bus used, falls back to Master if invalid
	var bus: StringName = &"Master"

	## Change the progress of the audio
	var seek: float = 0.0

	## Volume shift in decibels
	var volume: float = 0.0

	## Multiplier for pitch
	var pitch_scale: float = 1.0

	## Exponent that changes how much the sound fades over distance, 2D/3D only.
	var attenuation: float = 1.0

	## After this distance, the sound cannot be heard at all
	var max_distance: float = 2000.0

	## If true, the sound will start playing again upon finishing, respects the "seek" property
	var loop: bool = false

	func set_position_2D(value: Vector2):
		position_2D = value
		return self

	func set_position_3D(value: Vector3):
		position_3D = value
		return self

	func set_bus(value: StringName) -> StreamPlayerSettings:
		bus = value
		return self

	func set_seek(value: float) -> StreamPlayerSettings:
		seek = value
		return self

	func set_volume(value: float) -> StreamPlayerSettings:
		volume = value
		return self

	func set_pitch_scale(value: float) -> StreamPlayerSettings:
		pitch_scale = value
		return self

	func set_attenuation(value: float) -> StreamPlayerSettings:
		attenuation = value
		return self

	func set_max_distance(value: float) -> StreamPlayerSettings:
		max_distance = value
		return self

	func set_loop(value: bool) -> StreamPlayerSettings:
		loop = value
		return self

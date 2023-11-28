extends Node
class_name SoundManager
## System for optimally managing sounds


enum CHANNEL_TYPE {MONO, POSITIONAL_2D, POSITIONAL_3D}

var channels: Array[AudioStreamPlayer] = [AudioStreamPlayer.new(),AudioStreamPlayer.new()]
var channels_2D: Array[AudioStreamPlayer2D] = [AudioStreamPlayer2D.new(),AudioStreamPlayer2D.new()]
var channels_3D: Array[AudioStreamPlayer3D] = [AudioStreamPlayer3D.new(),AudioStreamPlayer3D.new()]

var registered_audio_streams: Dictionary #String:AudioStream

func play_sound(stream: AudioStream, type: CHANNEL_TYPE, settings: StreamPlayerSettings = StreamPlayerSettings.new()):
	match type:
		CHANNEL_TYPE.MONO:
			play_sound_mono(stream, settings)
			
		CHANNEL_TYPE.POSITIONAL_2D:
			play_sound_pos_2d(stream, settings)
	
		CHANNEL_TYPE.POSITIONAL_3D:
			play_sound_pos_3D(stream, settings)
	pass

func get_stream(streamClass: String)->AudioStream:
	return registered_audio_streams.get(streamClass, null)
	
func set_stream(streamClass: String, stream: AudioStream):
	registered_audio_streams[streamClass] = stream

func get_available_channel(type: CHANNEL_TYPE)->AudioStreamPlayer:
	return channels[0]

func play_sound_mono(stream: AudioStream, channel: int, settings: StreamPlayerSettings = StreamPlayerSettings.new()):
	assert(abs(channel) < channels.size())
	channels[channel].stream = stream
	channels[channel].pitch_scale = settings.pitch_scale
	channels[channel].play(settings.seek)
	
func play_sound_pos_2d(stream: AudioStream, channel: int, settings: StreamPlayerSettings = StreamPlayerSettings.new())-> AudioStreamPlayer2D:
	assert(abs(channel) < channels_2D.size())
	var player: AudioStreamPlayer2D = channels_2D[channel]
	player.stream = stream
	player.pitch_scale = settings.pitch_scale
	player.attenuation = settings.attenuation
	player.play(settings.seek)
	
	return player
	
func play_sound_pos_3D(stream: AudioStream, channel: int, settings: StreamPlayerSettings = StreamPlayerSettings.new()) -> AudioStreamPlayer3D:
	assert(abs(channel) < channels_3D.size())
	var player: AudioStreamPlayer3D = channels_3D[channel]
	player.stream = stream
	player.pitch_scale = settings.pitch_scale
	player.attenuation = settings.attenuation
	player.play(settings.seek)
	
	return player

class StreamPlayerSettings extends Object:
	#Change the progress of the audio
	var seek: float = 0.0
	
	#Multiplier for pitch
	var pitch_scale: float = 1.0

	#Exponent that changes how much the sound fades over distance, 2D/3D only.
	var attenuation: float = 1.0

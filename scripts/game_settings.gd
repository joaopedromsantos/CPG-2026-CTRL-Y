extends Node

const SAVE_PATH := "user://game_settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_GAMEPLAY := "gameplay"
const KEY_MUSIC_VOLUME := "music_volume"
const KEY_SFX_VOLUME := "sfx_volume"
const KEY_DIFFICULTY := "difficulty"

var music_volume := SoundSettings.MAX_VOLUME
var sfx_volume := SoundSettings.MAX_VOLUME
var selected_difficulty := DifficultySettings.DEFAULT_DIFFICULTY


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		_reset_to_defaults()
		return

	music_volume = SoundSettings.normalize_volume(
		int(config.get_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, SoundSettings.MAX_VOLUME))
	)
	sfx_volume = SoundSettings.normalize_volume(
		int(config.get_value(SECTION_AUDIO, KEY_SFX_VOLUME, SoundSettings.MAX_VOLUME))
	)
	selected_difficulty = DifficultySettings.normalize_difficulty(
		String(config.get_value(SECTION_GAMEPLAY, KEY_DIFFICULTY, DifficultySettings.DEFAULT_DIFFICULTY))
	)


func set_difficulty(difficulty: String) -> void:
	selected_difficulty = DifficultySettings.normalize_difficulty(difficulty)
	save_settings()


func set_music_volume(volume: int) -> void:
	music_volume = SoundSettings.normalize_volume(volume)
	save_settings()


func set_sfx_volume(volume: int) -> void:
	sfx_volume = SoundSettings.normalize_volume(volume)
	save_settings()


func set_audio_settings(new_music_volume: int, new_sfx_volume: int) -> void:
	music_volume = SoundSettings.normalize_volume(new_music_volume)
	sfx_volume = SoundSettings.normalize_volume(new_sfx_volume)
	save_settings()


func reset_audio_settings() -> void:
	music_volume = SoundSettings.MAX_VOLUME
	sfx_volume = SoundSettings.MAX_VOLUME
	save_settings()


func apply_music_volume(player: AudioStreamPlayer) -> void:
	SoundSettings.apply_music_volume(player, music_volume)


func apply_sfx_volume(player: AudioStreamPlayer) -> void:
	SoundSettings.apply_sfx_volume(player, sfx_volume)


func save_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, music_volume)
	config.set_value(SECTION_AUDIO, KEY_SFX_VOLUME, sfx_volume)
	config.set_value(SECTION_GAMEPLAY, KEY_DIFFICULTY, selected_difficulty)
	return config.save(SAVE_PATH) == OK


func _reset_to_defaults() -> void:
	music_volume = SoundSettings.MAX_VOLUME
	sfx_volume = SoundSettings.MAX_VOLUME
	selected_difficulty = DifficultySettings.DEFAULT_DIFFICULTY

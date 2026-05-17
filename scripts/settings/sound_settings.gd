class_name SoundSettings
extends RefCounted

const MIN_VOLUME := 0
const MAX_VOLUME := 10
const SILENT_DB := -80.0


static func normalize_volume(volume: int) -> int:
	return clampi(volume, MIN_VOLUME, MAX_VOLUME)


static func volume_to_db(volume: int) -> float:
	var normalized := normalize_volume(volume)
	if normalized <= MIN_VOLUME:
		return SILENT_DB

	return linear_to_db(float(normalized) / float(MAX_VOLUME))


static func apply_music_volume(player: AudioStreamPlayer, volume: int) -> void:
	_apply_volume(player, volume)


static func apply_sfx_volume(player: AudioStreamPlayer, volume: int) -> void:
	_apply_volume(player, volume)


static func _apply_volume(player: AudioStreamPlayer, volume: int) -> void:
	if player == null:
		return

	player.volume_db = volume_to_db(volume)

class_name PowerUpSpawnLogic
extends RefCounted

const TYPE_LUPA := "lupa"
const TYPE_REVIVE := "revive"
const TYPE_HEART := "heart"
const TYPE_LIGHTNING := "lightning"
const TYPE_HOURGLASS := "hourglass"
const TYPE_DOUBLE := "double"

const ASSET_DIR := "res://assets/power-ups/"

const FALLBACK_ASSETS := [
	"res://assets/power-ups/magnifying_glass.glb",
	"res://assets/power-ups/cutscene_model.glb",
	"res://assets/power-ups/heart_emoji.glb",
	"res://assets/power-ups/Lightning Bolt.glb",
	"res://assets/power-ups/transparent_glass_hourglass.glb",
]

const ASSET_TYPES := {
	"res://assets/power-ups/magnifying_glass.glb": TYPE_LUPA,
	"res://assets/power-ups/cutscene_model.glb": TYPE_REVIVE,
	"res://assets/power-ups/heart_emoji.glb": TYPE_HEART,
	"res://assets/power-ups/Lightning Bolt.glb": TYPE_LIGHTNING,
	"res://assets/power-ups/transparent_glass_hourglass.glb": TYPE_HOURGLASS,
}


func build_spawn_entries() -> Array:
	var spawn_entries := []
	var found_paths: Array[String] = []

	var dir := DirAccess.open(ASSET_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.to_lower().ends_with(".glb"):
				found_paths.append(ASSET_DIR + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	if found_paths.is_empty():
		for path in FALLBACK_ASSETS:
			if ResourceLoader.exists(path):
				found_paths.append(path)

	for path in found_paths:
		var type: String = ASSET_TYPES.get(path, "")
		if type != "":
			spawn_entries.append({"type": type, "path": path})

	spawn_entries.append({"type": TYPE_DOUBLE, "path": ""})
	return spawn_entries


func can_spawn(power_ups: Array, floor_back_z: float, lane_positions: Array, spawn_entries: Array) -> bool:
	for existing in power_ups:
		if absf(existing.position.z - floor_back_z) < 1.0:
			return false

	if lane_positions.size() == 0 or spawn_entries.size() == 0:
		return false

	return true

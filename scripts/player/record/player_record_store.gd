class_name PlayerRecordStore
extends RefCounted


func load_high_score(save_path: String, section: String, key_high_score: String) -> int:
	var config := ConfigFile.new()
	var error := config.load(save_path)
	if error != OK:
		return 0

	return int(config.get_value(section, key_high_score, 0))


func save_high_score(save_path: String, section: String, key_high_score: String, high_score: int) -> bool:
	var config := ConfigFile.new()
	if FileAccess.file_exists(save_path):
		config.load(save_path)

	config.set_value(section, key_high_score, high_score)
	return config.save(save_path) == OK

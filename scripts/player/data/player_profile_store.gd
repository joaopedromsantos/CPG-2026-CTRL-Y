class_name PlayerProfileStore
extends RefCounted


func load_display_name(save_path: String, section: String, key_display_name: String) -> String:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return ""
	return String(config.get_value(section, key_display_name, ""))


func save_display_name(save_path: String, section: String, key_display_name: String, display_name: String) -> bool:
	var config := ConfigFile.new()
	if FileAccess.file_exists(save_path):
		config.load(save_path)
	config.set_value(section, key_display_name, display_name)
	return config.save(save_path) == OK

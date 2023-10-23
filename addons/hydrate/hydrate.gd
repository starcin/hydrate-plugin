@tool
extends EditorPlugin

var editor_settings: EditorSettings
var configuration: ConfigFile
var timer: Timer
var popup: AcceptDialog
var player: AudioStreamPlayer
const configuration_file_path: String = "user://hydrate_settings.cfg"
const popup_path: String = "res://addons/hydrate/popup.tscn"
const sound_path: String = "res://addons/hydrate/drops.mp3"
var default_settings: Dictionary = {"active": true, "interval": 120, "enable_popup": true, "enable_sound": true}
var current_settings: Dictionary = {}
var setting_informations: Dictionary = {
	"active": {
		"name": "hydrate/active",
		"type": TYPE_BOOL
	},
	"interval": {
		"name": "hydrate/interval",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,180,1,or_greater"
	},
	"enable_popup": {
		"name": "hydrate/enable_popup",
		"type": TYPE_BOOL
	},
	"enable_sound": {
		"name": "hydrate/enable_sound",
		"type": TYPE_BOOL
	}
}


func _enter_tree():
	configuration = ConfigFile.new()
	var interface = get_editor_interface()
	editor_settings = interface.get_editor_settings()
	var file_loading_status = configuration.load(configuration_file_path)
	if file_loading_status == OK:
		for setting in default_settings:
			if configuration.has_section_key("General", setting):
				current_settings[setting] = configuration.get_value("General", setting)
			else:
				configuration.set_value("General", setting, default_settings[setting])
				current_settings[setting] = default_settings[setting]
	else:
		for setting in default_settings:
			configuration.set_value("General", setting, default_settings[setting])
			current_settings[setting] = default_settings[setting]
	for setting in current_settings:
		editor_settings.set("hydrate/%s" % setting, current_settings[setting])
		editor_settings.add_property_info(setting_informations[setting])
	configuration.save(configuration_file_path)
	editor_settings.settings_changed.connect(_on_settings_changed)
	popup = preload(popup_path).instantiate()
	popup.on_popup_setting_change.connect(func(is_disabled): editor_settings.set("hydrate/enable_popup", !is_disabled))
	interface.get_base_control().add_child(popup)
	player = AudioStreamPlayer.new()
	player.stream = preload(sound_path)
	interface.get_base_control().add_child(player)
	timer = Timer.new()
	timer.timeout.connect(_on_timeout)
	interface.get_base_control().add_child(timer)
	if (current_settings.active):
		timer.start(current_settings.interval * 60)


func _on_settings_changed():
	var changed_settings = editor_settings.get_changed_settings()
	for setting in changed_settings: # 'setting' is in "hydrate/setting" format
		var split_setting_key = setting.split("/", false)
		if split_setting_key.size() != 2 || split_setting_key[0] != "hydrate" || !current_settings.has(split_setting_key[1]):
			continue
		current_settings[split_setting_key[1]] = editor_settings.get_setting(setting)
		configuration.set_value("General", split_setting_key[1], current_settings[split_setting_key[1]])
		configuration.save(configuration_file_path)
		match setting:
			"hydrate/active":
				timer.start(current_settings.interval * 60) if current_settings.active else timer.stop()
			"hydrate/interval":
				var wait_time = current_settings.interval * 60
				if (current_settings.active):
					timer.start(wait_time)
				else:
					timer.wait_time = wait_time
			_:
				if (!current_settings.enable_popup && !current_settings.enable_sound):
					editor_settings.set("hydrate/active", false)


func _on_timeout():
	if current_settings.enable_popup:
		popup.popup_centered()
	if current_settings.enable_sound:
		player.play()


func _exit_tree():
	popup.free()
	player.free()
	timer.free()
	for setting in default_settings:
		editor_settings.erase("hydrate/%s" % setting)

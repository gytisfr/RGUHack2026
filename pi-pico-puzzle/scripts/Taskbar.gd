# Taskbar.gd
# Bottom taskbar with app launcher buttons.
extends PanelContainer

# These signals are caught by MockOS.gd which tells Desktop to spawn windows
signal open_notepad_requested()
signal open_script_editor_requested()


func _ready() -> void:
	$HBoxContainer/NotepadButton.pressed.connect(func(): open_notepad_requested.emit())
	$HBoxContainer/ScriptEditorButton.pressed.connect(func(): open_script_editor_requested.emit())
	$HBoxContainer/ClockLabel.text = _get_time()
	# Update clock every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func(): $HBoxContainer/ClockLabel.text = _get_time())
	add_child(timer)


func _get_time() -> String:
	var t = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [t["hour"], t["minute"], t["second"]]

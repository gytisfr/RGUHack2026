# MockOS.gd
# Root script for the main MockOS scene.
extends Control


@onready var _desktop: Control = $Desktop
@onready var _taskbar = $Taskbar


func _ready() -> void:
	# Connect taskbar signals to desktop spawn functions
	_taskbar.open_notepad_requested.connect(_desktop.spawn_notepad)
	_taskbar.open_script_editor_requested.connect(_desktop.spawn_script_editor)
	
	# Fill entire viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

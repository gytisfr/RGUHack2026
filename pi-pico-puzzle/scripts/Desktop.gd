# Desktop.gd
extends Control

const NOTEPAD_SCENE = preload("res://scenes/Notepad.tscn")
const SCRIPT_EDITOR_SCENE = preload("res://scenes/ScriptEditor.tscn")

@onready var _window_layer: Control = $WindowLayer


func _ready() -> void:
	spawn_script_editor()


func spawn_notepad(file_path: String = "") -> void:
	var win = NOTEPAD_SCENE.instantiate()
	_window_layer.add_child(win)
	win.position = Vector2(80 + randi() % 100, 60 + randi() % 80)
	if file_path != "":
		var app = win.get_node("VBox/Content/NotepadApp")
		if app:
			app.open_file(file_path)


func spawn_script_editor(file_path: String = "") -> void:
	var win = SCRIPT_EDITOR_SCENE.instantiate()
	_window_layer.add_child(win)
	win.position = Vector2(120 + randi() % 80, 80 + randi() % 60)
	if file_path != "":
		var app = win.get_node("VBox/Content/ScriptEditorApp")
		if app:
			app.open_file(file_path)

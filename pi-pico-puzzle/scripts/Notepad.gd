# Notepad.gd
# Saves and loads real .txt files using Godot's FileAccess (user:// directory).
extends MarginContainer

@onready var _text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var _save_btn: Button = $VBoxContainer/Toolbar/SaveButton
@onready var _open_btn: Button = $VBoxContainer/Toolbar/OpenButton
@onready var _file_label: Label = $VBoxContainer/Toolbar/FileLabel

var current_file: String = ""  # real path like "user://documents/notes.txt"
var _window_root: Node


func _ready() -> void:
	_window_root = get_parent()
	while _window_root and not _window_root.has_method("_on_close"):
		_window_root = _window_root.get_parent()
	if _window_root:
		_window_root.title = "Notepad"

	# Make sure save folder exists
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/documents")

	_save_btn.pressed.connect(_on_save)
	_open_btn.pressed.connect(_on_open)
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_update_label()


func _update_label() -> void:
	if current_file == "":
		_file_label.text = "Unsaved"
	else:
		_file_label.text = current_file.get_file()


# ── Real disk save ────────────────────────────────────────────────────────────
func _on_save() -> void:
	if current_file == "":
		# Default filename
		current_file = "user://documents/untitled.txt"

	# Ensure it ends in .txt
	if not current_file.ends_with(".txt"):
		current_file = current_file.trim_suffix(current_file.get_extension()) + "txt"

	var file = FileAccess.open(current_file, FileAccess.WRITE)
	if file == null:
		_file_label.text = "Save failed! (err %d)" % FileAccess.get_open_error()
		return
	file.store_string(_text_edit.text)
	file.close()

	_update_label()
	_file_label.text = _file_label.text + " ✓"
	if _window_root:
		_window_root.title = "Notepad — " + current_file.get_file()
	print("Notepad saved to: ", ProjectSettings.globalize_path(current_file))


# ── Real disk load ────────────────────────────────────────────────────────────
func _on_open() -> void:
	if current_file == "":
		return
	_load_from_disk(current_file)


func _load_from_disk(path: String) -> void:
	if not FileAccess.file_exists(path):
		_file_label.text = "File not found"
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_file_label.text = "Open failed!"
		return
	_text_edit.text = file.get_as_text()
	file.close()
	current_file = path
	_update_label()
	if _window_root:
		_window_root.title = "Notepad — " + path.get_file()


# Called externally (e.g. from Desktop.gd) to open a specific file
func open_file(path: String) -> void:
	_load_from_disk(path)


# Allow saving with Ctrl+S
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_S:
			_on_save()
			get_viewport().set_input_as_handled()

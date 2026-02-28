# Notepad.gd
# Does NOT extend Panel or replace Window.gd.
# Attach this script to a child node called "NotepadApp" inside the Window's Content.
# The parent Window scene handles close/minimize/drag via Window.gd.
extends MarginContainer

@onready var _text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var _save_btn: Button = $VBoxContainer/Toolbar/SaveButton
@onready var _open_btn: Button = $VBoxContainer/Toolbar/OpenButton
@onready var _file_label: Label = $VBoxContainer/Toolbar/FileLabel

var current_file: String = ""

# Reference to the root Window node so we can set its title
var _window_root: Node


func _ready() -> void:
	# Walk up to find the Window root (Panel with Window.gd)
	_window_root = get_parent()
	while _window_root and not _window_root.has_method("_on_close"):
		_window_root = _window_root.get_parent()

	if _window_root:
		_window_root.title = "Notepad"

	_save_btn.pressed.connect(_on_save)
	_open_btn.pressed.connect(_on_open)
	_update_label()

	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY


func _update_label() -> void:
	_file_label.text = current_file.get_file() if current_file != "" else "Unsaved"


func _on_save() -> void:
	if current_file == "":
		current_file = "/home/user/untitled.txt"
	var err = Kernel.write_file(current_file, _text_edit.text)
	_file_label.text = ("Error: " + err) if err != "" else (_file_label.text + " ✓")


func _on_open() -> void:
	if current_file == "":
		return
	var content = Kernel.read_file(current_file)
	if content != "":
		_text_edit.text = content


func open_file(path: String) -> void:
	current_file = path
	_text_edit.text = Kernel.read_file(path)
	_update_label()
	if _window_root:
		_window_root.title = "Notepad — " + path.get_file()

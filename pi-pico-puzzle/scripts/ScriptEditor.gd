# ScriptEditor.gd
# Saves scripts as real .cmd files on disk (user://scripts/).
# Run button executes the saved .cmd file through Kernel.
extends MarginContainer

@onready var _code_edit: CodeEdit = $VBoxContainer/VSplitContainer/CodeEdit
@onready var _output: RichTextLabel = $VBoxContainer/VSplitContainer/OutputPanel/RichTextLabel
@onready var _run_btn: Button = $VBoxContainer/Toolbar/RunButton
@onready var _clear_btn: Button = $VBoxContainer/Toolbar/ClearButton
@onready var _save_btn: Button = $VBoxContainer/Toolbar/SaveButton
@onready var _open_btn: Button = $VBoxContainer/Toolbar/OpenButton
@onready var _file_label: Label = $VBoxContainer/Toolbar/FileLabel
@onready var _status_label: Label = $VBoxContainer/Toolbar/StatusLabel

var current_file: String = ""  # real path like "user://scripts/myscript.cmd"
var _window_root: Node


func _ready() -> void:
	_window_root = get_parent()
	while _window_root and not _window_root.has_method("_on_close"):
		_window_root = _window_root.get_parent()
	if _window_root:
		_window_root.title = "Script Editor"

	# Ensure scripts folder exists on real disk
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/scripts")

	_run_btn.pressed.connect(_on_run)
	_clear_btn.pressed.connect(_on_clear_output)
	_save_btn.pressed.connect(_on_save)
	_open_btn.pressed.connect(_on_open)

	Kernel.script_output.connect(_on_script_output)
	_setup_syntax_highlighting()

	_code_edit.text = "# PicoS .cmd script\n# Save with 💾, then ▶ Run executes from disk\n\nprint \"Hello from PicoS!\"\n\nset name \"World\"\nprint \"Hello $name\"\n\nmkdir /home/user/mydata\nwrite /home/user/mydata/hello.txt \"Written by script!\"\nread /home/user/mydata/hello.txt\n\nfor i in 1..3 do print \"Loop $i\"\n"

	_print_to_output("[color=#555566]── PicoS Script Editor ──\nSave as .cmd, then Run executes from disk.[/color]\n")


func _setup_syntax_highlighting() -> void:
	var highlighter = CodeHighlighter.new()
	var keyword_color = Color(0.4, 0.7, 1.0)
	for kw in ["print", "set", "echo", "write", "read", "mkdir", "touch", "ls", "cd", "if", "then", "for", "in", "do"]:
		highlighter.add_keyword_color(kw, keyword_color)
	highlighter.add_color_region('"', '"', Color(0.6, 1.0, 0.6))
	highlighter.add_color_region("#", "", Color(0.5, 0.5, 0.5), true)
	highlighter.add_color_region("$", " ", Color(1.0, 0.8, 0.4), true)
	_code_edit.syntax_highlighter = highlighter


# ── Real disk save ────────────────────────────────────────────────────────────
func _on_save() -> void:
	if current_file == "":
		current_file = "user://scripts/script.txt"

	# Ensure extension is .cmd
	if not current_file.ends_with(".txt"):
		current_file = current_file.trim_suffix(current_file.get_extension()) + "txt"

	var file = FileAccess.open(current_file, FileAccess.WRITE)
	if file == null:
		_file_label.text = "Save failed! (err %d)" % FileAccess.get_open_error()
		_status_label.text = "Error"
		_status_label.modulate = Color(1.0, 0.3, 0.3)
		return
	file.store_string(_code_edit.text)
	file.close()

	_file_label.text = current_file.get_file() + " ✓"
	_status_label.text = "Saved"
	_status_label.modulate = Color(0.6, 1.0, 0.6)
	if _window_root:
		_window_root.title = "Script Editor — " + current_file.get_file()
	print("Script saved to: ", ProjectSettings.globalize_path(current_file))


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
	_code_edit.text = file.get_as_text()
	file.close()
	current_file = path
	_file_label.text = path.get_file()
	if _window_root:
		_window_root.title = "Script Editor — " + path.get_file()


# ── Run: auto-save then execute from disk ─────────────────────────────────────
func _on_run() -> void:
	var source = _code_edit.text.strip_edges()
	if source == "":
		_print_to_output("[color=#ff6666]Nothing to run.[/color]\n")
		return

	# Auto-save to disk first so the .cmd file is always up to date
	_on_save()

	# Check save succeeded before running
	if not FileAccess.file_exists(current_file):
		_print_to_output("[color=#ff6666]Could not save script before running.[/color]\n")
		return

	# Re-read from disk so we run exactly what was saved
	var file = FileAccess.open(current_file, FileAccess.READ)
	if file == null:
		_print_to_output("[color=#ff6666]Could not read .txt file.[/color]\n")
		return
	var disk_source = file.get_as_text()
	file.close()

	_print_to_output("\n[color=#aaaaff]▶ Running [b]%s[/b]...[/color]\n" % current_file.get_file())
	_status_label.text = "Running..."
	_status_label.modulate = Color(0.4, 0.8, 1.0)

	await get_tree().process_frame
	Kernel.run_script(disk_source)

	_status_label.text = "Done ✓"
	_status_label.modulate = Color(0.4, 1.0, 0.5)


func _on_script_output(text: String) -> void:
	_print_to_output("[color=#ccffcc]" + text.xml_escape() + "[/color]\n")


func _print_to_output(bbcode: String) -> void:
	_output.append_text(bbcode)
	await get_tree().process_frame
	var scrollbar = _output.get_v_scroll_bar()
	if scrollbar:
		scrollbar.value = scrollbar.max_value


func _on_clear_output() -> void:
	_output.clear()


func open_file(path: String) -> void:
	_load_from_disk(path)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_S:
			_on_save()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_R:
			_on_run()
			get_viewport().set_input_as_handled()

# ScriptEditor.gd
# Attach to the "ScriptEditorApp" MarginContainer child inside the Window Content.
# Window.gd on the root handles drag/close/minimize.
extends MarginContainer

@onready var _code_edit: CodeEdit = $VBoxContainer/VSplitContainer/CodeEdit
@onready var _output: RichTextLabel = $VBoxContainer/VSplitContainer/OutputPanel/RichTextLabel
@onready var _run_btn: Button = $VBoxContainer/Toolbar/RunButton
@onready var _clear_btn: Button = $VBoxContainer/Toolbar/ClearButton
@onready var _save_btn: Button = $VBoxContainer/Toolbar/SaveButton
@onready var _open_btn: Button = $VBoxContainer/Toolbar/OpenButton
@onready var _file_label: Label = $VBoxContainer/Toolbar/FileLabel
@onready var _status_label: Label = $VBoxContainer/Toolbar/StatusLabel

var current_file: String = ""
var _window_root: Node


func _ready() -> void:
	# Find the Window root
	_window_root = get_parent()
	while _window_root and not _window_root.has_method("_on_close"):
		_window_root = _window_root.get_parent()

	if _window_root:
		_window_root.title = "Script Editor"

	_run_btn.pressed.connect(_on_run)
	_clear_btn.pressed.connect(_on_clear_output)
	_save_btn.pressed.connect(_on_save)
	_open_btn.pressed.connect(_on_open)

	Kernel.script_output.connect(_on_script_output)
	_setup_syntax_highlighting()

	_code_edit.text = "# PicoS Script\n# Commands: print, set, echo, write, read, mkdir, touch, ls, cd, if, for\n\nprint \"Hello from PicoS!\"\n\nset name \"World\"\nprint \"Hello $name\"\n\nmkdir /home/user/mydata\nwrite /home/user/mydata/hello.txt \"Written by script!\"\nread /home/user/mydata/hello.txt\n"

	_print_to_output("[color=#555566]── PicoS Script Editor ready. Press ▶ Run to execute. ──[/color]\n")


func _setup_syntax_highlighting() -> void:
	var highlighter = CodeHighlighter.new()
	var keyword_color = Color(0.4, 0.7, 1.0)
	for kw in ["print", "set", "echo", "write", "read", "mkdir", "touch", "ls", "cd", "if", "then", "for", "in", "do"]:
		highlighter.add_keyword_color(kw, keyword_color)
	highlighter.add_color_region('"', '"', Color(0.6, 1.0, 0.6))
	highlighter.add_color_region("#", "", Color(0.5, 0.5, 0.5), true)
	highlighter.add_color_region("$", " ", Color(1.0, 0.8, 0.4), true)
	_code_edit.syntax_highlighter = highlighter


func _on_run() -> void:
	var source = _code_edit.text.strip_edges()
	if source == "":
		_print_to_output("[color=#ff6666]No script to run.[/color]\n")
		return
	_print_to_output("\n[color=#aaaaff]▶ Running script...[/color]\n")
	_status_label.text = "Running..."
	_status_label.modulate = Color(0.4, 0.8, 1.0)
	await get_tree().process_frame
	Kernel.run_script(source)
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


func _on_save() -> void:
	if current_file == "":
		current_file = "/home/user/script.picos"
	var err = Kernel.write_file(current_file, _code_edit.text)
	_file_label.text = "Error!" if err != "" else (current_file.get_file() + " ✓")


func _on_open() -> void:
	if current_file == "":
		return
	var content = Kernel.read_file(current_file)
	if content != "":
		_code_edit.text = content


func open_file(path: String) -> void:
	current_file = path
	_code_edit.text = Kernel.read_file(path)
	_file_label.text = path.get_file()
	if _window_root:
		_window_root.title = "Script Editor — " + path.get_file()

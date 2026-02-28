# Window.gd
# Attach to the root Panel of Window.tscn
# Handles dragging, minimize, close, and z-order focus.
extends Panel

@export var title: String = "Window":
	set(v):
		title = v
		if is_inside_tree() and _title_label:
			_title_label.text = v

var _dragging := false
var _drag_offset := Vector2.ZERO

@onready var _title_label: Label = $VBox/TitleBar/TitleLabel
@onready var _close_btn: Button = $VBox/TitleBar/CloseButton
@onready var _minimize_btn: Button = $VBox/TitleBar/MinimizeButton
@onready var _content: Control = $VBox/Content
@onready var _title_bar: Control = $VBox/TitleBar

var _minimized := false


func _ready() -> void:
	_title_label.text = title
	_close_btn.pressed.connect(_on_close)
	_minimize_btn.pressed.connect(_on_minimize)
	show()


func _on_close() -> void:
	queue_free()


func _on_minimize() -> void:
	_minimized = !_minimized
	_content.visible = !_minimized
	if _minimized:
		custom_minimum_size.y = _title_bar.size.y
		size.y = _title_bar.size.y
	else:
		custom_minimum_size.y = 0
		size = Vector2(size.x, 400)


# ── Dragging via title bar ────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			move_to_front()
			var local_pos = event.position
			var title_rect = Rect2(Vector2.ZERO, Vector2(size.x, _title_bar.size.y))
			if title_rect.has_point(local_pos):
				_dragging = event.pressed
				if event.pressed:
					_drag_offset = position - get_global_mouse_position()
				if event.canceled:
					_dragging = event.pressed

	elif event is InputEventMouseMotion:
		if _dragging:
			var new_pos = get_global_mouse_position() + _drag_offset
			var parent_size = get_parent().size
			new_pos.x = clamp(new_pos.x, 0, parent_size.x - size.x)
			new_pos.y = clamp(new_pos.y, 0, parent_size.y - size.y)
			position = new_pos

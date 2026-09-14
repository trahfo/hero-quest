class_name LevelEditorHistory
extends RefCounted

signal history_changed(undo_count: int, redo_count: int)

class HistoryEntry:
	var description: String = ""
	var before_state: Dictionary = {}
	var after_state: Dictionary = {}

	func _init(p_desc: String, p_before: Dictionary, p_after: Dictionary) -> void:
		description = p_desc
		before_state = p_before
		after_state = p_after

var max_history: int = 50
var undo_stack: Array[HistoryEntry] = []
var redo_stack: Array[HistoryEntry] = []
var apply_state_callback: Callable

func _init(p_apply_cb: Callable, p_max: int = 50) -> void:
	apply_state_callback = p_apply_cb
	max_history = maxi(p_max, 30)

func record_action(desc: String, before_state: Dictionary, after_state: Dictionary) -> void:
	var entry = HistoryEntry.new(desc, before_state, after_state)
	undo_stack.append(entry)
	if undo_stack.size() > max_history:
		undo_stack.pop_front()
	redo_stack.clear()
	history_changed.emit(undo_stack.size(), redo_stack.size())

func can_undo() -> bool:
	return not undo_stack.is_empty()

func can_redo() -> bool:
	return not redo_stack.is_empty()

func undo() -> String:
	if not can_undo():
		return ""
	var entry = undo_stack.pop_back()
	if apply_state_callback.is_valid():
		apply_state_callback.call(entry.before_state)
	redo_stack.append(entry)
	history_changed.emit(undo_stack.size(), redo_stack.size())
	return entry.description

func redo() -> String:
	if not can_redo():
		return ""
	var entry = redo_stack.pop_back()
	if apply_state_callback.is_valid():
		apply_state_callback.call(entry.after_state)
	undo_stack.append(entry)
	history_changed.emit(undo_stack.size(), redo_stack.size())
	return entry.description

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	history_changed.emit(0, 0)

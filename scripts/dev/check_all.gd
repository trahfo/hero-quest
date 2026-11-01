extends SceneTree

## Loads every GDScript under res:// so parse/compile errors surface. Exit code 1 on failure.

func _init() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	_collect("res://mini-games", files)
	var failed := 0
	for path in files:
		var script = load(path) as GDScript
		if script == null:
			printerr("PARSE FAIL: ", path)
			failed += 1
	print("Checked %d scripts, %d failed" % [files.size(), failed])
	quit(1 if failed > 0 else 0)

func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))

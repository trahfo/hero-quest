class_name TestSuiteADRCompliance
extends RefCounted

const TARGET_LINE_LIMIT: int = 250
const HARD_CEILING_LIMIT: int = 400

static func run(_tree: SceneTree) -> void:
	print("\n=== [SUITE 8] ADR 0001 ARCHITECTURAL COMPLIANCE & CLASS SIZE LIMITS ===")
	print("  - Verifying adherence to ADR 0001: Target < %d lines, Hard Ceiling <= %d lines..." % [TARGET_LINE_LIMIT, HARD_CEILING_LIMIT])

	var gd_files: Array[String] = []
	_scan_dir_for_gd_scripts("res://scripts", gd_files)

	assert(gd_files.size() > 10, "Expected to find at least 10 GDScript files, found %d" % gd_files.size())

	var violations: Array[String] = []
	var warnings: Array[String] = []
	var total_lines = 0

	for file_path in gd_files:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			continue
		var content = file.get_as_text()
		file.close()

		var lines = content.split("\n").size()
		total_lines += lines

		if lines > HARD_CEILING_LIMIT:
			violations.append("%s (%d lines > %d hard ceiling)" % [file_path, lines, HARD_CEILING_LIMIT])
		elif lines > TARGET_LINE_LIMIT:
			warnings.append("%s (%d lines > %d target)" % [file_path, lines, TARGET_LINE_LIMIT])

	print("  - Scanned %d GDScript files across the codebase (%d total lines)." % [gd_files.size(), total_lines])

	if not warnings.is_empty():
		print("  - [ADR Advisory] %d files in target range (%d-%d lines):" % [warnings.size(), TARGET_LINE_LIMIT + 1, HARD_CEILING_LIMIT])
		for w in warnings:
			print("    • %s" % w)

	if not violations.is_empty():
		var err_msg = "ADR 0001 HARD CEILING VIOLATION! The following %d file(s) exceed %d lines:\n" % [violations.size(), HARD_CEILING_LIMIT]
		for v in violations:
			err_msg += "    ✖ %s\n" % v
		assert(false, err_msg)

	print("  -> Passed! 100%% ADR 0001 compliance confirmed: 0 files exceed the %d-line limit." % HARD_CEILING_LIMIT)

static func _scan_dir_for_gd_scripts(path: String, out_files: Array[String]) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				_scan_dir_for_gd_scripts(full_path, out_files)
			elif file_name.ends_with(".gd"):
				out_files.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

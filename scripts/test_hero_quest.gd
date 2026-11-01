extends SceneTree

const TestSuiteCastleWorld = preload("res://scripts/tests/test_suite_castle_world.gd")
const TestSuiteArchitecture = preload("res://scripts/tests/test_suite_architecture.gd")
const TestSuiteLevelManagement = preload("res://scripts/tests/test_suite_level_management.gd")
const TestSuiteCharacterAndItems = preload("res://scripts/tests/test_suite_character_and_items.gd")
const TestSuiteDoorsAndInteractions = preload("res://scripts/tests/test_suite_doors_and_interactions.gd")
const TestSuiteLevelEditor = preload("res://scripts/tests/test_suite_level_editor.gd")
const TestSuiteEditorPersistenceAndPreview = preload("res://scripts/tests/test_suite_editor_persistence_and_preview.gd")
const TestSuiteVisionPerformance = preload("res://scripts/tests/test_suite_vision_performance.gd")
const TestSuiteFlickerAndOcclusion = preload("res://scripts/tests/test_suite_flicker_and_occlusion.gd")
const TestSuiteADRCompliance = preload("res://scripts/tests/test_suite_adr_compliance.gd")

func _init() -> void:
	print("================================================================")
	print("       🏰 HERO QUEST & GODOT ARCHITECTURAL TEST RUNNER 🏰       ")
	print("================================================================")

	await TestSuiteCastleWorld.run(self)
	await TestSuiteArchitecture.run(self)
	await TestSuiteLevelManagement.run(self)
	await TestSuiteCharacterAndItems.run(self)
	await TestSuiteDoorsAndInteractions.run(self)
	await TestSuiteLevelEditor.run(self)
	await TestSuiteEditorPersistenceAndPreview.run(self)
	await TestSuiteVisionPerformance.run(self)
	await TestSuiteFlickerAndOcclusion.run(self)
	await TestSuiteADRCompliance.run(self)

	print("\n================================================================")
	print("   === ALL 10 TEST SUITES PASSED SUCCESSFULLY! ===")
	print("================================================================")
	quit(0)

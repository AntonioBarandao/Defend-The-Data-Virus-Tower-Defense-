extends SceneTree

const HUD_SCENE := preload("res://Scenes/UI/CyberQuestionHud.tscn")
const CATEGORIES := ["cybersecurity", "networking"]
const DIFFICULTIES := ["easy", "medium", "hard"]
const EXPECTED_REWARDS := {"easy": 50, "medium": 100, "hard": 200}
const MINIMUM_QUESTIONS_PER_POOL := 10
const GAMEPLAY_SCENES := [
	"res://Scenes/Gameplay/Admin_Sandbox.tscn",
	"res://Scenes/Gameplay/Cutscene_Test_Game.tscn",
	"res://Scenes/Gameplay/Demo_Game.tscn",
	"res://Scenes/Gameplay/DEMO_SCENE.tscn",
	"res://Scenes/Gameplay/Normal_Game.tscn",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := HUD_SCENE.instantiate() as CyberQuestionHUD
	root.add_child(hud)
	await process_frame

	var questions: Dictionary = CyberQuestionHUD.QUESTIONS
	var seen_prompts: Dictionary = {}
	for category: String in CATEGORIES:
		if not questions.has(category):
			_fail("Missing question category: %s" % category)
			return

		for difficulty: String in DIFFICULTIES:
			if not questions[category].has(difficulty):
				_fail("Missing %s/%s question pool." % [category, difficulty])
				return

			var pool: Array = questions[category][difficulty]
			if pool.size() < MINIMUM_QUESTIONS_PER_POOL:
				_fail("%s/%s needs at least %d questions." % [category, difficulty, MINIMUM_QUESTIONS_PER_POOL])
				return
			if hud.call("_get_question_reward", difficulty) != EXPECTED_REWARDS[difficulty]:
				_fail("Incorrect reward for %s difficulty." % difficulty)
				return

			for question_value: Variant in pool:
				var question := question_value as Dictionary
				var prompt := String(question.get("prompt", "")).strip_edges()
				var answers := question.get("answers", []) as Array
				var correct := int(question.get("correct", -1))
				if prompt.is_empty() or seen_prompts.has(prompt):
					_fail("Question prompts must be non-empty and unique: %s" % prompt)
					return
				if answers.size() != 4 or correct < 0 or correct >= answers.size():
					_fail("Question must have four answers and a valid correct index: %s" % prompt)
					return
				seen_prompts[prompt] = true

	for scene_path: String in GAMEPLAY_SCENES:
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			_fail("Could not load gameplay scene: %s" % scene_path)
			return
		var gameplay_scene := packed_scene.instantiate()
		var scene_hud := gameplay_scene.get_node_or_null(^"CyberQuestionHUD") as CyberQuestionHUD
		if scene_hud == null:
			gameplay_scene.free()
			_fail("Gameplay scene is missing CyberQuestionHUD: %s" % scene_path)
			return
		for difficulty: String in DIFFICULTIES:
			if scene_hud.call("_get_question_reward", difficulty) != EXPECTED_REWARDS[difficulty]:
				gameplay_scene.free()
				_fail("%s has a stale %s reward." % [scene_path, difficulty])
				return
		gameplay_scene.free()

	print("Cyber question validation passed (%d questions across %d gameplay scenes)." % [seen_prompts.size(), GAMEPLAY_SCENES.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

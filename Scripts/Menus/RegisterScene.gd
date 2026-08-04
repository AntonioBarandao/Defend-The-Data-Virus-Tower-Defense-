
extends Control
var auth: Object = null

func _ready():
	if ClassDB.class_exists(&"AuthWrapper"):
		auth = ClassDB.instantiate(&"AuthWrapper")
	$FormPanel/VBox/CreateButton.pressed.connect(_on_create_pressed)
	$FormPanel/VBox/BackButton.pressed.connect(_on_back_pressed)
	$FormPanel/VBox/UsernameInput.grab_focus()
	$FormPanel/VBox/ConfirmPasswordInput.text_submitted.connect(_submit_registration)

func _on_create_pressed():
	var username: String = $FormPanel/VBox/UsernameInput.text.strip_edges()
	var email: String = $FormPanel/VBox/EmailInput.text.strip_edges()
	var password: String = $FormPanel/VBox/PasswordInput.text
	var confirm_password: String = $FormPanel/VBox/ConfirmPasswordInput.text
	var status: Label = $FormPanel/VBox/StatusLabel

	if username.is_empty() or email.is_empty() or password.is_empty() or confirm_password.is_empty():
		status.text = "Please complete every field."
		return
	if not email.contains("@") or not email.get_slice("@", 1).contains("."):
		status.text = "Enter a valid email address."
		return
	if password.length() < 8:
		status.text = "Password must be at least 8 characters."
		return
	if password != confirm_password:
		status.text = "Passwords do not match."
		return

	if auth == null or not auth.has_method(&"register_user"):
		status.text = "Account registration is unavailable on this platform."
		return

	if auth.register_user(username, password):
		status.text = "Account created successfully!"
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://Scenes/Menus/LoginScene.tscn")
	else:
		status.text = "Username already exists."

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/LoginScene.tscn")

func _submit_registration(_text: String) -> void:
	_on_create_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

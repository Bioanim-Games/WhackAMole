extends Control

## Bioanim Games Studio Splash Screen displayed immediately after the built-in Godot Engine boot splash.
## Fades in res://assets/art/bioanim_splash.webp, holds briefly, fades out, and transitions to TitleScreen.

const LOGO_PATH: String = "res://assets/art/bioanim_splash.webp"
const NEXT_SCENE_PATH: String = "res://scenes/ui/title_screen.tscn"
const FADE_IN_DURATION: float = 0.55
const HOLD_DURATION: float = 1.85
const FADE_OUT_DURATION: float = 0.50
const SKIP_UNLOCK_DELAY: float = 0.35

@onready var logo_texture: TextureRect = $LogoTexture
@onready var fade_overlay: ColorRect = $FadeOverlay

var _elapsed: float = 0.0
var _transitioning: bool = false
var _splash_tween: Tween = null


func _ready() -> void:
	if ResourceLoader.exists(LOGO_PATH):
		logo_texture.texture = ResourceLoader.load(LOGO_PATH) as Texture2D

	fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_splash_tween = create_tween()
	_splash_tween.tween_property(fade_overlay, "color:a", 0.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_splash_tween.tween_interval(HOLD_DURATION)
	_splash_tween.tween_property(fade_overlay, "color:a", 1.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_splash_tween.tween_callback(_go_to_title_screen)


func _process(delta: float) -> void:
	_elapsed += delta


func _input(event: InputEvent) -> void:
	if _transitioning or _elapsed < SKIP_UNLOCK_DELAY:
		return

	var should_skip: bool = false
	if event is InputEventMouseButton and event.pressed:
		should_skip = true
	elif event is InputEventScreenTouch and event.pressed:
		should_skip = true
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		should_skip = true

	if should_skip:
		_skip_to_title()


func _skip_to_title() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _splash_tween and _splash_tween.is_valid():
		_splash_tween.kill()
	var skip_tween: Tween = create_tween()
	skip_tween.tween_property(fade_overlay, "color:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	skip_tween.tween_callback(_go_to_title_screen)


func _go_to_title_screen() -> void:
	_transitioning = true
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)

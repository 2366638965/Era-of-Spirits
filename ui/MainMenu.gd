extends Control

const MENU_VIDEO_PATHS := [
	"res://assets/background/menu.mp4",
	"res://assets/background/menu.ogv"
]
const MENU_BGM_PATH := "res://assets/audio/menu.wav"
const TITLE_LOGO_PATH := "res://assets/tiles/ui/istitle.png"
const MENU_OFF_TEXTURE_PATH := "res://assets/tiles/ui/menu_off.png"
const MENU_ON_TEXTURE_PATH := "res://assets/tiles/ui/menu_on.png"
const CURSOR_TEXTURE_PATH := "res://assets/tiles/ui/mouse.png"
const SETTINGS_SAVE_PATH := "user://settings.cfg"
const MASTER_BUS_NAME := "Master"
const VIDEO_SOFT_LOOP_THRESHOLD := 0.985
const VIDEO_SOFT_LOOP_COOLDOWN_SEC := 0.25
const TEXT_CLICK_ANYWHERE := [0x70B9, 0x51FB, 0x4EFB, 0x610F, 0x5C4F, 0x5E55, 0x4F4D, 0x7F6E]
const TEXT_NEW_GAME := [0x5F00, 0x59CB, 0x6E38, 0x620F]
const TEXT_LOAD_GAME := [0x8BFB, 0x53D6, 0x5B58, 0x6863]
const TEXT_SETTINGS := [0x8BBE, 0x7F6E]
const TEXT_EXIT_GAME := [0x9000, 0x51FA, 0x6E38, 0x620F]

@onready var background_video: Control = $SafeArea/RootLayer/VideoLayer/BackgroundVideo
@onready var menu_bgm: AudioStreamPlayer = $MenuBgm
@onready var fade_layer: ColorRect = $SafeArea/RootLayer/FadeLayer
@onready var title_logo: TextureRect = $SafeArea/RootLayer/TitleLayer/TitleLogo
@onready var subtitle_label: Label = $SafeArea/RootLayer/TitleLayer/SubtitleLabel
@onready var button_panel: VBoxContainer = $SafeArea/RootLayer/MenuLayer/MenuAnchor/ButtonPanel
@onready var menu_background: TextureRect = $SafeArea/RootLayer/MenuLayer/MenuBackground

@onready var new_game_btn: BaseButton = $SafeArea/RootLayer/MenuLayer/MenuAnchor/ButtonPanel/NewGameBtn
@onready var load_game_btn: BaseButton = $SafeArea/RootLayer/MenuLayer/MenuAnchor/ButtonPanel/LoadGameBtn
@onready var settings_btn: BaseButton = $SafeArea/RootLayer/MenuLayer/MenuAnchor/ButtonPanel/SettingsBtn
@onready var exit_btn: BaseButton = $SafeArea/RootLayer/MenuLayer/MenuAnchor/ButtonPanel/ExitBtn
@onready var ui_sfx_hover: AudioStreamPlayer = $UiSfxHover
@onready var ui_sfx_click: AudioStreamPlayer = $UiSfxClick

@onready var settings_holder: Control = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder
@onready var master_mute_check: CheckBox = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/MasterMuteCheck
@onready var master_volume_slider: HSlider = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/MasterVolumeRow/MasterVolumeSlider
@onready var master_volume_value: Label = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/MasterVolumeRow/MasterVolumeValue
@onready var bgm_enable_check: CheckBox = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/BgmEnableCheck
@onready var bgm_volume_slider: HSlider = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/BgmVolumeRow/BgmVolumeSlider
@onready var bgm_volume_value: Label = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/BgmVolumeRow/BgmVolumeValue
@onready var sfx_enable_check: CheckBox = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SfxEnableCheck
@onready var sfx_volume_slider: HSlider = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SfxVolumeRow/SfxVolumeSlider
@onready var sfx_volume_value: Label = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SfxVolumeRow/SfxVolumeValue
@onready var fullscreen_check: CheckBox = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/FullscreenCheck
@onready var apply_settings_btn: Button = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SettingsButtonRow/ApplySettingsBtn
@onready var close_settings_btn: Button = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SettingsButtonRow/CloseSettingsBtn
@onready var reset_settings_btn: Button = $SafeArea/RootLayer/PopupLayer/SettingsMenuHolder/SettingsPanel/SettingsMargin/SettingsVBox/SettingsButtonRow/ResetSettingsBtn

var background_vlc_player: Node = null
var vlc_audio_track_disabled: bool = false
var menu_revealed: bool = false
var current_index: int = 0
var menu_buttons: Array[BaseButton] = []
var menu_off_texture: Texture2D = null
var menu_on_texture: Texture2D = null
var menu_style_off: StyleBoxTexture = null
var menu_style_on: StyleBoxTexture = null
var soft_loop_enabled: bool = false
var soft_loop_cooldown: float = 0.0
var settings_state: Dictionary = {}


func _ready() -> void:
	set_process(false)
	_setup_texts()
	_setup_menu_buttons()
	_setup_menu_ui()
	_setup_media()
	_setup_settings_panel()
	_connect_buttons()
	_setup_cursor()
	_play_fade_in()


func _setup_texts() -> void:
	subtitle_label.text = _codepoints_to_string(TEXT_CLICK_ANYWHERE)
	new_game_btn.text = _codepoints_to_string(TEXT_NEW_GAME)
	load_game_btn.text = _codepoints_to_string(TEXT_LOAD_GAME)
	settings_btn.text = _codepoints_to_string(TEXT_SETTINGS)
	exit_btn.text = _codepoints_to_string(TEXT_EXIT_GAME)


func _codepoints_to_string(codepoints: Array) -> String:
	var output := ""
	for codepoint in codepoints:
		output += char(codepoint)
	return output


func _setup_menu_buttons() -> void:
	menu_buttons = [new_game_btn, load_game_btn, settings_btn, exit_btn]


func _setup_menu_ui() -> void:
	menu_revealed = false
	current_index = 0

	if ResourceLoader.exists(TITLE_LOGO_PATH):
		title_logo.texture = load(TITLE_LOGO_PATH)

	menu_off_texture = _load_texture(MENU_OFF_TEXTURE_PATH)
	menu_on_texture = _load_texture(MENU_ON_TEXTURE_PATH)
	_build_menu_styles()

	subtitle_label.show()
	button_panel.hide()
	menu_background.hide()
	refresh_menu_selection()


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex: Resource = load(path)
	if tex is Texture2D:
		return tex as Texture2D
	return null


func _build_menu_styles() -> void:
	if menu_off_texture != null:
		menu_style_off = StyleBoxTexture.new()
		menu_style_off.texture = menu_off_texture
	if menu_on_texture != null:
		menu_style_on = StyleBoxTexture.new()
		menu_style_on.texture = menu_on_texture


func _setup_cursor() -> void:
	var cursor_texture: Texture2D = _load_texture(CURSOR_TEXTURE_PATH)
	if cursor_texture == null:
		return
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_POINTING_HAND, Vector2.ZERO)


func _default_settings() -> Dictionary:
	var window_mode: int = DisplayServer.window_get_mode()
	var fullscreen_enabled: bool = (
		window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	return {
		"master_muted": false,
		"master_volume": 80.0,
		"bgm_enabled": true,
		"bgm_volume": 80.0,
		"sfx_enabled": true,
		"sfx_volume": 80.0,
		"fullscreen": fullscreen_enabled
	}


func _setup_settings_panel() -> void:
	settings_state = _default_settings()
	_connect_settings_controls()
	_load_settings_from_disk()
	_sync_settings_controls_from_state()
	_apply_settings(false)
	_close_settings_panel()


func _connect_settings_controls() -> void:
	if not master_mute_check.toggled.is_connected(_on_master_mute_toggled):
		master_mute_check.toggled.connect(_on_master_mute_toggled)
	if not master_volume_slider.value_changed.is_connected(_on_master_volume_changed):
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if not bgm_enable_check.toggled.is_connected(_on_bgm_enable_toggled):
		bgm_enable_check.toggled.connect(_on_bgm_enable_toggled)
	if not bgm_volume_slider.value_changed.is_connected(_on_bgm_volume_changed):
		bgm_volume_slider.value_changed.connect(_on_bgm_volume_changed)
	if not sfx_enable_check.toggled.is_connected(_on_sfx_enable_toggled):
		sfx_enable_check.toggled.connect(_on_sfx_enable_toggled)
	if not sfx_volume_slider.value_changed.is_connected(_on_sfx_volume_changed):
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if not fullscreen_check.toggled.is_connected(_on_fullscreen_toggled):
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if not apply_settings_btn.pressed.is_connected(_on_apply_settings_pressed):
		apply_settings_btn.pressed.connect(_on_apply_settings_pressed)
	if not close_settings_btn.pressed.is_connected(_on_close_settings_pressed):
		close_settings_btn.pressed.connect(_on_close_settings_pressed)
	if not reset_settings_btn.pressed.is_connected(_on_reset_settings_pressed):
		reset_settings_btn.pressed.connect(_on_reset_settings_pressed)


func _load_settings_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_SAVE_PATH) != OK:
		return

	settings_state["master_muted"] = bool(cfg.get_value("audio", "master_muted", settings_state["master_muted"]))
	settings_state["master_volume"] = float(cfg.get_value("audio", "master_volume", settings_state["master_volume"]))
	settings_state["bgm_enabled"] = bool(cfg.get_value("audio", "bgm_enabled", settings_state["bgm_enabled"]))
	settings_state["bgm_volume"] = float(cfg.get_value("audio", "bgm_volume", settings_state["bgm_volume"]))
	settings_state["sfx_enabled"] = bool(cfg.get_value("audio", "sfx_enabled", settings_state["sfx_enabled"]))
	settings_state["sfx_volume"] = float(cfg.get_value("audio", "sfx_volume", settings_state["sfx_volume"]))
	settings_state["fullscreen"] = bool(cfg.get_value("display", "fullscreen", settings_state["fullscreen"]))


func _save_settings_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_muted", settings_state["master_muted"])
	cfg.set_value("audio", "master_volume", settings_state["master_volume"])
	cfg.set_value("audio", "bgm_enabled", settings_state["bgm_enabled"])
	cfg.set_value("audio", "bgm_volume", settings_state["bgm_volume"])
	cfg.set_value("audio", "sfx_enabled", settings_state["sfx_enabled"])
	cfg.set_value("audio", "sfx_volume", settings_state["sfx_volume"])
	cfg.set_value("display", "fullscreen", settings_state["fullscreen"])
	var save_result: int = cfg.save(SETTINGS_SAVE_PATH)
	if save_result != OK:
		push_warning("MainMenu: failed to save settings to %s (error=%d)" % [SETTINGS_SAVE_PATH, save_result])


func _sync_settings_controls_from_state() -> void:
	_set_checkbox_no_signal(master_mute_check, bool(settings_state["master_muted"]))
	_set_slider_no_signal(master_volume_slider, float(settings_state["master_volume"]))
	_set_checkbox_no_signal(bgm_enable_check, bool(settings_state["bgm_enabled"]))
	_set_slider_no_signal(bgm_volume_slider, float(settings_state["bgm_volume"]))
	_set_checkbox_no_signal(sfx_enable_check, bool(settings_state["sfx_enabled"]))
	_set_slider_no_signal(sfx_volume_slider, float(settings_state["sfx_volume"]))
	_set_checkbox_no_signal(fullscreen_check, bool(settings_state["fullscreen"]))
	_update_settings_value_labels()


func _set_checkbox_no_signal(checkbox: CheckBox, pressed: bool) -> void:
	checkbox.set_pressed_no_signal(pressed)


func _set_slider_no_signal(slider: HSlider, value: float) -> void:
	slider.set_value_no_signal(clampf(value, slider.min_value, slider.max_value))


func _update_settings_value_labels() -> void:
	master_volume_value.text = "%d%%" % int(round(master_volume_slider.value))
	bgm_volume_value.text = "%d%%" % int(round(bgm_volume_slider.value))
	sfx_volume_value.text = "%d%%" % int(round(sfx_volume_slider.value))


func _percent_to_db(percent: float) -> float:
	var clamped_percent: float = clampf(percent, 0.0, 100.0)
	if clamped_percent <= 0.0:
		return -80.0
	return linear_to_db(clamped_percent / 100.0)


func _apply_settings(save_to_disk: bool) -> void:
	_apply_master_audio_settings()
	_apply_bgm_settings()
	_apply_sfx_settings()
	_apply_display_settings()
	if save_to_disk:
		_save_settings_to_disk()


func _apply_master_audio_settings() -> void:
	var bus_idx: int = AudioServer.get_bus_index(MASTER_BUS_NAME)
	if bus_idx == -1:
		return
	AudioServer.set_bus_mute(bus_idx, bool(settings_state["master_muted"]))
	AudioServer.set_bus_volume_db(bus_idx, _percent_to_db(float(settings_state["master_volume"])))


func _apply_bgm_settings() -> void:
	var bgm_enabled: bool = bool(settings_state["bgm_enabled"])
	menu_bgm.volume_db = _percent_to_db(float(settings_state["bgm_volume"]))
	menu_bgm.stream_paused = not bgm_enabled
	if bgm_enabled and menu_bgm.stream != null and not menu_bgm.playing:
		menu_bgm.play()


func _apply_sfx_settings() -> void:
	var sfx_enabled: bool = bool(settings_state["sfx_enabled"])
	var sfx_volume_db: float = _percent_to_db(float(settings_state["sfx_volume"]))
	ui_sfx_hover.volume_db = sfx_volume_db
	ui_sfx_click.volume_db = sfx_volume_db
	ui_sfx_hover.stream_paused = not sfx_enabled
	ui_sfx_click.stream_paused = not sfx_enabled


func _apply_display_settings() -> void:
	var fullscreen_enabled: bool = bool(settings_state["fullscreen"])
	var target_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)


func _open_settings_panel() -> void:
	_sync_settings_controls_from_state()
	settings_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_holder.show()
	close_settings_btn.grab_focus()


func _close_settings_panel() -> void:
	settings_holder.hide()
	settings_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _is_settings_open() -> bool:
	return settings_holder.visible


func _on_master_mute_toggled(enabled: bool) -> void:
	settings_state["master_muted"] = enabled
	_apply_settings(false)


func _on_master_volume_changed(value: float) -> void:
	settings_state["master_volume"] = value
	_update_settings_value_labels()
	_apply_settings(false)


func _on_bgm_enable_toggled(enabled: bool) -> void:
	settings_state["bgm_enabled"] = enabled
	_apply_settings(false)


func _on_bgm_volume_changed(value: float) -> void:
	settings_state["bgm_volume"] = value
	_update_settings_value_labels()
	_apply_settings(false)


func _on_sfx_enable_toggled(enabled: bool) -> void:
	settings_state["sfx_enabled"] = enabled
	_apply_settings(false)


func _on_sfx_volume_changed(value: float) -> void:
	settings_state["sfx_volume"] = value
	_update_settings_value_labels()
	_apply_settings(false)


func _on_fullscreen_toggled(enabled: bool) -> void:
	settings_state["fullscreen"] = enabled
	_apply_settings(false)


func _on_apply_settings_pressed() -> void:
	_apply_settings(true)


func _on_close_settings_pressed() -> void:
	_close_settings_panel()


func _on_reset_settings_pressed() -> void:
	settings_state = _default_settings()
	_sync_settings_controls_from_state()
	_apply_settings(false)


func _input(event: InputEvent) -> void:
	if _is_settings_open():
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
				_close_settings_panel()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if menu_revealed and not _is_point_on_any_menu_button(mouse_event.position):
				_hide_menu_ui()
				get_viewport().set_input_as_handled()
				return
			if not menu_revealed:
				_reveal_menu()
				get_viewport().set_input_as_handled()
				return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed and menu_revealed:
			_process_mouse_release_menu_click()

	if not menu_revealed:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_UP:
				_move_selection(-1)
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_DOWN:
				_move_selection(1)
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
				_execute_menu_action(current_index)
				get_viewport().set_input_as_handled()
				return


func _process_mouse_release_menu_click() -> void:
	var hovered_index := _get_hovered_button_index()
	if hovered_index < 0:
		return
	_select_and_execute(hovered_index)
	get_viewport().set_input_as_handled()


func _get_hovered_button_index() -> int:
	for i in range(menu_buttons.size()):
		var btn := menu_buttons[i]
		if btn != null and btn.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return i
	return -1


func _reveal_menu() -> void:
	menu_revealed = true
	subtitle_label.hide()
	button_panel.show()
	menu_background.show()
	current_index = 0
	refresh_menu_selection()
	if not menu_buttons.is_empty():
		menu_buttons[current_index].grab_focus()


func _hide_menu_ui() -> void:
	menu_revealed = false
	button_panel.hide()
	menu_background.hide()


func _is_point_on_any_menu_button(point: Vector2) -> bool:
	for button in menu_buttons:
		if button != null and button.visible and button.get_global_rect().has_point(point):
			return true
	return false


func _move_selection(delta: int) -> void:
	if menu_buttons.is_empty():
		return
	current_index = wrapi(current_index + delta, 0, menu_buttons.size())
	refresh_menu_selection()
	menu_buttons[current_index].grab_focus()


func refresh_menu_selection() -> void:
	if menu_buttons.is_empty():
		return
	for i in range(menu_buttons.size()):
		_apply_button_visual(menu_buttons[i], i == current_index)


func _apply_button_visual(button: BaseButton, selected: bool) -> void:
	var style: StyleBoxTexture = menu_style_on if selected else menu_style_off
	if style == null:
		return

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", style)

	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	button.add_theme_constant_override("outline_size", 4)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _setup_media() -> void:
	_setup_vlc_background_video()

	if menu_bgm.stream == null and ResourceLoader.exists(MENU_BGM_PATH):
		menu_bgm.stream = load(MENU_BGM_PATH)
	menu_bgm.autoplay = true
	if menu_bgm.volume_db > -2.0:
		menu_bgm.volume_db = -8.0
	if not menu_bgm.playing:
		menu_bgm.play()


func _setup_vlc_background_video() -> void:
	if not ClassDB.class_exists("VLCMediaPlayer"):
		push_error("MainMenu: VLCMediaPlayer class not found. Check godot-vlc extension loading.")
		return
	if not ClassDB.class_exists("VLCMedia"):
		push_error("MainMenu: VLCMedia class not found. Check godot-vlc extension loading.")
		return

	if background_vlc_player == null:
		var player_obj: Object = ClassDB.instantiate("VLCMediaPlayer")
		if player_obj == null or not (player_obj is Node):
			push_error("MainMenu: failed to instantiate VLCMediaPlayer.")
			return
		background_vlc_player = player_obj as Node
		background_video.add_child(background_vlc_player)
		if background_vlc_player is Control:
			var player_control: Control = background_vlc_player as Control
			player_control.set_anchors_preset(Control.PRESET_FULL_RECT)
			player_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var selected_video_path: String = _resolve_menu_video_path()
	if selected_video_path == "":
		push_error("MainMenu: no menu video file found.")
		return

	var media_res: Variant = _load_vlc_media_from_res_path(selected_video_path)
	if media_res == null:
		push_error("MainMenu: failed to load VLCMedia from %s" % selected_video_path)
		return

	background_vlc_player.set("media", media_res)
	_try_set_vlc_player_silent(background_vlc_player)
	_try_enable_vlc_loop(background_vlc_player)
	_connect_vlc_loop(background_vlc_player)
	_connect_vlc_runtime_signals(background_vlc_player)
	_configure_soft_video_loop(background_vlc_player)

	if background_vlc_player.has_method("play"):
		background_vlc_player.call("play")
	else:
		push_error("MainMenu: VLCMediaPlayer has no play() method.")


func _configure_soft_video_loop(player: Node) -> void:
	soft_loop_enabled = player.has_method("get_position") and player.has_method("set_position")
	soft_loop_cooldown = 0.0
	set_process(soft_loop_enabled)


func _process(delta: float) -> void:
	if not soft_loop_enabled:
		return
	if background_vlc_player == null:
		return
	if soft_loop_cooldown > 0.0:
		soft_loop_cooldown = maxf(0.0, soft_loop_cooldown - delta)
		return

	var pos_variant: Variant = background_vlc_player.call("get_position")
	if typeof(pos_variant) != TYPE_FLOAT and typeof(pos_variant) != TYPE_INT:
		return

	var position: float = float(pos_variant)
	if position >= VIDEO_SOFT_LOOP_THRESHOLD:
		background_vlc_player.call("set_position", 0.0, true)
		soft_loop_cooldown = VIDEO_SOFT_LOOP_COOLDOWN_SEC


func _resolve_menu_video_path() -> String:
	for path in MENU_VIDEO_PATHS:
		if ResourceLoader.exists(path):
			return path
	return ""


func _load_vlc_media_from_res_path(res_path: String) -> Variant:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	return ClassDB.class_call_static("VLCMedia", "load_from_file", abs_path)


func _try_set_vlc_player_silent(player: Node) -> void:
	if player.has_method("set_mute"):
		player.call("set_mute", true)
		return
	if player.has_method("audio_set_mute"):
		player.call("audio_set_mute", true)
		return
	if player.has_method("set_volume"):
		player.call("set_volume", 0)
		return
	if player.has_method("audio_set_volume"):
		player.call("audio_set_volume", 0)


func _connect_vlc_loop(player: Node) -> void:
	var callback: Callable = Callable(self, "_on_vlc_end_reached")
	if player.has_signal("end_reached") and not player.is_connected("end_reached", callback):
		player.connect("end_reached", callback)


func _try_enable_vlc_loop(player: Node) -> void:
	if player.has_method("set_loop"):
		player.call("set_loop", true)
		return
	if _has_property(player, "loop"):
		player.set("loop", true)


func _has_property(target: Object, property_name: String) -> bool:
	for prop in target.get_property_list():
		if prop is Dictionary and prop.get("name", "") == property_name:
			return true
	return false


func _connect_vlc_runtime_signals(player: Node) -> void:
	if player.has_signal("playing"):
		var playing_cb: Callable = Callable(self, "_on_vlc_playing")
		if not player.is_connected("playing", playing_cb):
			player.connect("playing", playing_cb)


func _on_vlc_end_reached() -> void:
	if background_vlc_player == null:
		return
	if soft_loop_enabled:
		# Soft-loop should handle rewind before end_reached; keep this as fallback only.
		return
	if background_vlc_player.has_method("set_position"):
		background_vlc_player.call("set_position", 0.0, true)
	if background_vlc_player.has_method("play"):
		background_vlc_player.call("play")


func _on_vlc_playing() -> void:
	if vlc_audio_track_disabled:
		return
	if background_vlc_player == null:
		return
	if not background_vlc_player.has_method("unselect_track_type"):
		return

	var audio_track_type: int = 0
	var text_track_type: int = 2
	if ClassDB.class_exists("VLCTrack") and ClassDB.class_has_integer_constant("VLCTrack", "TYPE_AUDIO"):
		audio_track_type = ClassDB.class_get_integer_constant("VLCTrack", "TYPE_AUDIO")
	if ClassDB.class_exists("VLCTrack") and ClassDB.class_has_integer_constant("VLCTrack", "TYPE_TEXT"):
		text_track_type = ClassDB.class_get_integer_constant("VLCTrack", "TYPE_TEXT")

	background_vlc_player.call("unselect_track_type", audio_track_type)
	background_vlc_player.call("unselect_track_type", text_track_type)
	vlc_audio_track_disabled = true


func _connect_buttons() -> void:
	_try_connect(new_game_btn, Callable(self, "_on_new_game_button_pressed"))
	_try_connect(load_game_btn, Callable(self, "_on_load_game_button_pressed"))
	_try_connect(settings_btn, Callable(self, "_on_settings_button_pressed"))
	_try_connect(exit_btn, Callable(self, "_on_exit_button_pressed"))

	for i in range(menu_buttons.size()):
		var button: BaseButton = menu_buttons[i]
		var hover_cb: Callable = Callable(self, "_on_menu_button_hovered").bind(i)
		if not button.mouse_entered.is_connected(hover_cb):
			button.mouse_entered.connect(hover_cb)
		var focus_cb: Callable = Callable(self, "_on_menu_button_focused").bind(i)
		if not button.focus_entered.is_connected(focus_cb):
			button.focus_entered.connect(focus_cb)


func _try_connect(button: BaseButton, callback: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _play_fade_in() -> void:
	fade_layer.visible = true
	fade_layer.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_layer, "color:a", 0.0, 0.45)
	tween.finished.connect(func() -> void:
		fade_layer.visible = false
	)


func _on_menu_button_hovered(index: int) -> void:
	if not menu_revealed:
		return
	if current_index == index:
		return
	current_index = index
	refresh_menu_selection()


func _on_menu_button_focused(index: int) -> void:
	if not menu_revealed:
		return
	if current_index == index:
		return
	current_index = index
	refresh_menu_selection()


func _select_and_execute(index: int) -> void:
	if not menu_revealed:
		_reveal_menu()
	current_index = index
	refresh_menu_selection()
	print("MainMenu action index: %d" % index)
	_execute_menu_action(index)


func _on_new_game_button_pressed() -> void:
	_select_and_execute(0)


func _on_load_game_button_pressed() -> void:
	_select_and_execute(1)


func _on_settings_button_pressed() -> void:
	_select_and_execute(2)


func _on_exit_button_pressed() -> void:
	_select_and_execute(3)


func _execute_menu_action(index: int) -> void:
	match index:
		0:
			_on_new_game_pressed()
		1:
			_on_load_game_pressed()
		2:
			_on_settings_pressed()
		3:
			_on_exit_pressed()


func _on_new_game_pressed() -> void:
	print(_codepoints_to_string(TEXT_NEW_GAME))
	# TODO: Replace with your first gameplay scene path, for example:
	# get_tree().change_scene_to_file("res://scenes/xxx.tscn")


func _on_load_game_pressed() -> void:
	print(_codepoints_to_string(TEXT_LOAD_GAME))


func _on_settings_pressed() -> void:
	_open_settings_panel()


func _on_exit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

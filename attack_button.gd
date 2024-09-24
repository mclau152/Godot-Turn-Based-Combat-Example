extends Button


# Constants for player and enemy stats
const PLAYER_STRENGTH: int = 19
const PLAYER_WEAPON_DAMAGE: int = 10
const PLAYER_ARMOR: int = 10

const ENEMY_STRENGTH: int = 10
const ENEMY_WEAPON_DAMAGE: int = 5
const ENEMY_ARMOR: int = 20

@onready var player = $"../Player"  # Adjust the path if necessary
@onready var enemy = $"../Enemy"  # Adjust the path if necessary
@onready var enemy_health_bar = $"../EnemyHealthBar"  # Adjust the path if necessary
@onready var enemy_health_label = $"../EnemyHP"  # Adjust the path if necessary
@onready var player_health_bar = $"../PlayerHealthBar"  # Adjust the path if necessary
@onready var player_health_label = $"../PlayerHP"  # Adjust the path if necessary
@onready var game_over_panel = $"../GameOverPanel"  # Adjust the path if necessary
@onready var try_again_button = $"../GameOverPanel/TryAgainButton"  # Adjust the path if necessary
@onready var damage_text_scene = preload("res://DamageText.tscn")  # Path to the DamageText.tscn file

const MOVE_DISTANCE: float = 600.0
const MOVE_SPEED: float = 500.0
const ATTACK_DELAY: float = 0.5  # Delay in seconds before moving back

var rng = RandomNumberGenerator.new()
var player_start_pos: float
var enemy_start_pos: float

var player_max_hp: int = 120  # You can adjust this value as needed
var player_current_hp: int = player_max_hp
var enemy_max_hp: int = 120  # You can adjust this value as needed
var enemy_current_hp: int = enemy_max_hp

func _ready() -> void:
	pressed.connect(on_button_pressed)
	player_start_pos = player.position.x
	enemy_start_pos = enemy.position.x
	
	# Initialize health UI
	player_current_hp = player_max_hp
	update_player_health_ui()
	player_health_bar.max_value = player_max_hp

	enemy_current_hp = enemy_max_hp
	update_enemy_health_ui()
	enemy_health_bar.max_value = enemy_max_hp

	try_again_button.pressed.connect(restart_game)
	game_over_panel.visible = false

func on_button_pressed() -> void:
	if player_current_hp > 0 and enemy_current_hp > 0:
		disabled = true
		await player_turn()
		await enemy_turn()
		disabled = false
	else:
		show_game_over_panel()

func player_turn() -> void:
	# Move player forward
	var tween = create_tween()
	tween.tween_property(player, "position:x", player_start_pos + MOVE_DISTANCE, MOVE_DISTANCE / MOVE_SPEED)
	await tween.finished

	# Calculate damage
	var damage = max(0, (2 * PLAYER_STRENGTH) + PLAYER_WEAPON_DAMAGE - ENEMY_ARMOR) * rng.randf_range(0.7, 1.3)
	enemy_current_hp = max(0, enemy_current_hp - damage)
	update_enemy_health_ui()
	show_damage_text(enemy, damage)  # Display the damage text above the enemy

	# Delay before moving back
	await get_tree().create_timer(ATTACK_DELAY).timeout

	# Move player back
	tween = create_tween()
	tween.tween_property(player, "position:x", player_start_pos, MOVE_DISTANCE / MOVE_SPEED)
	await tween.finished

func enemy_turn() -> void:
	
	if player_current_hp > 0 and enemy_current_hp > 0:
		# Move enemy forward
		var tween = create_tween()
		tween.tween_property(enemy, "position:x", enemy_start_pos - MOVE_DISTANCE, MOVE_DISTANCE / MOVE_SPEED)
		await tween.finished

		# Calculate damage
		var damage = max(0, (2 * ENEMY_STRENGTH) + ENEMY_WEAPON_DAMAGE - PLAYER_ARMOR) * rng.randf_range(0.7, 1.3)
		player_current_hp = max(0, player_current_hp - damage)
		update_player_health_ui()
		show_damage_text(player, damage)  # Display the damage text above the player

		# Delay before moving back
		await get_tree().create_timer(ATTACK_DELAY).timeout

		# Move enemy back
		tween = create_tween()
		tween.tween_property(enemy, "position:x", enemy_start_pos, MOVE_DISTANCE / MOVE_SPEED)
		await tween.finished
	else:
		show_game_over_panel()



func update_player_health_ui() -> void:
	player_health_bar.value = player_current_hp
	player_health_label.text = "HP: %d/%d" % [player_current_hp, player_max_hp]

func update_enemy_health_ui() -> void:
	enemy_health_bar.value = enemy_current_hp
	enemy_health_label.text = "HP: %d/%d" % [enemy_current_hp, enemy_max_hp]

func set_player_max_hp(new_max_hp: int) -> void:
	player_max_hp = new_max_hp
	player_health_bar.max_value = player_max_hp
	player_current_hp = min(player_current_hp, player_max_hp)
	update_player_health_ui()

func set_enemy_max_hp(new_max_hp: int) -> void:
	enemy_max_hp = new_max_hp
	enemy_health_bar.max_value = enemy_max_hp
	enemy_current_hp = min(enemy_current_hp, enemy_max_hp)
	update_enemy_health_ui()

func show_game_over_panel() -> void:
	game_over_panel.visible = true
	try_again_button.visible = true  # Make the "Try Again" button visible

func restart_game() -> void:
	get_tree().reload_current_scene()


func show_damage_text(target: Node2D, damage: int) -> void:
	var damage_text = damage_text_scene.instantiate()
	damage_text.global_position = target.global_position + Vector2(-20, -280)  # Position the text above the target
	damage_text.text = str(damage)
	add_child(damage_text)

	# Animate the damage text
	var tween = create_tween()
	tween.tween_property(damage_text, "modulate:a", 0.0, 1.0)  # Fade out
	tween.tween_property(damage_text, "global_position", damage_text.global_position + Vector2(0, -50), 1.0)  # Rise upwards
	tween.chain().tween_callback(damage_text.queue_free)  # Remove the text node after the animation

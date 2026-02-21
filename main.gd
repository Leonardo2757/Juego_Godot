extends Node

@export var mob_scene: PackedScene

var score := 0
var highscore := 0

var difficulty := 1.0
var combo := 0
var multiplier := 1
var bonus_active := false
var frenzy_mode := false

var spawn_acceleration := 1.0


func _ready():
	randomize()
	load_highscore()


func _process(delta):

	# dificultad exponencial suave
	difficulty += delta * 0.015 * spawn_acceleration

	# activar frenesí después de sobrevivir bastante
	if difficulty > 3.5 and !frenzy_mode:
		start_frenzy()

	# micro efectos cinematográficos aleatorios
	if randf() < 0.002:
		micro_slow_motion()


# ======================
# GAME FLOW
# ======================

func new_game():
	score = 0
	combo = 0
	multiplier = 1
	difficulty = 1.0
	frenzy_mode = false

	$Player.start($StartPosition.position)
	$StartTimer.start()

	$HUD.update_score(score)
	$HUD.show_message("Get Ready")


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()

	save_highscore()

	Engine.time_scale = 0.3
	await get_tree().create_timer(0.6).timeout
	Engine.time_scale = 1.0

	$HUD.show_game_over()


# ======================
# SPAWN SYSTEM
# ======================

func _on_mob_timer_timeout():

	var mob = mob_scene.instantiate()

	var spawn = $MobPath/MobSpawnLocation
	spawn.progress_ratio = randf()

	mob.position = spawn.position

	var direction = spawn.rotation + PI/2
	direction += randf_range(-PI/3, PI/3)
	mob.rotation = direction

	# velocidad dinámica
	var base_speed = randf_range(150, 250)
	var speed = base_speed * difficulty

	# enemigos especiales
	var special_roll = randf()

	if special_roll < 0.05:
		# gigante lento
		mob.scale *= 2.0
		speed *= 0.6

	elif special_roll < 0.10:
		# mini demonio rapido
		mob.scale *= 0.6
		speed *= 1.8

	mob.linear_velocity = Vector2(speed,0).rotated(direction)
	mob.angular_velocity = randf_range(-5,5)

	add_child(mob)

	# spawn dinámico tipo director AI
	$MobTimer.wait_time = clamp(0.6 / difficulty, 0.05, 0.6)


# ======================
# SCORE SYSTEM
# ======================

func _on_score_timer_timeout():

	combo += 1

	if combo % 10 == 0:
		multiplier += 1
		$HUD.show_message("x" + str(multiplier) + " COMBO!")

	score += (2 if bonus_active else 1) * multiplier

	$HUD.update_score(score)

	random_events()


func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()


# ======================
# RANDOM EVENTS
# ======================

func random_events():

	if randf() < 0.07 and !bonus_active:
		activate_bonus()

	if randf() < 0.04:
		slow_enemies_event()

	if randf() < 0.02:
		spawn_acceleration += 0.3
		$HUD.show_message("MAS INTENSIDAD")


# BONUS SCORE
func activate_bonus():
	bonus_active = true
	$HUD.show_message("BONUS x2!")

	await get_tree().create_timer(6).timeout

	bonus_active = false
	$HUD.show_message("TERMINO BONUS")


# TODOS LOS ENEMIGOS MÁS LENTOS
func slow_enemies_event():
	Engine.time_scale = 0.7
	$HUD.show_message("CAMARA LENTA")

	await get_tree().create_timer(2.5).timeout
	Engine.time_scale = 1.0


# FRENESI
func start_frenzy():
	frenzy_mode = true
	multiplier += 2
	$HUD.show_message("MODO FRENESI!@@@!!!")


# MICRO CINEMATIC EFFECT
func micro_slow_motion():
	Engine.time_scale = 0.85
	await get_tree().create_timer(0.15).timeout
	Engine.time_scale = 1.0


# ======================
# SAVE SYSTEM (SIN NODOS)
# ======================

func save_highscore():
	if score > highscore:
		highscore = score

	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_var(highscore)


func load_highscore():
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		highscore = file.get_var()

extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../Background" # has ice, impassable, walkable
@onready var abigail_sprite: AnimatedSprite2D = $abigail_sprite 
@onready var conveyor_map: TileMapLayer = $"../Conveyor" # has conveyor
@onready var environment_map: TileMapLayer = $"../Environment" # has null, walkable, impassable

var NORMALSPEED = 1.5
var HIGHSPEED = 2
var TP_COORDS = {
	Vector2i(1, -22) : Vector2i(64, -30),
	Vector2i(64, -30) : Vector2i(1, -22),
	Vector2i(63, 4) : Vector2i(-6, 22),
	Vector2i(-6, 22) : Vector2i(63, 4),
}
var TP_TIMER = 0.5

var is_moving = false
var cur_direction = Vector2.DOWN
var speed = NORMALSPEED
var on_ice = false
var on_conveyor = false
var conv_direction = Vector2.DOWN
var is_teleporting = false

func _ready():
	global_position = tile_map.map_to_local(Vector2i(0,0))
	abigail_sprite.global_position = tile_map.map_to_local(Vector2i(0,0))
	abigail_sprite.play("idle_front")

# Transition from current_tile to target_tile
func _physics_process(delta):
	if not is_moving:
		return
	
	if global_position == abigail_sprite.global_position:
		is_moving = false
		if cur_direction == Vector2.UP:
			abigail_sprite.play("idle_back")
		elif cur_direction == Vector2.LEFT:
			abigail_sprite.play("idle_left")
		elif cur_direction == Vector2.DOWN:
			abigail_sprite.play("idle_front")
		elif cur_direction == Vector2.RIGHT:
			abigail_sprite.play("idle_right")
		return
		
	#print("From", sprite.global_position, "to", global_position)
	abigail_sprite.global_position = abigail_sprite.global_position.move_toward(global_position, speed)

func _process(delta):
	if is_moving or is_teleporting:
		return
	if on_ice or on_conveyor:
		move(cur_direction)
	elif Input.is_action_pressed("W"):
		abigail_sprite.play("idle_back")
		cur_direction = Vector2.UP
		move(Vector2.UP)
	elif Input.is_action_pressed("A"):
		abigail_sprite.play("idle_left")
		cur_direction = Vector2.LEFT
		move(Vector2.LEFT)
	elif Input.is_action_pressed("S"):
		abigail_sprite.play("idle_front")
		cur_direction = Vector2.DOWN
		move(Vector2.DOWN)
	elif Input.is_action_pressed("D"):
		abigail_sprite.play("idle_right")
		cur_direction = Vector2.RIGHT
		move(Vector2.RIGHT)
	elif Input.is_action_just_pressed("E") and cur_direction == Vector2.UP:
		teleport()
	elif Input.is_action_just_pressed("R"):
		abigail_sprite.play("playing_flute")
	elif Input.is_action_just_released("R"):
		abigail_sprite.play("idle_front")
		

func move(direction: Vector2):
	# Get current tile and target tile
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y,
	)
	
	var current_tile_type : TileData = tile_map.get_cell_tile_data(current_tile)
	var target_tile_type : TileData = tile_map.get_cell_tile_data(target_tile)
	var conv_current_tile_type : TileData = conveyor_map.get_cell_tile_data(current_tile)
	var conv_target_tile_type : TileData = conveyor_map.get_cell_tile_data(target_tile)
	var env_target_tile_type : TileData = environment_map.get_cell_tile_data(target_tile)
	
	if not target_tile_type.get_custom_data("Walkable") or (env_target_tile_type != null and not env_target_tile_type.get_custom_data("Walkable")):
		#print("not walkable")
		on_ice = false
		on_conveyor = false
		return
	
	# Check if on ice or on conveyer
	if target_tile_type.get_custom_data("Ice"):
		#print("ON ICE")
		on_ice = true
		speed = HIGHSPEED
	elif conv_target_tile_type != null and conv_target_tile_type.get_custom_data("Conveyor"):
		#print("ON CONVEYOR")
		on_conveyor = true
		if conv_target_tile_type.get_custom_data("conv_dir") == "UP":
			direction = Vector2.UP
		elif conv_target_tile_type.get_custom_data("conv_dir") == "DOWN":
			direction = Vector2.DOWN
		elif conv_target_tile_type.get_custom_data("conv_dir") == "LEFT":
			direction = Vector2.LEFT
		elif conv_target_tile_type.get_custom_data("conv_dir") == "RIGHT":
			direction = Vector2.RIGHT
		speed = HIGHSPEED
	else:
		#print("not ice or conveyor")
		on_ice = false
		on_conveyor = false
		speed = NORMALSPEED
		
	# assert: no tile should be both ice or conveyor
	if on_ice or on_conveyor:
		assert(on_conveyor != on_ice)
	
	# Play sprite animation
	cur_direction = direction
	if conv_current_tile_type != null and conv_current_tile_type.get_custom_data("Conveyor"):
		abigail_sprite.play("rotating")
	elif direction == Vector2.UP:
		if current_tile_type.get_custom_data("Ice"):
			abigail_sprite.play("sliding_up") 	
		else: 
			abigail_sprite.play("walk_up")
	elif direction == Vector2.LEFT:
		if current_tile_type.get_custom_data("Ice"):
			abigail_sprite.play("sliding_left") 	
		else: 
			abigail_sprite.play("walk_left")
	elif direction == Vector2.DOWN:
		if current_tile_type.get_custom_data("Ice"):
			abigail_sprite.play("sliding_down") 	
		else: 
			abigail_sprite.play("walk_down")
	elif direction == Vector2.RIGHT:
		if current_tile_type.get_custom_data("Ice"):
			abigail_sprite.play("sliding_right") 	
		else: 
			abigail_sprite.play("walk_right")
		
	# Move
	is_moving = true
	global_position = tile_map.map_to_local(target_tile)
	abigail_sprite.global_position = tile_map.map_to_local(current_tile)
	

func teleport():
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	if current_tile not in TP_COORDS:
		return
	is_teleporting = true
	abigail_sprite.play("rotating")
	await get_tree().create_timer(TP_TIMER).timeout # delay of TP_TIMER seconds
	global_position = tile_map.map_to_local(TP_COORDS[current_tile])
	abigail_sprite.global_position = tile_map.map_to_local(TP_COORDS[current_tile])
	await get_tree().create_timer(TP_TIMER).timeout
	abigail_sprite.play("idle_front")
	is_teleporting = false
	

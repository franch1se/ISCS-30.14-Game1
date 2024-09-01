extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../Background"
@onready var abigail_sprite: AnimatedSprite2D = $abigail_sprite

var is_moving = false
var vertical_offset = Vector2(0, -16)
var cur_direction = Vector2.DOWN
var speed = 1.5;
var on_ice = false;
var on_conveyor = false;
var conv_direction = Vector2.DOWN;

func _ready():
	global_position = tile_map.map_to_local(Vector2i(0,0))
	abigail_sprite.global_position = tile_map.map_to_local(Vector2i(0,0))
	abigail_sprite.play("idle_front")
	
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
	if is_moving:
		return
	
	if on_ice or on_conveyor:
		move(cur_direction)
	elif Input.is_action_pressed("W"):
		abigail_sprite.play("idle_back")
		move(Vector2.UP)
	elif Input.is_action_pressed("A"):
		abigail_sprite.play("idle_left")
		move(Vector2.LEFT)
	elif Input.is_action_pressed("S"):
		abigail_sprite.play("idle_front")
		move(Vector2.DOWN)
	elif Input.is_action_pressed("D"):
		abigail_sprite.play("idle_right")
		move(Vector2.RIGHT)

func move(direction: Vector2):
	#Get current tile and target tile
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y,
	)
	
	var current_tile_type : TileData = tile_map.get_cell_tile_data(current_tile)
	var target_tile_type : TileData = tile_map.get_cell_tile_data(target_tile)
		
	if not target_tile_type.get_custom_data("Walkable"):
		#print("not walkable")
		on_ice = false
		on_conveyor = false
		return
	
	#Check if on ice or on conveyer
	if target_tile_type.get_custom_data("Ice"):
		#print("ON ICE")
		on_ice = true
	elif target_tile_type.get_custom_data("Conveyor"):
		#print("ON CONVEYOR")
		on_conveyor = true
		if target_tile_type.get_custom_data("conv_dir") == "UP":
			direction = Vector2.UP
		elif target_tile_type.get_custom_data("conv_dir") == "DOWN":
			direction = Vector2.DOWN
		elif target_tile_type.get_custom_data("conv_dir") == "LEFT":
			direction = Vector2.LEFT
		elif target_tile_type.get_custom_data("conv_dir") == "RIGHT":
			direction = Vector2.RIGHT
	else:
		#print("not ice convey")
		on_ice = false
		on_conveyor = false
		
	#assert: no tile should be both ice or conveyor
	if on_ice or on_conveyor:
		assert(on_conveyor != on_ice)
	
	#Play sprite animation
	cur_direction = direction
	if current_tile_type.get_custom_data("Conveyor"):
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
		
	#Move
	is_moving = true
	global_position = tile_map.map_to_local(target_tile)
	abigail_sprite.global_position = tile_map.map_to_local(current_tile)
	

extends Node2D

@onready var tile_map = $"../TileMap"
@onready var sprite = $"Sprite"
@onready var animation = $"Sprite/animation"

var is_moving = false
var on_ice = false
var on_conv = false
var walkable = true
var current_dir = Vector2.UP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if is_moving == false:
		return
	if global_position != sprite.global_position:
		sprite.global_position = sprite.global_position.move_toward(global_position, 1)
		return
	is_moving = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_moving:
		return

	if (Input.is_action_pressed("W") and (!on_ice and !on_conv)):
		move(Vector2.UP)
		current_dir = Vector2.UP
		animation.play("walk_up")
	elif (Input.is_action_pressed("S") and (!on_ice and !on_conv)):
		move(Vector2.DOWN)
		current_dir = Vector2.DOWN
		animation.play("walk_down")
	elif (Input.is_action_pressed("A") and (!on_ice and !on_conv)):
		move(Vector2.LEFT)
		current_dir = Vector2.LEFT
		animation.play("walk_left")
	elif (Input.is_action_pressed("D") and (!on_ice and !on_conv)):
		move(Vector2.RIGHT)
		current_dir = Vector2.RIGHT
		animation.play("walk_right")
	
	if on_ice:
		if walkable == false:
			on_ice = false
		move(current_dir)
	if on_conv:
		if walkable == false:
			on_conv = false
		move(current_dir)

func move(dir: Vector2):
	
	#Current tile
	var current: Vector2i = tile_map.local_to_map(global_position)
	
	#Target tile
	var target: Vector2i = Vector2i(
		current.x + dir.x, 
		current.y + dir.y, 
	)
	print(current, target)
	
	var tile_data: TileData = tile_map.get_cell_tile_data(0, target)
	if tile_data.get_custom_data("Walkable") == false:
		walkable = false
	else: 
		walkable = true
	if walkable == false:
		return
	
	#Move
	is_moving = true
	global_position = tile_map.map_to_local(target)
	sprite.global_position = tile_map.map_to_local(current)
	if tile_data.get_custom_data("Ice"):
		on_ice = true
	elif tile_data.get_custom_data("Conveyor"):
		on_conv = true
		if tile_data.get_custom_data("conv_dir") == "UP":
			current_dir = Vector2.UP
		elif tile_data.get_custom_data("conv_dir") == "DOWN":
			current_dir = Vector2.DOWN
		elif tile_data.get_custom_data("conv_dir") == "LEFT":
			current_dir = Vector2.LEFT
		elif tile_data.get_custom_data("conv_dir") == "RIGHT":
			current_dir = Vector2.RIGHT
	elif tile_data.get_custom_data("Walkable") == false:
		on_conv = false
		on_ice = false
		return
	else: 
		on_conv = false
		on_ice = false

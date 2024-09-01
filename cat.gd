extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../Background"
@onready var environment_map: TileMapLayer = $"../Environment" # has null, walkable, impassable
@onready var abigail_sprite: AnimatedSprite2D = $"../Abigail/abigail_sprite"
@onready var cat_sprite: AnimatedSprite2D = $cat_sprite

var is_moving = false
var speed = 1
# WASD
var dx = [0, -1, 0, 1]
var dy = [-1, 0, 1, 0]
var MXVAL = 1000000000
var dist_threshold = 1;

func _ready():
	var starting = Vector2i(-1, 0) # 2 units distance from player
	global_position = tile_map.map_to_local(starting)
	cat_sprite.global_position = tile_map.map_to_local(starting)
	cat_sprite.play("idle")
	
func _physics_process(delta):
	if not is_moving:
		return
	
	if global_position == cat_sprite.global_position:
		cat_sprite.play("idle")
		is_moving = false
		return
		
	#print("From", sprite.global_position, "to", global_position)
	cat_sprite.global_position = cat_sprite.global_position.move_toward(global_position, speed)

func dist(cat: Vector2i, abi: Vector2i) -> int:
	return abs(cat.x - abi.x) + abs(cat.y - abi.y)

func _process(delta):
	if is_moving:
		return
	
	var cat_coor = tile_map.local_to_map(cat_sprite.global_position)
	var abigail_coor = tile_map.local_to_map(abigail_sprite.global_position)
	
	#Get all cardinal directions, sort by distance to abigail, least distance is the move
	var tile_choices = []
	for i in range(4):
		var target_tile = cat_coor + Vector2i(dx[i], dy[i])
		var target_tile_type : TileData = tile_map.get_cell_tile_data(target_tile)
		var env_target_tile_type : TileData = environment_map.get_cell_tile_data(target_tile)
		var dist_to_abi = dist(target_tile, abigail_coor)
		
		# target tile is not walkable -> make distance to MXVAL
		if (env_target_tile_type != null and not env_target_tile_type.get_custom_data("Walkable")) or not target_tile_type.get_custom_data("Walkable"):
			dist_to_abi = MXVAL
		tile_choices.append([dist_to_abi, i])
	tile_choices.sort()
	
	if tile_choices[0][0] <= dist_threshold or tile_choices[0][0] == MXVAL:
		return
	#print(tile_choices)
	
	var target_coor = cat_coor;
	if tile_choices[0][1] == 0:
		target_coor += Vector2i.UP
		cat_sprite.play("walk_up")
	elif tile_choices[0][1] == 1:
		target_coor += Vector2i.LEFT
		cat_sprite.play("walk_left")
	elif tile_choices[0][1] == 2:
		target_coor += Vector2i.DOWN
		cat_sprite.play("walk_down")
	elif tile_choices[0][1] == 3:
		target_coor += Vector2i.RIGHT
		cat_sprite.play("walk_right")
	
	#Move
	is_moving = true
	global_position = tile_map.map_to_local(target_coor)
	cat_sprite.global_position = tile_map.map_to_local(cat_coor)
	

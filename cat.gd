extends CharacterBody2D

@onready var tile_map: TileMapLayer = $"../Background"
@onready var environment_map: TileMapLayer = $"../Environment" # has null, walkable, impassable
@onready var abigail_sprite: AnimatedSprite2D = $"../Abigail/abigail_sprite"
@onready var cat_sprite: AnimatedSprite2D = $cat_sprite

# aux. variables for bfs
var dx = [0, -1, 0, 1]
var dy = [-1, 0, 1, 0]

var MXVAL = 1000000000
var MX_SEARCH_DEPTH = 7
var DIST_THRESHOLD = 2;		# dist for cat to sleep near abi
var SEPARATE_THRESHOLD = 12 # dist for cat to run towards abi
var NORMALSPEED = 1;
var HIGHSPEED = 2;

var is_moving = false
var speed = NORMALSPEED;
var moves_queue = []
var is_catchingup = false
var anim_frames = {
	"walk_down" : [0, 0.0],
	"walk_left" : [0, 0.0],
	"walk_right" : [0, 0.0],
	"walk_up" : [0, 0.0],
}

func _ready():
	var starting = Vector2i(-9, -17)
	global_position = tile_map.map_to_local(starting)
	cat_sprite.global_position = tile_map.map_to_local(starting)
	cat_sprite.play("idle")
	
func _physics_process(delta):
	if not is_moving:
		return
	
	if global_position == cat_sprite.global_position:
		is_moving = false
		if abigail_sprite.animation in anim_frames:
			anim_frames[abigail_sprite.animation][0] = abigail_sprite.get_frame()
			anim_frames[abigail_sprite.animation][1] = abigail_sprite.get_frame_progress()
		cat_sprite.play("idle")
		return
		
	#print("From", sprite.global_position, "to", global_position)
	cat_sprite.global_position = cat_sprite.global_position.move_toward(global_position, speed)

# Manhattan distance
func dist(cat: Vector2i, abi: Vector2i) -> int:
	return abs(cat.x - abi.x) + abs(cat.y - abi.y)

func get_direction(cur_tile: Vector2i, next_tile: Vector2i) -> Vector2i:
	assert(dist(cur_tile, next_tile) == 1)
	return next_tile - cur_tile

func bfs(cat: Vector2i, abi: Vector2i, mx_depth: int):
	# search tiles from cat to abi that has at most depth of {mx_depth}
	# adds moves to {queue_moves}.
	
	var queue = [[0, 0, cat]] 	# dist, depth, cat
	var parent = { cat : Vector2i.MAX } # tile : parent_tile. for path reconstruction
	
	for lst in queue:
		var cur_dist = lst[0]
		var depth = lst[1]
		var cur_tile = lst[2]
		for i in range(4):
			var target_tile = cur_tile + Vector2i(dx[i], dy[i])
			var target_tile_type : TileData = tile_map.get_cell_tile_data(target_tile)
			var env_target_tile_type : TileData = environment_map.get_cell_tile_data(target_tile)
			var dist_to_abi = dist(target_tile, abi)
		
			# target tile is not walkable -> continue
			if (env_target_tile_type != null and not env_target_tile_type.get_custom_data("Walkable")) or not target_tile_type.get_custom_data("Walkable"):
				continue
			
			# if tile is already visited or max_depth reached -> continue
			if target_tile in parent or depth+1 >= mx_depth:
				continue
			
			parent[target_tile] = cur_tile
			queue.append([dist_to_abi, depth+1, target_tile])
	
	queue.sort()
	# reconstruct path starting from {tile with least dist to abi} to cat
	# note that queue[0] is the cat_coor. the least dist is queue[1].
	var trgt_tile: Vector2i = queue[1][2]
	while trgt_tile != cat:
		moves_queue.append(trgt_tile)
		trgt_tile = parent[trgt_tile]
	

func _process(delta):
	if is_moving:
		return
	
	var cat_coor = tile_map.local_to_map(cat_sprite.global_position)
	var abigail_coor = tile_map.local_to_map(abigail_sprite.global_position)
	
	if not is_catchingup and dist(cat_coor, abigail_coor) >= SEPARATE_THRESHOLD:
		speed = HIGHSPEED
		is_catchingup = true
	
	if is_catchingup and dist(cat_coor, abigail_coor) <= DIST_THRESHOLD + 3:
		speed = NORMALSPEED
		is_catchingup = false
		
	# if cat is near abigail, don't move no more
	if dist(cat_coor, abigail_coor) <= DIST_THRESHOLD:
		moves_queue.clear()
		return
	
	# generate path only if there's no more moves
	if moves_queue.is_empty():
		bfs(cat_coor, abigail_coor, MX_SEARCH_DEPTH)
		
	#print(moves_queue)

	# move cat
	if moves_queue:
		var target_coor = moves_queue[-1]
		moves_queue.pop_back()
		if get_direction(cat_coor, target_coor) == Vector2i.UP:
			cat_sprite.play("walk_up")
			cat_sprite.set_frame_and_progress(anim_frames["walk_up"][0], anim_frames["walk_up"][1])
		elif get_direction(cat_coor, target_coor) == Vector2i.LEFT:
			cat_sprite.play("walk_left")
			cat_sprite.set_frame_and_progress(anim_frames["walk_left"][0], anim_frames["walk_left"][1])
		elif get_direction(cat_coor, target_coor) == Vector2i.DOWN:
			cat_sprite.play("walk_down")
			cat_sprite.set_frame_and_progress(anim_frames["walk_down"][0], anim_frames["walk_down"][1])
		elif get_direction(cat_coor, target_coor) == Vector2i.RIGHT:
			cat_sprite.play("walk_right")
			cat_sprite.set_frame_and_progress(anim_frames["walk_right"][0], anim_frames["walk_right"][1])
			
		# Move
		is_moving = true
		global_position = tile_map.map_to_local(target_coor)
		cat_sprite.global_position = tile_map.map_to_local(cat_coor)

	

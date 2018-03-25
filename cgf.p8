pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- Copa Globale Football '83

-- 7DRL
-- no one expected you to even qualify... because you didn't.  Scandals in Litvangium ejected the team from the tournament and no you're there.  The crowds are screaming and politics is playing out on the world stage.
-- No team from Argenstein has even won.  But here you are.  Seconds left on the clock, hopes and dreams and aspiration and inspirations being shouted in every langauge and you have a shot.
-- you have everything with you that need to win.  You just need to figure out how to do it.

-- rough design
-- there are goons and you're trying to get through them
-- the tools at your disposal are things in the room -- furniture and things
-- you can climb on it to lunge
-- kick some to do damage to enemies
-- enemies can also kick them at you
-- you're faster but weaker than the enemies ( you move 2x to every one they move, but they take 2 or 3 hits to die and you only take one hit)
-- you get to the exit and see how far you can get, if you can escape!

-- next:
-- win condition or progression
-- fix turn and actions boxes... think about a ui?
-- turn queue instead of using the update loop to manage turns 
--  (also enemies avoid chairs right now, thats broken)
-- smoother camera
-- more moves than just moving (lunge?  grab?)
-- enemies can k
-- kicks should lose momentum, not push indefinitely
-- better game over screen
-- more enemies, progression


-- done
-- turn counter
-- two moves per one enemy turn instead of just 1-1
-- turn based movement - for every two moves you make, the enemies make a move
-- enemies  come at you with A*
-- bit of optimization on A*
-- fix world boundaries
-- spawn furniture
-- you can attack the goons to make them disapear
-- goons randomly spawned
-- move around on the grid
-- avatar
-- grid
-- kick furniture
-- kicked furniture hits enemies


-- { debug stuff can be deleted
function repr(arg)
 -- turn any thing into a string (table, boolean, whatever)
 if arg == nil then
  return "nil"
 end
 if type(arg) == "boolean" then
  return arg and "true" or "false"
 end
 if type(arg) == "table" then 
  local retval = " table{ "
  for k, v in pairs(arg) do
   retval = retval .. k .. ": ".. repr(v).. ","
  end
  retval = retval .. "} "
  return retval
 end
 return ""..tostr(arg)
end

function make_debugmsg()
 return {
  space=sp_screen_native,
  draw=function(t)
   color(14)
   cursor(1,1)
   print("cpu: ".. stat(1))
   print("mem: ".. stat(2))
  end
 }
end

function print_stdout(msg)
 -- print 'msg' to the terminal, whatever it might be
 printh("["..repr(g_tick).."] "..repr(msg))
end
-- }

-- { particle stuff
function add_particle(x, y, dx, dy, life, color, ddy)
 particle_array_length += 1

 -- grow if needed
 if (#particle_array < particle_array_length) add(particle_array, 0)
 
 -- insert into the next available spot
 particle_array[particle_array_length] = {x = x, y = y, dx = dx, dy = dy, life = life or 8, color = color or 6, ddy = ddy or 0.0625}
end


function process_particles(at_scope)
 -- @casualeffects particle system
 -- http://casual-effects.com

 -- simulate particles during rendering for efficiency
 local p = 1
 local off = {0,0}
 if at_scope == sp_world and g_cam != nil then
  off = {-g_cam.x + 64, -g_cam.y + 64}
  -- off = {g_cam.x + 64, -g_cam.y + 64}
 end
 while p <= particle_array_length do
  local particle = particle_array[p]
  
  -- the bitwise expression will have the high (negative) bit set
  -- if either coordinate is negative or greater than 127, or life < 0
  if bor(band(0x8000, particle.life), band(bor(off[1]+particle.x, off[2]+particle.y), 0xff80)) != 0 then

   -- delete dead particles efficiently. pico8 doesn't support
   -- table.setn, so we have to maintain an explicit length variable
   particle_array[p], particle_array[particle_array_length] = particle_array[particle_array_length], nil
   particle_array_length -= 1

  else

   -- draw the particle by directly manipulating the
   -- correct nibble on the screen
   local addr = bor(0x6000, bor(shr(off[1]+particle.x, 1), shl(band(off[2]+particle.y, 0xffff), 6)))
   local pixel_pair = peek(addr)
   if band(off[1]+particle.x, 1) == 1 then
    -- even x; we're writing to the high bits
    pixel_pair = bor(band(pixel_pair, 0x0f), shl(particle.color, 4))
   else
    -- odd x; we're writing to the low bits
    pixel_pair = bor(band(pixel_pair, 0xf0), particle.color)
   end
   poke(addr, pixel_pair)
   
   -- acceleration
   particle.dy += particle.ddy
  
   -- advance state
   particle.x += particle.dx
   particle.y += particle.dy
   particle.life -= 1

   for _, c in pairs(collision_objects) do
    local collision_result = c:collides(particle)
    if collision_result != nil then
     particle.x += collision_result[1]
     particle.y += collision_result[2]
     particle.dy = 0
     particle.dx = 0
    end
   end

   p += 1
  end -- if alive
 end -- while
end

collision_objects = {
 {
  x=50,
  y=80,
  width=27,
  height=14,
  collides=function(t, part)
   if (
    part.x > t.x 
    and part.x - t.x < t.width 
    and part.y > t.y and
    part.y - t.y < t.height
   ) then
    -- particle sits on top of the collider
    return {0, - 1}
   end
  end,
  draw=function(t)
   rectfill(t.x, t.y, t.x + t.width, t.y + t.height, 11)
  end
 }
}

function make_particle_manager()
 particle_array, particle_array_length = {}, 0

 return {
  x=0,
  y=0,
  draw=function(t)
   process_particles(sp_world)
  end
 }
end
-- }

-- {
function cell_is_empty(cell)
--  if not cell then
--   return true
--  end
--
 return cell.contains == nil
end
-- }

-- { A* pathfinding
function _pop_lowest_rank_in(some_list)
 local lowest = some_list[1]
 local lowest_rank = lowest[2]

 for _, v in pairs(some_list) do
  if v[2] < lowest_rank then
   lowest = v
   lowest_rank = lowest[2]
  end
 end

 del(some_list, lowest)

 return lowest[1]
end

function distance_to_target_cell_heuristic(from, to)
--  local d = vecabs(vecsub(from_cell.grid_loc, to_cell.grid_loc))

--  return (d.x+d.y)
 return (
  abs(to.x - from.x) +
  abs(to.y - from.y)
 )
end

function next_move(from_cell, to_cell)
 return compute_path(from_cell, to_cell)[from_cell]
end

function compute_path(from_cell, to_cell)
 local frontier = {{from_cell, 0}}

 local came_from = {}
 came_from[from_cell] = nil

 local cost_so_far = {}
 cost_so_far[from_cell] = 0

--  local move_cost = 1

--  local current_cell = nil

 while #frontier > 0 do
  local current_cell = _pop_lowest_rank_in(frontier)

  if current_cell == to_cell then
   break
  end

  local new_cost = cost_so_far[current_cell] + 1

  -- XXX:  in order to opimize this more, I think I'd have to switch to using
  --       a single int (the index of the cell in the flat_cells list) to 
  --       refer to the cell, rather than adding the cell object itself to
  --       things.  that would make all the indices ints and all the cell 
  --       comparisons ints
  --       its turn based, so this should be good enough for now.

  for _, next in pairs(current_cell.neighbors) do
   if (
    cost_so_far[next] == nil or new_cost < cost_so_far[next]
   )
   and
   (
    next.contains == nil or next == to_cell
   )
    then
    came_from[next] = current_cell
    cost_so_far[next] = new_cost
    add(
     frontier, 
     {
      next,
      new_cost + distance_to_target_cell_heuristic(
       next.grid_loc,
       to_cell.grid_loc
      )
     }
    )
   end
  end
 end

 -- reverse the path
 local next = to_cell
 local result_path = {}
 repeat
  local next_from = came_from[next]
  result_path[next_from] = next
  next = next_from
 until (next == from_cell)

 return result_path
end
-- }

function _init()
 stdinit()
 g_turn = 1

 -- for iteration, go straight to game state
 game_start()
 --[[
 add_gobjs(
   make_menu(
   {
    'go',
   },
   function (t, i, s)
    add (
     s,
     make_trans(
     function()
      game_start()
     end
     )
    )
   end
  )
 )
 --]]
end

function _update()
 stdupdate()
end

function _draw()
 stddraw()
end

-- coordinate systems
sp_world = 0
sp_local = 1
sp_screen_native = 2
sp_screen_center = 3

-- @{ Useful utility function for getting started
function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end
-- @}


-- enum
G_STATE = ge_state_enemy_turn
ge_state_player_input = 1
ge_state_enemy_turn = 2

ge_obj_player = 1
ge_obj_goon = 2

ge_obj_chair = 10

function interact(obj, target_cell)
 if not target_cell.contains then
  target_cell:now_contains(obj)
  return
 end

 local other_obj = target_cell.contains

 add(g_board.cobjs, make_dust(target_cell, true))
 
 -- check to see if a goon is in the target_cell
 other_obj:attack(obj)
end

-- returns whether it could move or not
function move_obj_in_dir(obj, dir)
 if dir and (dir.x != 0 or dir.y != 0) then
  next_cell = vecgetcell(vecadd(dir, obj.grid_loc))
  if next_cell then
   add(g_board.cobjs,make_dust(obj.contained_by))
   interact(obj, next_cell)
   return true
  end
 end
 return false
end

-- @{ built in diagnostic stuff
function make_player(p)
 local thing = {
  x=0,
  y=0,
  p=p,
  obj_type=ge_obj_player,
  grid_loc=vecmake(1),
  space=sp_world,
  c_objs={},
  actions_remaining=2,
  update=function(t)
   if G_STATE == ge_state_player_input then
    -- move cells
    local next_cell = vecmake()
    if btnn(0, t.p) then
     next_cell.x = -1
    end 
    if btnn(1, t.p) then
     next_cell.x = 1
    end
    if btnn(2, t.p) then
     next_cell.y = -1
    end
    if btnn(3, t.p) then
     next_cell.y = 1
    end

    if next_cell.x != 0 or next_cell.y != 0 then
     t.actions_remaining -= 1
    end

    if t.actions_remaining == 0 then
     G_STATE = ge_state_enemy_turn
     g_turn += 1
    end

    move_obj_in_dir(t, next_cell)
   else
    -- enemies make one move and then player can input again
    G_STATE = ge_state_player_input
    t.actions_remaining = 2
   end

   updateobjs(t.c_objs)
  end,
  draw=function(t)
   -- spr(2, -3, -3)
   spr(5, 0,0)
   -- rect(-3,-3, 3,3, 8)
   -- local str = "world: " .. t.x .. ", " .. t.y
   -- print(str, -(#str)*2, 12, 8)
   -- local str = "grid: " .. t.grid_loc.x .. ", " .. t.grid_loc.y
   -- print(str, -(#str)*2, 18, 8)
   drawobjs(t.c_objs)
  end,
  attack=function(t, attacker)
   _init()
  end,
 }

 vecgetcell(thing.grid_loc):now_contains(thing)

 return thing
end

function make_camera()
 return {
  x=0,
  y=0,
  update=function(t)
   t.x=g_p1.x
   t.y=g_p1.y
  end,
  draw=function(t)
  end
 }
end

function vecdrawrect(start_p, end_p, c, fill)
 if fill then
  rectfill(start_p.x, start_p.y, end_p.x, end_p.y, c)
 else
  rect(start_p.x, start_p.y, end_p.x, end_p.y, c)
 end
end

-- @}

function getcell(x,y)
 return vecgetcell(vecmake(x,y))
end

function vecgetcell(loc)
 if (
  loc.x < g_board.grid_dimensions.x+1 and loc.x > 0 and
  loc.y < g_board.grid_dimensions.y+1 and loc.y > 0
 ) then
  return g_board.cells[loc.x][loc.y]
 end
 return nil
end

function make_cell(i, j)
 return {
  x = 9*i+2,
  y = 9*j+2,
  contains = nil,
  grid_loc=vecmake(i,j),
  now_contains=function(t, other)
   if other.contained_by and other.contained_by.contains then
    other.contained_by.contains = nil
   end
   t.contains = other
   other.contained_by = t
   vecset(other, t)
   vecset(other.grid_loc, vecmake(i,j))
  end,
  draw=function(t)
   vecdrawrect(null_v, vecmake(7,7), 5)
  end,
 }
end

function make_goon(c)
 return {
  x=0,
  y=0,
  grid_loc=vecmake(),
  obj_type=ge_obj_goon,
  space=sp_world,
  attack=function(t, attacker)
   if attacker.obj_type == ge_obj_goon then
    return
   end

   -- and leave behind corpse...
   local new_corpse = g_board:spawn_thing(make_chair(38), t.contained_by)
   new_corpse:attack(attacker)

   -- if attacked, enemy is killed
   t.contained_by:now_contains(attacker)
   g_board:remove(t)
  end,
  update=function(t)
   if G_STATE == ge_state_enemy_turn then
    local next_cell = next_move(t.contained_by, g_p1.contained_by)
    move_obj_in_dir(t, vecsub(next_cell.grid_loc, t.grid_loc))
   end
  end,
  draw=function(t)
   -- local next_cell = next_move(t.contained_by, g_p1.contained_by)

   palt(0, false)
   spr(37,0,0)
   palt()
   -- rect(0,0,8,8,11)
   -- if next_cell != nil then
    -- local n = vecsub(next_cell, t.contained_by)
    -- rectfill(n.x, n.y, n.x + 7, n.y+7, 11)
    -- for _, next_cell in pairs(path) do
    --  local n = vecsub(next_cell, t.contained_by)
    --  rectfill(n.x, n.y, n.x + 7, n.y+7, c)
    -- end
   -- end
  end
 }
end

function make_dust(loc, is_pop)
 local offsets={}
 for i=1,3 do
  add(offsets, {rnd(7), rnd(7)})
 end
 return {
  x=loc.x,
  y=loc.y,
  is_pop = is_pop,
  space=sp_local,
  start=g_tick,
  offsets=offsets,
  showing=#offsets,
  update=function(t)
   local e = elapsed(t.start)
   local alive =10
   if t.is_pop then
    alive = 5
   end
   if e > alive then
    del(g_board.cobjs, t)
   end
   if e % 3 == 0 then
    t.showing -= 1
   end
  end,
  draw=function(t)
   local size = 1
   local col = 6
   if t.is_pop then
    size = 4
    col = 9
   end
   for i=1,#t.offsets do
    if i <= t.showing then
     local o = t.offsets[i]
     rectfill(o[1],o[2],o[1]+size,o[2]+size,col)
    end
   end
  end
 }
end

function make_chair(sprnum)
 return {
  x=0,
  y=0,
  grid_loc=vecmake(),
  obj_type=ge_obj_chair,
  space=sp_world,
  sprnum=sprnum,

  -- for being kicked
  target_cell=nil,
  kick_distance=nil,
  kick_dir = nil,

  update=function(t)
   if t.kick_distance == nil then
    return
   end

   -- reset kick stuff
   if t.kick_distance <= 0 then
    t.kick_distance = nil
    t.kick_dir = nil
    return
   end

   local could_move = move_obj_in_dir(t, t.kick_dir)
   t.kick_distance -= 1

   if not could_move then
    g_board:remove(t)
   end
   -- if not animating, done
   -- if animating and on final frame, move into target cell
  end,
  attack=function(t, attacker)
   -- start out moving four squares when kicked
   t.kick_dir = vecsub(t.grid_loc, attacker.grid_loc)
   t.kick_distance = 4
  end,
  draw=function(t)
   -- spr(10,0,0)

   palt(0, false)
    
   if not t.sprnum then
    print("c", 1, 1, 4)
   else
    spr(t.sprnum,0,0)
   end

   palt()
  end
 }
end

WALL_MARKER = 52

function find_board_dimensions()
 -- read the board dimensions
 local block_start = vecmake()
 local block_end = vecmake()

 local start_index = vecmget(block_end)

 if (start_index != WALL_MARKER) then
  cls()
  print("error, start_index is: "..start_index)
  stop()
 end

 local found = false
 for i=block_end.x+1,128 do
  for j=block_end.y,32 do
   local current_block = mget(i, j)
   if current_block == WALL_MARKER then
    block_end = vecmake(i,j)
    break
   end
  end
 end

 return vecsub(vecsub(block_end, block_start), vecmake(1))
end

function make_board()
 -- original debug board dimension
--  BOARD_DIM = vecmake(24, 18)
 BOARD_DIM = find_board_dimensions()


--  cls()
--  print(vecrepr(BOARD_DIM))
--  stop()


 local cells = {}
 local flat_cells = {}
 -- row
 for i=1,BOARD_DIM.x do
  add(cells, {})
  -- column
  for j=1,BOARD_DIM.y do
   new_cell = add(cells[i], make_cell(i,j))
   add(flat_cells, new_cell)
  end
 end

 local board = {
  x=0,
  y=0,
  space=sp_world,
  cells=cells,
  flat_cells = flat_cells,
  cobjs={},
  grid_dimensions = BOARD_DIM,
  -- goes from (0,0)
  grid_dimensions_world = vecmake((BOARD_DIM.x+1)*9+2, (BOARD_DIM.y+1)*9+2),
  remove=function(t, obj)
   if obj.contained_by and obj.contained_by.contains == t then
    obj.contained_by.contains = nil
    obj.contained_by = nil
   end
   del(g_objs, obj)
  end,
  update=function(t)
   updateobjs(t.cobjs)
  end,
  random_empty_cell=function(t)
   local next_cell = nil
   repeat
    local i = flr(rnd(t.grid_dimensions.x)) + 1
    local j = flr(rnd(t.grid_dimensions.y)) + 1
    next_cell = t.cells[i][j]

   until (next_cell.contains == nil)
   return next_cell
  end,
  spawn_thing=function(t, new_thing, cell)
   cell:now_contains(new_thing)
   add_gobjs(new_thing)
   return new_thing
  end,
  spawn_things_randomly=function(t, num_to_spawn, cons)
   for i=1,num_to_spawn do
    -- pick a location
    local cell = t:random_empty_cell()
    if cell then
     local new_thing = cons()
     cell:now_contains(new_thing)
     add_gobjs(new_thing)
    end
   end
  end,
  read_map_data=function(t)
   for c in all(t.flat_cells) do
    -- read sprite
    local map_loc = c.grid_loc
    local map_ind = vecmget(map_loc)
    if map_ind != 0 then
     local cons_tbl = SPR_CONS_MAP[map_ind]
     if cons_tbl then
      local new_thing = cons_tbl[1]()
      c:now_contains(new_thing)
      if cons_tbl[2] then
       add_gobjs(new_thing)
      end
     end
     -- cls()
     -- print(map_ind)
     -- stop()
    end
   end
  end,
  draw=function(t)
   -- draw the border
   vecdrawrect(vecmake(8), t.grid_dimensions_world, 2)

   drawobjs(t.flat_cells)
   drawobjs(t.cobjs)
  end
 }

 for c in all(board.flat_cells) do
   c.neighbors = {}
   local i= c.grid_loc.x
   local j= c.grid_loc.y
   if i > 1 then
    add(c.neighbors,board.cells[i-1][j])
   end
   if i < BOARD_DIM.x then
    add(c.neighbors,board.cells[i+1][j])
   end
   if j > 1 then
    add(c.neighbors,board.cells[i][j-1])
   end
   if j < BOARD_DIM.y then
    add(c.neighbors,board.cells[i][j+1])
   end
 end
 
 return board
end

function make_hud()
 return {
  x=0,
  y=0,
  space=sp_screen_center,
  draw=function(t)
   -- vecdrawrect(vecmake(-10,50), vecmake(26, 56), 5, true)
   rectfill(-10,50, 26, 56, 5)
   print("actions:"..g_p1.actions_remaining, -9, 51, 7)
   rect(-11,49, 27, 57, 7)

   rectfill(-10,-50, 26, -56, 5)
   print("turn:"..g_turn, -9, -55, 7)
   rect(-11,-49, 27, -57, 7)
  end
 }
end

function get_player()
 return g_p1
end

-- map of sprite to constructor
SPR_CONS_MAP = {}
SPR_CONS_MAP[37] = {make_goon, true}
SPR_CONS_MAP[5]  = {get_player, false}
SPR_CONS_MAP[10] = {make_chair, true}

function game_start()
 g_objs = {
 }

 g_board = add_gobjs(make_board())
 g_cam= add_gobjs(make_camera())
 g_p1 = add_gobjs(make_player(0))
 g_board:read_map_data()
 -- make some goons and some furniture
--  local g = add_gobjs(make_goon(11))
--  getcell(7,7):now_contains(g)

--  local g = add_gobjs(make_goon(12))
--  getcell(BOARD_DIM.x, BOARD_DIM.y):now_contains(g)
 
--  g_board:spawn_things_randomly(10, make_goon)
--  g_board:spawn_things_randomly(40, make_chair)

 g_hud = add_gobjs(make_hud())

--  local c = add_gobjs(make_chair())
--  getcell(3, 2):now_contains(c)
--
--  local c = add_gobjs(make_chair())
--  getcell(4, 4):now_contains(c)
--
--  local c = add_gobjs(make_chair())
--  getcell(7, 7):now_contains(c)
--
 add_gobjs(make_debugmsg())



--  g_brd = make_board()
--  add(g_objs, g_brd)
--  g_tgt = make_tgt(0,0)
--  add(g_objs,g_tgt)
end

------------------------------

function stdinit()
 g_tick=0    --time
 g_ct=0      --controllers
 g_ctl=0     --last controllers
 g_cs = {}   --camera stack 
 g_objs = {} --objects

end

function stdupdate()
 g_tick = max(0,g_tick+1)
 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()
 updateobjs(g_objs)
end

function updateobjs(objs)
 foreach(objs, function(t)
  if t.update then
   t:update(objs)
  end
 end)
end

function stddraw()
 cls()
 drawobjs(g_objs)
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   local cam_stack = 0

   -- i think the idea here is that if you're only drawing local,
   -- then you only need to push -t.x, -t.y
   -- if you're drawing camera space, then the camera will manage the screen
   -- center offset
   -- if you're drawing screen center 
   if t.space == sp_screen_center then
    pushc(-64, -64)
    cam_stack += 1
   elseif t.space == sp_world and g_cam  then
    pushc(g_cam.x - 64, g_cam.y - 64)
    pushc(-t.x, -t.y)
    cam_stack += 2
   elseif not t.space or t.space == sp_local then
    pushc(-t.x, -t.y)
    cam_stack += 1
   elseif t.space == sp_screen_native then
   end

   t:draw(objs)

   for i=1,cam_stack do
    popc()
   end
  end
 end)
end

--returns state,changed
function btns(i,p)
 i=shl(1,i)
 if p==1 then
  i=shl(i,8)
 end
 local c,cng =
   band(i,g_ct),
   band(i,g_ctl)
 return c>0,c~=cng
end

--returns new press only
function btnn(i,p)
 if p==-1 then --either
  return btnn(i,0) or btnn(i,1)
 end
 local pr,chg=btns(i,p)
 return pr and chg
end

function getspraddr(n)
 return flr(n/16)*512+(n%16)*4
end

function sprcpy(dst,src,w,h)
 w = w or 1
 h = h or 1
 for i=0,h*8-1 do
  memcpy(getspraddr(dst)+64*i,
     getspraddr(src)+64*i,4*w)
 end
end

function pushc(x, y)
 local l=g_cs[#g_cs] or {0,0}
 local n={l[1]+x,l[2]+y}
 add(g_cs, n)
 camera(n[1], n[2])
end

function popc()
 local len = #g_cs
 g_cs[len] = nil
 len -= 1
 if len > 0 then
  local xy=g_cs[len]
  camera(xy[1],xy[2])
 else
  camera()
 end
end

function make_menu(
 lbs, --menu lables
 fnc, --chosen callback
 x,y, --pos
 omb, --omit backdrop
 p,   --player
 cfnc --cancel callback
)
 local m={
  --lbs=lbs,
  --f=fnc,
  --fc=cfnc,
  i=0, --item
  s=g_tick,
  e=5,
  x=x or 64,
  y=y or 80,
  h=10*#lbs+4,
  --omb=omb,
  tw=0,--text width
  p=p or -1,
  draw=function(t)
   local e=elapsed(t.s)
   local w=t.tw*4+10
   local x=min(1,e/t.e)*(w+9)/2
   if not omb then
    rectfill(-x,0,x,t.h,0)
    rect(-x,0,x,t.h,1)
   end
   if e<t.e then
    return
   end
   x=w/2+1
   for i,l in pairs(lbs) do
    if not t.off or i==t.i+1 then
     local y=4+(i-1)*10
     print(l,-x+9,y+1,0)
     print(l,-x+9,y,7)
    end
   end
   spr(0,-x,2+10*t.i)
  end,
  update=function(t,s)
   if (t.off) return
   if elapsed(t.s)<(t.e*2) then
    return
   end

   if btnn(5,t.p) then
    if fnc then
     fnc(t,t.i,s)
     --sfx(2)
    end
   end

   --cancel
   if btnn(4,t.p) then
    if cfnc then
     cfnc(t,s)
     --sfx(2)
    end
   end

   if btnn(2,t.p) and
     t.i>0 then
    t.i-=1
    sfx(1)
   end
   if btnn(3,t.p) and
     t.i<(#lbs-1) then
    t.i+=1
    sfx(1)
   end
  end
 }
 for l in all(lbs) do
  m.tw=max(m.tw,#l)
 end
 return m
end

function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
end

function trans(s)
 if (s<1) return
 s=2^s
 local b,m,o =
   0x6000,
   15,
   s/2-1+(32*s)

 for y=0,128-s,s do
  for x=0,128-s,s do
   local a=b+x/2
   local c=band(peek(a+o),m)
   c=bor(c,shl(c,4))
   for i=1,s do
    memset(a,c,s/2)
    a+=64
   end
  end
  b+=s*64
 end
end

function make_trans(f,d,i)
 return {
  d=d,
  e=g_tick,
  f=f,
  i=i,
  x=0,
  y=0,
  update=function(t,s)
   if elapsed(t.e)>10 then
    if (t.f) t:f(s)
    del(s,t)
    if not t.i then
     add(s,
       make_trans(nil,nil,1))
    end
   end
  end,
  draw=function(t)
   local x=flr(elapsed(t.e)/2)
   if t.i then
    x=5-x
   end
   trans(x)
  end
 }
end
-- @{ vector library
function vecdraw(v, c, scale, o)
 o = o or null_v

 local end_point = vecadd(o, vecscale(v, scale or 30))
 line(o.x, o.y, end_point.x, end_point.y, c)
 return
end

function rnd_centered(max_val)
 return rnd(max_val)-(max_val/2)
end

function vecrand(scale, center, yscale)
 local result = vecmake(rnd(scale), rnd(yscale or scale))
 if center then
  result = vecsub(result, vecmake(scale/2, (yscale or scale)/2))
 end
 return result
end

function vecrepr(v)
 return "("..v.x..", "..v.y..")"
end

function vecmget(v)
 return mget(v.x, v.y)
end

function vecmake(xf, yf)
 xf = xf or 0

 return {x=xf, y=(yf or xf)}
end

function veccopy(tgt)
 return vecmake(tgt.x, tgt.y)
end

-- global null vector
null_v = vecmake()

function vecscale(v, m)
 return {x=v.x*m, y=v.y*m}
end

function vecmagsq(v)
 return v.x*v.x+v.y*v.y
end

function vecmag(v, sf)
 if sf then
  v = vecscale(v, sf)
 end
 local result=sqrt(vecmagsq(v))
 if sf then
  result=result/sf
 end
 return result
end

-- function vecnormalized(v)
--  return vecscale(v, 1/vecmag(v))
-- end

function vecdot(a, b)
 return (a.x*b.x+a.y*b.y)
end

function vecadd(a, b)
 return {x=a.x+b.x, y=a.y+b.y}
end

function vecsub(a, b)
 return {x=a.x-b.x, y=a.y-b.y}
end

function vecabs(v)
 return vecmake(abs(v.x), abs(v.y))
end

function vecflr(a)
 return vecmake(flr(a.x), flr(a.y))
end

function vecset(target, source)
 target.x = source.x
 target.y = source.y
end

-- function vecminvec(target, minvec)
--  target.x = min(target.x, minvec.x)
--  target.y = min(target.y, minvec.y)
--  return target
-- end

-- function vecmaxvec(target, maxvec)
--  target.x = max(target.x, maxvec.x)
--  target.y = max(target.y, maxvec.y)
--  return target
-- end

function vecfromangle(angle, mag)
 mag = mag or 1.0
 return vecmake(mag*cos(angle), mag*sin(angle))
end

function veclerp(v1, v2, amount, clamp)
 -- tokens: can compress this with ternary
 local result = vecadd(vecscale(vecsub(v2,v1),amount),v1)
 if clamp and vecmag((vecsub(result,v2))) < clamp then
  result = v2
 end
 return result
end

function clamp(v, min_v, max_v)
 return min(max(v, min_v or 0), max_v or 1)
end

function vecclamp(v, min_v, max_v)
 return vecmake(
  clamp(v.x, min_v.x, max_v.x),
  clamp(v.y, min_v.y, max_v.y)
 )
end
-- @}

__gfx__
00600000101221010000000033000330000000009911911960633333000000000000000000000000040000000000000000000000000000000000000000000000
0066000000088000000c000030000030000000009999999907033333000000000000000000000000040000000000000000000000000000000000000000000000
0066600010033001000c000000000000000000009776977660633333000000000000000000000000040000000000000000000000000000000000000000000000
00666600283083820cc8cc000003000000000000976d976d33333333000000000000000000000000040000000000000000000000000000000000000000000000
0066650028380382000c000000000000000000009666966633333333000000000000000000000000044444000000000000000000000000000000000000000000
0066500010033001000c000030000030000000009999999933333333000000000000000000000000040004000000000000000000000000000000000000000000
00650000000880000000000033000330000000009911119933333333000000000000000000000000040004000000000000000000000000000000000000000000
00500000101221010000000000000000000000009999999933333333000000000000000000000000000000000000000000000000000000000000000000000000
0000001cccccccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c11111111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c100000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001c00000000c1000000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000001cc100000000000000000000009999999999999999000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000111100000000000000000000008888888820202020000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008770877022022202000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008666866620202020000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999999999000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008999999929999999000000000000000000000000000000000000000000000000000000000000000000000000
00000011000000000000000011000000000000008899999822999992000000000000000000000000000000000000000000000000000000000000000000000000
0000001c0000000000000000c1000000000000008889998822299922000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111111110000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000181118110000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000182118210000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000182118210000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000182118218888888800800000888888880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000182818210000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000188888210000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000112222210000000000800000008000000000000000000000000000000000000000000000000000000000000000000000
__map__
3435353535353700000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
360500000a253610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3735353535353400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344


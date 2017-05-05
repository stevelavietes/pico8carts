pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

cartdata("pushback_high_scores")
alphabet = "abcdefghijklmnopqrstuvwxyz "

-- function clear_scores()
--  for i=0,63 do
--   dset(i, 1)
--  end
-- end
-- clear_scores()

-- next iteration:
--     - [tabled] facial expression on goon
--     - some way to get health back (heart box)
--     - super pellet?

function make_rain(x, y, angle, length, col, speed)
 local start=g_tick
 return {
  x=x,
  y=y,
  space=sp_screen_native,
  angle=angle,
  length=length,
  to_x = length*cos(angle),
  to_y = length*sin(angle),
  col=col,
  speed=speed,
  offset=0,
  update=function(t)
   t.offset=t.speed*elapsed(start_rain)
  end,
  draw=function(t)
   local x=t.x
   local y=(t.offset+t.y)%128

   line(
    x,
    y,
    x+t.to_x,
    y+t.to_y,
    t.col
   )
  end
 }
end

function make_title()
 start_rain = g_tick
 local speeds={0.4,1.4}
 for i=0,50 do
  local speed=speeds[flr(rnd(2))+1]
  add_gobjs(
   make_rain(rnd(128), rnd(128), 0.25, 4, 1, rnd(1)+speed)
 )
 end
 add_gobjs({
  x=30,
  y=20,
  created=g_tick,
  off_right_x = 2,
  off_right_y = 1,
  off_left_x = -2,
  off_left_y = -1,
  next_flash=300+flr(rnd(60)),
  update=function(t)
   local flash_mod = elapsed(t.created) % t.next_flash
   if flash_mod == 0 or flash_mod == 10 then
    g_state = st_freeze
    g_freeze_frame = g_tick
    g_freeze_framecount = rnd(6)

    if elapsed(t.created) % t.next_flash == 10 then
     t.next_flash = 300 + flr(rnd(60))
    end
   end
  end,
  draw=function(t)
   -- background
   rectfill(-t.x, 33, 124-t.x, 58, 11)
   rectfill(-t.x, 34, 124-t.x, 57, 0)

   -- title text
   for i=0,4 do
    sspr(i*8, 32, 8, 8, i*14, 0, 16, 16)
    sspr(i*8, 40, 8, 8, i*14, 16, 16, 16)
   end

   local amount = elapsed(t.created) / 240
   local off = 10*sin(amount)
   local off_pre = 10*sin(elapsed(t.created+10)/240)
   local off_post = 10*sin(elapsed(t.created-18)/240)
   local s = 9
   local grimace=sin(1.25*amount)
   local eye_dart = cos(2.5*amount)
   if grimace > 0.25 then
    eye_dart = cos(6.5*amount)
    s = 10
   end

   local eye_dir = 13
   if eye_dart > 0 then
    eye_dir = 15
   end
   for i=12,15 do
    local c = 7
    if i > 13 then
     c = 6
    end
    if i == eye_dir then
     c = 1
    end
    if s != 12 then
     pal(i, c)
    end
   end

   local y_off = 43
   for i=2,5 do
    pal(i, 8)
   end
   spr(s, 24+off, y_off)
   pal()

   -- green block
   spr(g_pusher_sprite,24+off_pre+20, y_off)
   spr(g_pusher_sprite,24+off_post-20, y_off)

   -- goons
   local off_pre = 10*sin(elapsed(t.created+15)/240)
   pushc(-(24+off_pre+30+t.off_right_x), -(y_off+t.off_right_y))
   draw_goon()
   popc()

   local off_post = 10*sin(elapsed(t.created-21)/240)
   pushc(-(24+off_post-30+t.off_left_x),- (y_off+t.off_left_y))
   draw_goon()
   popc()
  end
 })
 local speeds={2.4,4.4}
 for i=0,10 do
  local speed=speeds[flr(rnd(2))+1]
  add_gobjs(
   make_rain(rnd(128), rnd(128), 0.25, 4, 6, rnd(1)+speed)
  )
 end
end

function _init()
 stdinit()

 make_title()
 add_gobjs(
   make_menu(
   {
    'go',
    'high scores',
   },
   function (t, i, s)
    add (
     s,
     make_trans(
     function()
      if i == 0 then
       game_start()
      else
       g_current_score = 10
       add_gobjs(make_high_score_list())
      end
     end
     )
    )
   end
  )
 )
end

function _update60()
 stdupdate()
end

function color_opaque_pixels(tgt_color)
 local lines_to_color = 127
 local frames_elapsed = 0
 if g_dying and g_freeze_frame then
  frames_elapsed = elapsed(g_freeze_frame)
  lines_to_color = rescale(frames_elapsed, 0, g_freeze_framecount, 0, 127)
 end
 for i=0,127 do
  for j=0,lines_to_color do
   local c = pget(i, j)
   if c != 0 then
    pset(i, j, tgt_color)
   end
  end
 end
end

function _draw()
 stddraw()
 if g_state == st_freeze then
  targetc = 7
  if g_dying then
   targetc = 2
  end
  color_opaque_pixels(targetc)
 else
  if g_being_attacked then
   color_opaque_pixels(8)
   if elapsed(g_being_attacked) > 3 then
    g_being_attacked = false
   end
  end
 end

 -- frozen objects draw after color operations
 drawobjs(g_frozen_objs)
end

-- coordinate systems
sp_world = 0
sp_local = 1
sp_screen_native = 2
sp_screen_center = 3

-- @{ useful utility function for getting started
function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end
-- @}

function make_cell(x,y)
 return {
  x=1+9*(x-1)+1,
  y=1+9*(y-1)+1,
  space=sp_local,
  grid_x=x,
  grid_y=y,
  containing=nil,
  world_coords=function(t, from_center)
   local result = vecadd(g_board, t)
   if from_center == true then
    result = vecadd(result, vecmake(3,3))
   end
   return result
  end,
  mark_for_contain=function(t, c, amt)
   t.containing = c
   if c.container then
    c.container.containing = nil
   end
   mark_for_move(c, t, amt)
   c.container = t
  end,
  draw=function(t)
   rect(0,0,7,7, 5)
  end
 }
end

function make_goon(x, y)
 -- goons are red for now
 local newgoon = make_merge_box(8)
 g_board:mark_cell_for_contain(x, y, newgoon, 1)
 add(g_board.watch_cells, newgoon)
 newgoon.time_last_move = g_tick
 newgoon.shiftable = ss_pushable
 newgoon.brain = br_move_at_player
 g_goon_count += 1
 return newgoon
end

function _pop_lowest_rank_in(some_list)
 local lowest = some_list[1]
 local lowest_rank = lowest.rank

 for i=2,#some_list do
  if some_list[i].rank < lowest_rank then
   lowest = some_list[i]
   lowest_rank = lowest.rank
  end
 end

 del(some_list, lowest)

 return lowest.cell
end

function neighbor_cells_of(x, y)
 local neighbors = {}
 -- + - x
 if x > 1 then
  add(neighbors, g_board.all_cells[x - 1][y])
 end
 if x < g_board.size_x then
  add(neighbors, g_board.all_cells[x + 1][y])
 end
 -- + - y
 if y > 1 then
  add(neighbors, g_board.all_cells[x][y - 1])
 end
 if y < g_board.size_y then
  add(neighbors, g_board.all_cells[x][y + 1])
 end

 return neighbors
end

function distance_to_player_heuristic(from_cell)
 local dx = abs(from_cell.grid_x - g_player_piece.grid_x)
 local dy = abs(from_cell.grid_y - g_player_piece.grid_y)

 return (dx+dy)
end

function tprint(str)
 local tcurrent = time()
 print(str..": "..tcurrent-tlast)
 tlast = tcurrent
end

function compute_path(from_cell, to_cell)
 local frontier = {{cell=from_cell, rank=0}}
 local came_from = {}
 local cost_so_far = {}
 came_from[from_cell] = nil
 cost_so_far[from_cell] = 0

 local move_cost = 1

 while  #frontier > 0 do
  local current_cell = _pop_lowest_rank_in(frontier)

  if current_cell == to_cell then
   if came_from[to_cell] == nil then
    cls()
    print("bad_path")
    asdf()
   end
   return came_from, cost_so_far
  end

  local new_cost = cost_so_far[current_cell] + move_cost

  for _, next in pairs(current_cell.neighbors) do
   if (
    not (cell_is_not_empty(next) and next != to_cell)
   )
   and 
   (
    cost_so_far[next] == nil or new_cost < cost_so_far[next]
   ) then
    cost_so_far[next] = new_cost
    local priority = new_cost + distance_to_player_heuristic(to_cell, next)
    add(frontier, {cell=next, rank=priority})
    came_from[next] = current_cell
   end
  end
 end

 return came_from, cost_so_far
end

function make_lose(t)
 -- freeze the screen -- make trans back to menu?
 -- @todo: better feedback that game is over
 g_state = st_freeze
 g_freeze_frame = g_tick
 g_freeze_framecount = 240
 g_dying = true

 add(g_frozen_objs,make_text(16, 6))
 add_gobjs(make_trans(function() _game_over() end))
end

function rescale(current, from_low, from_hi, to_low, to_hi)
 if not to_hi then
  to_hi = 1
 end
 if not to_low then
  to_low = 0
 end

 clamp(current, from_low, from_hi)

 return (((current - from_low) / (from_hi - from_low)) * (to_hi - to_low) + to_low)
end

function make_game_over_screen(score)
 return {
  x=-20,
  y=-6,
  space=sp_screen_center,
  draw=function(t)
   rect(0, 0, 38, 14, 8)
   print("game over", 2, 2, 2)
   print("score: "..score, 2, 8, 12)
  end
 }
end

function find_new_score_loc(scores, score)
 if #scores >= 5 and scores[5][2] >= score then
  return nil
 end

 ind = 1
 for scr_tpl in all(scores) do
  if score > scr_tpl[2] then
   return ind
  end
  ind += 1
 end

 return ind
end

function load_high_score_table()
 local highscore_table = {}

 -- initials
 for entry=0, 19, 4 do
  local initials = ""
  for i=0, 2 do
   local current = dget(entry+i)
   initials = initials .. sub(alphabet, current, current)
  end
  local score = dget(entry+3) 
  add(highscore_table, {initials, score})
 end
 return highscore_table
end

function save_score(scores, new_score_loc, initials, score)
 new_scores = {}
 for i=1, max(#scores, new_score_loc) do
  if i == new_score_loc then
   add(new_scores, {initials, score})
   -- print(i..": ".."new: "..initials[1]..initials[2]..initials[3].. " ".. score)
  end

  if i <= #scores then
   add(new_scores, {intified(scores[i][1]), scores[i][2]})
   -- print(i..": "..scores[i][1])
  end
 end
 for i=1, #new_scores do
  for l=0,2 do
   dset(4*(i-1)+l, new_scores[i][1][l+1])
   -- print((i-1)*4+l)
  end
  dset(4*(i-1)+3, new_scores[i][2])
   -- print(3+(i-1)*4)
 end
end

function make_enter_score(score)
 -- load the previous high scores
 local scores = load_high_score_table()
 local new_score_loc = find_new_score_loc(scores, score)

 -- assume that score saved to table is sorted
 if not new_score_loc then
  -- show high score list
  add_gobjs(make_retry(np))
  add_gobjs(make_high_score_list(scores))
  return
 end

 return {
  x=0,
  y=0,
  initials = {1, 1, 1},
  initial_str="aaa",
  current_letter=0,
  update=function(t)
   if btnn(0) then 
    t.current_letter = max(t.current_letter - 1, 0)
   end
   if btnn(1) then 
    t.current_letter = min(t.current_letter + 1, 3)
   end
   -- down
   if t.current_letter < 3 then
    if btnn(3) then
     t.initials[t.current_letter + 1] = min(
      27,
      t.initials[t.current_letter+1] + 1
     )
     if t.initials[t.current_letter + 1] == 27 then
      t.initials[t.current_letter + 1] = 1
     end
    end
    -- up
    if btnn(2) then
     t.initials[t.current_letter + 1] = max(
      0,
      t.initials[t.current_letter+1] - 1
     )
     if t.initials[t.current_letter + 1] == 0 then
      t.initials[t.current_letter + 1] = 26 
     end
    end
   else
    if btnn(4) or btnn(5) then
     save_score(scores, new_score_loc, t.initials, score)
     add_gobjs(make_retry())
     add_gobjs(make_high_score_list())
     del(g_go, t)
    end
   end

   t.initial_str = ""
   for i=1,3 do
    t.initial_str = (t.initial_str..sub(alphabet, t.initials[i], t.initials[i]))
   end
  end,
  draw=function(t)
   -- background
   rect(45,79,90,96,0)
   rectfill(46,80,89,95,5)

   print(t.initial_str,55,82,12)
   print("high score!", 47, 90, 12)
   if t.current_letter == 3 then
    pal(1, 11)
   end
   spr(225, 67, 80, 2, 2)
   if t.current_letter == 3 then
    pal(1, 1)
   end
   -- cursor
   if t.current_letter < 3 then
    rect(54+4*t.current_letter, 81, 54+4*t.current_letter+4, 87, 11)
   end
  end
 }
end

function _game_over()
 local final_score = g_current_score
 reset()

 add_gobjs(make_enter_score(g_current_score))
end

function digits(num)
 local result = 1
 while (num/10 >= 1) do
  result += 1
  num = flr(num/10)
 end
 return result
end


function make_high_score_list(scores)
 if not scores then
  scores = load_high_score_table()
 end
 return {
  x=40,
  y=20,
  ndigits=digits(scores[1][2]),
  scores=scores,
  draw=function(t)
   cursor(0, 0)
   rectfill(0,0, 2+(8+t.ndigits)*4+3, 2+6*5-1, 5)
   rectfill(-1,-1, 3+(8+t.ndigits)*4, 2+6*5-2, 6)
   rect(-2,-2, 2+(8+t.ndigits)*4+2, 2+6*5-2, 0)
   for i, stuff in pairs(scores) do
    if i == 1 then
     color(8)
    else
     color(0)
    end
    print("["..i.."] "..stuff[1]..": "..stuff[2])
   end
  end
 }
end

function intified(str)
 result = {}
 for i=1,3 do
  for l=1,26 do
   if sub(str, i, i) == sub(alphabet, l, l) then
    add(result, l)
   end
  end
 end
 return result
end


function make_retry()
 add_gobjs(make_game_over_screen(g_current_score))
 add_gobjs(
  make_menu(
   {
    "play again",
    "main menu"
   },
   function (t, i, s)
    add(
     s,
     make_trans(
      function()
       if i == 0 then
        game_start()
       else
        _init()
       end
      end
     )
    )
   end
  )
 )
end

function attack_player()
 g_being_attacked = g_tick
--  g_freeze_frame = g_tick
--  g_state = st_freeze
--  g_freeze_framecount = 3
 shake_screen(15, 10, 3)
 g_health -= 1
end

function br_move_at_player(t)
 if t.attacking != nil and elapsed(t.attacking) % 60 == 0 then
  -- @todo: attack juice?
  attack_player(t)
 end
--  if t.attacking != nil and elapsed(t.attacking) > 90 then
--   -- trigger attack
--   add_gobjs(make_lose(g_player_piece.container:world_coords()))
--   t.attacking = nil
--  end

 local path, _ = compute_path(t.container, g_player_piece.container)

 -- attack if next to the player
 if path[g_player_piece.container] == t.container then
  if t.attacking == nil then
   t.attacking = g_tick
  end
 elseif t.attacking != nil then
  t.attacking = nil
  t.shake_offset = nil
 end

 if t.attacking then
  t.shake_offset = vecrand(2, true)
 end

 if elapsed(t.time_last_move) > 45 and true then
  t.time_last_move = g_tick
  local current = g_player_piece.container
  while path != {} and path[current] != nil do
   last = current
   current = path[current]
   del(path, current)
   if (
    path[current] == t.container 
    and current == g_player_piece.container 
    ) then
    return
   end
   if (
    path[current] == t.container 
    and current != g_player_piece.container 
   ) then
    current:mark_for_contain(t)
    return
   end
  end
 end
end

--[[
this needs to be refactored.  instead a "want to move" buffer, then sweep and
resolve approach should be used.
]]--
mark_for_move=function(t, to_cell, amt)
 if amt and amt == 1 then
  vecset(t, to_cell)
 else
  t.from_loc = vecmake(t.x, t.y)
  t.to_loc = vecmake(to_cell.x, to_cell.y)
  t.to_amount = amt or 0
  add(g_board.dust,make_dust(t.from_loc))
 end
 t.grid_x = to_cell.grid_x
 t.grid_y = to_cell.grid_y
end

-- shiftable
ss_inert     = 0
ss_shiftable = 1
ss_pushable  = 2

g_goon_sprite = 70
g_pusher_sprite = 74

function draw_goon()
 local spr_offset=0
 if g_tick % 10 <= 5 then 
  spr_offset=2
 end
 spr(g_goon_sprite+spr_offset, -4, -4,2,2)
end

function make_merge_box(col)
 return {
  x=0,
  y=0,
  space=sp_local,
  container=nil,
  to_amount=1,
  col = col,
  merge_blips=nil,
  shiftable=ss_shiftable,
  brain=nil,
  neighbor=function(t, inc_x, inc_y)
   return (
    g_board.all_cells[
     t.container.grid_x+inc_x
    ][
     t.container.grid_y+inc_y
    ].containing
  )
  end,
  merge_with=function(t, other, x_dir, y_dir)
   if other.chargeable then
    other:charge_with(t, x_dir, y_dir)
   end
  end,
  update=function(t)
   if t.brain then
    t:brain()
   end

   if t.from_loc and t.to_loc then
    -- if not t.merge_blips then
    --  t.merge_blips = {}
    --  for i=0,num_merge_blips-1 do
    --   local rnd_x = (rnd(2)-1)
    --   local rnd_y = (rnd(2)-1)
    --   add(t.merge_blips, vecmake(rnd_x, rnd_y))
    --  end
    -- end
    t.to_amount += 0.1

    local interp_amount = smootherstep(0, 1, t.to_amount)
    vecset(t, veclerp(t.from_loc, t.to_loc, interp_amount))

    if t.to_amount == 1 then
     t.from_loc = nil
     t.to_loc = nil
     t.merge_blips = nil
    end

    if t.col == 11 then
     t.shake_offset = nil
     for x_dir = -1, 1, 2 do
      if blocks_to_edge(t.container.grid_x, x_dir, 'x') == 1 then
       local next_block = g_board:block(t.container.grid_x + x_dir, t.container.grid_y)
       if next_block and next_block.col == 8 then
        t.shake_offset = vecrand(2, true)
       end
      end
     end
     for y_dir = -1, 1, 2 do
      if blocks_to_edge(t.container.grid_y, y_dir, 'y') == 1 then
       local next_block = g_board:block(t.container.grid_x, t.container.grid_y + y_dir)
       if next_block and next_block.col == 8 then
        t.shake_offset = vecrand(2, true)
       end
      end
     end
    end
   end
  end,
  kick=function(t, kick_dir)
   t.kick_dir = kick_dir
  end,
  draw=function(t)
   local offset = t.shake_offset
   if offset == nil then
    offset = null_v
   end

   pushc(offset.x, offset.y)

   if t.col != 8 then
    spr(g_pusher_sprite, 0, 0)
   else
    draw_goon()
   end

   popc(offset.x, offset.y)

   -- if t.merge_blips != nil then
   --  local amt = vecsub(t, t.from_loc)
   --  for b in all(t.merge_blips) do
   --   local new_loc = vecadd(amt, b)
   --   line(b.x, b.y, new_loc.x, new_loc.y)
   --  end
   -- end
  end
 }
end

function make_blast(start_block, color_block, x_dir, y_dir)
 return {
  x=start_block.x,
  y=start_block.y,
  col=color_block.col,
  start_frame=g_tick,
  space=sp_local,
  update=function(t)
   if elapsed(t.start_frame) > 60 then
    color_block.container.containing = nil
    color_block.controller = nil
    del(g_board.watch_cells, t)
    g_state = st_playing
   end
  end,
  draw=function(t)
   local start = vecmake(0,0)
   local vstop = vecmake(1, 1)

   -- four options
   if x_dir < 0 then
    start = vecmake(8, -1)
    vstop = vecmake(9+8*blocks_to_edge(start_block.grid_x, x_dir, 'x')+2, 8)
   elseif x_dir > 0 then
    start = vecmake(-1, -1)
    vstop = vecmake(-1-8*blocks_to_edge(start_block.grid_x, x_dir, 'x')-3, 8)
   elseif y_dir > 0 then
    start = vecmake(-1, -1)
    vstop = vecmake(8, -1-8*blocks_to_edge(start_block.grid_y, y_dir, 'y')-3)
   elseif y_dir < 0 then
    start = vecmake(-1, 8)
    vstop = vecmake(8, 9+8*blocks_to_edge(start_block.grid_y, y_dir, 'y')+2)
   end

   -- @todo: make this animate out after a short wait for juice
   --
   -- local interp_amount = smootherstep(0, 1, 1-elapsed(t.start_frame)/40)
   -- local vstop_2 = veclerp(vstop, vstart, interp_amount)
   --
   -- if x_dir ~= 0 then
   --  vstop.x = vstop_2.x
   -- elseif y_dir ~= 0 then
   --  vstop.y = vstop_2.y
   -- end

   rectfill(start.x, start.y, vstop.x, vstop.y, t.col)
  end
 }
end

function make_player_controller(player)
 return {
  x=0,
  y=0,
  space=sp_world,
  player=player or 0,
  update=function(t)
   if not g_board then
    return
   end

   -- input @{
   if not (g_state == st_playing) then
    return
   end

   local dir = vecmake(0,0)
   local did_shift = false

   if not btn(4, t.player) then
    if btnn(0, t.player) then
     did_shift = g_board:shift_cells(1, 0)
     dir.x=1
    elseif btnn(1, t.player) then
     did_shift = g_board:shift_cells(-1, 0)
     dir.x = -1
    elseif btnn(2, t.player) then
     did_shift = g_board:shift_cells(0,1)
     dir.y = 1
    elseif btnn(3, t.player) then
     did_shift = g_board:shift_cells(0,-1)
     dir.y = -1
    end
   else
    kick_dir = vecmake()
    local did_kick = false
    if btnn(0, t.player) then
     did_kick = true
     kick_dir.x = -1
    elseif btnn(1, t.player) then
     did_kick = true
     kick_dir.x = 1
    elseif btnn(2, t.player) then
     did_kick = true
     kick_dir.y = -1
    elseif btnn(3, t.player) then
     did_kick = true
     kick_dir.y = 1
    end
    if did_kick then
     local kick_block = vecadd(
      kick_dir,
      vecmake(
       g_player_piece.grid_x,
       g_player_piece.grid_y
      )
     )
     local kicked_block = g_board:block(kick_block.x, kick_block.y)
     -- if g_board.all_cells[
     if kicked_block then
      kicked_block.col = 10
      kicked_block:kick(kick_dir)
     end
    end
   end
   -- @}

   -- if did_shift and rnd(3) < 1  then
   --  add_merge_block_to_edge(dir)
   -- end

   if did_shift then
    local eye_dir = 12
    if dir.x == 1 then
     eye_dir = 13
    elseif dir.y == -1 then
     eye_dir = 14
    elseif dir.x == -1 then
     eye_dir = 15
    end

    g_player_piece.eye_dir = eye_dir
   end
  end,
 }
end

-- @todo: alternate version that only spawns on edges for goons
function empty_cells_on_edges(valid_edges)
 local empty_cells = {}
 for i=1,g_board.size_x do
  for j=1,g_board.size_y do
   -- only check border cells
   if (not valid_edges) or i==1 or i==g_board.size_x or j==1 or j==g_board.size_y then
    if (
     not valid_edges
     or (valid_edges.x ~= 0 and i == valid_edges.x) 
     or (valid_edges.y ~= 0 and j == valid_edges.y)
    ) then
     if not block_is_not_empty(i, j) then
      add(empty_cells, {i, j})
     end
    end
   end
  end
 end
 return empty_cells
end

-- if valid_edges is null, this will put boxes anywhere on the grid
function random_empty_cell(valid_edges)
 local empty_cells = empty_cells_on_edges(valid_edges)
 local num_empty_cells = #empty_cells
 if num_empty_cells == 0 then
  cls()
  print("you lose!")
  stop()
 end
 return empty_cells[flr(rnd(num_empty_cells))+1]
end

function add_merge_block_to_edge(dir)
 local valid=vecmake(0,0)
 if dir then
  if dir.x > 0 then 
   valid.x = g_board.size_x 
  elseif dir.x < 0 then
   valid.x = 1
  elseif dir.y > 0 then
   valid.y = g_board.size_y
  elseif dir.y < 0 then
   valid.y = 1
  end
 end
 if false then
  -- 'wide' palette
  -- local palette = {12, 10, 11, 14}
  -- just green for now
 --  local palette = {11}
  local c = random_empty_cell(valid)
 --  local col = palette[flr(rnd(#palette))+1]
  local new_box = make_merge_box(11)
  add(g_board.watch_cells, new_box)
  g_board:mark_cell_for_contain(c[1], c[2], new_box, 1.0)
  new_box:update()
 end
end

function cell_is_not_empty(cell)
 return cell.containing != nil
end

function make_dust(loc)
 if loc.x == 0 or loc.y == 0 then
  return nil
 end
 local offsets={}
 for i=1,3 do
  add(offsets, {rnd(7), rnd(7)})
 end
 return {
  x=loc.x,
  y=loc.y,
  space=sp_local,
  start=g_tick,
  offsets=offsets,
  showing=#offsets,
  update=function(t)
   local e = elapsed(t.start)
   if e > 10 then
    del(g_board.dust, t)
   end
   if e % 3 == 0 then
    t.showing -= 1
   end
  end,
  draw=function(t)
   for i=1,#t.offsets do
    if i <= t.showing then
     local o = t.offsets[i]
     rect(o[1],o[2],o[1]+1,o[2]+1,6)
    end
   end
  end
 }
end

function make_level_transition()
 g_current_level += 1
 g_state = st_menu
 make_level_complete()
--  make_level()
end

function make_text(nspr, nchars)
 return {
  x=-(7*nchars)/2,
  y=-4,
  space=sp_screen_center,
  start=g_tick,
  draw=function(t)
   -- cls()
   -- print("here_2", 0,0)
   -- stop()
   off_func = function(i)
    return 8*sin((elapsed(t.start+2*i)%90)/90)
   end
   for i=0,nchars do
    local offset = off_func(i)
    spr(nspr+i, i*6,  offset) -- c
   end
  end
 }
end

function make_level_complete()
 add_gobjs(make_text(32, 5))
 add_gobjs(make_scoreboard())
 add_gobjs(
  make_menu(
   {
    'continue!',
   },
   function(t,i,s)
    add(
     s,
     make_trans(
     function()
      reset(false)
      make_level()
     end
     )
    )
   end
  )
 )
end

function block_is_empty(i, j)
 return (
  i > 0 and i <= g_board.size_x and
  j > 0 and j <= g_board.size_y and
  not cell_is_not_empty(g_board.all_cells[i][j])
 )
end

function block_is_not_empty(i, j)
 return (
  i > 0 and i <= g_board.size_x and
  j > 0 and j <= g_board.size_y and
  cell_is_not_empty(g_board.all_cells[i][j])
 )
end

-- compute the number of blocks until the block edge
-- if dir is positive, go to the highest coordinate, negative goes towards 0
function blocks_to_edge(dim, dir, axis)
 -- blocks_to_edge(1, 1) -> 4 || grid size: 5, 5
 -- blocks_to_edge(2, 1) -> 3 || grid size: 5, 5
 -- blocks_to_edge(3, 1) -> 2 || grid size: 5, 5
 -- blocks_to_edge(4, 1) -> 1
 -- blocks_to_edge(5, 1) -> 0
 -- blocks_to_edge(1, -1) -> 0 || grid size: 5, 5
 -- blocks_to_edge(2, -1) -> 1 || grid size: 5, 5
 -- blocks_to_edge(3, -1) -> 2 || grid size: 5, 5
 -- blocks_to_edge(4, -1) -> 3
 -- blocks_to_edge(5, -1) -> 4
 local size = 1
 if dir > 0 then
  size = g_board.size_x
  if axis == 'y' then
   size = g_board.size_y
  end
 end

 return dir * (size - dim) 
end

function make_blip(loc)
 return {
  x=loc.x,
  y=loc.y,
  space=sp_world,
  draw=function(t)
   circfill(0,0,3,8)
  end
 }
end

function shift_push_buffer(t, push_buffer, x_dir, y_dir)
 if #push_buffer > 0 then
  for pb=#push_buffer, 1, -1 do
   local elem = push_buffer[pb]
   local g_x = elem.container.grid_x
   local g_y = elem.container.grid_y
   did_shift = t:shift_cell_from(g_x, g_y, g_x-x_dir, g_y-y_dir)
  end
 end

 return did_shift
end

function make_squish(thing, last_squish)
 shake_screen(8, 6, 2)
 local center = thing.container:world_coords(true)
 del(g_board.watch_cells, thing)
 thing.container.containing = nil
 g_goon_count -= 1
 local n_goons = g_goon_count
 g_state = st_freeze
 g_freeze_frame = g_tick
 g_freeze_framecount = 1
 g_player_piece.squished=g_tick

 g_current_score += 1
 return {
  x=center.x,
  y=center.y,
  space=sp_world,
  start_tick=g_tick,
  update=function(t)
   if elapsed(t.start_tick) > 30 then
    if n_goons == 0 then
     make_level_transition()
    end

    del(g_objs, t)
   end
  end,
  draw=function(t)
   local disp = vecmake(elapsed(t.start_tick))
   for _, i in pairs({{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}) do
    rect(i[1] * disp.x, i[2] * disp.y, i[1] * disp.x + 1, i[2]*disp.y + 1, 8)
   end
  end
 }
end

function make_center_circle()
 return {
  x=64,
  y=64,
  -- space=sp_screen_native,
  draw=function(t)
   circfill(0,0,32)
  end
 }
end

function make_board(x, y)
 local cols={1, 1}
--  local cols={1,6}
 local speeds={0.4,1.4}
 for i=0,50 do
  local seed=flr(rnd(2))
  add_gobjs(
   make_rain(rnd(128), rnd(128), 0.25, 4, cols[seed+1], rnd(1)+speeds[seed+1])
  )
 end
 local all_cells = {}
 local flat_cells = {}
 for i=1,x do
  all_cells[i] = {}
  for j=1,y do
   local c = make_cell(i,j)
   local ind = i + (x)*(j-1)
   flat_cells[ind] = c
   all_cells[i][j] = c
  end
 end
 local watch_cells = {}
--  local watch_cells = {make_merge_box(11)}
--  all_cells[3][1]:mark_for_contain(watch_cells[1], 1)
--
--  local other = add_gobjs(make_merge_box(1,3,11))
--  all_cells[1][3]:mark_for_contain(other, 1)
--
--  other = add_gobjs(make_merge_box(4,4,8))
--  all_cells[4][4]:mark_for_contain(other, 1)

 local s_x = 8*(x+1)+1
 local s_y = 8*y+1+y+1

 return {
  level=g_current_level,
  x=-s_x/2,
  y=-s_y/2,
  space=sp_world,
  size_x=x,
  size_y=y,
  all_cells=all_cells,
  flat_cells=flat_cells,
  watch_cells=watch_cells,
  lastgoon = g_tick,
  dust={},
  blast_queue = nil,
  blast=function(t, start_block, color_block, x_dir, y_dir)
   g_state = st_blasting
   add(t.watch_cells, make_blast(start_block, color_block, x_dir, y_dir))
   del(t.watch_cells, color_block)
  end,
  shift_cells=function(t, x_dir, y_dir)
   t.blast_queue = {}

   local first_x = 1
   local final_x = t.size_x

   local first_y = 1
   local final_y = t.size_y

   local x_inc = -x_dir
   local y_inc = -y_dir

   if x_dir > 0 then
    first_x = final_x
    final_x = 1
   end

   if y_dir > 0 then
    first_y = final_y
    final_y = 1
   end

   if x_dir == 0 then
    x_inc = 1
   end
   if y_dir == 0 then
    y_inc = 1
   end

   -- assert that you're never moving it diagonally
   if x_dir != 0 and y_dir != 0 then
    cls()
    print("should never see this.")
    stop()
   end

   local did_shift = false

   local outer_loop_start = first_x
   local outer_loop_final = final_x
   local outer_loop_inc = x_inc
   local inner_loop_start = first_y
   local inner_loop_final = final_y
   local inner_loop_inc = y_inc

   local inner_loop = "y"

   if x_dir != 0 then
    outer_loop_start = first_y
    outer_loop_final = final_y
    outer_loop_inc = y_inc
    inner_loop_start = first_x
    inner_loop_final = final_x
    inner_loop_inc = x_inc
    inner_loop = "x"
   end

   for outer=outer_loop_start,outer_loop_final,outer_loop_inc do
    push_buffer = {}
    for inner=inner_loop_start,inner_loop_final,inner_loop_inc do
     local i = outer
     local next_i = i + outer_loop_inc
     local prev_i = i - outer_loop_inc
     local j = inner
     local next_j = j + inner_loop_inc
     local prev_j = j - inner_loop_inc
     if inner_loop == "x" then
      j = outer
      next_j = j + outer_loop_inc
      prev_j = j - outer_loop_inc
      i = inner
      next_i = j + inner_loop_inc
      prev_j = j - inner_loop_inc
     end

     if block_is_empty(i, j) then
      did_shift = shift_push_buffer(t, push_buffer, x_dir, y_dir)

      -- clear the push buffer
      push_buffer = {}
     elseif block_is_not_empty(i, j) then
      local this_block = t:block(i, j)
      if this_block.shiftable == ss_inert then
       -- @todo: add a squish here
       push_buffer = {}
      elseif this_block.shiftable == ss_shiftable then
       add(push_buffer, this_block)
      elseif  this_block.shiftable == ss_pushable then
       if #push_buffer != 0 then
        add(push_buffer, this_block)
       end
      end
     end
    end
    -- check to see if the last block is a pushable, if is, squish it and shift
    -- the rest
    -- @todo: squish here
    if (
     #push_buffer > 0 and push_buffer[#push_buffer].shiftable == ss_pushable 
    ) then
     -- remov the pushable (its s`quished`)
     add_gobjs(make_squish(push_buffer[#push_buffer]))
     del(push_buffer, push_buffer[#push_buffer])
     did_shift = shift_push_buffer(t, push_buffer, x_dir, y_dir)
    end
   end

   -- check the blast queue
   if #(t.blast_queue) > 0 then
    for blst_opts in all(t.blast_queue) do
     g_board:blast(blst_opts[1], blst_opts[2], blst_opts[3], blst_opts[4])
    end
   end

   return did_shift
  end,
  cell=function(t, i, j)
   if (
    (i > 0 and i <= t.size_x )
    and (j > 0 and j <= t.size_y)
   ) then
    return t.all_cells[i][j]
   end
  end,
  block=function(t, i, j)
   if (
    (i > 0 and i <= t.size_x )
    and (j > 0 and j <= t.size_y)
    and block_is_not_empty(i, j)
   ) then
    return t.all_cells[i][j].containing
   end
  end,
  shift_cell_from=function(t, from_i, from_j, to_i, to_j)
   if from_i == to_i and from_j == to_j then
    return false
   end

   if (
    block_is_not_empty(from_i, from_j) 
   ) then
    t.all_cells[to_i][to_j]:mark_for_contain(
     t.all_cells[from_i][from_j].containing
    )
    return true
   end
   return false
  end,
  mark_cell_for_contain=function(t, x, y, c, amt)
   t.all_cells[x][y]:mark_for_contain(c, amt)
  end,
  _compute_paths=function (t)
   if not g_enemy then
    return
   end

   local path, dists = compute_path(
    g_enemy.container,
    g_player_piece.container
   )

   local current = g_player_piece.container
   while path != {} and path[current] != nil do
    current = path[current]
    del(path, current)
   end
  end,
  update=function(t)
   t:_compute_paths()

   updateobjs(t.flat_cells)
   updateobjs(t.watch_cells)
   updateobjs(t.dust)
  end,

  draw=function(t)
   drawobjs(t.flat_cells)
   drawobjs(t.dust)
   drawobjs(t.watch_cells)
   drawobjs(t.scoreboard)

   -- border square
   rect(0,0,s_x,s_y,8)
  end
 }
end

function make_scoreboard()
 return {
  x=32,
  y=1,
  space=sp_screen_native,
  draw=function(t)
   -- @todo: handle multipe digits in the scoreboard...
   rect(50, 0, 88, 20, 7)
   cursor(52, 2)
   color(6)
   print("level: "..g_current_level)
   print("score: "..g_current_score)
   print("health:"..g_health)
  end
  }
 end

function make_shake_scope()
 return {
  x=0,
  y=0,
  update=function(t)
   if g_shake_end and g_tick < g_shake_end then
    if (
     not g_shake_frequency 
     or (g_shake_end - g_tick) % g_shake_frequency == 0
    ) then
     vecset(g_cam, vecrand(g_shake_mag, true))
    end
   else
    g_shake_end = nil
    g_shake_mag = nil
    g_shake_frequency = nil
    vecset(g_cam, vecmake())
   end
  end
 }
end

function make_camera()
 return {
  x=0,
  y=0,
  update=function(t)
   -- if g_p1 then
   --  t.x=g_p1.x
   --  t.y=g_p1.y
   -- end
  end,
  draw=function(t)
  end
 }
end
-- @}

-- @{ general math
function clamp(val, minval, maxval)
 return max(min(val, maxval), minval)
end

function smootherstep(edge0, edge1, x)
  x= clamp((x - edge0)/(edge1 - edge0), 0.0, 1.0);
 return x*x*x*(x*(x*6 - 15) + 10);
end
-- @}

-- @{ vector library
function vecrand(scale, center)
 local result = vecmake(rnd(scale), rnd(scale))
 if center then
  result = vecsub(result, vecmake(scale/2))
 end
 return result
end

function vecstr(v)
 return ""..v.x..", "..v.y
end

function gvecstr(v)
 return ""..v.grid_x..", "..v.grid_y
end

function vecmake(xf, yf)
 if not xf then
  xf = 0
 end
 return {x=xf, y=(yf or xf)}
end

function vecdistsq(a, b, sf)
 if sf then
  a = vecscale(a, sf)
  b = vecscale(b, sf)
 end
 
 local distsq = (b.x-a.x)^2 + (b.y-a.y)^2
 
 if sf then
  distsq = distsq/sf
 end
 
 return distsq
end

-- global null vector
null_v = vecmake(0)

function vecnorm(v) 
 return vecscale(v, 1/sqrt(vecdistsq(null_v,v)) )
end

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

function vecadd(a, b)
 return {x=a.x+b.x, y=a.y+b.y}
end

function vecsub(a, b)
 return {x=a.x-b.x, y=a.y-b.y}
end


function vecset(target, source)
 target.x = source.x
 target.y = source.y
end

function veclerp(v1, v2, amount, clamp)
 -- tokens: can compress this with ternary
 local result = vecadd(vecscale(vecsub(v2,v1),amount),v1)
 if clamp and vecmag((vecsub(result,v2))) < clamp then
  result = v2
 end
 return result
end
-- @}

function debug_messages()
 return {
  x=0,
  y=0,
  space=sp_screen_native,
  draw=function(t)
   cursor(0, 0)
   color(8)
   print("cpu: ".. stat(1))

   if g_state == st_playing and stat(1) > 1 then
    -- cls()
    -- print("cpu cost exceeded 100%")
    -- stop()
   end
   print("mem: ".. stat(2))
   print("g_tick: "..g_tick)
   if g_enemy then
    print("enemy_pos: "..gvecstr(g_enemy.container))
    if g_enemy.attacking then
     print("attacking... "..g_enemy.attacking)
    end
   end
   if g_goon_count then
    print("goons: "..g_goon_count)
   end
   if g_player_piece then
    -- print(g_player_piece.x)
    -- print(g_player_piece.y)
   end
   if g_cs and #g_cs > 0 then
    print(#g_cs)
   end
  end
 }
end

function make_player_avatar(x, y)
 local obj={
  x=0,
  y=0,
  space=sp_local,
  shiftable=ss_inert,
  chargeable=true,
  grid_x=x,
  grid_y=y,
  eye_dir=15,
  attacked=nil,
  squished=nil,
  charge_with=function(t, other, x_dir, y_dir)
   add(g_board.blast_queue, {t, other, x_dir, y_dir})
  end,
  update=function(t)
   if g_health <= 0 and not g_dying then
    make_lose(g_player_piece.container:world_coords())
   end
  end,
  draw=function (t)
   rectfill(1,1,6,6,2)
   -- spr(6, 0,0)

   local s = 9

   if t.squished and elapsed(t.squished) < 30 then
    s = 10
   end

   local attacked = false
   for b in all(g_board.watch_cells) do
    if b.attacking then
     if elapsed(b.attacking) > 45 then
      s = 12
     else
      s = 11
     end

     if b.grid_y < t.grid_y then
      t.eye_dir = 12
     elseif b.grid_x < t.grid_x then
      t.eye_dir = 13
     elseif b.grid_y > t.grid_y then
      t.eye_dir = 14
     else
      t.eye_dir = 15
     end
     attacked = true
     break
    end
   end

   if attacked then
    if not t.attacked then
     t.attacked = g_tick
    end
   else
    t.attacked = nil
   end

   -- damage system
   for i=0,3 do
    local damage_col = i+2
    local base_color = 9
    if g_health <= 4-i then
     base_color = 8
    end
    pal(damage_col, base_color)
   end

   -- eye direction
   for i=12,15 do
    local c = 7
    if i > 13 then
     c = 6
    end
    if i == t.eye_dir then
     c = 1
    end
    if s != 12 then
     pal(i, c)
    end
   end
   spr(s, 0,0)
   pal()
  end
 }
 g_board:mark_cell_for_contain(x,y,obj)
 local t_c = g_board.all_cells[x][y]
 vecset(obj, t_c)
 return obj
end

function make_test_obj(x, y, space, label, children)
 return {
  x=x,
  y=y,
  space=space,
  label=label,
  children=children,
  update=function (t)
   if label == "root" then
    if btnn(0) then
     t.x -= 5
    end
    if btnn(1) then
     t.x += 5
    end
    if btnn(2) then
     t.y += -5
    end
    if btnn(3) then
     t.y += 5
    end
   end
  end,
  draw=function(t)
   rect(-2,-2,2,2, 4)
   circfill(0,0,1,7)
   print(label.." "..vecstr(t), -6*#label/2, 10)
   drawobjs(t.children)
  end
 }
end

g_current_level = 1
g_current_score = 0

function reset(constants)
 g_objs = {
  -- make_mouse_ptr(),
 }
 g_frozen_objs = {}
 g_cam= add_gobjs(make_camera())

 if constants then
  g_current_level = 1
  g_current_score = 0
  g_state = st_menu
 end
end

function game_start()
 reset(true)
 make_level()
 g_health = 5
end

function shake_screen(duration, magnitude, frequency)
 g_shake_end = g_tick + duration + 1
 g_shake_mag = magnitude
 g_shake_frequency = frequency
end

function make_level()
--  local children = {}
--  for i=1,10 do
--   add(children, make_test_obj(5,12*i,sp_local,"child"..i))
--  end
--  g_board = add_gobjs(make_board(2,2))
 g_goon_count = 0
 g_shake_scope = add_gobjs(make_shake_scope())
 g_board = add_gobjs(make_board(7,7))
 g_score = add_gobjs(make_scoreboard())
--  add_gobjs(make_center_circle())

--  for b in all(g_board.flat_cells) do
--   add_gobjs(make_blip(b:world_coords(true)))
--  end

 -- add neighbor lists
 for i=1,g_board.size_x do
  for j=1,g_board.size_y do
   c = g_board.all_cells[i][j]
   c.neighbors = neighbor_cells_of(i,j)
  end
 end

 g_player_piece = make_player_avatar(4,4)
 add(g_board.watch_cells, (g_player_piece))
--  add_gobjs(make_test_obj(0,0,sp_world,"root",children))
 g_p1 = add_gobjs(make_player_controller(0))

 -- add goons
 for i=1,(g_current_level+1) do
  local empty = nil
  while true do
   empty = random_empty_cell()
   if (
    abs(empty[1]-g_player_piece.grid_x) != 1 
    and abs(empty[2]-g_player_piece.grid_y) != 1) then
    break
   end
  end
   g_enemy = make_goon(empty[1], empty[2])
 end

 -- add merge boxes
 local numboxes = flr(8+rnd(3))
 for i=1,numboxes do
  local c = random_empty_cell()
  local new_box = make_merge_box(11)
  add(g_board.watch_cells, new_box)
  g_board:mark_cell_for_contain(c[1], c[2], new_box, 1.0)
  new_box:update()
 end

--  add_gobjs(debug_messages())
 g_state = st_playing
end

st_playing = 0
st_blasting = 1
st_menu = 2
st_freeze = 3

g_freeze_frame = nil
g_freeze_framecount = nil

------------------------------

function stdinit()
 g_tick=0    --time
 g_ct=0      --controllers
 g_ctl=0     --last controllers
 g_cs = {}   --camera stack 
 g_objs = {} --objects
 g_frozen_objs = {}
end

function stdupdate()
 g_tick = max(0,g_tick+1)
 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()

 if g_state == st_freeze then
  if elapsed(g_freeze_frame) > g_freeze_framecount then
   g_state = st_playing
   g_freeze_frame = nil
   g_freeze_framecount = nil
  end
 else
  updateobjs(g_objs)
 end
 updateobjs(g_frozen_objs)
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
    pushc(-t.x, -t.y)
    cam_stack += 2
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
 p = p or -1
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
    pal()
    rect(-x,0,x,t.h,12)
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
   if elapsed(t.e)>20 then
    if (t.f) t:f(s)
    del(s,t)
    if not t.i then
     add(s,
       make_trans(nil,nil,1))
    end
   end
  end,
  draw=function(t)
   local x=flr(elapsed(t.e)/4)
   if t.i then
    x=5-x
   end
   trans(x)
  end
 }
end

__gfx__
006000001012210100000000330003303aaaa933333000339911911900000000000c000099999995919191919991191199911911000000000000000000000000
0066000000088000000c000030000030aa000a933300900399999999000000006775555699119115991999159919919599199195000000000000000000000000
0066600010033001000c000000000000a76076a933099400977697760002000060000c0697c797c797c797c797c797c7977c977c000000000000000000000000
00666600283083820cc8cc0000030000a00000a900099940976d976d002200006c7700069d7f9d7f9d7f9d7f9d7f9d7f47cc97cc000000000000000000000000
0066650028380382000c000000000000aa000aa90949994096669666002220006cc7cc0646e696e646e696e646e696e64ccc9ccc000000000000000000000000
0066500010033001000c0000300000303aaaaa930949994099999999000200006cccccc64999999549999995499999954c999c95000000000000000000000000
006500000008800000000000330003303a9a99330099940099111199000000006cccccc6491111954177771549911995c911c115000000000000000000000000
00500000101221010000000000000000a999999330094003999999990000000066666666493392954177771549311295491c8815000000000000000000000000
66666000666660006666600066666000666600006666000006666600000000000000000000000000000000000000000000000000000000000000000000000000
67776500676765006777650067776500677650006776600006767650000000000000000000000000000000000000000000000000000000000000000000000000
67676600676765006766650066766500676650006767650006767650002020000000000000000000000000000000000000000000000000000000000000000000
67777650676765006777650006765500677650006767650006666650000220200000000000000000000000000000000000000000000000000000000000000000
67667650676765006667650006765000676650006767650066777660002222000000000000000000000000000000000000000000000000000000000000000000
67777650677765006777650006765000677650006776650067666765000020000000000000000000000000000000000000000000000000000000000000000000
66666650666665006666650006665000666650006666550066656665000000000000000000000000000000000000000000000000000000000000000000000000
05555550055555000555550000555000055550000555500005550555000000000000000000000000000000000000000000000000000000000000000000000000
00066660006660000666600066666000666600006660000000000000000000000000000000000000776666773333333300000000000000000000000000000000
00067765006765000677650067776500677660006765000000000000000000000000000000000000788288273bbbbbb300000000000000000000000000000000
000676650067650006766500676765006767650067650000000000000000000000000000000000008788788233b33b3300000000000000000000000000000000
000675550067650006776500676765006767650067650000000000000000000000000000000000008888888203b3bb3000000000000000000000000000000000
000676600067660006766500677765006776650066650000000000000000000000000000000000006888882603bb3b3000000000000000000000000000000000
000677650067765006776500676765006767650067650000000000000000000000000000000000006688826633b33b3300000000000000000000000000000000
00066665006666500666650066666500666665006665000000000000000000000000000000000000766826673bbbbbb300000000000000000000000000000000
00005555000555500055550005555500055555000555000000000000000000000000000000000000776666773333333300000000000000000000000000000000
66666000066600006666600066666000666660006666600066666000666660006666600066666000777666506666666699999999999999999999999900000000
67776500667650006777650067776500676765006777650067776500677765006777650067776500073335000000000088888888877787779999999900000000
67676500677650006667650066676500676765006766650067666500666765006767650067676500076365000775077587708770877087708888888800000000
67676500667650006777650006776500677765006777650067776500056765006777650067776500733633506755675586668666866686668770877000000000
67676500667660006766650066676500666765006667650067676500006765006767650066676500073635006555655599999999999999999999999900000000
67776500677765006777650067776500056765006776650067776500006765006777650005676500076665006666666689999999899999998999999900000000
66666500666665006666650066666500006665006666550066666500006665006666650000666500666666506660006688999998889999988899999800000000
05555500005555000555550005555500000555000555500005555500005555000555550000055500000000006666666688899988888999888889998800000000
333300003333300033333000333330003333000000000000000000000000000000000000000000000bb00bb0bbb00bbb00000000000000000000000000000000
3bb330003b3b35003bbb35003b3b35003bb350000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb00000000000000000000000000000000
3b3b30003b3b35003b3335003b3b35003bb350000000000000000000000000000000000000000000bbbbbbbbbbbbbbbb00000000000000000000000000000000
3bbb35003b3b35003bbb35003bbb35003bb3500000000000000000080800000000000080800000000bbbbbb00bbbbbb000000000000000000000000000000000
3b3335003b3b3500333b35003b3b35003bb3500000000000000008eeee000000000000eeee8000000bbbbbb00bbbbbb000000000000000000000000000000000
3b3555003bbb35003bbb35003b3b35003bb350000000000000000e888828000000008e8888200000bbbbbbbbbbbbbbbb00000000000000000000000000000000
333500003333350033333500333335003bb35000000000000008e778877200000000e77887728000bbbbbbbbbbbbbbbb00000000000000000000000000000000
055500000555550005555500055555003bb35000000000000000e778877280000008e778877200000bb00bb0bbb00bbb00000000000000000000000000000000
333330003333300033333000333330003bb35000000000000008e878878200000000e87887828000000000000000000000000000000000000000000000000000
3bbb35003bbb35003bbb35003b3b3500333350000000000000002888888280000008288888820000000000000000000000000000000000000000000000000000
3b3b35003b3b35003b3335003b3b3500055550000000000000008288882000000000028888280000000000000000000000000000000000000000000000000000
3bbb35003bbb35003b3335003bb33500333300000000000000000022228000000000082222000000000000000000000000000000000000000000000000000000
3b3b35003b3b35003b3335003b3b35003bb350000000000000000080800000000000000808000000000000000000000000000000000000000000000000000000
3bbb35003b3b35003bbb35003b3b35003bb350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333500333335003333350033333500333350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555500055555000555550005555500055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001cc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001c1111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001cc1cc111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001c11c1c1cc11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001cc1c1c1c1c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001111c1c1c1c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000011111ccc1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344


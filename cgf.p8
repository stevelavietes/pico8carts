pico-8 cartridge // http://www.pico-8.com
version 15
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
-- kick furniture
-- kicked furniture hits enemies


-- done
-- spawn furniture
-- you can attack the goons to make them disapear
-- goons randomly spawned
-- move around on the grid
-- avatar
-- grid



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

function _init()
 stdinit()

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

-- @{ mouse support
poke(0x5F2D, 1)

function make_mouse_ptr()
 return {
  x=0,
  y=0,
  button_down={false,false,false},
  space=sp_screen_native,
  update=function(t)
   -- if you have the vector functions
   -- vecset(t, makev(stat(32), stat(33)))
   t.x = stat(32)
   t.y = stat(33)

   local mbtn=stat(34)
   for i,mask in pairs({1,2,4}) do
    t.button_down[i] = band(mbtn, mask) == mask and true or false
   end
  end,
  draw=function(t)
   -- chang the color if you have one of the buttons down
   if t.button_down[1] then
    pal(3, 11)
    add_particle(0, 0, 0, 1, 60, 11, 1)
   end
   if t.button_down[2] then
    pal(3, 12)
   end
   if t.button_down[3] then
    pal(3, 10)
   end
   spr(3, t.x-3, t.y-3)
   if t.button_down[1] or t.button_down[2] or t.button_down[3] then
    pal(3,3)
   end
   print("("..t.x..","..t.y..")", 1, 13)
  end
 }
end
-- @}

-- enum
G_STATE = ge_state_playing
ge_state_playing = 1
ge_state_animating = 2

ge_obj_player = 1
ge_obj_goon = 2

ge_obj_chair = 10

function interact(obj, target_cell)
 if not target_cell.contains then
  target_cell:now_contains(obj)
  return
 end

 local other_obj = target_cell.contains
 
 -- check to see if a goon is in the target_cell
 other_obj:attack(obj)
end

-- returns whether it could move or not
function move_obj_in_dir(obj, dir)
 if dir and (dir.x != 0 or dir.y != 0) then
  next_cell = get_cell(vecadd(dir, obj.grid_loc))
  if next_cell then
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
  grid_loc=vecmake(),
  space=sp_world,
  c_objs={},
  update=function(t)
   -- move cells
   local m_x = 0
   local m_y = 0
   local next_cell = vecmake()
   if btnn(0, t.p) then
    next_cell.x = -1
    -- m_x =-1
   end 
   if btnn(1, t.p) then
    next_cell.x = 1
    -- m_x = 1
   end
   if btnn(2, t.p) then
    next_cell.y = -1
    -- m_y = -1
   end
   if btnn(3, t.p) then
    next_cell.y = 1
    -- m_y = 1
   end
   -- t.x += m_x
   -- t.y += m_y

   move_obj_in_dir(t, next_cell)

   updateobjs(t.c_objs)
  end,
  draw=function(t)
   -- spr(2, -3, -3)
   spr(5, 0,0)
   -- rect(-3,-3, 3,3, 8)
   local str = "world: " .. t.x .. ", " .. t.y
   print(str, -(#str)*2, 12, 8)
   local str = "grid: " .. t.grid_loc.x .. ", " .. t.grid_loc.y
   print(str, -(#str)*2, 18, 8)
   drawobjs(t.c_objs)
  end
 }

 get_cell(thing.grid_loc):now_contains(thing)

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

function vecdrawrect(start_p, end_p, c)
 rect(start_p.x, start_p.y, end_p.x, end_p.y, c)
end
-- @}

function get_cell(loc)
 if (
  loc.x < g_board.grid_dimensions.x and loc.x > -1 and
  loc.y < g_board.grid_dimensions.y and loc.y > -1
 ) then
  return g_board.cells[loc.x+ 1][loc.y+ 1]
 end
 return nil
end

function make_cell(i, j)
 return {
  x = 9*i+2,
  y = 9*j+2,
  contains = nil,
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

function make_goon()
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

   -- if attacked, enemy is killed
   t.contained_by:now_contains(attacker)
   g_board:remove(t)
  end,
  draw=function(t)
   spr(37,0,0)
   rect(0,0,8,8,11)
  end
 }
end

function make_chair()
 return {
  x=0,
  y=0,
  grid_loc=vecmake(),
  obj_type=ge_obj_chair,
  space=sp_world,

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
   spr(10,0,0)
   -- rect(0,0,8,8,11)

  end
 }
end



function make_board()
 BOARD_DIM = vecmake(24, 18)

 local cells = {}
 local flat_cells = {}
 -- row
 for i=1,BOARD_DIM.x do
  add(cells, {})
  -- column
  for j=1,BOARD_DIM.y do
   new_cell = add(cells[i], make_cell(i-1,j-1))
   add(flat_cells, new_cell)
  end
 end


 return {
  x=0,
  y=0,
  space=sp_world,
  cells=cells,
  flat_cells = flat_cells,
  grid_dimensions = BOARD_DIM,
  -- goes from (0,0)
  grid_dimensions_world = vecmake(BOARD_DIM.x*9+2, BOARD_DIM.y*9+2),
  remove=function(t, obj)
   if obj.contained_by then
    obj.contained_by.contains = nil
    obj.contained_by = nil
   end
   del(g_objs, obj)
  end,
  update=function(t)
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
  spawn_thing=function(t, num_to_spawn, cons)
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
  draw=function(t)
   -- draw the border
   vecdrawrect(null_v, t.grid_dimensions_world, 2)

   drawobjs(t.flat_cells)
  end
 }
end

function game_start()
 g_objs = {
  make_debugmsg(),
 }

 g_board = add_gobjs(make_board())
 -- make some goons and some furniture
 g_board:spawn_thing(10, make_goon)
 g_board:spawn_thing(40, make_chair)
 g_cam= add_gobjs(make_camera())
 g_p1 = add_gobjs(make_player(0))


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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008770877000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008666866600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008999999900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008899999800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008889998800000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344


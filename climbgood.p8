pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- skate up the tower, i dare you

function repr(arg)
 -- turn any thing into a string (table, boolean, whatever)
 if arg == nil then
  return "nil"
 end
 if type(arg) == "boolean" then
  return arg and "true" or "false"
 end
 if type(arg) == "table" then 
  if arg[1] then
   -- hackity hack hac
   local retval = " list[ "
   for _, v in pairs(arg) do
    retval = retval .. repr(v) .. ","
   end
   retval = retval .. "] "
   return retval
  end
  local retval = " table{ "
  for k, v in pairs(arg) do
   retval = retval .. k .. ": ".. repr(v).. ","
  end
  retval = retval .. "} "
  return retval
 end
 return ""..arg
end

function print_stdout(msg)
 -- print 'msg' to the terminal, whatever it might be
 printh("["..repr(g_tick).."] "..repr(msg))
end

function _init()
 g_tick=0
 g_ct=0    --controllers
 g_ctl=0   --last controllers

 g_cs = {}   --camera stack

 g_scroffset = 128 --scrolling
 g_scrspeed = 0
 g_scrline = 40
 g_airdragmod=0.5

 g_state = 0 --don't play
 
 g_objs = {}
 g_uiobjs = {} 
 
--  make_title()
 game_start()
end

function update_collision(o1,o2)
 local o1s = o1.speed
 local o2s = o2.speed
 
 if o1.speedy <= 0 then
  o1.speed*=-1
  o1.x+=(o1.speed*2)
 else
  o1.speedy*=-1
  o1.y+=o1.speedy
  --straight down bounce
  if o1s==0 then
   if o1.direction==1 then
    o1s=-2
   else
    o1s=2
   end
  end
 end

 if o2.speedy <= 0 then
  o2.speed*=-1
  o2.x+=(o2.speed*2)
 else
  o2.speedy*=-1
  o2.y+=o2.speedy  
  --straight down bounce
  if o1s==0 then
   if o1.direction==1 then
    o1s=-2
   else
    o1s=2
   end
  end
 end
 
 if o1s == 0 then
  o1.speed = o2s
 end
 if o2s == 0 then
  o2.speed = o1s
 end
end

-- { particle stuff from @casualeffects
-- fast particle system
-- by morgan mcguire @casualeffects
-- http://casual-effects.com
-- Released as BSD-license open source February 2017.


function add_particle(x, y, dx, dy, life, color, ddy)
 particle_array_length += 1

 -- grow if needed
 if (#particle_array < particle_array_length) add(particle_array, 0)
 
 -- insert into the next available spot
 particle_array[particle_array_length] = {x = x, y = y, dx = dx, dy = dy, life = life or 8, color = color or 6, ddy = ddy or 0.0625}
end


function process_particles()
 -- @casualeffects particle system
 -- http://casual-effects.com

 -- simulate particles during rendering for efficiency
 local p = 1
 while p <= particle_array_length do
  local particle = particle_array[p]
  
  -- the bitwise expression will have the high (negative) bit set
  -- if either coordinate is negative or greater than 127, or life < 0
  if bor(band(0x8000, particle.life), band(bor(particle.x, particle.y), 0xff80)) != 0 then

   -- delete dead particles efficiently. pico8 doesn't support
   -- table.setn, so we have to maintain an explicit length variable
   particle_array[p], particle_array[particle_array_length] = particle_array[particle_array_length], nil
   particle_array_length -= 1

  else

   -- draw the particle by directly manipulating the
   -- correct nibble on the screen
   local addr = bor(0x6000, bor(shr(particle.x, 1), shl(band(particle.y, 0xffff), 6)))
   local pixel_pair = peek(addr)
   if band(particle.x, 1) == 1 then
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

   -- for _, c in pairs(collision_objects) do
   --  local collision_result = c:collides(particle)
   --  if collision_result != nil then
   --   particle.x += collision_result[1]
   --   particle.y += collision_result[2]
   --   particle.dy = -particle.dy
   --  end
   -- end

   p += 1
  end -- if alive
 end -- while
end
-- }

function is_holding(obj, held)
 return (
  obj.will_hold and 
  held.is_holdable and
   (held.held_by == nil or 
    held.held_by == obj)
 )
end

function _update()
 g_tick = max(0,g_tick+1)
 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()


 animate_tiles()
 
 foreach(g_uiobjs, function(t)
  if t.update then
   t:update(g_uiobjs)
  end
 end)

 if g_state == 0 then
  return
 end
 
 -- disabling for now to test other mechanic
 if false and g_tick % 6 == 0 then
  g_timer -= 1
 end
 
 if (g_timer < 1) then
  g_state = 0
  
  add(g_uiobjs, make_menu(
   {'retry', 'huh'},
   function(t,i,s)
    --del(s,t)
    
    add(s, make_trans(
     function()
      game_start()
     end))
     
   end,
   64,64
  ))
  
  
  --cls()
--  print("game over.")
  --print("height: "..128-g_scroffset)
  --stop()
 end
 
 
 if shouldscroll() then
  g_scrspeed = -4
 else
  g_scrspeed = min(
    0,g_scrspeed+0.5)
 end
 scrollby(g_scrspeed)

 for v in all(g_violets) do
  if v.y > 127 and not v.off then
   respawn_in_level()
   v.off = g_tick
   v.y = 140
   --v.x = 60
   v.speed=0
   v.speedy=0
   v.will_hold=false
  end
  v:update()
 end
 
 for v in all(g_blocks) do
  if v.y > 128 then
   v.y = -8
   --v.x = 20
  end
 end

 foreach(g_violets, update_phys)
 foreach(g_blocks, update_phys)
 foreach(g_objs,update_phys)

 collide(
  g_violets[1],
  g_violets[2])
  
 -- todo - accel structures?
 for v in all(g_violets) do
  for b in all(g_blocks) do
   collide(v, b)
  end
  for o in all(g_objs) do
   if o.getrect and 
     rectintersect(
      v:getrect(), 
      o:getrect()) then
    if o.pickup then
     o:pickup(v)
    end
   end
  end
 end
 
 foreach(g_violets, update_held)

end

function animate_tiles()
 --experiment with animating
 --sprites in maps by copying
 --sprite data around
 local src=119+flr((g_tick%20)/4)
 sprcpy(71,src)
 src=73+flr((g_tick%12)/4)
 sprcpy(72,src)
 
 src=76+(g_tick%4)
 sprcpy(m_zipup,src)
 src=92+flr((g_tick%16)/4)
 sprcpy(m_zipdown,src)
 
 foreach(g_objs, function(t)
  if t.update then
   t:update(g_objs)
  end
 end)

end


function collide(o1, o2)
 if not o1 or not o2 then
  return
 end
 
 if o1.off or o2.off then
  return
 end

 if rectintersect(
   o1:getrect(), o2:getrect())
     then
  if is_holding(o1, o2) then
   update_holding(o1, o2)
  else
   update_collision(o1,o2)
  end
 end
end

-- list of level
c_level_indices = {178, 176, 162, 160}

function game_start(level)
 g_state = 1 -- play!
 g_objs={}
 g_uiobjs={}
 particle_array, particle_array_length = {}, 0

 -- the pushable blocks (heart boxes)
 g_blocks={
  -- make_block(50,35)
 }
 foreach(g_blocks, init_phys)

 for i = 0,15 do
  mset(i,0,72)
 end 

 -- load the level
 if level == nil then
  level = 1
 end

 g_current_level = level
 
 board = load_board(
   c_level_indices[level])
 g_leveltable = board2table(
   board)
 
 g_spawn_loc = nil
 g_sprobjs = {}
 for i = 1, #board.items do
  local item = board.items[i]
  
  if item.itemtype ==
    it_sprobj then
   add(g_sprobjs, item)
  end

  if item.itemtype == it_spawn_loc then
   g_spawn_loc = {
    8*item.xpos,
    g_scroffset - (
     16
     +item.yscr*128
     +item.ypos*8
     )
   }
  end
 end
 g_sprobj_index = 1
 
 
 for y = 0, 31 do
  local r = g_leveltable[y+1]
  local yy = 31 - y
  for x = 0, 15 do
   
   if r != nil then
    mset(x, yy, r[x+1])
   else
    mset(x, yy, 0)
   end
  end
 end
 
 --[[
 -- not sure why 30 works, have to ask @stevel
 for i = 0,15 do
  mset(i,30,72)
 end 

 -- make some walls to bounce off of
 for x in all({2, 13}) do
  for y=8,30 do
   mset(x, y, 72)
  end
 end
 --]]

 if not g_spawn_loc then
  cls()
  print(
   "error: level ["
   ..g_current_level
   .."] does not have a spawn"
   .." set."
  )
  stop()
 end

 g_violets={
   make_violet(
    0,
    g_spawn_loc[1],
    g_spawn_loc[2]
   ), 
 }
 
 add(g_objs,
      make_pop(g_violets[1].x,
        g_violets[1].y))
      
 foreach(g_violets, init_phys)
 
 if #g_violets > 1 then
  g_violets[2].x = 86
  g_violets[2].direction=0
 end

 --[[
 --init as random
 if true then
  for i=1,32 do
   scrollby(-8)
  end
  g_scroffset = 128
  
  foreach(g_violets, function(v)
   v.y=41
  end)
  foreach(g_blocks, function(v)
   v.y=41
  end)
 end
 --]]
 g_scroffset = 128
 g_timer=99

 spawn_sprobj()
end

ot_apple = 0
ot_bounceypad = 1

sprobj_ctors = {
 [ot_apple] = function(x,y)
  return make_apple(x,y-8)
 end,
 [ot_bounceypad] = function(x,y)
  return make_bouncypad(x,y-8)
 end,
}


function spawn_sprobj()
 
 
 local ypos =
     flr((128-g_scroffset)/8)+17
 
 for i = g_sprobj_index,
   #g_sprobjs do
  
  local objypos =
    g_sprobjs[i].yscr*16 +
      g_sprobjs[i].ypos 
  
  if objypos <= ypos then
   
   local item = g_sprobjs[i]
   local ctor = sprobj_ctors[
     item.objtype]
   
    
   if ctor then
    --make the object
   
    local obj = ctor(
      item.xpos*8,
        g_scroffset -
         (item.yscr*128+
           item.ypos*8))
    
    --find the pos
    
    add(g_objs, obj)
    
    --add(g_objs, make_leveltrans(
    --g_current_level + 1))
     
   end
   
   g_sprobj_index += 1
  else
   break
  end
  
 end
 
 
end


function make_title()
 add(g_uiobjs,
   make_drawon(d_climbing,
     function(t,s)
      add(s,
        make_drawon(d_violets,
          function(t,s)
           
           add(s, make_menu(
            {'1 player',
             '2 player',
             'exit',},
             function(t, i)
              if i == 2 then
               load('git/menu')
               run()
               return
              end
              add(s, make_trans(
     function()
      game_start()
     end))

--              game_start()
             end
           ))
           
           --game_start()
          end))
     end))
end


function update_held(obj)
 local held=obj.holding
 if obj.will_hold then
  if held then
   update_holding(obj, held)
   if obj.direction == 0 then
    held.x=obj.x-0.5*obj.hbx1
   else
    held.x=obj.x+1.25*obj.hbx1
   end
   held.y=obj.y+obj.hby0+0.25*obj.hby1
  end
 else
  if held then
   held.held_by=nil
   obj.holding=nil
  end
 end
end

function update_holding(obj, held)
 held.speed = obj.speed
 held.speedy= obj.speedy
 held.direction=obj.direction
 held.speedinc=obj.speedinc
 
 
 obj.holding=held
 held.held_by=obj
end

function numdigits(n)
 local d = 1
 while ((n / 10) > 1) do
  n/=10
  d+=1
 end
 return d
end

function draw_thing(thing)
 if thing.draw then
  thing:draw()
 end
end

function _draw()
 cls()
 rectfill(0,0,127,127,12)
 
 --test cloud
 spr(128,(((g_tick%640)/4+88)%160)-32,
   ((0-g_scroffset/3)%144)-16,4,2)
 
 spr(128,(((g_tick%800)/5+44)%160)-32,
   ((44-g_scroffset/3)%144)-16,4,2)
 
 spr(128,(((g_tick%640)/4+0)%160)-32,
   ((88-g_scroffset/3)%144)-16,4,2)
 
 
 
 for i=0,15 do
  pal(i,1)
 end
 camera(-1,-1)
  draw_map(128)
 camera()
 camera(-2,-2)
  draw_map(2)
 camera()
 
 pal()
 
 draw_map()
 
 --[[
 line(9,g_scrline,
   127,g_scrline,5)
 print(g_scrline,0,g_scrline-2,
   5)
 --]]
 
 foreach(g_violets, draw_thing)
 foreach(g_blocks, draw_thing)
 foreach(g_objs, draw_thing)

 draw_uiobjs(g_uiobjs)
 
 if g_state == 0 then
  return
 end
 -- height/score display
 color(1)
 local scrl=128-g_scroffset
--  rectfill(1,120, 1+4*(8+numdigits(scrl)),126)
 if shouldscroll() then
  color(11)
 else
  color(3)
 end
--  print("height: "..flr(scrl), 2,121)
 if g_violets[1] then
  color(11)
  if g_violets[1]:next_to_wall() then
   color(9)
   if g_violets[1].wall_hang_timer and g_violets[1].wall_hang_timer > 0 then
    color(12)
   end
  end
  -- print("speed: "..repr(g_violets[1].speed), 2, 116)
  -- print("jumps: "..repr(g_violets[1].jumps), 2, 110)
  local mp = map_position(g_violets[1])
   -- print(
   --  "fields: "
   --  .. repr(map_fields_list2(g_violets[1])),
   --  2,
   --  122,
   --  1
   -- )
   print("speed: "..repr(g_violets[1].x), 2, 122, 1)
 end
 color(5)

 --[[
 --debug offset and ground
 print(off,0,0,7)
 local f,smy,my=g_violets[1]:getflr()
 print(f..' '..smy..' '..my,0,8,7)
 --]]

 process_particles()
end

function draw_map(lyr)
 local top=flr(
 (g_scroffset%256)/8)

 local off=getlocaloff()
 if top<16 then
  local mh = 16-top  
  map(0,top,0,off,16,mh,lyr)
  if mh<17 then
   map(0,16,0,off+mh*8,16,17-mh,lyr)
  end
 else
  local mh = 32-top
  map(0,top,0,off,16,mh,lyr)
  if mh<17 then
   map(0,0,0,off+mh*8,16,17-mh,lyr)
  end
 end

end

function getlocaloff()
 return 7-(g_scroffset%8)-7
end

function getscrmy()
 result = {}
 local top=flr(
 (g_scroffset%256)/8)

 if top<16 then
  for i=top,15 do
   add(result,i)
  end
  local rm=16-#result
  for i=16,16+rm do
   add(result,i)
  end
 else
  for i=top,31 do
   add(result,i)
  end
  local rm=16-#result
  for i=0,rm do
   add(result,i)
  end
 end

 return result
end

function make_block(x,y)
 return {
  x=x,
  y=y,
  hbx0=0,
  hbx1=8,
  hby0=0,
  hby1=8,
  is_holdable=true,
  update=function(b) end,
  draw=function(b)
   spr(96,b.x,b.y)
  end,
 }
end

function make_bouncypad(x, y)
 local r = {
  x=x,
  y=y,
  hbx0=0,
  hbx1=8,
  hby0=0,
  hby1=8,
  off = true,
  pickup=function(a, o)
   -- todo: check the normal direction before flipping the vector
   o.speed = -o.speed
   o.speedy = -o.speedy
  end,
  draw=function(b)
   spr(67,b.x,b.y)
  end
 }

 init_phys(r)
 return r
end

g_rot_cw = true
g_rot_c_cw = false

function pix_coords_from_spr_ind(ind)
--  def func(index, width, result_mult):
--   return ((index % width) * result_mult, math.floor(index / width) * result_mult)
 return {
  ( ind % 16) * 8,
  flr(ind/16) * 8
 }
end

function rotate_sprite_90(from_spr, to_spr, shifts, clockwise)
 local spr_width = 2
 local centering = 8* spr_width / 2 
 local from = pix_coords_from_spr_ind(from_spr)
 local from_x_base = from[1]
 local from_y_base = from[2]
 local to = pix_coords_from_spr_ind(to_spr)
 local to_x_base = to[1]
 local to_y_base = to[2]

 local cos_theta = cos(shifts/ 30)
 local sin_theta = sin(shifts/ 30)

 -- todo: fix th

   -- cls()
   -- print("from: "..repr({from_x_base, from_y_base}))
   -- print("to: "..repr({to_x_base, to_y_base}))
   -- stop()
 for x=0,8*spr_width - 1 do
  for y=0,8*spr_width - 1 do
   local from_x = x - centering
   local from_y = y - centering

   local to_x = from_x * cos_theta - from_y * sin_theta 
   local to_y = from_y * cos_theta + from_x * sin_theta 

   to_x += centering
   to_y += centering
   local c = abs(xp) < 7 and abs(yp) < 7 and sget(from_x_base + x, from_y_base + y) or 0 

   -- print("from: "..repr({x, y}))
   -- print("from: "..repr({from_x, from_y}))
   -- print("to: "..repr({to_x, to_y}))
   -- print("to: "..repr({to_x_base + to_x + centering, to_y + to_y_base + centering})
   -- )

   -- local col = sget(from_x_base + x, from_y_base + y)
   sset(to_x_base + to_x, to_y_base + to_y, c)
  end
 end
   -- stop()
end

function make_apple(x,y)
 local r = {
  breaks_blocks=true,
  xstop_reverse=true,
  x=x,
  y=y,
  hbx0=0,
  hbx1=8,
  hby0=0,
  hby1=8,
  pickup=function(a, o)
   g_timer += 15
   del(g_objs, a)
  end,
  update=function(b,s)
   if b.y > 127 then
    del(s,b)
   end

   if b.speed > 0 then
    b.speed = 1
   else
    b.speed = -1
   end

  end,
  draw=function(b)
   spr(64,b.x,b.y)
  end
 }
 init_phys(r)
 return r
end

function init_phys(o)
 local phys={
  held_by=nil,
  direction=1,
  speed=0,
  speedinc=0.25,
  speedy=0,
  getrect=function(t)
   return {
    t.x+t.hbx0,
    t.y+t.hby0,
    t.x+t.hbx1,
    t.y+t.hby1
   }
  end,
  --
  getflr=function(t)
   local mx = flr((t.x+t.hbx0)/8)
   local mx2 = min(15,max(0,mx+1))

   local hit=false
   local off=getlocaloff()
   local mys=getscrmy()

   local myp= flr((t.y+t.hby1-off)/8)
   local my=myp+1

   local smy = my
   for i=my,17 do
    local m=mys[i]
    --local s=mget(mx,m)
    if band(1,fget(mget(mx,m)))>0 or
     band(1,fget(mget(mx2,m)))>0 then
     hit=true
     break
    end
    my+=1
   end

   if not hit then
    return 128,0,0
   end

   local r = (my-1)*8-t.hby1+off
   --return (my-1)*8-t.hby1--+off
   --return my*8-t.hby1-g_scroffset
   return r,smy,my

  end
 }
 for k,v in pairs(phys) do o[k] = v end

 return o
end

function respawn_in_level()
 game_start(g_current_level)
end

function level_complete()
 if g_current_level < #c_level_indices then
  --game_start(g_current_level + 1)
  add(g_objs, make_leveltrans(
    g_current_level + 1))
 else
  game_completed()
 end
end

function make_leveltrans(next)
 g_violets[1].off = true
 g_violets[1].trans = true
 
 return {
  x=0,y=0,off=true,
  update=function(t,s)
   
   local mapline =
     flr((128-g_scroffset)/8)+32
   
   
   if mapline - #g_leveltable
     > 32 then
    
    g_violets[1].trans = nil
    g_violets[1].off = nil
    
    
    game_start(next)
    del(s, t)
   else
    scrollby(-3)
    g_violets[1].y-=3
   end
   
  end
 } 
end



function game_completed()
 cls()
 print("you win")
 stop()
end

function normalize(x, y)
 local len = sqrt(x*x + y*y)
 return {x/len, y/len}
end

g_speed_cols = {10,14,11}
function make_blur(from_obj)
 local dir = normalize(
  from_obj.speed,
  from_obj.speedy
 )
 local dir = {-dir[1], -dir[2]}
 local speed_off = 0
 if from_obj.speed < 0 then
  speed_off = 16
 end
 return {
  x=rnd(7)-4+from_obj.x+speed_off,
  y=rnd(15)-4+from_obj.y+6,
  dir=dir,
  start=g_tick,
  draw=function(t)
   line(
    t.x,
    t.y,
    t.x+2*dir[1],
    t.y+2*dir[2],
    g_speed_cols[flr(rnd(3))+1]
   )
  end,
  update=function(t)
   if elapsed(t.start) > 5 then
    del(from_obj.speed_blurs, t)
   end
  end
 }
end

function make_violet(p, x, y)
 return {
  x=x,
  y=y,
  hbx0=4,
  hbx1=12,
  hby0=0,
  hby1=16,
  jumps=2,
  frame=0,
  speed=0,
  speedy=0,
  last_speed=0,
  rot_ctr=0,
  init_tick=g_tick,
  update=function(t)
   if t.off then
    t.frame=0
    t.xoff = sin(g_tick/100)*10
    t.yoff = sin(g_tick/200)*10
    if t.trans then
     return
    end
   end

   local ground = t:getflr()
   local spdadj=2

   -- state detection
   local on_wall = t:next_to_wall()
   local jumping = (t.y != ground)

   if on_wall then
    if t.wall_hang_timer then
     t.wall_hang_timer -= 1
    else
     t.wall_hang_timer = 10
    end
   else
    t.wall_hang_timer = nil
   end

    -- input

    --left
    if btn(0,p) then
     if t.direction == 1 then
      t.frame = 0
     end
     if (
      (not jumping) 
      or on_wall 
      or t.speed < 0
     ) then
      t.direction = 0
      t.speed = max(
       -2-spdadj,
       t.speed-2*t.speedinc
      )
     end
    --right
    elseif btn(1,p) then
     if t.direction == 0 then
      t.frame = 0
     end
     if (
      (not jumping) 
      or on_wall 
      or t.speed > 0
     ) then
      t.direction = 1
      t.speed =
      min(
       2+spdadj,
       t.speed+2*t.speedinc
      )
     end
    else
     if abs(t.speed) < 
      t.speedinc then
      t.speed=0
      t.frame = 0
     end
    end

    if on_wall then
     t.jumps = max(t.jumps, 1)
     t.init_tick = nil
    end


    --jump
    if btnn(5,p) and t.jumps > 0 then
     t.jumps -= 1
     t.speedy = -9
    end

    -- todo: this should give a
    -- speed boost but have a 
    -- fixed direction.
    -- less control, but more 
    -- distance
    if on_wall then
     t.speed *= -1
     t.jumps +=1 
     t.init_tick = nil
    end

   if (
    t.y == ground 
    and t.speedy == 0
   ) then
    t.jumps = 2
   end

   t.frame=(t.frame+1)%3

   local map_pos = map_position(t)
   local map_flags =
     band(shl(1,4),
       fget(mget(map_pos[1],
         map_pos[2])))

   if map_flags == 0
     and map_pos[3] then
    map_flags =
     band(shl(1,4),
       fget(mget(map_pos[3],
         map_pos[2])))
   end

   if map_flags != 0 then
    t.speed_blurs = {}
    level_complete()
   end
   -- for i in all(t.speed_blurs) do
   --  i:update()
   -- end
  end,
  draw=function(t)
   -- which direction to draw the
   -- sprite
   local sflip =
     (t.direction == 1)

   -- sprite to draw
   local s = 4
   if abs(t.speedy) == 0 then
    if abs(t.speed) > 0 then
     s = 46
    end

    if (
     abs(t.speed) > 0 
     and abs(t.speed) > abs(t.last_speed)
    ) then
     if not t.pushed then
      t.pushed = g_tick
     end

     s = 4 + ((flr(elapsed(t.pushed) / 3)) % 2)*2
    else
     t.pushed = nil
    end
   else
    if abs(t.speedy) > 0 then
     if t.speedy > 0 then
      s = 10
     else
      s = 8
     end
    end

    if t.jumps == 0 then
     if t.init_tick == nil then
      t.init_tick = g_tick
      t.rot_ctr = 0
     end
     s = 0
     t.rot_ctr += 1
     rotate_sprite_90(38, 0, t.rot_ctr, g_rot_c_cw)
    end
   end
   if t.wall_hang_timer and t.wall_hang_timer > 0 then
    s = 36
   end
   t.last_speed = t.speed

   spr(s,t.x,t.y,2,2,sflip)
   pal()
  end,
  next_to_wall=function (t)
   t.x += t.speed
   local on_wall = next_to_wall(t)
   t.x -= t.speed

   return on_wall
  end,
 }
end

-- function make_violet(p, x, y)
--  return {
--   x=x,
--   y=y,
--   frame=0,
--   hbx0=4,
--   hbx1=12,
--   hby0=0,
--   hby1=16,
--   holding=nil,
--   last_speed=nil,
--   pushed=nil,
--   will_hold=false,
--   is_holdable=false,
--   breaks_blocks=true,
--   jumps=2,
--   wall_hang_timer=nil,
--   speed_blurs={},
--   init_tick=g_tick,
--   rot_ctr=0,
--   ---
--   update=function(t)
--    if t.off then
--     t.frame=0
--     t.xoff = sin(g_tick/100)*10
--     t.yoff = sin(g_tick/200)*10
--
--     if t.trans then
--      return
--     end
--     
--     if btn(0,p) then
--      t.x-=1
--     end
--
--     if btn(1,p) then
--      t.x+=1
--     end
--
--     if t.y > 20 then
--      t.y-=1
--     end
--
--     if t.y < 88 and btn(5,p)
--      then
--       t.off=nil
--       t.x+=t.xoff
--       t.y+=t.yoff
--       t.xoff=nil
--       t.yoff=nil
--       add(g_objs,
--       make_pop(t.x,t.y))
--      end
--
--      return
--     end
--
--     local ground = t:getflr()
--     local spdadj=2
--     local frameadj=1
--
--     -- --run
--     -- if btn(4,p) then
--     --  spdadj=2 --was 2
--     --  frameadj=1
--     --  t.will_hold=true
--     -- else
--     --  t.will_hold=false
--     -- end
--
--     -- state detection
--     local on_wall = t:next_to_wall()
--     local jumping = (t.y != ground)
--
--     if on_wall then
--      if t.wall_hang_timer then
--       t.wall_hang_timer -= 1
--      else
--       t.wall_hang_timer = 10
--      end
--     else
--      t.wall_hang_timer = nil
--     end
--
--     --left
--     if btn(0,p) then
--      if t.direction == 1 then
--       t.frame = 0
--      end
--      if (not jumping) or on_wall or t.speed < 0 then
--       t.direction = 0
--       t.speed =
--       max(-2-spdadj,
--       t.speed-2*t.speedinc)
--      end
--      --right
--     elseif btn(1,p) then
--      if t.direction == 0 then
--       t.frame = 0
--      end
--      if (not jumping) or on_wall or t.speed > 0 then
--       t.direction = 1
--       t.speed =
--       min(2+spdadj,
--       t.speed+2*t.speedinc)
--      end
--      --stop
--     else
--      if abs(t.speed) < 
--       t.speedinc then
--       t.speed=0
--       --t.frame=(t.frame+0.5)%3
--       t.frame = 0
--      end
--     end

       -- @TODO: resume update pulling from here
--
--     if on_wall then
--      t.jumps = max(t.jumps, 1)
--      t.init_tick = nil
--     end
--
--     --jump
--     if btnn(5,p) and t.jumps > 0 then
--      t.jumps -= 1
--     -- if t.y == ground and
--     --   t.speedy == 0 then
--      t.speedy = -9
--     -- end
--
--
--     if on_wall then
--      t.speed *= -1
--      t.jumps +=1 
--      t.init_tick = nil
--     end
--    end
--
--    if t.y == ground and t.speedy == 0 then
--     t.jumps = 2
--    end
--
--    t.frame=(t.frame+frameadj)%3
--
--    local map_pos = map_position(t)
--    local map_flags =
--      band(shl(1,4),
--        fget(mget(map_pos[1],
--          map_pos[2])))
--    
--    if map_flags == 0
--      and map_pos[3] then
--     map_flags =
--      band(shl(1,4),
--        fget(mget(map_pos[3],
--          map_pos[2])))
--    end
--    
--    cls()
--    print(map_flags)
--    if map_flags != 0 then
--     t.speed_blurs = {}
--     level_complete()
--    end
--    for i in all(t.speed_blurs) do
--     i:update()
--    end
--
--    if abs(t.speed) > 0 then
--    end
--   end,
--   next_to_wall=function (t)
--    t.x += t.speed
--    local on_wall = next_to_wall(t)
--    t.x -= t.speed
--
--    return on_wall
--   end,
--   ---
--   draw=function(t)
--    -- @todo: review this function - much of it can be stripped from this build
--    local sflip =
--      (t.direction == 1)
--    local s = 4
--    
--    --duck
--    if g_state == 1
--      and btn(3,p) then
--     s = 14 
--    end
--
--    local ground = t:getflr()
--
--    if t.speed ~= 0 then
--     if ((sflip and t.speed<0) or
--       (not sflip and
--         t.speed > 0))
--       then
--      s=12
--     else
--      s=2*flr(t.frame)+6
--     end
--    end
--    if p==1 then
--     pal(2,3)
--     pal(14,11)
--     pal(8,2)
--    end
--
--    local ntw = t:next_to_wall()
--    
--    if t.y ~= ground then
--     s=0
--     if g_state == 1
--       and (g_tick%4)>2 then
--      s = 2
--     end
--     if ntw then
--      s = 12
--     end
--    end
--    
--    --debug ground detection
--    if false then
--    line(t.x, ground,
--      t.x+16, ground, 7)
--    line(t.x,t.y,t.x+16,t.y,8)
--    if t.gy then
--     line(t.x,t.gy,t.x+16,
--      t.gy,11)
--    end
--    end
--    
--    if t.holding then
--     s+=32
--    end
--    
--    local x = t.x
--    local y = t.y
--    if t.off then
--     s=4
--     if t.xoff then
--      x+=t.xoff
--      y+=t.yoff
--     end
--    end
--
--    s=4
--    local flip_x = false
--    local flip_y = false
--    if abs(t.speedy) == 0 then
--     if abs(t.speed) > 0 then
--      s = 46
--     end
--
--     if abs(t.speed) > 0 and abs(t.speed) > abs(t.last_speed) then
--      if not t.pushed then
--       t.pushed = g_tick
--      end
--
--      s = 4 + ((flr(elapsed(t.pushed) / 3)) % 2)*2
--     else
--      t.pushed = nil
--     end
--    else
--     if t.speedy > 0 then
--      -- @todo: could be removed if it isn't readable.  or maybe turned into a spin jump?
--       s = 10
--     else
--       s = 8
--     end
--
--     if t.jumps == 0 then
--      if t.init_tick == nil then
--       t.init_tick = g_tick
--       t.rot_ctr = 0
--      end
--      s = 0
--      t.rot_ctr += 1
--      rotate_sprite_90(38, 0, t.rot_ctr, g_rot_c_cw)
--     end
--    end
--    if t.wall_hang_timer and t.wall_hang_timer > 0 then
--     s = 36
--    end
--    t.last_speed = t.speed
--
--    -- s=0
--    -- if btn(4) then
--    --  t.rot_ctr += 2
--    -- end
--    -- rotate_sprite_90(38, 0, t.rot_ctr, g_rot_c_cw)
--
--    -- if t.last_speed and abs(t.last_speed) < abs(t.speed) then
--    --  if not t.pushed then
--    --   t.pushed = g_tick
--    --  end
--    --  if t.pushed then
--    --   if elapsed(t.pushed) < 10 then
--    --    s = 6
--    --   end
--    --  end
--    -- elseif abs(t.speed) > 0 then
--    --  s = 46
--    -- end
--    -- t.last_speed = t.speed
--    
--    spr(s,x,y,2,2,sflip)
--    pal()
--    
--    if t.off then
--     s=132
--     if g_tick%20>10 then
--      s=134
--     end
--     spr(s,x,y,2,2)
--    end
--
--    if abs(t.speed) > 3 and not ntw and not t.off then
--     add_particle(t.x, t.y, -1, 1, 30, 6, 0.0625) 
--     if #t.speed_blurs < 10 then
--      add(
--       t.speed_blurs,
--       make_blur(t)
--      )
--     end
--    elseif not ntw then
--     t.speed_blurs = {}
--    end
--
--    for s in all(t.speed_blurs) do
--     s:draw()
--    end
--   end
--   ---
--  }
-- end

function map_position(o)
 local off=getlocaloff()
 local my = flr(
   (o.y-off+o.hby1 -1)/8)+1
 
 local mx = flr((o.x+o.hbx0)/8)
 local mx2 = flr((o.x+o.hbx1)/8)
 
 local mys = getscrmy()
 local r = {
  mx2,
  mys[my]
 }
 
 if mx ~= mx2 then
  add(r, mx2)
 end
 return r 
end

function next_to_wall(o)
 local off=getlocaloff()
 local my = flr((o.y-off)/8)+1
 local mx = flr((o.x+o.hbx0)/8)

 local mx2 =
   min(15,max(0,mx+1))
 local mys = getscrmy()
 
 --hby1/8
 local h=0
 if o.hby1 > 8 then
  h=1
 end
 
 
 local hit=false
 --todo, base on rect
 for i=0,h do
  if band(shl(1,2),
    fget(mget(mx,mys[my+i]))) > 0 then
   hit=true
   break
  end
  if band(shl(1,2),
    fget(mget(mx2,mys[my+i]))) > 0 then
   hit=true
   break
  end
 end

 return hit
end

function overlaps_map_field(o, f)
 for i in all(map_fields_list2(o)) do
  if i == f then
   return true
  end
 end
 return false
end

function map_fields_list2(o)
 local off=getlocaloff()
 local my = flr((o.y-off)/8)+1
 local mx = flr((o.x+o.hbx0)/8)

 local mx2 =
   min(15,max(0,mx+1))
 local mys = getscrmy()
 
 --hby1/8
 local h=0
 if o.hby1 > 8 then
  h=1
 end
 local x_options = {mx, mx2}
 
 local tmp_results = {}
 
 --todo, base on rect
 for i=0,h do
  for x in all(x_options) do
   for n=0,7 do
    if fget(mget(x,mys[my+i]), n) then
     tmp_results[n] = true
    end
   end
  end
 end

 local result = {}
 for i=0,7 do
  if tmp_results[i] == true then
   add(result, i)
  end
 end

 return result
end

function test_xstop(o)
 if (not o.breaks_blocks) return
 
 if next_to_wall(o) then
  if o.speed==0 then
   if o.direction==0 then
    o.x-=1
   else
    o.x+=1
   end
   
  else
   --hack for apple vs violet
   if o.xstop_reverse then
    o.speed*=-1
   else
    o.x+=o.speed*-1 
   end
  end
 end
end

function test_break(o)
 if not o.breaks_blocks then
  return
 end
 if o.speedy >= 0 then
  return
 end
 
 local off=getlocaloff()
 local my =
   flr((o.y-off-1)/8)+1
 
 local mx = flr((o.x+o.hbx0)/8)
 local mx2 =
   min(15,max(0,mx+1))
 local mys = getscrmy()
 
 local mxs={}
 if o.direction==1 then
  add(mxs,mx2)
  add(mxs,mx)
 else
  add(mxs,mx)
  add(mxs,mx2)
 end
 
 for m in all(mxs) do
  if band(fget(mget(m,mys[my])),
    shl(1,1)) > 0 then
    
   o.speedy=abs(o.speedy)
   
   if band(fget(mget(m,mys[my])),
    shl(1,3)) == 0 then
     
     
     --todo, don't make apple
     --if there's already
     --a block there
     local f=false
     if my>1 then
      if band(fget(
        mget(m,mys[my-1])),
          shl(1,1)) > 0 then
       f=true
      end
     end
     
     
     if f or rnd(100) < 10 then
      mset(m,mys[my],0) 
      make_break(m*8,(my-1)*8+off)
     else
      --mset(m,mys[my],88)
      
      mset(m,mys[my],0) 
      make_break(m*8,(my-1)*8+off)
      
      
      local a = make_apple(
        m*8, (my-2)*8+off)
      if o.direction == 0 then
       a.speed = 1
      else
       a.speed = -1
      end
      add(g_objs, a)
     
     end
   end
   
   return
  end
 end
end

function smootherstep(x)
 -- assumes x in [0, 1]
 return x*x*x*(x*(x*6 - 15) + 10);
end

function update_phys(o)
 if o.off then
  return
 end
 if o.held_by ~= nil then
  return
 end

 -- apply zippers 
 if overlaps_map_field(o, f_zipup) then
  o.speedy -= 0.5
 end

 if overlaps_map_field(o, f_zipdown) then
  o.speedy += 0.5
 end

 local ground=o:getflr()
 local drag=o.speedinc
 if o.y ~= ground then
  drag*=g_airdragmod
 end
 
 -- xdrag
 if abs(o.speed) >= drag then
  if o.direction==0 then
   if o.speed < 0 then
    o.speed+=drag
   else
    o.speed-=drag
   end
  else
   if o.speed > 0 then
    o.speed-=drag
   else
    o.speed+=drag
   end
  end
 else
  o.speed=0
 end

 if o.y < ground or o.speedy<0 then
  --o.gy=nil
  o.speedy = min(6, o.speedy+1)
 end


 local off=getlocaloff()

 if o.y >= ground
   and o.speedy >= 0 then
   
  o.gy = o.y
  o.speedy = 0
  o.y = ground
 end
 
 
 local fact = 1
 if o.wall_hang_timer and o.wall_hang_timer > 0 then
  fact = 0.25
 elseif o.wall_hang_timer then
  fact = smootherstep(1-max(-35, o.wall_hang_timer)/(-35))
 end
 o.y+=o.speedy*fact
 o.x+=o.speed
 
 test_xstop(o)
 test_break(o)
 

 if o.x < -16 then
  o.x = 128
 elseif o.x > 128 then
  o.x = -o.hby1
 end
end

function rectintersect(a,b)
 return not (
  b[1] > a[3] or
  b[3] < a[1] or
  b[2] > a[4] or
  b[4] < a[2])
end

function scrtomap(x,y)
--todo, wraparound
 return flr(x/8),
   flr((y+g_scroffset)/8)
end

--sprites are currently
--screenspace so we must
--adjust them when we change
--the scroll position
function scrollby(n)
 --todo, if scrolling by
 --more than -8 at a time
 --call multiple times

 _scrollby(n)
 spawn_sprobj()
end

function _scrollby(n)
 if (n==0) return
 
 local premys=getscrmy()
 
 g_scroffset+=n
 foreach(g_violets, function(v)
  v.y-=n
 end)
 foreach(g_blocks, function(v)
  v.y-=n
 end)
 foreach(g_objs, function(v)
  v.y-=n
 end)
 
 
 local mys=getscrmy()
 local nexty = (mys[17]+1)%32
 
 -- don't do anything unless
 -- we cross the line
 if (premys[17]+1)%32 == nexty
   then
  return
 end
 
 local i=0
 local empty = nexty%4 > 0
 
 
 local mapline =
   flr((128-g_scroffset)/8)+32
 
 local row =
   g_leveltable[mapline]
 
 if row then
  for x = 0, 15 do
   mset(x, nexty, row[x+1])
  end
 else
  for x = 0, 15 do
   mset(x, nexty, 0)
  end
 end
 --taco
 
 --if nexty%4 == 1
 --  and rnd(100) > 20 then
 --  
 -- for i = 0,x15 do
 --  mset(i,nexty,72)
 -- end 
 -- return
 --end
 
 local on = rnd(100)>50 
 local lasts = nil
 
 
  
--  while i<16 do
--   
--   local len=flr(rnd(2))+i+2
--   
--   local s = 0
--   
--    
--   if not empty then
--    if on then
--     if rnd(100) > 50 then
--      s=72
--     else
--      s=71
--     end
--    end
--   end
--   
--   on = not on
--   
--   local start=i
--   for j=i,len do
--    if i > 15 then
--     break
--    end
--    if j==start
--      and i>0
--      and s==0
--      and lasts==71 then
--     mset(i,nexty,87)
--    else
--     mset(i,nexty,s)
--    end
--    i+=1
--   end
--   
--   lasts = s
--   
--  end
 
--  if empty and rnd(100)>50 then
--   local i = flr(rnd(11))
--   local l = flr(rnd(6))+i 
--   for x=i,l do
--    mset(x,nexty,72)
--   end
--  
--  end
 

 
 
end

function shouldscroll()

 -- debug keeping all on screen
 --[[
 for v in all(g_violets) do
  if v.y > 100 then
   return false
  end
 end
 --]]
 
 
 for v in all(g_violets) do
  if v.y < g_scrline and
    v.speedy < 0 then
   return true
  end
 end

 return false
end

function make_break(x,y) 
 for xspd in all(
   {-3,-1.5,1.5,3}) do
  local o = init_phys({
   f=0,
   x=x+1,
   y=y,
   hbx0=0,
   hbx1=1,
   hby0=0,
   hby1=1,
   is_holdable=false,
   draw=function(t)
    sspr(64,32,4,4,t.x,t.y-3,4,4)
   end,
   update=function(t,s)
    t.f+=1
    if t.f >20 then
     del(s,t)
    end
   end
  }
 )
 -- set the initial velocity
 local rndoff=rnd()
 o.speed = xspd+xspd*rndoff
 o.speedy= -4*rndoff
 add(g_objs,o)
 end
 return 
end

function make_pop(x,y)
 return {
  x=x,
  y=y,
  off=true,
  f=0,
  update=function(t,s)
   if t.f==3 then
    del(s,t)
   end
   t.f+=0.5
  end,
  draw=function(t,s)
   spr(136+flr(t.f)*2,t.x,t.y,2,2)
  end
 }
end

d_climbing = {
15,55,
16,54,
17,51,
16,49,
14,49,
11,51,
9,53,
7,57,
7,60,
8,63,
10,64,
13,63,
15,62,
18,59,
21,56,
23,53,
24,50,
23,49, 
21,51,
18,57,
17,62,
18,64,
20,63,
23,60,
25,56,
23,61,
23,63,
24,64,
26,63,
28,60,
30,57,
32,55,
34,55,
34,57,
33,59,
31,62,
30,64,
33,60,
35,57, 
37,55,
38,55,
38,57,
37,59,
36,61,
36,63,
37,64,
39,63,
41,60,
43,56,
47,49,
43,57,
46,55,
47,56,
47,59,
46,61,
45,63,
42,64,
41,63,
41,62,
45,64, 
48,63,
50,60,
52,56,
49,62,
50,64,
52,64,
55,59,
57,55,
56,58,
59,55,
61,55,
61,57,
59,60,
58,63,
59,64,
61,64,
67,63,
65,62,
64,59,
67,56,
69,55, 
70,57,
68,63,
65,69,
63,72,
61,71,
62,68,
64,66,
68,64,
71,63,
72,61
}

d_violets = {
79,48,
78,56,
77,64,
82,57,
87,48,
79,64,
84,64,
86,58,
87,56,
85,63,
86,64,
90,61,
91,57,
93,55,
94,55,
96,56,
96,60,
93,63,
90,63,
90,59,
93,58,
97,59,
101,58,
103,56,
105,52,
104,50,
102,53,
99,60,
99,63,
101,64,
104,62,
106,61,
108,60,
110,57,
109,55,
106,56,
104,62,
106,64,
110,62,
113,58,
115,54,
116,51,
112,54,
115,54,
113,59,
111,62,
113,64,
115,63,
116,62,
118,59,
120,55,
121,58,
120,62,
116,64,
115,59,
120,64,
122,63,
124,61
}  
  
function make_drawon(d, fnc)
 return {
  x=0,
  y=0,
  e=g_tick,
  d=d,
  fnc=fnc,
  update=function(t,s)
   if not t.fnc then
    return
   end
   
   if t.skipped then
    return
   end
   
   if btnn(5, 0) then
    t.skipped = true
    t.fnc(t,s)
    return
   end
   
   if elapsed(t.e) == #t.d/2
     then
    t.fnc(t,s)
   end
  
  end,
  draw=function(t,s)
   
   
   local x,y = t.d[1],t.d[2]
   
   y += sin(g_tick/50+x/200)*6
    
   for i=1,(#t.d/2-1) do
    
    if not t.skipped and
      i > elapsed(t.e)-1 then
     break
    end
    
    local o = 2*i+1
    local nx,ny =
      t.d[o],t.d[o+1]
    
    ny += sin(g_tick/50+nx/200)*6
    
    line(x+1,y+1,nx+1,ny+1,1)
    
    line(x,y,nx,ny,7)
    x,y = nx,ny
    
    
    --if i > g_tick%(#t.d/2) then
    -- break
    --end
    
   end
  
  
  end
  
 }



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

function draw_uiobjs(s)
 foreach(s, function(t)
  if t.draw then
   pushc(-t.x,-t.y)
   t:draw(g_uiobjs)
   popc()
  end
 end)
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
   spr(64,-x,2+10*t.i)
  end,
  update=function(t,s)
   if (t.off) return
   if elapsed(t.s)<(t.e*2) then
    return
   end

   if btnn(5,t.p) then
    if fnc then
     fnc(t,t.i,s)
     sfx(2)
    end
   end

   --cancel
   if btnn(4,t.p) then
    if cfnc then
     cfnc(t,s)
     sfx(2)
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

-------------------------------

-----------------------
-- begin: shared code
-----------------------

-- (itemdef)
-- item type constants

it_none = 0
it_horzblock = 1
it_vertblock = 2
it_platform = 3
it_goal = 4
it_spawn_loc = 5
it_sprobj = 6
it_zipup = 7
it_zipdown = 8

function load_board(sprid)
 local result = {}
 
 local x,y = getsprxy(sprid)
 
 local numscreens,x,y = 
   spr2num(x,y,2)
  
 result.numscreens = numscreens
 
 local items = {}
 result.items = items
 
 local itemtype = nil
 local v = nil
 
 while true do
  itemtype,x,y =
     spr2num(x,y,1)
  
  if itemtype == it_none then
   break
  end
  
  local item = {
   itemtype=itemtype,
  }
  add(items,item)
  
  v,x,y =
     spr2num(x,y,1)
  item.xpos = v
  
  v,x,y =
     spr2num(x,y,2)
  
  item.yscr = v
  
  v,x,y =
     spr2num(x,y,1)
  
  item.ypos = v
  
  local fnc = 
    it_readers[itemtype]
  
  if fnc then
   x,y = fnc(item,x,y)
  end
 
 end

 return result
end

--sprite constants for rendering
--to map table
m_brick = 72
m_platform = 71
m_spawn = 86
m_goal = 87
m_zipup = 89
m_zipdown = 90
 
-- field globals
-- todo: could be better if these 
-- are the shl fields, not integer
-- constants
f_goal = 4
f_zipup = 6
f_zipdown = 5

function board2table(board)
 local t = {}
 
 for y = 1, board.numscreens * 16 do
  local r = {}
  add(t, r)
  for x = 1,16 do
   add(r, 0)
  end 
 end
 
 local function horzrun(x,y,w,m)
  if y < 1 or y > #t then
   return
  end
  for i = x, min(16, x+w-1) do
   t[y][i] = m
  end
 end
 
 -- (itemdef)
 -- items which want to be rendered
 -- should extend this table with
 -- a function which sets the y,x
 -- values of a sequential table
 -- of sequential tables

 local renderfncs = {
  [it_horzblock]=function(item,x,y)
   horzrun(x, y, item.width, m_brick)
  end,
  [it_vertblock]= function(item,x,y)
   for i = y, min(y+item.height-1, #t) do
    t[i][x] = m_brick  
   end
  end,
  [it_platform]=function(item,x,y)
   horzrun(x, y, item.width, m_platform)
  end,
  [it_goal]= function(item, x, y)
   
   for i = y,min(
     y+item.height-1, #t) do
    horzrun(x, i,
      item.width, m_goal)
   end
   
  end,
  [it_spawn_loc] = function(item, x, y)
   t[y][x] = m_spawn
  end,
  
  [it_zipup]= function(item, x, y)
   
   for i = y,min(
     y+item.height-1, #t) do
    horzrun(x, i,
      item.width, m_zipup)
   end
   
  end,
  
  [it_zipdown]= function(item, x, y)
   
   for i = y,min(
     y+item.height-1, #t) do
    horzrun(x, i,
      item.width, m_zipdown)
   end
   
  end,
  
 }
 
 for i = 1, #board.items do
  local item = board.items[i]
  local fnc =
    renderfncs[item.itemtype]
  
  if fnc then
   fnc (
    item,
    item.xpos+1,
    item.yscr*16 + item.ypos+1
   )
  end
 end

 return t
end

-- (itemdef)
-- any object which reads its
-- own fields (beyond ones
-- shared by all objects)
-- should register a function
-- here which fills those into
-- the item and returns the
-- advanced x,y pixel position
it_readers = {
 [it_horzblock]=
   function(item,x,y)
    return loaditemfield(
      item,x,y,1,'width',1)
   end,
 [it_vertblock]=
   function(item,x,y)
    return loaditemfield(
      item,x,y,1,'height',1)
   end,
 [it_platform]=
   function(item,x,y)
    return loaditemfield(
      item,x,y,1,'width',1)
   end,
 [it_spawn_loc]=
   function(item,x,y)
    return loaditemfield(
      item,x,y,1,'width',1)
   end,
 [it_goal]=
   function(item,x,y)
    x,y = loaditemfield(
      item,x,y,1,'width',1)
    x,y = loaditemfield(
      item,x,y,1,'height',1)
    return x,y
   end,
 [it_sprobj]=
   function(item,x,y)
    x,y = loaditemfield(
      item,x,y,1,'objtype')
    return x,y
   end,
   
 [it_zipup]=
   function(item,x,y)
    x,y = loaditemfield(
      item,x,y,1,'width',1)
    x,y = loaditemfield(
      item,x,y,1,'height',1)
    return x,y
   end,
  
 [it_zipdown]=
   function(item,x,y)
    x,y = loaditemfield(
      item,x,y,1,'width',1)
    x,y = loaditemfield(
      item,x,y,1,'height',1)
    return x,y
   end,
}

function loaditemfield(
  item,x,y,w,name,offset)
 local v,x,y =
  spr2num(x,y,w)
 
 if (offset) v += offset
 item[name] = v
 
 return x,y
end

function spr2num(x,y,w)
 local num = 0
 for i = 0, w-1 do
  local v = sget(x,y)
  num = bor(shl(v, 4*i), num)
  
  x,y = nextsprxy(x,y)
 end
 
 return num,x,y
end

function getsprxy(n)
 return (n % 16) * 8,
   flr(n/16) * 8
end

function nextsprxy(x,y)
 x += 1
 if x % 8 == 0 then
  x -= 8
  y += 1
  if y % 8 == 0 then
   y -= 8
   x += 8
   
   --todo, test wrapping
   if x == 128 then
    x = 0
    y += 8
   end
  end
 end
 
 return x,y
end

-----------------------
-- end: shared code
-----------------------


__gfx__
00000088811000000000001881000000000000088811000000000008881100000000088811111110000008881111111000000011881100000000000000000000
09f001118811000009f0011118110000000000111881100000000011188110000000111881188810000011188118881000000111188100000000000000000000
09f009ff1881000009f009ff118100000000009ff18810000000009ff188100000009ff18881110000009ff188811100000001ff118810000000000000000000
0220091ff18110000220091ff188100000000091ff18110000000091ff181100000091ff18110000000091ff18110000000009fff18880000000008881100000
02209ffff188100002209ffff1181000000009ffff188100000009ffff1888100009ffff111000000009ffff111000000000091ff11888800000011188110000
022209fff1881000022209fff11880000000009fff1881000000009fff11111000009fff20229f0000009fff2022000000009ffff1111800000009ff18810000
002220999188100000222099991880000000000222111100000000022200000009f2222222229ff0000f022222229ff0000009ff2111ff000000091ff1811000
0002222222181000000222222211110000000222222220000000002222229f000962222222200000009ff22222ee96f00000022222209f0000009ffff1881000
000022222222000000002222222200000002222222229f000000022222229f0000600eeeeee000000009f20eee2206000000022222220000000009fff1881000
04002222222220000400222222222000009f20eeee009f000009f2eeee00000000064422eeee0000000000ee004460000000029f222200000000009991881000
04000222222222ff04000222222222ff009f0eeeeee0ff000009feeeeee0000000006644eeee000000000e22046600000000029ff22200000000222222221000
042eee22222029ff042eee22222029ff000002220eee0000000002220eee24000000816604220000000002446681000000000229222e00000002222242222000
042eeeee22200090042eeeee222000900600444400ee00600600444400ee246000001100664400000000446600110000000000eeeeee00000002222222222000
0000eeeeeee244000000eeeeeee244000066666666ee660000666666666e240000000000006600600600660000000000000000e244e020000009feeeeee9f000
000000eeeeee2440000000eeeeee24400008100000221000000810000008140000000000008166000066810000000000000000044e2240000009feeeeee99000
000000000eee0040000000000eee0040000110000444100000011000000110000000000000110000000011000000000000000000004400000000444004440000
00000088811000000000001881000000000000888111111100000000011111110000088811111110000008881111111000000011881100000000088811000000
00000111881100000000011118110000009f01118811888100000088881188810000111881188810000011188118881000000111188100000000111881111100
000009ff18810000000009ff11810000009629ff18881110000001118888111000009ff18881110000009ff188811100000001ff1188100000009ff188188810
0000091ff18110000000091ff18810000062291ff1811000000009ff11810000000091ff18100000000091ff18110000000009fff1888000000091ff18811100
00009ffff188100000009ffff118100000649ffff11100000000091ff11100000009ffff111000000009ffff111000000000091ff11888800009ffff11110000
000009fff1881000000009fff1188000816409fff20229f009f09ffff200000009f09fff2020000000f09fff20229ff000009ffff111180000009fff20000000
0000009991881000000000999918800011642e22222229ff09f009fff220000009f2222222229f0009ff222222229ff0000009ff21111000000f022222229f00
09ff22222218100009ff22222211110000642e222222000000622222222000000062222222229ff0009f222222ee00000000002222222090009ff22222229ff0
09f222222222000009f222222222000000600e2222e0000000600eee22e0000000600eeeeee00000000000eeee2206000000022222222f900009f222eee00000
0000222222220000000022222222000000600eeeeee000000006442222ee000000064422eeee000000000e22004406000000022222222f900000000eeeee0000
04000222222200000400022222220000006000eeee00000000006649ff2200000000664404220000000002440400600000000222eee0000000000eeeeeee0000
042eee2222200000042eee222220000000640eeeee00000000008169ff44000000008166004400000000440000660000000002eeeeee00000000022200220000
042eeeee22200000042eeeee2220000081642eeee0000000000011009666006000001100666600600000000066810000000000eeeeee00000600444404440060
0000eeeeeee244000000eeeeeee2440011642eee00000000000000000081660000000000008166000600666600110000000000e244e020000066666666666600
000000eeeeee2440000000eeeeee24400060000000000000000000000011000000000000001100000066810000000000000000044e2240000008100000081000
000000000eee0040000000000eee0040000600000000000000000000000000000000000000000000000011000000000000000000004400000001100000011000
00000000000000007766667700eee8000000000000000000000004004444444444444444444444444444444444444444990009900009000009aaa900aaa9aaa0
0000400000040000788288270e788e800000000000000000001141004aaaaaaaaaa4aaaaaaa4aaaaaaa4aaaaaaa4aaaa00000000009a90009aaaaa90aa909aa0
00b35b0000b35b0087887882e78e88e8000000000000000001b35b10499999999994a9999994afffff94a99f99f4a9990009000009aaa900aaa9aaa099000990
0b7bbb300bb7bb3088888882e8e8e8e800000000000000001b7bbb31499999999994a9999994aff9f994a9ff9ff4a999009a90009aaaaa90aa909aa000000000
0bbbbb300bbbbb3068888826e8e888e800000000000000001bbbb331444444444444444444444444444444444444444409aaa900aaa9aaa09900099000090000
0bbbb3300bbbb33066888266e88eee8e00000000000000001bbb333100000000aaaaaaa4aaaaaaa4aaaaaaa4aaaaaaa49aaaaa90aa909aa000000000009a9000
0bbb33300bbb3330766826670e8888e000000000000000000133331000000000a9999994afff9994a99fff94a99999f4aaa9aaa0990009900009000009aaa900
00333300003333007766667700eeee0000000000000000000011110000000000a9999994aff99994a9fff994a9999ff4aa909aa000000000009a90009aaaaa90
000000000000000000000000088888200000000001111110033333300111111044444444000000000000000000000000dd202dd000000000002d20002ddddd20
00000000000000000000000088ee82600000000001cccc1503bbbb3501cccc1549444494000000000000000000000000ddd2ddd0220002200002000002ddd200
0000000000000000000000008ee826500000000001c1111503b3333501c11115444444440000000000000000000000002ddddd20dd202dd000000000002d2000
0000000000000000000000008e8265760000000001c1cc1503bbbb3501c1cc154444444400000000000000000000000002ddd200ddd2ddd02200022000020000
000000000000000000000000882657620000000001c11c1503333b3501c11c1544444444000000000000000000000000002d20002ddddd20dd202dd000000000
000000000000000000000000826576520000000001cccc1503bbbb3501cccc15444444440000000000000000000000000002000002ddd200ddd2ddd022000220
00000000000000000000000000076572000000000111111503333335011111154944449400000000000000000000000000000000002d20002ddddd20dd202dd0
000000000000000000000000000622220000000000555555005555550055555544444444000000000000000000000000220002200002000002ddd200ddd2ddd0
77666677008888000000000000000000000000000000000000000000444444444444444400000000000000000000000000000000000000000000000000000000
788288270f8ee88000000000000000000000000000000000000000004aaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000
878878828f778e8800000000000000000000000000000000000000004a9999999999999900000000000000000000000000000000000000000000000000000000
888888828e7888e200000000000000000000000000000000000000004a9999999999999900000000000000000000000000000000000000000000000000000000
688888268e8882e20000000000000000000000000000000000000000444444444444444400000000000000000000000000000000000000000000000000000000
6688826688e82e250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76682667088ee2500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666677008225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00881000008810000088100000000000008810000088100000000000111111111111111111111111111111111111111100000000000000000000000000000000
00ff810000ff810000ff81000088100000ff8100f0ff8100000000001333333313b333b31bbb3bbb133333331333333300000000000000000000000000000000
009f8100009f8100009f810000ff8100009f8100209f81000000000013b333b31bbb3bbb13333333133333331333333300000000000000000000000000000000
002228100022281000222810009f810002222f1002222810000000001bbb3bbb13333333133333331333333313b333b300000000000000000000000000000000
022222f0f222220000222200f222220000f220000022222000000000111111111111111111111111111111111111111100000000000000000000000000000000
f0eee00000ee2f0000eef000000eef00002220004eeee0f000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e0e0004eeee000000ee00000e00e0000eee0000000ee4000000000000000000000000000000000000000000000000000000000000000000000000000000000
00404000000004000004400000400400000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007777770000000007777777600000000006000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000770000006600000770000000066000000000000066000000000000000000000000000000000000000000000000000
00000000777777777777000000000000007000000000060007000770000000600000600006000000000000000006600000000000000000000000000000000000
00000077777777777777777777000000070000770000006007007700000000600006600606000600000060000600000000000000000000000000000000000000
00077777777777777777777777770000070007700000006070077000000000060066060606600600000060060600060000000000000660000000000000000000
00777777777777777777777777777000700077000000000670070000000000060060000600000600000006060060060000006000000000000000000000000000
07777777777777777777777777777000700070000000000670000000000000060000600066600000006000060000060000006006000006000000000000060000
07777777777777777777777777777000700000000000000670000000000000060066006060000000000060000660000000000606000006000000000000000000
07777777777777777777777777766700600000000000000670000000000000060000006000600060006600606000000000600000000006000000000000000000
06677777777777777777777777777770600000000000600670000000000000060060606606006000000000600060006000000000006000000000060000000000
00667777777777777777777777777770600000000006600660000000000006060060066000066000006060660600600000660000600000000060000000000600
00076666777777667777777777777760060000000066006060000000000066060606000600660060006006600006600000000000006000600000000000000000
00000667777777766666667677777600060000000660006006000000000660600000660006600060060600060066000000606006060060000000000000000000
00000066667776660066666666666000006000000000060006000000006600600060060600000600000066000660006000000600000000000000000000000060
00000000066666000000000000000000000600000000600000660000000066000000006006006000000000060000060000060000000000000000600606006000
00000000000000000000000000000000000066666666000000006666666600000000066000000000000000000000000000000000006000000000000000000000
4030003e206330204010000f00e635204030003e2063302000000000000000000000000000000000000000000000000000000000000000000000000000000000
55004038de2320e255001018943020ce55004038de2320e200000000000000000000000000000000000000000000000000000000000000000000000000000000
00852700103013400064270040300f16008527001030134000000000000000000000000000000000000000000000000000000000000000000000000000000000
863800e5306f1622191100a580010000863800e5306f171000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e1045260600000018100424000000002e1045260713801000000000000000000000000000000000000000000000000000000000000000000000000000000000
10a536200000000010af15100000000010a536201f16220600000000000000000000000000000000000000000000000000000000000000000000000000000000
0810205500000000a42a10af00000000081020550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202063250000000030105e2700000000202063250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3010000f810338001010000f000000006010000f1059231035402535000000000000000000000000000000000000000000000000000000000000000000000000
3400572c01287d0072001358000000002c001210653010cf30a53040000000000000000000000000000000000000000000000000000000000000000000000000
005f2300128680076008335100000000004c5b002310d720af40504f000000000000000000000000000000000000000000000000000000000000000000000000
5f3400a30000000000106c00000000001010008920822a2022440d62000000000000000000000000000000000000000000000000000000000000000000000000
3800e3540000000071000000000000002900523d262a20c2b40d6680000000000000000000000000000000000000000000000000000000000000000000000000
00102310000000000000000000000000004230002320f23005000000000000000000000000000000000000000000000000000000000000000000000000000000
5f40205f000000000000000000000000df2300e3304f243000000000000000000000000000000000000000000000000000000000000000000000000000000000
12c105f10000000000000000000000002a104110af2b30af00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000b349ae2833b7bb33000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007600760000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000007600007633b7bb330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000080000008076007600000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000800000088600007833b7bb3300000000000000000000000000000000000000000000000000000000
00000000000000000000066666660000000000000000000076000076860000788670067800000000000000000000000000000000000000000000000000000000
00000666666600000000066666660000000000000000000007600760076007608760076800000000000000000000000000000000000000000000000000000000
00000666666606660000066868660000000000000000000033b7bb3333b7bb3333b7bb3300000000000000000000000000000000000000000000000000000000
006666686866666600000666666600000000000000000000b7b77b7b000000000000000000000000000000000000000000000000000000000000000000000000
0660066666666600000006666660000000000000000000003bb66bb3b7b77b7b0000000000000000000000000000000000000000000000000000000000000000
660006666660066066006660006600000000000000000000007676003bb66bb3b7b77b7b00000000000000000000000000000000000000000000000000000000
60066660006000660666066767606600000000000000000087600768007676003bb66bb300000000000000000000000000000000000000000000000000000000
00660667676660060000660006600666000000000000000087600768876007680776676000000000000000000000000000000000000000000000000000000000
06606600000066000006600000666000000000000000000000767600007676008767676800000000000000000000000000000000000000000000000000000000
6666600000000666006600000000660000000000000000003bb77bb33bb77bb33bb77bb300000000000000000000000000000000000000000000000000000000
000600000000000600600000000006600000000000000000b7b66b7bb7b66b7bb7b66b7b00000000000000000000000000000000000000000000000000000000
77666677776666777766667777666677776666777766667777666677776666777766667777666677776666777766667777666677776666777766667777666677
78828827728288277222882772222227722222277222222772222227722222277222222772222227722222277222222772222227722222277222222772222227
87887882878878828788788287887882278878822728788227227882272272822722722227227222272272222722722227227222272272222722722227227222
88888882888888828888888288888882888888828888888288888882888888828888888228888882228888822228888222228882222228822222228222222222
68888826688888266888882668888826688888266888882668888826688888266888882668888826688888266888882668888826688888266888882668888826
66888266668882666688826666888266668882666688826666888266668882666688826666888266668882666688826666888266668882666688826666888266
76682667766826677668266776682667766826677668266776682667766826677668266776682667766826677668266776682667766826677668266776682667
77666677776666777766667777666677776666777766667777666677776666777766667777666677776666777766667777666677776666777766667777666677
77666677776666777766667777666677776666777766667777666677776666777766667700000000000000000000000000000000000000000000000000000000
72222227722222277222222772222227722222277222222772222227722222277222222700000000000000000000000000000000000000000000000000000000
27227222272272222722722227227222272272222722722227227222272272222722722200000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000
62888826622888266222882662222826622222266222222662222226622222266222222600000000000000000000000000000000000000000000000000000000
66888266668882666688826666888266668882666628826666228266662222666622226600000000000000000000000000000000000000000000000000000000
76682667766826677668266776682667766826677668266776682667766826677662266700000000000000000000000000000000000000000000000000000000
77666677776666777766667777666677776666777766667777666677776666777766667700000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994afff11cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777cccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777ccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777cccccccccccccccccccccccccccccccccccccc9994afff11cccccc
cccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777777777777ccccccccccccccccccccccccccccccccccccc9994aff911cccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777777ccccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777777cccccccccccccccccccccccccccccccccccccaaaaaaa411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777667ccccccccccccccccccccccccccccccccccccafff999411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccc667777777777777777777777777777cccccccccccccccccccccccccccccccccccaff9999411cccccc
cccccccccccccccccccccccccccccccccccccccccccccccc66777777777777777777777777777ccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc7666677777766777777777777776cccccccccccccccccccccccccccccccccccaaa4aaaa11cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccc6677777777666666676777776cccccccccccccccccccccccccccccccccccc9994afff11cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccc6666777666cc66666666666ccccccccccccccccccccccccccccccccccccc9994aff911cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666cccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccc
2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2ccccccccc4444444411cccccc
c2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccccccccccaaa4aaaa11cccccc
cc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccccccccc9994afff11cccccc
ccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2cccccccccccc9994aff911cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22cccccccccaaaaaaa411cccccc
dd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcccccccccafff999411cccccc
ddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcccccccccaff9999411cccccc
2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2c2ddddd2ccccccccc4444444411cccccc
c2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccc2ddd2ccccccccccaaa4aaaa11cccccc
cc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccc2d2ccccccccccc9994afff11cccccc
ccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2ccccccc2cccccccccccc9994aff911cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccc
22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22c22ccc22cccccccccaaaaaaa411cccccc
dd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcdd2c2ddcccccccccafff999411cccccc
ddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcddd2dddcccccccccaff9999411cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccaaa9aaacaaa9aaacaaa9aaaccccccccccccccccccccc7777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccaa9c9aacaa9c9aacaa9c9aaccccccccccccccccccccc7777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc99ccc99c99ccc99c99ccc99ccccccccccccccccccccc77777777777777777777777777667ccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccc667777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc9ccccccc9ccccccc9ccccccccccccccccccccccccc66777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc9a9ccccc9a9ccccc9a9ccccccccccccccccccccccccc7666677777766777777777777776cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc9aaa9ccc9aaa9ccc9aaa9cccccccccccccccccccccccccc6677777777666666676777776ccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc9aaaaa9c9aaaaa9c9aaaaa9cccccccccccccccccccccccccc6666777666cc66666666666cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccaaa9aaacaaa9aaacaaa9aaaccccccccccccccccccccccccccccc66666ccccccccccccccccccccccccccc88811ccccccccccccccccccccccccccccccc
ccccccccaa9c9aacaa9c9aacaa9c9aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1118811cccccccccccccccccccccccccccccc
cccccccc99ccc99c99ccc99c99ccc99cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9ff1881cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc91ff1811ccccccccccccccccccccccccccccc
ccccccccccc9ccccccc9ccccccc9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9ffff1881ccccccccccccccccccccccccccccc
cccccccccc9a9ccccc9a9ccccc9a9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9fff1881ccccccccccccccccccccccccccccc
ccccccccc9aaa9ccc9aaa9ccc9aaa9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2221111ccccccccccccccccccccccccccccc
cccccccc9aaaaa9c9aaaaa9c9aaaaa9ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc22222222cccccccccccccccccccccccccccccc
ccccccccaaa9aaacaaa9aaacaaa9aaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222229fccccccccccccccccccccccccccccc
ccccccccaa9c9aacaa9c9aacaa9c9aacccccccccccccccccccccccccccccccccccccccccccccccccccccccc9f2ceeeecc9fccccccccccccccccccccccccccccc
cccccccc99ccc99c99ccc99c99ccc99cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9fceeeeeecffccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222ceeeccccccccccccccccccccccccccccccc
ccccccccccc9ccccccc9ccccccc9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6cc4444cceecc6cccccccccccccccccccccccccccc
cccccccccc9a9ccccc9a9ccccc9a9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666ee66ccccccccccccccccccccccccccccc
ccccccccc9aaa9ccc9aaa9ccc9aaa9cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc81ccccc221cccccccccccccccccccccccccccccc
cccccccc9aaaaa9c9aaaaa9c9aaaaa9ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccc4441cccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444111111111111111111111111111111111111111111111111cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa1333333313333333133333331333333313333333133333331ccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994afff1333333313333333133333331333333313333333133333331ccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff91333333313333333133333331333333313333333133333331ccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444441111111111111111111111111111111111111111111111111ccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa41111111111111111111111111111111111111111111111111ccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994afff11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994afff11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994afff11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77777cccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
7777777cccccccccccccccccccccccccccccccccccccccccccccccccafff999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77777777ccccccccccccccccccccccccccccccccccccccccccccccccaff9999411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77777777cccccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
77777777ccccccccccccccccccccccccccccccccccccccccccccccccaaa4aaaa11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
777777667ccccccccccccccccccccccccccccccccccccccccccccccc9994afff11cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
7777777777cccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
7777777777cccccccccccccccccccccccccccccccccccccccccccccc4444444411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
7777777776ccccccccccccccccccccccccccccccccccccccccccccccaaaaaaa411cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
676777111c111c111c1ccc111cc11ccccc11cccccccccc1c1c111cccaf11199411cccccccc1c1c1c1c11cccccc111ccccc11cccccccccccccccccccccccccccc
66666661cc1c1c1c1c1ccc1cccc1ccccccc1ccc1cccccc1c1c1c1cccaff9199111cccccccc1c1c1c1cc1cccccc1cccccccc1cccccccccccccccccccccccccccc
ccccccc1cc111c11cc1ccc11cc11ccccccc1cccccccccc111c1c1ccc4411144411cccc111c111c111cc1cccccc111cccccc11ccccccccccccccccccccccccccc
ccccccc1cc1c1c1c1c1ccc1cccc1ccccccc1ccc1cccccccc1c1c1cc1aa14aaa111cccccccccc1ccc1cc1cccccccc1cc1ccc1cccccccccccccccccccccccccccc
ccccccc1cc1c1c111c111c111cc11ccccc111ccccccccccc1c111c1c99111fff11cccccccccc1ccc1c111cc1cc111c1ccc11cccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc9994aff911cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000810f0101012020202000000000007000700f402000404040400000000000000001010000000000000000000000000000010101010100000000
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
000100002a05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


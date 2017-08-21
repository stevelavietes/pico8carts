pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- skiiiii

-- todo:
-- tune speed
-- add moguls
-- add weight system
-- some kind of 2nd order system
-- "z-sorted" tree drawing system
-- rocks don't cause crashes at the moment 

-- cool flavor:
-- draw the hat when you crash
-- skis skitter down the mountain
-- upgrading the draw order

-- today:
-- don't spawn trees near the player [x]
-- make trees spawn to the left and right as well as up and down [x]
-- add a point counter for back country mode [x]
-- token pass [x]
-- add music [x]
-- rock spawn location [x]
-- make the camera focus on the finish line when you cross it instead of the player in slalom mode [x]
-- overflow bug
-- fix the player standing back up after crashing
-- add a button prompt with the "dash" button
-- better backcountry score display
-- kill downarrow hunker down mode
-- increase the top speed as the level goes on
-- maybe cheering crowds in slalom mode?  Something else to help cue you for your progress in the level!
-- moguls
-- a jump system
-- refined movement mechanics (I miss the slidey ness of the old system, plus the new system has some quirks - you can slide up the mountain for example).
-- retune camera filter
-- add sfx
 -- turn 
 -- gate hit
 -- gate miss
 -- end of the slalom
 -- menu select

-- @{ one euro filter impl, see: http://cristal.univ-lille.fr/~casiez/1euro/
-- 1 euro filter parameters, tuned to make the effect visible
beta = 0.0001
mincutoff = 0.0001
-- mincutoff = 0.0003

function make_one_euro_filt(beta, mincutoff)
 return {
  first_time = true,
  dx = 0,
  rate = 1/30,
  mincutoff = mincutoff, -- hz
  beta = beta, -- cutoff slope
  d_cutoff = 0, -- derivative cutoff
  xfilt = make_low_pass_filter(),
  dxfilt = make_low_pass_filter(),
  filter=function(t, x)
   if t.first_time then
    t.dx = 0
   else
    t.dx = (x - t.xfilt.hatxprev) * t.rate
   end
   local edx = t.dxfilt:filter(t.dx, t:alpha(t.rate, t.d_cutoff))
   local cutoff = mincutoff + beta * abs(edx)

   return t.xfilt:filter(x, t:alpha(t.rate, cutoff))
  end,
  alpha = function(t, rate, cutoff)
   local tau = 1.0 / (2 * 3.14159 * cutoff)
   local te = 1.0 / rate
   return (1.0 / (1.0 + tau/te))
  end
 }
end

function make_low_pass_filter()
 return {
  first_time = true,
  hat_x_prev = nil,
  hat_x = nil,
  filter = function(t, x, alpha)
   if t.first_time then
    t.first_time = false
    t.hat_x_prev = x
   end
   t.hat_x = alpha * x + (1 - alpha) * t.hat_x_prev
   t.hat_x_prev = t.hat_x
   return t.hat_x
  end
 }
end
-- @}

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

g_mogulneer_accel = 0.8
g_mogulneer_accel = 0.4
-- g_mogulneer_accel = 0.3

collision_objects = {
 {
  x=30,
  y=80,
  width=67,
  height=24,
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
   -- rectfill(t.x, t.y, t.x + t.width, t.y + t.height, 11)
  end
 }
}
-- }

-- { debug stuff can be deleted
function make_debugmsg()
 local maxmem=stat(2)
 local minmem=stat(2)
 return {
  space=sp_screen_native,
  draw=function(t)
   maxmem = max(maxmem, stat(0)/1024)
   -- minmem = min(minmem, stat(2))
   color(14)
   cursor(1,1)
   print("cpu: ".. stat(1))
   print("mem: ".. stat(0)/1024)
   print(" max:" ..maxmem)
   print("gst: "..state_map[g_state])
   if g_p1 then
    print("vel: ".. vecmag(g_p1.vel))
    print("ang: ".. g_p1.angle)
    -- print("g:  ".. repr(g_p1.perp_dot))
    print("d_al:  ".. vecmag(g_p1.drag_along))
    print("d_ag:  ".. vecmag(g_p1.drag_against))
    print("t_a:  ".. vecmag(g_p1.total_accel))
    print("g:  ".. vecmag(g_p1.g))
    if g_p1.amount then
     print("amt:  ".. g_p1.amount)
    end
    -- if not g_p1.svp then
    --  g_p1.svp = null_v
    -- end
    -- print("v_d:  ".. repr(vecdot(g_p1.svp, g_p1.vel)))
    -- print("d_o: ".. g_cam.delta_offset)
   end
  end
 }
end

-- dead code
-- function repr(arg)
--  -- turn any thing into a string (table, boolean, whatever)
--  if arg == nil then
--   return "nil"
--  end
--  if type(arg) == "boolean" then
--   return arg and "true" or "false"
--  end
--  if type(arg) == "table" then 
--   local retval = " table{ "
--   for k, v in pairs(arg) do
--    retval = retval .. k .. ": ".. repr(v).. ","
--   end
--   retval = retval .. "} "
--   return retval
--  end
--  return ""..arg
-- end
-- }

function make_snow_particles()
 local mksnow=function(y)
  add_particle(rnd(128), y, rnd(0.5)-0.25, 0.5+rnd(0.3), 270, 7, 0)
 end

 for i=1,100 do
  mksnow(rnd(128))
 end

 return {
  x=0,y=0,
  update=function(t)
   if g_state == ge_state_menu then
    mksnow(0)
   end
  end,
  draw=function(t)
   process_particles()
  end
 }
end

function spray_particles()
 return {
  x=0,
  y=0,
  angle_last = 0,
  add_trail_spray=function(t)
   local velmag = vecmag(g_p1.vel)
   if velmag < 2 then
    return
   end

   local amount = min(max(remap(velmag, 3, 5, 0, 1), 0.0), 1.0)
   g_p1.amount = amount

   for i=0,25 do
    if rnd() < amount or amount > 0.95 then
     local pos = vecscale(g_p1.ski_vec, rnd(10)-5)
     add_particle(
      g_p1.x+pos.x, g_p1.y+pos.y,
      rnd(0.5)-0.25, 0.5+rnd(0.3),
      270,
      12,
      0
     )
    end
   end
  end,
  add_brake_spray=function(t)
   -- CBB
   if not (btn(0) or btn(1) or btn(5) or btn(2) or btn(3)) then
    return
   end

   -- local v_ag = g_p1.vel_against
   -- local amt = abs(v_ag) / 5

   -- compute the spray angle
   local d_angle = g_p1.angle - t.angle_last
   t.angle_last = g_p1.angle
   local tgt_angle = g_p1.angle
   if d_angle > 0 then
    -- increasing to the right
    tgt_angle -= 0.10
   elseif d_angle < 0 then
    -- decreasing to the left
    tgt_angle += 0.10
   end

   if abs(d_angle) > 0 or t.tgt_angle == nil then
    t.tgt_angle = tgt_angle
   else
    return
   end


   -- vecscale(g_p1.ski_vec_perp, -vecmag(g_p1.vel))
   for i=0,25 do
    local ski_vec = vecfromangle(t.tgt_angle+rnd(0.1)-0.05, vecmag(g_p1.vel)) 
    --+ rnd(0.20) - 0.1, 2+rnd(1)-0.5)
    local off=vecrand(6, true)
    -- local off=vecmake()
    if rnd() < 1 then
      add_particle(
       g_p1.x+off.x,
       -- g_p1.x+off.x-3-g_p1.bound_min.x,
       -- g_p1.x+off.x+rnd(6)-3+g_p1.bound_min.x,
       g_p1.y+off.y,
       -- g_p1.y+off.y-3-g_p1.bound_min.y,
       -- g_p1.y+off.y+rnd(6)-3+g_p1.bound_min.y,
       ski_vec.x,--+rnd(1),
       ski_vec.y,--+rnd(1),
       -- ski_vec.x/1.5,--+rnd(1),
       -- ski_vec.y/1.5,--+rnd(1),
       10,
       6,
       1
      )
     end
   end


   -- take the velocity magnitude and project it along the perpendicular
   -- local vel_along_perp = vecscale(g_p1.ski_vec_perp, (rnd(0.5)+0.5) * vecmag(g_p1.vel))
   -- vel_along_perp = vecscale(vecadd(vel_along_perp, g_p1.vel), rnd(0.5)+0.5)
   --
   -- local amount = 1
   --
   -- for i=0,25 do
   --  if rnd() < amount or amount > 0.95 then
   --   local pos = vecscale(g_p1.ski_vec, rnd(10)-5)
   --   add_particle(
   --    g_p1.x+pos.x, g_p1.y+pos.y,
   --    vel_along_perp.x + rnd(3)-1.5, vel_along_perp.y + rnd(3)-1.5,
   --    270,
   --    12,
   --    g_mogulneer_accel
   --   )
   --  end
   -- end
  end,
  update=function(t)
   t:add_trail_spray()
   t:add_brake_spray()
  end,
  draw=function(t)
   process_particles(sp_world)
  end
 }
end

function make_title()
 -- CBB
 return {
  x=7,
  y=20,
  draw=function()
   -- print("mogulneer", 0, 0, 1)
   -- print("mogulneer", 1, 1, 12)
   spr(128, 0, 0, 16,4)
  end,
 }
end

function _init()
 music(-1)
 g_shake_end = nil
 g_shake_mag = nil
 g_shake_frequency = nil
 g_flash_end = nil
 g_flash_color =nil 

 g_state = ge_state_menu

 particle_array, particle_array_length = {}, 0
 stdinit()

 add_gobjs(make_bg(6))
 add_gobjs(make_title())
 add_gobjs(make_debugmsg())
 add_gobjs(make_snow_particles())
 add_gobjs(
  make_menu(
   {
    'slalom',
    'back country',
   },
   function (t, i, s)
    function done_func()
     if i==0 then
      slalom_start(1)
     else
      backcountry_start()
     end
    end
    add_gobjs(make_snow_trans(done_func, 7))
    add_gobjs(make_debugmsg())
    -- add (
    --  s,
    --  make_trans(
    --  function()
    --   if i==0 then
    --    -- slalom
    --    -- slalom_course_menu()
    --    -- slalom_start(1)
    --    slalom_start(1)
    --    -- add_gobjs(make_snow_trans())
    --   elseif i==1 then
    --    -- back country
    --    backcountry_start()
    --   end
    --  end
    --  )
    -- )
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

-- @{ useful utility function for getting started
function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end

function smootherstep(x)
 -- assumes x in [0, 1]
 return x*x*x*(x*(x*6 - 15) + 10);
end

function remap(
 val,
 i_min, 
 i_max,
 o_min,
 o_max
)
 return (
  (
   o_min 
   + (
    (val - i_min) 
    * (o_max-o_min)
    /(i_max-i_min)
   )
  )
 )
end
-- @}

-- @{ vector library
-- function vecdraw(v, c, o)
--  if not o then
--   o = vecmake()
--  end
-- --  local end_point = vecadd(o, vecscale(vecnormalized(v), 5))
--  local end_point = vecadd(o, vecscale(v, 30))
--  line(o.x, o.y, end_point.x, end_point.y, c)
--  return
-- end

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

-- function vecclamp(v, min_v, max_v)
--  return vecmake(
--   min(max(v.x, min_v.x), max_v.x),
--   min(max(v.y, min_v.y), max_v.y)
--  )
-- end
-- @}

-- @{ built in diagnostic stuff
function make_player(p)
 return {
  x=0,
  y=0,
  p=p,
  space=sp_world,
  c_objs={},
  -- pose goes from -4 to +4
  pose=4,
  vel=vecmake(0),
  vel_along=0,
  vel_against=0,
  bound_min=vecmake(-3, -4),
  bound_max=vecmake(2,0),
  angle=0, -- ski angle
  ski_vec=null_v,
  ski_vec_perp=null_v,
  wedge=false,
  trail_points={},
  crashed=false,
  last_push=g_tick,
  c_drag_along=0.02,
  c_drag_against=0.2,

  -- debug variables
  g=null_v,
  total_accel=null_v,
  drag_along=null_v,
  drag_against=null_v,
  update=function(t)
   -- crash case
   if t.crashed then
    t.vel = vecscale(t.vel, 0.9)
    vecset(t, vecadd(t, t.vel))
    if vecmagsq(t.vel) < 0.1 then
     g_cam.drift = true
     g_cam.last_target_point = t
     function done_func()
      make_score_screen(g_bc_score, true)
     end
     add_gobjs(make_snow_trans(done_func, 7, 45))
     -- t.celebrate = g_tick
    end
    return
   end

   t.wedge = true
   local tgt_dir = nil
   if btn(0, t.p) then
    -- left
    tgt_dir = -0.5

    t:horizontal_push(0)
   end 
   if btn(1, t.p) then
    -- right

    if tgt_dir != nil then
     t.wedge = true
    else
     tgt_dir = 0
    end
    t:horizontal_push(1)
   end
   if btn(3, t.p) then
    -- down
    tgt_dir = -0.25
    if t.angle == -0.25 then
     t.wedge = false
    end
   end
   if btnn(2, t.p) then
    -- up
    if abs(t.angle) < 0.25 then
     t.angle = 0
    else
     t.angle = -0.5
    end
   end
   if btnn(4, t.p) then
    -- z
    -- @TODO: jump
   end
   if btn(5, t.p) then
    -- loaded_ski = g_ski_both
    t.wedge = false
    -- x
   end

   -- sets up the current direction of the skis, "brakes"
   if tgt_dir then
    if tgt_dir > t.angle then
     t.angle = min(t.angle + 0.015, 0)
    elseif tgt_dir < t.angle then
     t.angle = max(t.angle - 0.015, -0.5)
    end

    if tgt_dir == -0.25 and abs(t.angle +0.25) < 0.015 then
     t.angle = -0.25
    end
   end

   -- compute the acceleration
   t.total_accel = t:acceleration()

   -- euler integration for now
   t.vel = vecadd(t.vel, t.total_accel)
   vecset(t, vecadd(t, t.vel))
   updateobjs(t.c_objs)

   for i=#t.trail_points,1,-1 do
    if (t.y - t.trail_points[i].y > 100) then
     del(t.trail_points, t.trail_points[i])
    end
   end

   t:add_new_trail_point(t)
  end,
  acceleration=function(t)
   -- cbb
   -- local brake_force = t:brake_force()

   -- ski direction unit vector
   local ski_vec = vecfromangle(t.angle)
   t.ski_vec = ski_vec
   local perpendicular = t.angle - 0.25
   if t.angle > -0.25 then
    perpendicular = t.angle + 0.25
   end
   local ski_vec_perp = vecfromangle(perpendicular)
   t.ski_vec_perp = ski_vec_perp

   local drag_multiplier = 1
   if t.wedge then
    drag_multiplier = 5
   end

   -- component of gravity along the skis (acceleration)
   -- local g = vecscale(ski_vec, vecdot(vecmake(0, g_mogulneer_accel), ski_vec))
   -- local g = vecmake(0, g_mogulneer_accel)

   -- drag against @{ 
   -- velocity adjustment 
   -- 1 1 1 1       0.5     0.0
   --      0.5  --- 1.0  -- 1.5
   -- t.g = g
   -- t.g = vecsub(
   --  g,
   --  vecmake(
   --     0, 
   --     vecdot(vecmake(0, -g_mogulneer_accel), ski_vec_perp)
   --  )
   -- )
   -- g = t.g
   g = vecscale(ski_vec, ski_vec.y * g_mogulneer_accel)
   t.g = g

   local vel_along  = vecdot(ski_vec, t.vel)
   t.vel_along = vel_along
   -- local vel_mag_sq  = vecmagsq(t.vel)
   local vel_against = vecdot(ski_vec_perp, t.vel)
   t.vel_against = vel_against

   -- drag along the ski is against the component of velocity along the ski
   t.drag_along = vecscale(ski_vec, -t.c_drag_along * drag_multiplier * vel_along*abs(vel_along))

   t.drag_against = vecscale(
    ski_vec_perp,
    -t.c_drag_against * drag_multiplier * (vel_against * abs(vel_against))
   )
   -- @}

   -- if brake force is a thing
   -- return vecadd(
   --  vecadd(g, vecadd(t.drag_along, t.drag_against)),
   --  brake_force
   -- )
   return vecadd(g, vecadd(t.drag_along, t.drag_against))
  end,
  -- brake_force=function(t)
  --  -- if not t.wedge then
  --  if true then
  --   return vecmake()
  --  end
  --
  --  return vecscale(t.vel, -0.3)
  -- end,
  horizontal_push=function(t, dir)
   if (
    btnn(dir, t.p) 
    and t.angle == -0.5 + 0.5*dir 
    and elapsed(t.last_push) > 10 
   )
   then
    -- push right
    t.vel = vecadd(t.vel, vecmake(-0.5+dir, 0))
    t.last_push = g_tick
   end
  end,
  draw=function(t)
   local pose = flr((t.angle + 0.25)*16)

   -- trail renderer
   -- @TODO: make this render behind the trees
   for i=2,#t.trail_points do
    for x_off=-1,1,2 do
     local p1 = vecsub(t.trail_points[i-1], t)
     local p2 = vecsub(t.trail_points[i], t)
     line(p1.x + x_off, p1.y, p2.x + x_off, p2.y, 6)
    end
   end

   -- skis are in the sprite for the crash case
   if not t.crashed then
    for x_off in all({-1, 1}) do
    -- for x_off in all({1}) do
     -- draw the skis
     local ang = t.angle
     local offset = 1
     if t.wedge then
      ang = t.angle-0.06*x_off
      offset = 2
     end

     local turn_off = vecscale(vecmake(cos(ang+0.25*x_off), sin(ang+0.25*x_off)), offset)

     local first_p = vecscale(vecmake(cos(ang), sin(ang)),4)
     local last_p  = vecscale(first_p, -1)

     -- if not t.wedge then
      first_p = vecadd(first_p, turn_off)
      last_p = vecadd(last_p, turn_off)
     -- end

     line(first_p.x, first_p.y, last_p.x, last_p.y, 4)
     -- line(first_p.x, first_p.y, 0, 0, 4)
     circfill(first_p.x, first_p.y, 1, 8)
    end
   end

   -- circfill(0, 0, 1, 11)

   -- draw_bound_rect(t, 11)
   -- hit box stuff (might need it later)
   -- spr(2, -3, -3)
   -- rect(-3,-3, 3,3, 8)
   -- print(str, -(#str)*2, 12, 8)
   g_cursor_y=12
   print_cent("pose: " .. pose, 8)
   -- print_cent("world: " .. t.x .. ", " .. t.y, 8)
   -- print_cent("g_p1: " .. g_p1.x .. ", " .. g_p1.y, 8)
   -- print_cent("load_left: " .. t.load_left, 8)
   -- print_cent("load_right: " .. t.load_right, 8)
   -- print_cent("vel: " .. vecmag(t.vel), 8)
   -- print_cent("drag acceleration: " .. repr(t:drageration()), 8)
   -- print_cent("angle: " .. t.angle, 8)

   -- @{ acceleration components
   -- if t.drag_against != nil then
   -- if false then
    -- print_cent("v_g: " .. vecmag(t.grav_accel), 2)
    -- print_cent("v_d_along: " .. vecmag(t.drag_along), 12)
    -- print_cent("v_d_against: " .. vecmag(t.drag_against), 1)
    -- print_cent("v_t: " .. vecmag(t.total_accel), 9)
    -- print_cent("vel_ang: " .. t.vel_angle, 8)
    -- print_cent("vel: " .. repr(vecnormalized(t.vel)), 8)
    -- vecdraw(t.drag_along, 12)
    -- vecdraw(t.drag_against, 1)
    -- vecdraw(t.total_accel, 9)
    -- vecdraw(t.vel, 2)
    -- vecdraw(t.vel, 11)
   -- end
   -- print_cent("angle: " .. t.angle, 8)
   -- print_cent("pose: ".. pose, 8)
   -- print_cent("v_b: " .. t.angle, 8)
   -- print_cent("v_d: " .. t.angle, 8)
   -- @}

   -- if false then
   local offset = 0

   palt(0, false)
   palt(3, true)
   if t.wedge then
    palt(14, false)
    pal(14, 11)
    pal(13, 11)
   else
    palt(14, true)
    palt(13, true)
    offset = 2
   end
   local sprn = 17+abs(pose)*2
   if t.crashed then
    sprn = 29
   elseif sprn == 25 and elapsed(t.last_push) < 5 or vecmag(t.vel) < 0.1 then
    -- @TODO: do something with the hood when you're not moving... celeste?
    sprn = 27
   end

   spr(sprn, -8, -11 + offset, 2, 2, pose < 0)
   palt()
   pal()

   drawobjs(t.c_objs)
   print_cent("sprn: ".. sprn, 8)

   -- draw_bound_rect(t, 11)
  end,
  add_new_trail_point=function(t, p)
   p = vecflr(p)
   local last_point = t.trail_points[#t.trail_points]
   if (
     last_point == nil or
     last_point.x != p.x or
     last_point.y != p.y
   ) then
    add(t.trail_points, p)
   end
  end
 }
end

g_epsilon = 0.001

function make_camera()
 return {
  x=30,
  y=60,
  low_pass=make_one_euro_filt(beta, mincutoff),
  delta_offset = 0,
  drift = false,
  last_target_point = nil,
  drift_start = nil,
  update=function(t)
   if g_state != ge_state_playing then
    return
   end

   local offset = 20

   if g_p1.vel then
    offset += g_p1.vel.y*10
   end

   local new_offset = t.low_pass:filter(offset)
   t.delta_offset = new_offset - offset
   local target_point = vecadd(g_p1, vecmake(0, new_offset))

   if not t.drift then
    t.last_target_point = target_point
    t.last_vel = g_p1.vel
   else
    if not t.drift_start then
     t.drift_start = g_tick
    end
    target_point = t.last_target_point
    if elapsed(t.drift_start) < 20 then
     vecset(
      t.last_target_point,
      vecadd(
       t.last_target_point,
       veclerp(t.last_vel, null_v, elapsed(t.drift_start)/10)
      )
     )
    end
   end
   -- vecset(t,target_point)

   vecset(t,veclerp(t,target_point,0.2,0.7))

   if g_shake_end and g_tick < g_shake_end then
    if (
     not g_shake_frequency
     or ((g_shake_end - g_tick) % g_shake_frequency) == 0
    ) then
     vecset(t, vecadd(t, vecrand(g_shake_mag, true)))
    end
   end

   -- Fix floating point math on the camera  -> integer position
   -- removes "sizzles" in the position of all the objects esp. after
   -- filtering the position of the camera.
   vecset(t, vecflr(t))
  end,
  is_visible=function(t, o)
   -- uses a circle based visibility check
   if not o.vis_r or 
    (
     (
      t.x - 64 - o.vis_r < o.x 
      and t.x + 64 + o.vis_r > o.x
     ) 
     and 
     (
      t.y - 64 - o.vis_r < o.y 
      and t.y + 64 + o.vis_r > o.y
     )
    ) 
   then
    return true
   end

   return false
  end,
 }
end
-- @}

-- gate enums
ge_gate_start = 0
ge_gate_end = 1
ge_gate_left = 2
ge_gate_right = 3
ge_gate_next = 4

ge_state_menu = 0
ge_state_menu_trans = 1
ge_state_playing = 2

state_map = {}
state_map[0] = "menu"
state_map[1] = "menu_trans"
state_map[2] = "playing"

-- gate_str_map = {
--  "start",
--  "end",
--  "left",
--  "right",
--  "next",
-- }

-- gate settings
gate_height = 10 
gate_stem_color = 5
gate_flag_height = 4
gate_flag_width = 4
gate_flag_height_offset = 6

-- track data
tracks = {
 { 
  sel = vecmake(30, 96),
  course = {
   {vecmake(0,    0), 32,  ge_gate_start},
   {vecmake(-32, 50),  0,  ge_gate_right},
   {vecmake(-66, 90),  0},
   {vecmake(-2, 100),  0},
   {vecmake(12,  80),  0},
   {vecmake(62,  80),  0},
   {vecmake(62, 100),  0},
   {vecmake(62, 100),  0},
   {vecmake(42,  80),  0},
   {vecmake(16,  90),  0},
   {vecmake(-2, 100),  0},
   {vecmake(-32, 50),  0},
   {vecmake(-66, 90),  0},
   {vecmake(-2, 100),  0},
   {vecmake(12,  80),  0},
   {vecmake(62,  80),  0},
   {vecmake(62, 100),  0},
   {vecmake(62, 100),  0},
   {vecmake(42,  80),  0},
   {vecmake(16,  90),  0},
   {vecmake(-2, 100),  0},
   -- {vecmake(-32, 50),  0,  ge_gate_right},
   -- {vecmake(-66, 90),  0,  ge_gate_next},
   -- {vecmake(-2, 100),  0,  ge_gate_next},
   -- {vecmake(12,  80),  0,  ge_gate_next},
   -- {vecmake(62,  80),  0,  ge_gate_next},
   -- {vecmake(62,  100),  0,  ge_gate_next},
   -- {vecmake(62,  100),  0,  ge_gate_next},
   -- {vecmake(42, 80),  0,  ge_gate_next},
   -- {vecmake(16, 90),  0,  ge_gate_next},
   -- {vecmake(-2, 100),  0,  ge_gate_next},
   -- {vecmake(-32, 50),  0,  ge_gate_right},
   -- {vecmake(-66, 90),  0,  ge_gate_next},
   -- {vecmake(-2, 100),  0,  ge_gate_next},
   -- {vecmake(12,  80),  0,  ge_gate_next},
   -- {vecmake(62,  80),  0,  ge_gate_next},
   -- {vecmake(62,  100),  0,  ge_gate_next},
   -- {vecmake(62,  100),  0,  ge_gate_next},
   -- {vecmake(42, 80),  0,  ge_gate_next},
   -- {vecmake(16, 90),  0,  ge_gate_next},
   -- {vecmake(-2, 100),  0,  ge_gate_next},
   {vecmake(0,   80), 16,  ge_gate_end},
  }
 },
 { 
  sel = vecmake(60, 45),
  course = {
  }
 }
}

ge_timerstate_stopped = 0
ge_timerstate_running = 1

-- from picotris attack
function make_clock()
 return {
  x=64,
  y=2,
  c=0,
  m=0,
  s=0,
  misses=0,
  state=ge_timerstate_stopped,
  start=function(t)
   t.state = ge_timerstate_running
  end,
  stop=function(t)
   t.state = ge_timerstate_stopped
  end,
  draw=function(t)
   rectfill(-16,-1,16,5,6)
   local mp,sp,cp = '','',''
   if t.m<10 then
    mp=0
   end
   if t.s<10 then
    sp=0
   end
   if t.c < 10 then
    cp=0
   end
   print(mp..t.m..':'..sp..t.s.."."..cp..t.c, -15,0,0)

   local ndigits=6
   if t.misses > 9 then
    ndigits +=1
   end
   if t.misses > 99 then
    ndigits += 1
   end

   local half_len = ndigits/2

   rectfill(-half_len*4, 7, half_len*4, 13, 6)
   print("miss:"..t.misses, -half_len*4+1, 8, 0)
  end,
  update=function(t)
   if t.state == ge_timerstate_stopped then
    return
   end
   t.c+=1
   --fixed-point math not
   --accurate enough for
   --division of seconds.
   --do addition instead
   if t.c>=30 then
    t.c=0
    t.s+=1
    if t.s>=60 then
     t.s=0
     t.m+=1
    end
   end
  end,
  inc_missed_gate = function(t)
   t.misses += 1
   shake_screen(min(15*(vecmag(g_p1.vel)/4), 5), 15, 3)
   flash_screen(4, 8)
  end
 }
end

-- final score display
function make_score_display(base_timer, score_mode)
 local timer = nil
 if not score_mode then
  timer = {
   m=base_timer.m,
   c=base_timer.c,
   s=base_timer.s
  }
 end
 return {
  x=0,
  y=-192,
  start=vecmake(0, -192),
  target=vecmake(0, -4),
  frame=15,
  made=g_tick,
  duration=25,
  space=sp_world,
  update=function(t)
   if t.frame < t.duration then
    vecset(t, veclerp(t.start, t.target, smootherstep(t.frame/t.duration)))
   end

   if t.frame < t.duration + 0 then
    t.frame += 1
    for j=-32,32,8 do
     for i=0,30 do
      local off=vecrand(6, true)
      add_particle(
       j+t.x + off.x+rnd(6)-3,
       t.y + off.y+rnd(6)-3,
       0 + rnd(6)-3,
       3+rnd(1),
       8,
       6,
       0.5 
      )
     end
    end
   end
   if t.made and elapsed(t.made) > 45 then
    t.made = nil
    local event_str = "slalom"
    if score_mode then
     event_str = "backcountry mode"
    end
    add_gobjs(
     make_menu(
      {
       'try '.. event_str.. ' again',
       'main menu',
      },
      function (t, i, s)
       local function done_func()
        if i==0 then
         if score_mode then
          backcountry_start()
         else
          slalom_start(1)
         end
        else
         _init()
        end
       end
       add_gobjs(make_snow_trans(done_func, 7))
       add_gobjs(make_debugmsg())
      end
     )
    )
   end
  end,
  timer_score=function(t)
   local m_t = 0
   if timer.m > 10 then
    m_t = min(9, flr(timer.m/10))
   end
   local m_o = timer.m - 10*flr(timer.m/10)
   -- seconds
   local s_t = 0
   if timer.s > 10 then
    s_t = min(9, flr(timer.s/10))
   end
   local s_o = timer.s - 10*flr(timer.s/10)
   -- centoseconds
   local c_t = 0
   if timer.c > 10 then
    c_t = min(9, flr(timer.c/10))
   end
   local c_o = timer.c - 10*flr(timer.c/10)
   return {m_t, m_o, 10, s_t, s_o, 10, c_t, c_o}
  end,
  backcountry_score=function(t)
   -- pull each digit out and store it
   local score = base_timer.score
   local result = {}
   repeat
    add(result, score % 10)
    score /= 10
   until flr(score) == 0

   -- ugly array flip
   local flipped_result = {}
   for i=#result,1,-1 do
    add(flipped_result, result[i])
   end

   return flipped_result
  end,
  draw=function(t)
   -- minutes
   local gratz_str = "congratulations!"
   local msg_str = "your final time was:"
   if score_mode == true then
    msg_str = "your final score was:"
   end
   g_cursor_y = -12 
   print_cent(gratz_str, 14)
   print_cent(msg_str, 14)

   local char_array = {}
   if score_mode  then 
    char_array = t:backcountry_score()
   else
    char_array = t:timer_score()
   end

   local x_off = -#char_array*4
   palt(3, true)
   palt(0, false)
   pal(7, 2)
   pal(6, 14)
   for i in all(char_array) do
    spr(196+i, x_off, 0, 1, 1, false, false)
    x_off += 8
   end
   pal()
   palt()
   -- print("p: "..t.x.." "..t.y, -12, 12, 11)
   process_particles(sp_world)
  end
 }
end

function make_score_screen(timer, backcountry_mode)
 g_objs = {
  make_bg(7),
  make_score_display(timer, backcountry_mode),
  make_debugmsg(),
 }
 g_cam= nil
 g_p1 = nil
 g_cam = null_v
 g_state = ge_state_menu
end

function make_gate(gate_data, accum_y, starter_objects)
 local index = #starter_objects + 1
 local gate_kind = gate_data[3]
 if gate_kind == ge_gate_next or gate_kind == nil then
  gate_kind = (
   ge_gate_right 
   - starter_objects[#starter_objects].gate_kind 
   + ge_gate_left
  )
 end
 local result = {
  x=gate_data[1].x,
  y=accum_y,
  radius=gate_data[2],
  gate_kind=gate_kind,
  space=sp_world,
  overlaps = false,
  missed=false,
  passed=nil,
  spr_ind=68,
  celebrate = false,
  update=function(t)
   local flash = false
   if abs(g_p1.y - t.y) < 0.5 then
    t.overlaps = true
   elseif t.overlaps or (g_p1.y < t.y and g_p1.y + g_p1.vel.y > t.y) then
    if t.gate_kind == ge_gate_start then
     g_timer:start()
    elseif t.gate_kind == ge_gate_end then
     g_timer:stop()
     g_cam.drift = true
     g_cam.last_target_point = t
     function done_func()
      make_score_screen(g_timer)
     end
     add_gobjs(make_snow_trans(done_func, 7, 45))
     t.celebrate = g_tick
    elseif t.gate_kind == ge_gate_left then
     if g_p1.x > t.x  then
      flash = true
     elseif t.passed == nil then
      t.passed = g_tick
     end
     -- stop()
    elseif t.gate_kind == ge_gate_right then
     if g_p1.x < t.x then
      flash = true
     elseif t.passed == nil then
      t.passed = g_tick
     end
    end
    t.overlaps = false
   end

   if flash and not t.missed then
    g_timer:inc_missed_gate()
    t.missed = true
   end
  end,
  draw=function(t)
   if abs(t.y - g_cam.y) > 70 then
    return
   end
   if t.gate_kind == ge_gate_start or t.gate_kind == ge_gate_end then
    -- flag
    for xdir=-1,1,2 do
     -- stem
     line(xdir * t.radius, 0, xdir*t.radius, -gate_height, gate_stem_color)
     for i=1,gate_flag_height do
      -- confetti
      for j=1,2 do
       if t.celebrate then
        add_particle(
         t.x + xdir * t.radius,
         t.y,
         rnd(4)-2,
         -rnd(3)-1,
         10,
         rnd(14)+2,
         0.5
        )
       end
      -- 
      line(
       xdir*t.radius, -gate_flag_height_offset - i,
       xdir*t.radius + xdir*gate_flag_width, -gate_flag_height_offset - i,
       8
      )
      end
     end
    end
   else
    local offset=0
    local flip = false
    if t.gate_kind == ge_gate_left then
     flip = true

     -- because the sprite is on the left pixel of a 16 wide sprite
     offset = -15  
     pal(12, 8)
     pal(1, 2)
    end
    -- for debugging gate location
    -- circ(0, 0, 5, 9)
    -- circ(0, 0, 1, 9)
    -- circ(0, 0, 0, 11)
    if t.missed then
     -- @TODO: add more juice?
     circ(0, 0, 4, 8)
     -- circ(0, 0, 5, 8)
    end
    if t.passed != nil and not t.missed then
     if elapsed(t.passed) % 2 == 1 then
      t.spr_ind += 2
     end
     if t.spr_ind == 76 then
      t.passed = nil
     end
    end
    spr(t.spr_ind, offset, -16, 2, 2, flip)
    if flip then
     pal()
    end
   end
   -- print(gate_str_map[t.gate_kind+1], 8, 8, 11)
   -- print("d: "..abs(g_p1.y - t.y), 8, 16, 11)
   -- print(t.overlaps, 8, 24, 11)
  end
 }
 return result
end

-- function make_track_mark(track_data)
--  return {
--   x=track_data["sel"].x,
--   y=track_data["sel"].y,
--   draw=function()
--    circfill(0, 0, 5, 11)
--   end
--  }
-- end
--
-- function make_track_marks()
--  result = {}
--  for tr in all(tracks) do
--   add(result, make_track_mark(tr))
--  end
--  return result
-- end


-- constructor for slalom mode
function slalom_start(track_ind)
 g_state = ge_state_playing
 g_objs = {
  make_bg(7),
  make_debugmsg(),
 }

 g_mountain = add_gobjs(make_mountain("slalom", track_ind))
 g_partm    = add_gobjs(spray_particles())
 g_cam      = add_gobjs(make_camera())
 g_p1       = add_gobjs(make_player(0))
 g_timer    = add_gobjs(make_clock())

 -- start the music
 music(10)
end

ramp = {1, 13, 12, 6, 3, 11, 10}

function make_backcountry_points()
 return {
  x=0,
  y=0,
  space=sp_screen_native,
  score=0,
  col=1,
  update=function(t)
   if not g_p1.crashed then
    -- @TODO: make this an exponentional easing function
    t.col = ramp[min(flr((g_p1.vel.y/4) * #ramp)+1, #ramp)]
    t.score += g_p1.vel.y
   end
  end,
  draw=function(t)
   print(t.score, 60, 1, t.col)
  end,
 }
end

function backcountry_start()
 g_state = ge_state_playing
 g_objs = {
  make_bg(7),
  make_mountain("back_country"),
  make_debugmsg(),
 }

 g_bc_score = add_gobjs(make_backcountry_points())
 g_partm    = add_gobjs(spray_particles())
 g_cam      = add_gobjs(make_camera())
 g_p1       = add_gobjs(make_player(0))

 music(0)
end

function make_bg(col)
 col = col or 7

 return {
  draw=function(t)
   stdclscol(col)
  end
 }
end

function make_line(g1, g2)
 return {
  x=0, 
  y=0, 
  space=sp_world,
  g1=g1,
  g2=g2,
  slope=nil,
  offset=nil,
  compute_slope=function(t)
   return (t.g2.y - t.g1.y) / (t.g2.x - t.g1.x)
  end,
  compute_offset=function(t)
   -- t.slope * (x - g1.x) =  (y - g1.y)
   -- t.slope * x - t.slope * g1.x =  (y - g1.y)
   -- x = y / t.slope - g1.y / t.slope + g1.x
   return g1.x - g1.y / t.slope
  end,
  x_coordinte=function(t, y_coordinate)
   if t.slope == nil then
    t.slope = t:compute_slope()
    t.offset = t:compute_offset()
   end
   return  y_coordinate / t.slope + t.offset
  end,
  draw=function(t)
   if abs(t.g2.y - g_cam.y) > 70 and abs(t.g1.y - g_cam.y) > 70 then
    return
   end
   local colors = {8,8,1,2}
   for offset=-1,1,2 do
    for i=0,3 do
     local mult = 50+i
     local c = colors[i+1]
     line(g1.x + mult*offset, g1.y, g2.x + mult*offset, g2.y, c)
    end
   end
  end
 }
end

function backcountry_random_tree_loc(y_loc)
 local off = g_cam or null_v

 local new_loc = nil
 repeat
  new_loc = vecmake(off.x + rnd(192)-96, y_loc)
 until (abs(new_loc.x) > 90)

 return new_loc
end

function make_mountain(kind, track_ind)
 local trees = {}
 local starter_objects = {}
 local lines = {}

 if kind == "slalom" then
  local gates = {}
  starter_objects = {}

  -- @todo: add flags and route here
  local accum_y = 0
  for gate in all(tracks[track_ind]["course"]) do
   accum_y += gate[1].y
   add(gates, make_gate(gate, accum_y, gates))
  end
  for i=2,#gates do
   local p1 = gates[i-1]
   local p2 = gates[i]

   add(lines, make_line(gates[i-1], gates[i]))
  end
  for l_obj in all(lines) do
   add(starter_objects, l_obj)
  end
  for g_obj in all(gates) do
   add(starter_objects, g_obj)
  end

  local current_line = 1
  -- i want to place trees 80 units back and 80 units forward
  for i=0,16 do
   local y_c = i*10-80
   local l = lines[current_line]
   if y_c > l.g2.y then
    current_line += 1
    l = lines[current_line]
   end
   -- get the boundaries for the height
   for off=-1,1,2 do
    for j=1,4 do
     local off_x = off*90
     local rndloc = vecmake(
      rnd(40)-20 + off_x + l:x_coordinte(y_c),
      rnd(12)-6 + y_c
     )
     add(trees, make_tree(rndloc))
    end
   end
  end
 else
  -- backcountry mode
  for i=0,50 do
   local rndloc = backcountry_random_tree_loc(i*12-300)
   add(trees, make_tree(rndloc, true))
  end
  for i=0,5 do
   local rndloc = vecmake(rnd(128)-64, i*120-300)
   add(trees, make_rock(rndloc))
  end
 end
 return {
  x=0,
  y=0,
  sp=sp_world,
  c_objs=starter_objects,
  -- p_objs={make_boundary(-96,96)},
  p_objs=trees,
  lines=lines,
  line_for_height=function(t, y)
   for i=1,#lines do
    if t.lines[i].g2.y > y then
     return t.lines[i] 
    end
   end
   return t.lines[#lines]
  end,
  update=function(t)
   updateobjs(t.p_objs)
   updateobjs(t.c_objs)

   -- check to see if we need to bump the tree down
   if kind != "slalom" then
    for o in all(t.p_objs) do
     if g_cam.y - o.y > 300 then
      vecset(o, backcountry_random_tree_loc(g_cam.y))
     elseif abs(g_cam.x - o.x) > 60 then
      -- vecset(o, backcountry_random_tree_loc(5))
      -- vecset(o, backcountry_random_tree_loc(g_cam.y))
     else
      if overlaps_bounds(o, g_p1) and not g_p1.crashed then
       g_p1.crashed = true
       shake_screen(min(15*(vecmag(g_p1.vel)/4), 5), 15, 3)
       flash_screen(4, 8)
      end
     end
    end
   end
  end,
  draw=function(t)
   drawobjs(t.p_objs)
   drawobjs(t.c_objs)
  end
 }
end

function flash_screen(duration, c)
 g_flash_end = g_tick + duration + 1
 g_flash_color = c
end

function shake_screen(duration, magnitude, frequency)
 g_shake_end = g_tick + duration + 1
 g_shake_mag = magnitude
 g_shake_frequency = frequency
end

function make_boundary(xmin, xmax)
 return {
  x=0,
  y=0,
  space=sp_world,
  xmin=xmin,
  xmax=xmax,
  draw=function(t)
   -- min line
   line(t.xmin, g_cam.y-64, t.xmin, g_cam.y+64, 8)
   -- max line
   line(t.xmax, g_cam.y-64, t.xmax, g_cam.y+64, 8)
  end
 }
end

function respawn_object(t, anywhere)
 if g_cam.y - t.y > 80 then
  t.y += 160
  if anywhere then
   t.x = rnd(192) - 92
   if g_p1.x == 0 and g_p1.y == 0 and abs(t.y) < 10 then
    repeat
     t.x = rnd(192) - 92
    until (abs(t.x) > 30)
   end
  else
   local flip = 110
   local rnd_off = rnd(80) - 40
   if rnd(1) > 0.5 then
    flip *= -1
   end
   t.x = flip + rnd_off+ g_mountain:line_for_height(t.y):x_coordinte(t.y)
  end
 end

 if anywhere then
  if abs(g_cam.x - t.x) > 80 then
   if g_cam.x > t.x then
    t.x += 160
   else
    t.x -= 160
   end
  end
 end
end

function make_tree(loc, anywhere)
 return {
  x=loc.x,
  y=loc.y,
  space=sp_world,
  radius=3,
  bound_min=vecmake(-2,9),
  bound_max=vecmake(1,12),
  flip=rnd(1) > 0.5,
  update=function(t)
   respawn_object(t, anywhere)
  end,
  draw=function(t)
   -- if abs(t.y - g_cam.y) > 70 then
   --  return
   -- end
   -- spr(-2,-2,1,2,10)
   spr(15, -4, -4, 1, 2, t.flip)
   -- rect(-4,-4,4,4,11)
   -- draw_bound_rect(t, 11)
  end
 }
end

function make_rock(loc)
 return {
  x=loc.x,
  y=loc.y,
  space=sp_world,
  radius=3,
  index=flr(rnd(4)),
  bound_cent=vecmake(0, 9),
  update=function(t)
   respawn_object(t, true)
  end,
  draw=function(t)
   spr(96+t.index, -4, -4, 1, 2)
  end
 }
end

function draw_bound_circ(obj, col)
 circ(obj.bound_cent.x, obj.bound_cent.y, obj.radius,col)
end

function draw_bound_rect(obj, col)
 rect(
  obj.bound_min.x,
  obj.bound_min.y,
  obj.bound_max.x,
  obj.bound_max.y,
  col
 )
end

function overlaps_bounds(fst, snd)
 if fst == snd or not fst or not snd then
  return false
 end
 if not fst.bound_min or not snd.bound_min or 
   not fst.bound_max or not snd.bound_max then
  return false
 end
 -- hb: x0, y0, x1, y1
 
 local fst_pos = {fst.x, fst.y}
 local snd_pos = {snd.x, snd.y}
 local fst_bmin = {fst.bound_min.x, fst.bound_min.y}
 local fst_bmax = {fst.bound_max.x, fst.bound_max.y}
 local snd_bmin = {snd.bound_min.x, snd.bound_min.y}
 local snd_bmax = {snd.bound_max.x, snd.bound_max.y}
 for dim=1,2 do
  fst_dim = {
   fst_bmin[dim] + fst_pos[dim],
   fst_bmax[dim] + fst_pos[dim]
  }
  snd_dim = {
   snd_bmin[dim] + snd_pos[dim],
   snd_bmax[dim] + snd_pos[dim]
  }
  if (
   (fst_dim[2] < snd_dim[1])
   or
   (fst_dim[1] > snd_dim[2])
  ) then
   return false
  end 
 end
 
 return true
end

function print_cent(str, col)
 print(str, -(#str)*2, g_cursor_y, col)
 g_cursor_y += 6
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

-- use whatever the current optimal method is for drawing this stuff
function stdcls()
 rectfill(127,127,0,0,0)
end

function stdclscol(col)
 rectfill(127,127,0,0,col)
end

function stddraw()
 drawobjs(g_objs)

 if g_flash_end and g_tick < g_flash_end then
  for i=1,128 do
   for j=1,128 do
    local col = pget(i, j)
    if col != 7 then
     pset(i, j, g_flash_color)
    end
   end
  end
 else
  g_flash_end = nil
 end
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   local cam_stack = 0
   local t_t = vecflr(t)

   -- i think the idea here is that if you're only drawing local,
   -- then you only need to push -t.x, -t.y
   -- if you're drawing camera space, then the camera will manage the screen
   -- center offset
   -- if you're drawing screen center 
   if t.space == sp_screen_center then
    pushc(-64, -64)
    cam_stack += 1
   elseif t.space == sp_world and g_cam  then
    pushc(flr(g_cam.x) - 64, flr(g_cam.y) - 64)
    pushc(-t_t.x, -t_t.y)
    cam_stack += 2
   elseif not t.space or t.space == sp_local then
    pushc(-t_t.x, -t_t.y)
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

-- @TODO: switch to a table approach instead of object based 
function make_snow_chunk(src, tgt, col, size, nframes, delay)
 local start = g_tick+delay
 return {
  x=src.x,
  y=src.y,
  update=function(t)
   vecset(t, veclerp(t, tgt, elapsed(start)/nframes))
  end,
  draw=function(t)
   circfill(0, 0, size, col)
  end
 }
end

function make_snow_trans(done_func, final_color, delay)
 -- if there is already a transition, don't create a new one.
 if g_trans then
  return
 end
 if not delay then
  delay = 0
 end
 local snow = {}
 local topsize =  16
 for i=1,128,topsize do
  for j=1,128,topsize do
   local tgt = vecmake(i,j)
   local src = vecsub(
    tgt,
    vecsub(vecmake(256), vecflr(vecscale(vecrand(16), 8)))
   )
   local size = topsize+rnd(topsize/4)
   local col = flr(rnd(2))+6
   add(snow, make_snow_chunk(src, tgt, col, size, 30 + rnd(15), delay))
   if col != final_color then
    add(
     snow,
     make_snow_chunk(
      vecsub(src, vecmake(128)),
      tgt,
      final_color,
      size,
      60 + rnd(15),
      delay
     )
    )
   end
  end
 end

 local start=g_tick
 g_trans = {
  x=0,
  y=0,
  space=sp_screen_native,
  snow=snow,
  update=function(t)
   if elapsed(start) > delay then
    g_state = ge_state_menu_trans
    if elapsed(start) - delay > 28 then
     del(g_objs, t)
     g_trans = nil
     done_func()
    end
    updateobjs(snow)
   end
  end,
  draw=function(t)
   if elapsed(start) > delay then
    drawobjs(snow)
   end
  end,
 }
 return g_trans
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

__gfx__
0060000010122101000000003300033000666000000600000000000098899000998899000bb00000000000000000000000000000000000000000000000000000
0066000000088000000c0000300000300633360000636000000000009988990059988990088b0000000000000000000000000000000000000000000000006000
0066600010033001000c00000000000063333360063336000000000049988990599889900888b000000000000000000000000000000000000000000000066000
00666600283083820cc8cc0000030000336663300066600000666000549988905599889908000000000000000000000000000000000000000000000000033000
0066650028380382000c000000000000063336000633360000555600554998995599889908000000000000000000000000000000000000000000000000033000
0066500010033001000c000030000030003330006334336000555500555888885599889928200000000000000000000000000000000000000000000000633600
00650000000880000000000033000330000400000004000000000000000000005588888828200000000000000000000000000000000000000000000000333300
00500000101221010000000000000000000400000004000000000000000000000000000022200000000000000000000000000000000000000000000000333300
33888883333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333306333360
0387978333333333a33333333333333a33333333333333a333333333333333333333333333333333333333333333333333333333333333333333333303333330
30899980333333338333333333333338333333333333333833333333333a33333333333333333333333333333333333333333333333333333333333303333330
3b88888b333333338333333333333338833333333333333883333333333388333333333333333333333333333333333333333333333333333344333363344336
30222220333330388830333333303338880333333333333888333333333388883333333333333333333333333333333333333333333343333443333333344333
43b23b233333308888803333333303888883333333033388888333333333388888833333333388888883333333338888888333333333433344a3333300044000
44bb4bb3333330879780333333330387978033333330338879733333330333887973333333a888888973333333a888888973333333334034b383333300044000
3444344333333089998033333333308999803333333303889980333333300388998b0333333333888993333333333388899333333333490b3883333300044000
0000000033333b88888b333333333b88888b333333333b88888b333333330b088883333333333000b08333333333338888833333333349908883333300000000
000000003333302222203333333330222220333333333302222303333333332222233333333333222223333333333322b223333333334d22b888333300000000
0000000033333322322333333333332232233333333333223223333333333322322333333333333222233333333333320223333333334d228088333300000000
00000000333333dd3dd33333333333dd3dd33333333333dd3dd33333333333dd3dd333333333333dd33333333333333d03333333333393228998333300000000
00000000333333ee3ee33333333333ee3ee33333333333ee3ee33333333333ee3ee333333333333ee33333333333333e03333333333399228978333300000000
00000000333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000
00000000333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000
00000000333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000005c0000000000000000000005c00000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000005cc000000000000000000055c00000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000051cc00000000000000000051cc0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000511cc00000000000000005511c0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000005c11cc0000000000000005cc1c0000000000000000050000000000000000000000000000000000000000000000000000
00666600000000000000000000000000511cc00000000000000055111cc000000000000000550000000000000000000000000000000000000000000000000000
0666666000000000000000000000000051cc0000000000000000511cccc0000000000000055c0000000000000000000000000000000000000000000000000000
666666660000000000000000000000005cc000000000000000055ccc0000000000000000551c0000000000000000000000000000000000000000000000000000
000000000000000000000000000000005c000000000000000005cc0000000000000000055c1c0000000000000000000000000000000000000000000000000000
000000000000000000000000000000005000000000000000000500000000000000000055111c0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500000000000000000550000000000000000055ccccc0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500000000000000000500000000000000000550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000500000000000000005500000000000000005500000000000000005555555555500000000000000000000000000000000
000000000000000000000000000000005000000000000000050000000000000000550000000000000005550cc11c11cc00000000000000000000000000000000
0000000000000000000000000000000050000000000000005500000000000000055000000000000005550000cc111cc000000555555555550000000000000000
00000000000000000000000000000000500000000000000050000000000000005500000000000000550000000cc1cc005555550cc11c11cc0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000066660000066600000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66655660055556600655560000555666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55556556655655500566556006555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66555555555665566555555665556655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000
00000000070000000077000000000007000000000000000000000000000000000000000000007000000000000000000000000000777000000000000000000000
00000000777000000777700000000077700070000000000000000000070000000000000000077700000700000000070000000007777700000000000000000000
07777007777700007777777700000777770777000007700007700000777000000777700000077770007770070000777000000077777770000000000000000000
77777777777770077777777770007777777777000077770077770007777000007777700000077777077770777007777777000777777777770000000000000000
17711171111110111111177711011177111711100117110017711011111000001771117000011111111111771011111111101111117771110000000000000000
1c7cc111cccc101ccccccc7cc101cccccccccc1001ccc10017cc101ccc1000001c7cc1170001ccc11cccccc7101ccccccc101cccccc7ccc11000000000000000
1ccccc1ccccc101cccccccccc101cccccccccc1001ccc1001ccc101ccc1000001ccccc110001ccc11ccccccc101ccccccc101ccccccccccc1000000000000000
1ccccccccccc101cccccccccc101cccccccccc1001ccc1001ccc101ccc1000001cccccc10001ccc11ccccccc101ccccccc101ccccccccccc1000000000000000
1ccccccccccc101ccc1111ccc101ccc1111ccc1001ccc1001ccc101ccc1000001ccc1cc10001ccc11ccc1111101ccc1111101ccc11111ccc1000000000000000
1ccccccccccc101ccc1001ccc101ccc1001ccc1001ccc1001ccc101ccc1000001ccc1cc17001ccc11ccc1000001ccc1000001ccc10001ccc1000000000000000
1ccccccccccc101ccc1001ccc101ccc1001ccc1001ccc1001ccc101ccc1000001ccc1cc11701ccc11ccc1777001ccc1777701ccc10701ccc1000000000000000
1ccc1ccc1ccc101ccc1001ccc101ccc10011111001ccc1001ccc101ccc1000001ccc1ccc1101ccc11ccc1111101ccc1111101ccc17771ccc1000000000000000
1ccc11c11ccc101ccc1001ccc101ccc10000000001ccc1001ccc101ccc1000001ccc11ccc101ccc11ccccccc101ccccccc101ccc11111ccc1000000000000000
1ccc11111ccc101ccc1001ccc101ccc10000000001ccc1001ccc101ccc1000001ccc101cc101ccc11ccccccc101ccccccc101ccccccccccc1000000000000000
1ccc10001ccc101ccc1001ccc101ccc10000770001ccc1001ccc101ccc1000001ccc101cc101ccc11ccccccc101ccccccc101ccccccccccc1700000000000000
1ccc10001ccc101ccc1001ccc101ccc10007777001ccc1001ccc101ccc1000001ccc101cc171ccc11ccc1111101ccc1111101ccccccccccc1100000000000000
1ccc10001ccc101ccc1001ccc101ccc10111111001ccc1001ccc101ccc1000001ccc101cc111ccc11ccc1000001ccc1000001ccc111111ccc170000000000000
1ccc10001ccc101ccc1001ccc101ccc101cccc1001ccc1007ccc101ccc1000001ccc1011cc11ccc11ccc1000001ccc1000001ccc100001ccc110000000000000
1ccc10001ccc101ccc1701ccc101ccc171cccc1001ccc1707ccc101ccc1707001ccc10011cc1ccc11ccc1707001ccc1707001ccc1000011ccc10000000000000
1ccc10001ccc101ccc7701ccc101ccc7711ccc1001ccc7777ccc101ccc1777701ccc10001cc1ccc11ccc1777001ccc1777701ccc1000001ccc10000000000000
1ccc10001ccc101ccc7771ccc101ccc7771ccc1001ccc7777ccc101ccc1111101ccc10001cc1ccc11ccc1111101ccc1111101ccc1000001ccc10000000000000
1ccc10001ccc701ccc7cccccc101ccc7cccccc1001ccc77c7ccc101ccccccc101ccc10001cccccc71ccccccc101ccccccc101ccc1000001ccc10000000000000
1ccc70001cc7771cccccccc77171cccccccc771071cccccccc77171ccccccc171ccc700011cccc771ccccccc101ccccccc101ccc1000007ccc70000000000000
1cc777001c77777ccccccc777777ccccccc7777077ccccccc777777ccccccc771cc77700011cc7777ccccccc107ccccccc707ccc10000777c770000000000000
11777770177777711111177777771111117777707711111177777771111117771177777000117777711111177771111117777711100077777770000000000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc377777733377773337777773377777733777777337777773377777733777777337777773377777733333333300000000
cccccccccccccccccccccccccccccccc376666733376673337666673376666733767767337666673376666733766667337666673376666733337773300000000
cccccccccccccccccccccccccccccccc376776733377673337777673377776733767767337677773376777733777767337677673376776733337673300000000
cccccccccccccccccccccccccccccccc376776733307673337666673307666733766667337666673376666733000767337666673376666733337773300000000
cccccccccccccccccccccccccccccccc376776733337673337677773377776733777767337777673376776733333767337677673377776733337673300000000
ccccccccccccccc1111ccccccccccccc376666733337673337666673376666733000767337666673376666733333767337666673300076733337773300000000
cccccccccccccc117711cccccccccccc377777733337773337777773377777733333777337777773377777733333777337777773333377733330003300000000
cccccccccccccc177771cccccccccccc300000033330003330000003300000033333000330000003300000033333000330000003333300033333333300000000
ccccccccccccc11777711ccccccccccc377777733777777300000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc777ccccccc17777771ccccccccccc376666733766667300000000000000000000000000000000000000000000000000000000000000000000000000000000
cc77777ccccc117777771ccccccccccc376776733767767300000000000000000000000000000000000000000000000000000000000000000000000000000000
c7777777cccc177777771ccccccccccc376666733766667300000000000000000000000000000000000000000000000000000000000000000000000000000000
c77777777cc11777777711cc777ccccc376776733777767300000000000000000000000000000000000000000000000000000000000000000000000000000000
c777777777c17777777771777777cccc376666733000767300000000000000000000000000000000000000000000000000000000000000000000000000000000
c7777777771177777777717777777ccc377777733333777300000000000000000000000000000000000000000000000000000000000000000000000000000000
c77777777717777777777117777777cc300000033333000300000000000000000000000000000000000000000000000000000000000000000000000000000000
777777777117777777777711777777cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7777777771777777777777717777777c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777117777777777777117777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777177777777777777711777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777771177777777777777771177777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777771777777777777777777117777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777711777777777777777777711777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777117777777777777777777771777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777177777777777777777777771177000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77771177777777777777777777777177000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77771777777777777777777777777117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77711777777777777777777777777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77117777777777777777777777777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71177777777777777777777777777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11777777777777777777777777777711000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777777777777777777777777777771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

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
001000000356000000035500000003540000000356003540035400000003540000000354000000035400000007550075400000000000075400754000000000000756007550075400754000000000000000000000
011000000356000000035600000003540000000356003540035400000003540000000354000000035400000007540075400000000000075400754000000000000555005550055500555000000000000000000000
001000000356500000035650000003565035650350003565035000356503565035000b5600b5600b5600b5500b5300b5100b50500000075000750000000000000550005500055000550000000000000000000000
0010000000045000452b6250000000045000002b6250000000045000002b6250000000045000002b6250000000045000452b6250000000045000002b6250000000045000002b6250000000045000002b6252b625
0010000000045000452b6250000000045000002b6250000000045000002b6250000000045000002b625000002b625000052b6252b625000052b6552b625000002b625000052b6252b655000052b6252b6452b655
001000001455214552145521455213552135521355213552135521355213552135521355213532135321151200000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001455214552145521455213550135521355213552125501255212552125521355213552135521355213552135521355213542135421354213532135120000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000955500000095500000009555000000955000000055550000005555000000555500000055550000004555000000455500000045550000004555000000455500000045500000004555000000455000000
000c000000045000002b715000002b625000002a71500000000450000028715000002b62500000287150000000045000002b715000002b625000002b7150000000045000002a715000002b625000002b62500000
010c00001c1221b1221c1221b1221c1221b1221c1221b1221c1221c1221c1221c122000000000000000000001a122181221a122181221a122181221a122181221a1221a1221a1221a12200000000000000000000
010c000017122171221712217122171221712217122171221c1211c1221c1221c1221c1221c1221c1221c1221b1211b1221b1221b1221b1221b1221b1221b1220000000000000000000000000000000000000000
010c00001c1221b1221c1221b1221c1221b1221c1221b1221c1221c1221c1221c1220000000000000001c122101210000010122000001012210122000001a1221012100000101220000010122101221c1211c122
010c00001712200000000000000000000000000000000000101220000000000000000000000000000000000017122000000000000000000000000000000000001312213122000000000010102100001010210122
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
01 00034544
00 01034344
00 00030544
00 01030644
00 00034544
02 02040544
00 41424344
00 41424344
00 41424344
00 41424344
01 10111544
00 10111244
00 10111344
00 10111444
02 10111444
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


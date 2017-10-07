pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- skiiiii

-- todo:
-- tune speed
-- add moguls
-- add weight system
-- some kind of 2nd order system
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
-- fix the player standing back up after crashing [x]
-- bend course to show better which way the player should go [x]
-- use curved lines instead of straight lines [x]
-- penalty for missing gates [x]
-- animation that "pays out" the missed gates penalty on your final time [x]
 -- jump that you can control the height of (like mario) [x]
 -- make skis spread out while jumping [x]
-- kill downarrow hunker down mode [x]
-- a jump system [x]
-- split the spray up into two objects, one underneath the player, one on top
-- can't do ^ because rght now there is one and only one particle bank

-- when flat, the tuck button should give you a push (rather than the arrows)
-- maybe the up button brakes?  increases the drag on both dimensions?
-- after jumping give a boost to drag against and reduction to drag along to get a bit of a zigzag going
-- tune the brake spray to be lighter

-- jump needs to turn off when you land

-- jump:
 -- make you much turnier when you land a jump
 -- wedge is off while jumping
-- overflow bug
-- dash if you cross the gate close to the gate
-- moguls
-- display all gates in the score for slalom
-- add a button prompt with the "dash" button
-- better backcountry score display
-- increase the top speed as the level goes on
-- maybe cheering crowds in slalom mode?  something else to help cue you for your progress in the level!
-- refined movement mechanics (i miss the slidey ness of the old system, plus the new system has some quirks - you can slide up the mountain for example).
-- retune camera filter (add some x to it too?)
-- better spray and better trail particles
-- add sfx
 -- turn 
 -- gate hit
 -- gate miss
 -- end of the slalom
 -- menu select

-- probably not:
-- "z-sorted" tree drawing system

-- mute_debug = true

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
   t.dx = t.first_time and 0 or (x - t.xfilt.hatxprev) * t.rate

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
function add_particle(x, y, dx, dy, life, color, ddy, pass)
 particle_array_length += 1

 -- grow if needed
 if (#particle_array < particle_array_length) add(particle_array, 0)
 
 -- insert into the next available spot
 particle_array[particle_array_length] = {x = x, y = y, dx = dx, dy = dy, life = life or 8, color = color or 6, ddy = ddy or 0.0625, pass = pass or 0}
end


function process_particles(at_scope, pass)
 -- @casualeffects particle system
 -- http://casual-effects.com

 -- simulate particles during rendering for efficiency
 local p = 1
 local off = {0,0}
 if at_scope == sp_world and g_cam != nil then
  off = {-g_cam.x + 64, -g_cam.y + 64}
  -- off = {g_cam.x + 64, -g_cam.y + 64}
 end
 pass = pass or 0
 while p <= particle_array_length do
  local particle = particle_array[p]
  if particle.pass == pass then
  
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

   if g_state == ge_state_menu then
    for _, c in pairs(collision_objects) do
     local collision_result = c:collides(particle)
     if collision_result != nil then
      particle.x += collision_result[1]
      particle.y += collision_result[2]
      particle.dy = 0
      particle.dx = 0
     end
    end
   end

   p += 1
  end -- if alive
 else
  p +=1 
 end
 end -- while
end

collision_objects = {}
-- }

-- g_mogulneer_accel = 0.8
g_mogulneer_accel = 0.4
-- g_mogulneer_accel = 0.3


-- { debug stuff can be deleted
function make_debugmsg()
 local maxmem=stat(2)
 local minmem=stat(2)
 return {
  space=sp_screen_native,
  draw=function(t)
   if mute_debug == true then
    return
   end
   maxmem = max(maxmem, stat(0)/1024)
   -- minmem = min(minmem, stat(2))
   color(14)
   cursor(1,1)
   print("cpu: ".. stat(1))
   print("mem: ".. stat(0)/1024)
   print(" max:" ..maxmem)
   print("gst: "..state_map[g_state])
   -- print("shk: "..repr(g_shake_end))
   -- print("smg: "..repr(g_shake_mag))
   -- print("shf: "..repr(g_shake_frequency))
   -- print("lst: "..repr(last_shake))
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
 return ""..arg
end
-- }

function make_snow_particles()
 return {
  x=0,
  y=0,
  update=function(t)
   if g_state == ge_state_menu then
    -- make snow
    add_particle(rnd(128), 0, rnd_centered(0.5), 0.5+rnd(0.3), 270, 7, 0)
   end
  end,
  draw=function()
   process_particles()
  end
 }
end

function spray_particles()
 return {
  x=0,
  y=0,
  add_trail_spray=function(t)
   local velmag = vecmag(g_p1.vel)
   if velmag < 2 then
    return
   end

   local amount = min(max(remap(velmag, 3, 5, 0, 1), 0.0), 1.0)
   local n_trail_pts = #g_p1.trail_points

   for i=0,25 do
    if rnd() < amount or amount > 0.95 then
     local ind = 1+flr(rnd(min(6, n_trail_pts)))
     pos = vecadd(
      vecscale(g_p1.ski_vec, rnd_centered(6)),
      g_p1.trail_points[n_trail_pts - ind]
     )
     add_particle(
     -- pos
      pos.x, pos.y,
      -- vel
      rnd_centered(0.5), 0.5+rnd(0.3),
      270,
      12,
      0
     )
    end
   end
  end,
  add_brake_spray=function(t)
   if not g_p1.sliding then
    return
   end

   -- compute the spray angle
   -- along the perpendicular

   local mag = -min(abs(g_p1.vel_against/1.5), 1)

   for i=0,25 do
    local ski_vec = vecfromangle(g_p1.perpendicular+rnd_centered(0.2),mag)

    local off=vecadd(
     vecscale(g_p1.ski_vec_perp, -3),
     vecscale(g_p1.ski_vec, rnd_centered(6))
    )
    off = vecadd(off, vecrand(4, true))

    local life = 30+rnd(5)

    -- makes bigger chunks some % of the time
    local num_parts = rnd() < 0.25 and 1 or 0

    for i_x=0,num_parts do
     for i_y=0,num_parts do
      add_particle(
        g_p1.x+off.x+i_x,
        g_p1.y+off.y+i_y,
        ski_vec.x,--+rnd(1),
        max(ski_vec.y, -0.5),--+rnd(1),
        life, -- life
        6, -- col
        -0.01, --ddy
        1
       )
     end
    end
   end
  end,
  update=function(t)
   if not g_p1.jumping then
    t:add_trail_spray()
    t:add_brake_spray()
   end
  end,
  draw=function(t)
   process_particles(sp_world)
  end
 }
end

function make_title()
 return {
  x=0,
  y=-64,
  duration=20,
  start_frame=g_tick-15,
  start=vecmake(-264, -264),
  target=vecmake(8, 20),
  update=function(t)
   local frame = elapsed(t.start_frame)
   if frame < t.duration then
    vecset(t, veclerp(t.start, t.target, smootherstep(frame/t.duration)))

    for j=0,16*8,8 do
     for i=0,30,2 do
      local off=vecadd(t, vecrand(12, true))
      add_particle(
       j+off.x,
       off.y,
       rnd_centered(6),
       1,
       -- 3+rnd(1),
       30+rnd(100),
       7,
       0.5 
      )
     end
    end
   end
  end,
  draw=function()
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
 particle_array, particle_array_length = {}, 0

 stdinit()
 add_gobjs(make_snow_trans(_title_stuff, 6))
end

function _title_stuff()
 g_state = ge_state_menu
 stdinit()
 add_gobjs(make_bg(6))
 add_gobjs(make_title())
 add_gobjs(make_debugmsg())
 add_gobjs(make_snow_particles())
 add_gobjs(
  make_timer(
   10,
   function()
    add(
     collision_objects, 
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
        return {0, -1}
       end
      end
     }
    )
    add_gobjs(make_menu(
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
     end
     )
     )
    end
    )
 )
end

function make_timer(time_to_wait, callback)
 return {
  x=0,
  y=0,
  start=g_tick,
  time_to_wait=time_to_wait,
  callback=callback,
  update=function(t)
   if elapsed(t.start) > t.time_to_wait then
    del(t, g_objs)
    t.callback()
    -- @TODO: why is this not deleting itself?
    t.update = nil
   end
  end
 }
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

function lerp(input, min_out, max_out)
 return input * (max_out - min_out) + min_out
end

function remap(
 val,
 i_min, 
 i_max,
 o_min,
 o_max
)
 return lerp((val-i_min)/(i_max-i_min), o_min, o_max)
end
-- @}

-- @{ vector library
function vecdraw(v, c, scale, o)
 o = o or null_v

 local end_point = vecadd(o, vecscale(v, scale or 30))
 line(o.x, o.y, end_point.x, end_point.y, c)
 return
end

-- @TODO: use this function
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
  -- pose goes from -4 to +4
  pose=4,
  vel=null_v,
  vel_along=0,
  vel_against=0,
  bound_min=vecmake(-3, -4),
  bound_max=vecmake(2,0),
  angle=0, -- ski angle
  perpendicular=0,
  turn_start = nil,
  drag_scale = 1,
  ski_vec=null_v,
  ski_vec_perp=null_v,
  wedge=false,
  trail_points={},
  crashed=false,
  last_push=g_tick,
  c_drag_along=0.02,
  -- c_drag_against=0.1,
  c_drag_against=0.05,
  sliding=false,

  -- jump
  jumping = nil,
  jump_velocity = 0,
  jump_height= 0,

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
     g_cam.last_target_point = veccopy(t)
     function done_func()
      make_score_screen(g_bc_score, true)
     end
     add_gobjs(make_snow_trans(done_func, 7, 45))
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
    t.angle = abs(t.angle) < 0.25 and 0 or -0.5
   end

   if btn(5, t.p) then
    t.wedge = false
   end

   local jmp = btn(4, t.p)
   -- jump button states
   if jmp then
    t.jumping = t.jumping or g_tick
   elseif t.jumping then
    if t.jump_velocity < 0 then
     t.jump_velocity = 0
    elseif t.jump_height == 0 then
     t.jumping = nil
    end
   end

   if t.jumping == g_tick then
    t.jump_velocity = -3
    t.jump_height = 0
    -- jump acceleration == mogulneer acceleration for now
   end

   if t.jumping and t.jump_height <= 0 then
    -- apply euler integration to the jump
    t.jump_velocity += g_mogulneer_accel
    t.jump_height += t.jump_velocity

    -- @todo: this jumping model assumes a flat plane.
    -- should compute the slope of the slope and then figure out when
    -- the player crosses the plane of the snow again.  but this might
    -- just work well enough even though it isn't correct.
    -- could just accumulate the y component of the velocity and then
    -- multiply that by the slope of the slope each tick to move the target
    -- height down each tick  as long as the player falls faster than they move down the slope, they'll hit the ground
    if t.jump_height > 0 then
     -- reset the jump
     t.turn_start = g_tick - 20
     t.jump_height = 0
     t.jump_velocity = 0
    end
   end

   -- tuck based turnability scaling
   local turn_amount = (t.wedge and 0.015) or (t.jumping and 0.018) or 0.011

   -- sets up the current direction of the skis, "brakes"
   if tgt_dir then
    if t.turn_start == nil then
     t.turn_start = g_tick
    end

    if tgt_dir > t.angle then
     t.angle = min(t.angle + turn_amount, 0)
    elseif tgt_dir < t.angle then
     t.angle = max(t.angle - turn_amount, -0.5)
    end

    if tgt_dir == -0.25 and abs(t.angle +0.25) < 0.015 then
     t.angle = -0.25
    end
   else
    t.turn_start = nil
   end

   -- compute the acceleration
   t.total_accel = t.jumping and null_v or t:acceleration()

   -- euler integration for now
   t.vel = vecadd(t.vel, t.total_accel)
   vecset(t, vecadd(t, t.vel))

   for i=#t.trail_points,1,-1 do
    if (t.y - t.trail_points[i].y > 100) then
     del(t.trail_points, t.trail_points[i])
    end
   end

   t:add_new_trail_point(t)
  end,
  acceleration=function(t)
   -- ski direction unit vector
   local ski_vec = vecfromangle(t.angle)
   t.ski_vec = ski_vec
   local perpendicular = t.angle - 0.25
   if t.angle > -0.25 then
    perpendicular = t.angle + 0.25
   end
   local ski_vec_perp = vecfromangle(perpendicular)
   t.ski_vec_perp = ski_vec_perp
   t.perpendicular = perpendicular

   local drag_multiplier = 1
   if t.wedge then
    drag_multiplier = 5
   end

   -- component of gravity along the skis (acceleration)
   local g_accel = g_mogulneer_accel
   local ang_fact = nil
   if abs(t.angle) < 0.05 then
    ang_fact = abs(t.angle) * 5
   elseif abs(t.angle) > 0.45 then
    ang_fact = (0.5 - abs(t.angle)) * 20
   end
   if ang_fact then
    g_accel = smootherstep(ang_fact) * g_mogulneer_accel
   end
   local g = vecscale(ski_vec, g_accel)
   t.g = g

   local vel_along  = vecdot(ski_vec, t.vel)
   t.vel_along = vel_along
   local vel_against = vecdot(ski_vec_perp, t.vel)
   t.vel_against = vel_against

   -- drag along the ski is against the component of velocity along the ski
   t.drag_along = vecscale(
    ski_vec,
    -1 * t.c_drag_along * drag_multiplier * vel_along*abs(vel_along)
   )

   local drag_scale = 1
   if t.turn_start and elapsed(t.turn_start) < 30 then
    drag_scale = cos(elapsed(t.turn_start)/(2*30))
    drag_scale *= drag_scale
   end
   t.drag_scale = drag_scale

   t.drag_against = vecscale(
    ski_vec_perp,
    -drag_scale * t.c_drag_against * drag_multiplier * (vel_against)
   )

   t.sliding = abs(vel_against) > abs(vel_along)

   return vecadd(g, vecadd(t.drag_along, t.drag_against))
  end,
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
  draw=function(t, _, layername)
   local pose = flr((t.angle + 0.25)*16)

   -- trail renderer
   if layername == "backmost" then
    for i=2,#t.trail_points do
     local p1 = vecsub(t.trail_points[i-1], t)
     local p2 = vecsub(t.trail_points[i], t)
     for x_off=-1,1,2 do
      if not t.trail_points[i].gap and not t.trail_points[i-1].gap then
       line(p1.x + x_off, p1.y, p2.x + x_off, p2.y, 6)
      end
     end
    end
    return
   end

   -- skis are in the sprite for the crash case
   if not t.crashed then
    for x_off=-1,1,2 do
     local ang = t.angle
     local offset = 1
     if t.jumping or t.wedge then
      ang = t.angle-0.06*x_off
      if t.jumping then
       ang += 0.08*x_off
      end
      offset = 2
     end

     local jump_off = vecmake(0, t.jump_height)
     local turn_off = vecscale(vecmake(cos(ang+0.25*x_off), sin(ang+0.25*x_off)), offset)
     turn_off = vecadd(turn_off, jump_off)

     local first_p = vecscale(vecmake(cos(ang), sin(ang)),4)
     local last_p  = vecscale(first_p, -1)

     first_p = vecadd(first_p, turn_off)
     last_p = vecadd(last_p, turn_off)

     line(first_p.x, first_p.y, last_p.x, last_p.y, 4)
     circfill(first_p.x, first_p.y, 1, 8)
    end
   end

   -- @TODO: compute the maximum height. should be a quadratic equation.
   if t.jumping then
    local shadow_size = lerp(smootherstep(-t.jump_height/18), 3, 1)
    circfill(0, 0, shadow_size, 5)
   end

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
    -- @todo: do something with the hood when you're not moving... celeste?
    sprn = 27
   end

   -- draw the skier sprite
   spr(sprn, -8, -11 + offset + t.jump_height, 2, 2, pose < 0)
   palt()
   pal()

   g_cursor_y=12
   jump_height_max = max(abs(t.jump_height), jump_height_max)
   if not mute_debug then
    print_cent("sliding: " .. repr(t.sliding))
    print_cent("ski_vec: " .. repr(t.ski_vec_perp))
   -- print_cent("jump_height: " .. t.jump_height, 8)
   -- print_cent("jump_velocity: " .. t.jump_velocity, 8)
   -- print_cent("max height: "..jump_height_max, 8)
   -- print_cent("jumping: "..repr(t.jumping))
   -- print_cent("remain_mag: "..repr(remain_mag), 8)
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
    print_cent("vel_against: " .. repr(t.vel_against), 8)
    -- print_cent("vel: " .. repr(vecnormalized(t.vel)), 8)
    -- vecdraw(t.drag_along, 11)
    -- vecdraw(t.drag_against, 1)
    -- vecdraw(t.total_accel, 9)
    -- vecdraw(t.vel, 2)
    -- vecdraw(vecscale(t.ski_vec, t.vel_along), 4)
    vecdraw(t.ski_vec_perp, 1, 5)
    -- vecdraw(t.vel, 11)
   -- end
   -- print_cent("angle: " .. t.angle, 8)
   -- print_cent("pose: ".. pose, 8)
   -- print_cent("v_b: " .. t.angle, 8)
   -- print_cent("v_d: " .. t.angle, 8)
  end
  end,
  add_new_trail_point=function(t, p)
   p = vecflr(p)
   p.gap = t.jumping
   local last_point = t.trail_points[#t.trail_points]
   if (
     last_point == nil 
     or last_point.x != p.x 
     or last_point.y != p.y
   ) then
    add(t.trail_points, p)
   end
  end
 }
end

function make_camera(x,y)
 return {
  x=x or 30,
  y=y or 60,
  low_pass=make_one_euro_filt(beta, mincutoff),
  delta_offset = 0,
  drift = false,
  last_target_point = nil,
  drift_start = nil,
  update=function(t)
   if g_state == ge_state_menu_trans then
    return
   end

   local target_point = null_v

   if g_p1 then
    local offset = 20
    if g_p1.vel then
     offset += g_p1.vel.y*10
    end

    local new_offset = t.low_pass:filter(offset)
    t.delta_offset = new_offset - offset
    target_point = vecadd(g_p1, vecmake(0, new_offset))

    if not t.drift then
     t.last_target_point = target_point
     t.last_vel = g_p1.vel
    else
     t.drift_start = t.drift_start or g_tick

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
   end

   vecset(t,veclerp(t,target_point,0.2,0.7))

   if g_shake_end and g_tick < g_shake_end then
    if (
     not g_shake_frequency
     or ((g_shake_end - g_tick) % g_shake_frequency) == 0
    ) then
     vecset(t, vecadd(t, vecrand(g_shake_mag, true)))
    end
   end

   -- fix floating point math on the camera  -> integer position
   -- removes "sizzles" in the position of all the objects esp. after
   -- filtering the position of the camera.
   vecset(t, vecflr(t))
  end,
  -- is_visible=function(t, o)
  --  -- uses a circle based visibility check
  --  if not o.vis_r or 
  --   (
  --    (
  --     t.x - 64 - o.vis_r < o.x 
  --     and t.x + 64 + o.vis_r > o.x
  --    ) 
  --    and 
  --    (
  --     t.y - 64 - o.vis_r < o.y 
  --     and t.y + 64 + o.vis_r > o.y
  --    )
  --   ) 
  --  then
  --   return true
  --  end
  --
  --  return false
  -- end,
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

-- debug only
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
  increment=function(t, amount)
   for i=1,amount do
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
   end
  end,
  update=function(t)
   if t.state == ge_timerstate_stopped then
    return
   end
   t:increment(1)
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

   if t.frame < t.duration then
    t.frame += 1
    for j=-32,32,8 do
     for i=0,30 do
      local off=vecrand(6, true)
      add_particle(
       j+t.x + off.x+rnd_centered(6),
       t.y + off.y+rnd_centered(6),
       0 + rnd_centered(6),
       3+rnd(1),
       8,
       6,
       0.5 
      )
     end
    end
   elseif (
    base_timer.misses 
    and base_timer.misses > 0 
    and t.made and (elapsed(t.made) % 15) == 0
   ) then
    base_timer.misses -= 1
    g_timer:increment(50)
    shake_screen(8, 5)
    flash_screen(4, 8)
    -- stop()
   end

   if (
    t.made 
    and elapsed(t.made) > 45 
    and (score_mode or base_timer.misses == 0)
   ) then
    t.made = nil
    local event_str = score_mode and "backcountry mode" or "slalom" 
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
         _title_stuff()
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
   if base_timer.m > 10 then
    m_t = min(9, flr(base_timer.m/10))
   end
   local m_o = base_timer.m - 10*flr(base_timer.m/10)
   -- seconds
   local s_t = 0
   if base_timer.s > 10 then
    s_t = min(9, flr(base_timer.s/10))
   end
   local s_o = base_timer.s - 10*flr(base_timer.s/10)
   -- centoseconds
   local c_t = 0
   if base_timer.c > 10 then
    c_t = min(9, flr(base_timer.c/10))
   end
   local c_o = base_timer.c - 10*flr(base_timer.c/10)
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
   local msg_str = score_mode and "your final score was:" or "your final time was:"

   g_cursor_y = -12 
   if score_mode or base_timer.misses == 0 then
    print_cent(gratz_str, 14)
    print_cent(msg_str, 14)
   end
   g_cursor_y = 9
   if not score_mode then
    print_cent("misses: "..base_timer.misses, 14)
   end

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
 g_p1 = nil
 g_cam = add_gobjs(make_camera(0,0))
 g_state = ge_state_menu
end

function make_gate(gate_data, accum_y, starter_objects)
--  local index = #starter_objects + 1
 local gate_kind = gate_data[3]
 if gate_kind == ge_gate_next or gate_kind == nil then
  gate_kind = (
   ge_gate_right 
   - starter_objects[#starter_objects].gate_kind 
   + ge_gate_left
  )
 end
 local gate_border_offset = 0
 if gate_kind == ge_gate_right then
  gate_border_offset = 30
 elseif gate_kind == ge_gate_left then
  gate_border_offset = -30
 end
 return {
  x=gate_data[1].x,
  y=accum_y,
  gate_border_offset = gate_data[1].x + gate_border_offset,
  radius=gate_data[2],
  gate_kind=gate_kind,
  space=sp_world,
  overlaps = false,
  missed=false,
  passed=nil,
  spr_ind=68,
  celebrate = false,
  update=function(t)
   -- already passed the gate
   if t.passed or t.missed then
    return
   end

   local flash = false

   if abs(g_p1.y - t.y) < 0.5 then
    t.overlaps = true
   elseif t.overlaps or (g_p1.y < t.y and g_p1.y + g_p1.vel.y > t.y) then
    if t.gate_kind == ge_gate_start then
     g_timer:start()
    elseif t.gate_kind == ge_gate_end then
     g_timer:stop()
     g_cam.drift = true
     g_cam.last_target_point = veccopy(t)
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
         rnd_centered(4),
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

    if t.missed then
     -- @TODO: add more juice to missing?
     circ(0, 0, 4, 8)
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
  end
 }
end

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
 in_front_of_player       = add_gobjs(
  {
   x=0,
   y=0,
   draw=function()
    process_particles(sp_world, 1)
    g_mountain:draw_in_front_of_player()
   end
  }
 )

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
    -- @todo: make this an exponentional easing function
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
 g_objs = { make_bg(7) }

 g_mountain = add_gobjs(make_mountain("back_country"))
 add_gobjs(make_debugmsg())

 g_bc_score = add_gobjs(make_backcountry_points())
 g_partm    = add_gobjs(spray_particles())
 g_cam      = add_gobjs(make_camera())
 g_p1       = add_gobjs(make_player(0))
 in_front_of_player       = add_gobjs(
  {
   x=0,
   y=0,
   draw=function()
    process_particles(sp_world, 1)
    g_mountain:draw_in_front_of_player()
   end
  }
 )

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

-- slalom track borders
function make_line(before, g1, g2, after)
 -- hermitian curves
 local m0 = vecmake(0, 1)
 local m1 = vecmake(0, -1)
 if before then
  m0 = vecsub(g1, before)
 end
 if after then
  m1 = vecsub(after, g2)
 end

 local p0 = vecmake(g1.gate_border_offset, g1.y)
 local p1 = vecmake(g2.gate_border_offset, g2.y)

 local pts = {p0}

 --        p0_t                 m0_t                  p1_t              m1_t
 -- p(t) = (2t^3 - 3t^2 +1)p0 + (t^3 - 2t^2 + t)*m0 + (-2t^3+3t^2)*p1 + (t^3-t^2)*m1

 local curve_points = 10
 local last_point = p0
 for z_prime=1,curve_points,1 do
  local z = z_prime/curve_points
  local p0_t = vecscale(p0, (2*z*z*z - 3*z*z + 1))
  local m0_t = vecscale(m0, (z*z*z - 2*z*z + z))
  local p1_t = vecscale(p1, (-2*z*z*z + 3*z*z))
  local m1_t = vecscale(m1, (z*z*z - z*z))
  local p_t = vecadd(vecadd(p0_t, m0_t), vecadd(p1_t, m1_t))
  add(pts, p_t)
  last_point = p_t
 end

 return {
  x=0, 
  y=0, 
  space=sp_world,
  g1=g1,
  g2=g2,
  x_coordinte=function(t, y_coordinate)
   local tgt_ind = #pts
   for i=2,#pts do
    if pts[i].y > y_coordinate then
     tgt_ind = i
     break
    end
   end
   local pt1 = pts[tgt_ind-1]
   local pt2 = pts[tgt_ind]
   return (y_coordinate - pt1.y) * (pt2.x - pt1.x) / (pt2.y - pt1.y) + pt1.x
  end,
  draw=function(t)
   if abs(t.g2.y - g_cam.y) > 70 and abs(t.g1.y - g_cam.y) > 70 then
    return
   end

   local last_point = p0
   local colors = {8,8,1,2}
   for p_ind = 2,#pts,1 do
    local last_point = pts[p_ind-1]
    local p_t = pts[p_ind]

    for offset=-1,1,2 do
     for l_ind=0,3 do
      local i=50+l_ind
      local c = colors[l_ind+1]
      line(last_point.x+offset*i, last_point.y, p_t.x+offset*i, p_t.y, c)
     end
    end
    last_point = p_t
   end
  end
 }
end

function backcountry_random_tree_loc(y_loc)
 local off = g_cam or null_v

 local new_loc = nil
 repeat
  new_loc = vecmake(off.x + rnd_centered(192), y_loc)
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
   add(lines, make_line(gates[i-2], gates[i-1], gates[i], gates[i+1]))
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
      rnd_centered(40) + off_x + l:x_coordinte(y_c),
      rnd_centered(12) + y_c
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
   local rndloc = vecmake(rnd_centered(128), i*120-300)
   add(trees, make_rock(rndloc))
  end
 end
 return {
  x=0,
  y=0,
  sp=sp_world,
  c_objs=starter_objects,
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

   -- check to see if we need to respawn the tree
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
   drawobjs({g_p1}, "backmost")
   drawobjs(t.p_objs, "behind_player")
   drawobjs(t.c_objs)
  end,
  draw_in_front_of_player=function(t)
   drawobjs(t.p_objs, "in_front_player")
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

function respawn_object(t, anywhere)
 if g_cam.y - t.y > 80 then
  t.y += 160
  if anywhere then
   t.x = rnd_centered(192)
   if g_p1.x == 0 and g_p1.y == 0 and abs(t.y) < 10 then
    repeat
     t.x = rnd_centered(192)
    until (abs(t.x) > 30)
   end
  else
   local flip = 110
   local rnd_off = rnd_centered(80)
   if rnd(1) > 0.5 then
    flip *= -1
   end
   t.x = flip + rnd_off+ g_mountain:line_for_height(t.y):x_coordinte(t.y)
  end
  -- cycle objects to end of the list, effectively z-sorting the tree list
  del(g_mountain.p_objs, t)
  add(g_mountain.p_objs, t)
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
  height=flr(rnd(16)),
  update=function(t)
   respawn_object(t, anywhere)
  end,
  draw=function(t)
   sspr(
    120, 0, 8, 16, 
    -4 - t.height/8, -4 - t.height,
    8+t.height/4, 16 + t.height,
    t.flip
   )
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
 col = col or 8
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
-- function stdcls()
--  rectfill(127,127,0,0,0)
-- end

function stdclscol(col)
 rectfill(127,127,0,0,col)
end

function stddraw()
 drawobjs(g_objs)

 if g_flash_end and g_tick < g_flash_end then
  for i=1,128 do
   for j=1,128 do
    if pget(i, j) != 7 then
     pset(i, j, g_flash_color)
    end
   end
  end
 else
  g_flash_end = nil
 end
end

function drawobjs(objs, mode)
 foreach(objs, function(t)
  if mode == "behind_player" then
   if t.y > g_p1.y - 10 then
    return
   end
  elseif mode == "in_front_player" then
   if t.y < g_p1.y - 10 then
    return
   end
  end
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

   t:draw(objs, mode)

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

-- @todo: switch to a table approach instead of object based 
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
 delay = delay or 0

 local snow = {}
 local topsize =  17
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

__gfx__
0060000010122101000000003300033000666000000600000000000098899000998899000bb0000011357bdf0000000000000000000000000000000000000000
0066000000088000000c0000300000300633360000636000000000009988990059988990088b0000fffeeddc0000000000000000000000000000000000006000
0066600010033001000c00000000000063333360063336000000000049988990599889900888b000cbbaa9980000000000000000000000000000000000066000
00666600283083820cc8cc0000030000336663300066600000666000549988905599889908000000877665540000000000000000000000000000000000033000
0066650028380382000c000000000000063336000633360000555600554998995599889908000000433221110000000000000000000000000000000000033000
0066500010033001000c000030000030003330006334336000555500555888885599889928200000111111110000000000000000000000000000000000633600
00650000000880000000000033000330000400000004000000000000000000005588888828200000111111110000000000000000000000000000000000363300
00500000101221010000000000000000000400000004000000000000000000000000000022200000111111110000000000000000000000000000000000333300
33888883333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333306333360
0387978333333333a33333333333333a33333333333333a333333333333333333333333333333333333333333333333333333333333333333333333303336330
30899980333333338333333333333338333333333333333833333333333a33333333333333333333333333333333333333333333333333333333333303333330
3b88888b333333338333333333333338833333333333333883333333333388333333333333333333333333333333333333333333333333333344333363333336
30222220333330388830333333303338880333333333333888333333333388883333333333333333333333333333333333333333333343333443333333363333
43b23b233333308888803333333303888883333333033388888333333333388888833333333388888883333333338888888333333333433344a3333300333300
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
00000000000000000000000000000000000000000004400033333333333333333333333333333333000000000000000000000000000000000000000000000000
00000000000000000000000000000000440000000444000033333333333333333333333333333333000000000000000000000000000000000000000000000000
00000000000000000000000000000000440000000400000033333323332333333333333333233333000000000000000000000000000000000000000000000000
00066000066660000066600000666000440006666600000033333323332333333333333332233333000000000000000000000000000000000000000000000000
66655660055556600655560000555666044666666660000033333322322333333333333322233333000000000000000000000000000000000000000000000000
555565566556555005665560065555550046666bb666600033333311111333333333333311133333000000000000000000000000000000000000000000000000
66555555555665566555555665556655066466666666600033333317d7133333333333311d733333000000000000000000000000000000000000000000000000
5555555555555555555555555555555606644666000a0a003333d31ddd13d333333333111dd33333000000000000000000000000000000000000000000000000
00000000000000000000000000000000066666660000000033333d17071d33333333331d11733333000000000000000000000000000000000000000000000000
00000000000000000000000000000000066666666a0aa000333333272723333333333322d2733333000000000000000000000000000000000000000000000000
00000000000000000000000000000000056666666666000033333327372333333333333222733333000000000000000000000000000000000000000000000000
000000000000000000000000000000000056666666660000333333dd3dd333333333333dd3333333000000000000000000000000000000000000000000000000
000000000000000000000000000000000022666666650000333333ee3ee333333333333ee3333333000000000000000000000000000000000000000000000000
00000000000000000000000000000000002005555250000033333333333333333333333333333333000000000000000000000000000000000000000000000000
00000000000000000000000000000000002000000200000033333333333333333333333333333333000000000000000000000000000000000000000000000000
00000000000000000000000000000000222000000222000033333333333333333333333333333333000000000000000000000000070000000000000000000000
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


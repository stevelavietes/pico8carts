pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

function ef_linear(amount)
 return amount
end

crop = 0.3
function ef_out_quart_cropped(amount)
 local amount_cropped = min(amount, crop)
 local t = amount_cropped - 1
 local result = -1 * (t*t*t*t- 1)
 if amount >= crop then
  amount = amount - 0.3
  return (result * (1.0 - amount) + 1.0 * (amount))
 end
 return result
end

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
-- }

-- { debug stuff can be deleted
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

function print_stdout(msg)
 -- print 'msg' to the terminal, whatever it might be
 printh("["..repr(g_tick).."] "..repr(msg))
end
-- }

function snow_particles()
 return {
  x=0,y=0,
  update=function(t)
   add_particle(rnd(128), 0, rnd(0.5)-0.25, 0.5+rnd(0.3), 270, 7, 0)
  end,
  draw=function(t)
   process_particles()
   for _, o in pairs(collision_objects) do
    o:draw()
   end
  end
 }
end

function spray_particles()
 return {
  x=0,
  y=0,
  v_last = vecmake(0),
  update=function(t)
   -- add_particle(rnd(128), 0, rnd(0.5)-0.25, 0.5+rnd(0.3), 270, 7, 0)
   d_v = vecsub(t.v_last, g_p1.vel)
   if vecmagsq(d_v) < 0.01 then
    return
   end
   for i=0,25 do
    local off=vecrand(6, true)
     add_particle(
      g_p1.x+off.x+rnd(6)-3+g_p1.bound_min.x,
      g_p1.y+off.y+rnd(6)-3+g_p1.bound_min.y,
      d_v.x/2+rnd(1),
      d_v.y/2+rnd(1),
      10,
      6,
      0.5 
     )
   end
   t.v_last = g_p1.vel
  end,
  draw=function(t)
   process_particles(sp_world)
   -- for _, o in pairs(collision_objects) do
   --  o:draw()
   -- end
  end
 }
end


function make_title()
 return {
  x=30,
  y=20,
  draw=function()
   print("mogulneer", 0, 0, 1)
   print("mogulneer", 1, 1, 12)
  end,
 }
end

function _init()
 particle_array, particle_array_length = {}, 0
 stdinit()

 add_gobjs(make_title())
 add_gobjs(snow_particles())
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

-- @{ useful utility function for getting started
function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end

function smootherstep(x)
 -- assumes x in [0, 1]
 return x*x*x*(x*(x*6 - 15) + 10);
end
-- @}

-- @{ vector library
function vecdraw(v, c, o)
 if not o then
  o = vecmake()
 end
--  local end_point = vecadd(o, vecscale(vecnormalized(v), 5))
 local end_point = vecadd(o, vecscale(v, 30))
 line(o.x, o.y, end_point.x, end_point.y, c)
 return
end

function vecrand(scale, center, yscale)
 local result = vecmake(rnd(scale), rnd(yscale or scale))
 if center then
  result = vecsub(result, vecmake(scale/2, (yscale or scale)/2))
 end
 return result
end

function vecmake(xf, yf)
 if not xf then
  xf = 0
 end
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

function vecnormalized(v)
 return vecscale(v, vecmag(v))
end

function vecdot(a, b)
 return (a.x*b.x+a.y*b.y)
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

function vecminvec(target, minvec)
 target.x = min(target.x, minvec.x)
 target.y = min(target.y, minvec.y)
 return target
end

function vecmaxvec(target, maxvec)
 target.x = max(target.x, maxvec.x)
 target.y = max(target.y, maxvec.y)
 return target
end

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

function vecclamp(v, min_v, max_v)
 return vecmake(
  min(max(v.x, min_v.x), max_v.x),
  min(max(v.y, min_v.y), max_v.y)
 )
end
-- @}

-- @{ built in diagnostic stuff
g_ski_none = 0
g_ski_left = 1
g_ski_right = 2
g_ski_both = 3

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
  bound_min=vecmake(2, 4),
  bound_max=vecmake(6,8),
  angle=0, -- ski angle
  density_and_drag_c = 0.05,
  load_left=0,
  load_right=0,
  turnyness=0,
  brakyness=0,
  wedge=false,
  trail_points={},
  update=function(t)
   local loaded_ski = g_ski_none
   if btn(0, t.p) then
    -- right
    -- t.angle -= 0.01
    -- max(t.angle, -0.5)
    -- if t.pose == 4 then
    --  t.pose = -4
    -- elseif t.pose > -4 then
    --  t.pose -= 1
    -- end
    loaded_ski = g_ski_right
   end 
   if btn(1, t.p) then
    -- left
    -- t.angle += 0.01
    -- min(t.angle, -0.5)
    -- if t.pose == -4 then
    --  t.pose = 4
    -- elseif t.pose < 4 then
    --  t.pose += 1
    -- end
    if loaded_ski != g_ski_none then
     loaded_ski = g_ski_both
    else
     loaded_ski = g_ski_left
    end
   end
   if btnn(2, t.p) then
    -- up
    -- if abs(t.pose) > 0 and abs(t.pose) < 4 then
    --  local dir = 1
    --  if t.pose < 0 then
    --   dir = -1
    --  end
    --  t.pose += dir
    -- end
    if abs(t.angle) < 0.25 then
     t.angle = 0
    else
     t.angle = -0.5
    end
    loaded_ski = g_ski_both
   end
   if btnn(3, t.p) then
    -- down
    -- if abs(t.pose) > 0 then
    --  local dir = -1
    --  if t.pose < 0 then
    --   dir = 1
    --  end
    --  t.pose += dir
    -- end
    t.angle = -0.25
    loaded_ski = g_ski_none
   end

   if btn(4, t.p) then
    -- z
   end
   if btn(5, t.p) then
    -- x
   end

   -- sets up the current direction of the skis, "brakes"
   t:loaded_ski(t.vel, loaded_ski)

   -- apply velocity and acceleration
   local grav_accel = t:gravity_acceleration()
   t.grav_accel = grav_accel
   local drag_accel = t:drag_acceleration()
   local brake_force = t:brake_force()
   local total_accel = vecscale(
    vecadd(vecadd(grav_accel, drag_accel), brake_force),
    0.8
   )
   t.total_accel = total_accel
   -- local total_accel = grav_accel

   t.vel = vecadd(t.vel, total_accel)
   t.vel = clamp_velocity(t.vel)
   vecset(t, vecadd(t, t.vel))
   updateobjs(t.c_objs)

   for i=#t.trail_points,1,-1 do
    if (t.y - t.trail_points[i].y > 100) then
     del(t.trail_points, t.trail_points[i])
    end
   end

   t:add_new_trail_point(t)
  end,
  loaded_ski=function(t, vel, loaded_ski)
   t.wedge = false

   -- if neither ski is loaded, then nothing to do
   if loaded_ski == g_ski_none then
    t.load_left = 0
    t.load_right = 0
    return vel
   end

   -- if its both, then just slow the current rate (brakes)
   if loaded_ski == g_ski_both then
    t.load_left = 0
    t.load_right = 0
    t.wedge = true
    local brake_amt = -0.3
    if vecmagsq(vel) > brake_amt*brake_amt then
     return vecscale(vel, brake_amt)
    else
     return vecscale(vel, -1)
    end
   end

   -- if switching skis - 
   -- @TODO: turn linking pop
   if (
     (loaded_ski == g_ski_right and t.load_left != 0) or
     (loaded_ski == g_ski_left and t.load_right != 0) 
   ) then
    t.load_left = 0
    t.load_right = 0
   end

   local target_angle = 0.25
   local turn_dir = 0
   local load_var = 0
   if loaded_ski == g_ski_right then
    t.load_right += 1/60
    t.load_right = min(t.load_right, 1)
    -- load_var = t.load_right
    load_var = 1
    target_angle = 0
    turn_dir = -1
   end

   if loaded_ski == g_ski_left then
    t.load_left += 1/60 
    t.load_left = min(t.load_left, 1)
    -- load_var = t.load_left
    load_var = 1
    target_angle = 0.5
    turn_dir = 1
   end

   local turnyness = ef_linear(load_var)
   -- local turnyness = ef_out_quart_cropped(load_var)
   local brakyness = 1-turnyness

   local vel_mag = brakyness*vecmag(vel)

   -- t.angle += turn_dir * turnyness*0.2
   -- t.angle += turn_dir * 0.1 * turnyness
   t.angle += turn_dir * turnyness/60
   t.angle = min(0.0, max(t.angle, -0.5))
   t.turnyness=turnyness
   t.brakyness=brakyness
   return
   -- return vecfromangle(t.angle, vel_mag)
  end,
  gravity_acceleration=function(t)
   -- components of acceleration
   -- gravity
   -- drag
   -- fd = 0.5 * density * velocity squared * drag coefficient * area
   -- load (rotation force)
   -- if abs(t.pose) >= 3 then
   --  return null_v
   -- end
   --
   -- local dir = 1
   -- if t.pose < 0 then
   --  dir = -1
   -- end

   -- gravity
   -- return vecfromangle(t.angle, g_mogulneer_accel*sin(t.angle))
   return vecmake(0, g_mogulneer_accel)
  end,
  drag_acceleration=function(t)
   -- drag
   -- local drag_accel = vecmake()

   local ski_vec = vecfromangle(t.angle)

   -- drag along the ski
   t.drag_accel_along = vecscale(
    ski_vec,
    -1*0.2 * t.density_and_drag_c* vecdot(ski_vec, t.vel)
   )

   -- drag against
   local perpendicular = t.angle - 0.25
   if t.angle > -0.25 then
    perpendicular = t.angle + 0.25
   end
   local ski_vec_perp = vecfromangle(perpendicular)
   t.drag_accel_against = vecadd(
    vecscale(
     ski_vec_perp,
     -1 * t.density_and_drag_c* vecdot(ski_vec_perp, t.vel)
    ),
    vecscale(
     ski_vec_perp,
     vecdot(vecmake(0, -g_mogulneer_accel), ski_vec_perp)
    )
   )

   return vecadd(t.drag_accel_along, t.drag_accel_against)

   -- normal drag -- along the velocity
   -- drag_accel = vecscale(
   --  vecnormalized(t.vel),
   --  -0.2 * t.density_and_drag_c * mag_vec
   -- )
   --
   -- -- additional drag is on the current velocity that is 
   -- local vel_angle = atan2(t.vel.x, t.vel.y)-1
   -- -- interesting behavior here
   -- if vel_angle == -0.75 then
   --  vel_angle = -0.25
   -- end
   --
   -- -- 0-1 scale of the difference between the vel angle and ski angle
   -- t.vel_angle = 4*(min(abs(t.angle - vel_angle), 0.25))
   -- local perpendicular = t.angle - 0.25
   -- if t.angle > -0.25 then
   --  perpendicular = t.angle + 0.25
   -- end
   --
   -- t.vel_angle = 0.3 * mag_vec * sin(t.vel_angle)
   --
   -- -- drag_accel = vecadd(
   -- --  drag_accel,
   -- --  vecfromangle(perpendicular, 0.3 * mag_vec * sin(t.vel_angle))
   -- -- )
   -- drag_accel = vecscale(
   --  vecnormalized(t.vel),
   --  -0.2 * t.density_and_drag_c * mag_vec --  - 0.3 * mag_vec * sin(t.vel_angle)
   --
   -- )
   --
   -- -- drag_accel = vecfromangle(
   -- --  t.angle,
   -- --  -0.2 * t.density_and_drag_c * mag_vec
   -- -- )
   --
   -- -- vecadd(
   -- --  drag_accel,
   -- --  vecfromangle(
   -- --   8t.angle,
   -- --   -0.2 * t.density_and_drag_c * mag_vec
   -- --  )
   -- -- )
   --
   -- -- todo: cap the acceleration by the velocity in a coponent.
   -- -- drag_accel = vecminvec(drag_accel, vecscale(t.vel, -1))
   --
   --
   -- return drag_accel
   -- -- return veclerp(
   -- --  vecmake(0, g_mogulneer_accel),
   -- --  vecmake(dir*sqrt(g_mogulneer_accel), sqrt(g_mogulneer_accel)),
   -- --  abs(t.pose)/3
   -- -- )
  end,
  brake_force=function(t)
   if not t.wedge then
    return vecmake()
   end

   local result = vecscale(t.vel, -0.3)
   return result
  end,
  draw=function(t)
   local pose = flr((t.angle + 0.25)*16)

   -- trail renderer
   for i=2,#t.trail_points do
    for x_off in all({-1, 1}) do
     local p1 = vecsub(t.trail_points[i-1], t)
     local p2 = vecsub(t.trail_points[i], t)
     line(p1.x + x_off, p1.y, p2.x + x_off, p2.y, 6)
    end
   end

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

   circfill(0, 0, 1, 11)

   -- draw_bound_rect(t, 11)
   -- hit box stuff (might need it later)
   -- spr(2, -3, -3)
   -- rect(-3,-3, 3,3, 8)
   -- print(str, -(#str)*2, 12, 8)
   g_cursor_y=12
   print_cent("world: " .. t.x .. ", " .. t.y, 8)
   -- print_cent("load_left: " .. t.load_left, 8)
   -- print_cent("load_right: " .. t.load_right, 8)
   -- print_cent("pose: " .. t.pose, 8)
   -- print_cent("vel: " .. vecmag(t.vel), 8)
   -- print_cent("drag acceleration: " .. repr(t:drag_acceleration()), 8)
   -- print_cent("angle: " .. t.angle, 8)

   -- @{ acceleration components
   if t.grav_accel != nil then
    print_cent("v_g: " .. vecmag(t.grav_accel), 2)
    print_cent("v_d_along: " .. vecmag(t.drag_accel_along), 12)
    print_cent("v_d_against: " .. vecmag(t.drag_accel_against), 1)
    print_cent("v_t: " .. vecmag(t.total_accel), 9)
    -- print_cent("vel_ang: " .. t.vel_angle, 8)
    -- print_cent("vel: " .. repr(vecnormalized(t.vel)), 8)
    vecdraw(t.drag_accel_along, 12)
    vecdraw(t.drag_accel_against, 1)
    vecdraw(t.total_accel, 9)
    vecdraw(t.vel, 2)
    -- vecdraw(t.vel, 11)
   end
   -- print_cent("v_a: " .. t.angle, 8)
   -- print_cent("v_b: " .. t.angle, 8)
   -- print_cent("v_d: " .. t.angle, 8)
   -- @}

   -- print_cent("v: " .. vecmag(t.vel), 8)
   if true then
    palt(0, false)
    palt(3, true)
    if t.wedge then
     palt(14, false)
     pal(14, 11)
    else
     palt(14, true)
    end
    spr(17+abs(pose)*2, -8, -11, 2, 2, pose < 0)
    palt()
    pal()
   end

   -- print_cent("cos: "..cos(t.angle+0.25)
   -- print_cent("tness: " .. t.turnyness, 8)
   -- print_cent("bness: " .. t.brakyness, 8)
   drawobjs(t.c_objs)
  end,
  add_new_trail_point=function(t, p)
   p = vecmake(flr(p.x), flr(p.y))
   if (
     t.trail_points[#t.trail_points] == nil or
     t.trail_points[#t.trail_points].x != p.x or
     t.trail_points[#t.trail_points].y != p.y
   ) then
    add(t.trail_points, p)
   end
  end
 }
end

g_epsilon = 0.001

function clamp_velocity(vel)
 local result = vecclamp(
  vel,
  vecmake(-9*g_mogulneer_accel), vecmake(9*g_mogulneer_accel)
 )

 for i in all({'x','y'}) do
  if abs(result[i]) < g_epsilon then
   result[i] = 0
  end
 end
 return result
end

function make_grid(space, spacing)
 return {
  x=0,
  y=0,
  space=space,
  spacing=spacing,
  update=function(t) end,
  draw=function(t) 
   local space_label = "local"
   if t.space == sp_world then
    space_label = "world" 
   elseif t.space == sp_screen_center then
    space_label = "screen_center"
   elseif t.space == sp_screen_native then
    space_label = "screen_native"
   end

   for x=0,3 do
    for y=0,3 do
     local col = y*4+x
     local xc =(x-1.5)*t.spacing 
     local yc = (y-1.5)*t.spacing
     rect(xc-1, yc-1,xc+1, yc+1, col)
     circ(xc, yc, 7, col)
     local str = space_label .. ": " .. xc .. ", ".. yc
     print(str, xc-#str*2, yc+9, col)
    end
   end
  end
 }
end

function make_camera()
 return {
  x=0,
  y=0,
  update=function(t)
   -- t.x=g_p1.x
   -- t.y=g_p1.y
   local target_point = g_p1 

   if g_p1.vel then
    target_point = vecadd(g_p1, vecmake(0, g_p1.vel.y*6))
   end
   vecset(t,veclerp(t,target_point,0.5,0.3))
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

function game_start()
 g_objs = {
  make_bg(),
  make_mountain(),
  make_debugmsg(),
 }

 g_partm = add_gobjs(spray_particles())

 g_cam= add_gobjs(make_camera())
 g_p1 = add_gobjs(make_player(0))


--  g_brd = make_board()
--  add(g_objs, g_brd)
--  g_tgt = make_tgt(0,0)
--  add(g_objs,g_tgt)
end

function make_bg()
 return {
  x=0,
  y=0,
  space=sp_screen_native,
  draw=function(t)
   rectfill(0,0,128,128, 7)
  end
 }
end

function make_mountain()
 local starter_objects = {}
 for i=0,60 do
  local rndloc = vecmake(rnd(128)-64, i*10-300)
  add(starter_objects, make_tree(rndloc))
 end
 return {
  x=0,
  y=0,
  sp=sp_world,
  c_objs=starter_objects,
  p_objs={make_boundary(-96,96)},
  update=function(t)
   updateobjs(t.p_objs)
   updateobjs(t.c_objs)

   -- check to see if we need to bump the tree down
   for o in all(t.c_objs) do
    if g_cam.y - o.y > 300 then
     vecset(o, vecmake(rnd(128)-64, g_cam.y + 300))
    end
   end
  end,
  draw=function(t)
   drawobjs(t.p_objs)
   drawobjs(t.c_objs)
  end
 }
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

function make_tree(loc)
 return {
  x=loc.x,
  y=loc.y,
  space=sp_world,
  radius=3,
  bound_cent=vecmake(0, 9),
  draw=function(t)
   -- spr(-2,-2,1,2,10)
   spr(15, -4, -4, 1, 2)
   -- rect(-4,-4,4,4,11)
   -- draw_bound_circ(t, 11)
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
43b23b233333308888803333333303888883333333033388888333333333388888833333333388888883333333333338888333333333433344a3333300044000
44bb4bb3333330879780333333330387978033333330338879733333330333887973333333a8888889733333333333888973333333334034b383333300044000
3444344333333089998033333333308999803333333303889980333333300388998b0333333333888993333333333388899333333333490b3883333300044000
0000000033333b88888b333333333b88888b333333333b88888b333333330b088883333333333000b08333333333388888833333333349908883333300000000
00000000333330222220333333333022222033333333330222230333333334222223333333333322222333333333a322b223333333334b22b888333300000000
0000000033333322322333333333332232233333333343223223333333443322322333333333333222233333333333320223333333334b228088333300000000
00000000333333bb3bb33333333334bb4bb33333333334bb4bb33333333444bb4bb333333333333bb33393333333333b03339333333393228998333300000000
00000000333333443443333333333344344333333333333443443333333333399344993333334444444993333333444404499333333399228978333300000000
00000000333333993993333333333339939933333333333399399333333333333333333333333333333333333333333333333333333333333333333300000000
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
07000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700007000770070707007000000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07770007700777070707007000070770770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777077707777070707007770770770777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccc07c707ccc0c0c0c00c770cc0cc0cc7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc1c0c1c0c1110c0c0c00ccc0c70c70c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c10c0c0c0c0770c0c0c00c1c0cc0cc0c7c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c00c0c0c0c0cc0c0c0c00c0c0c10c10cc1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c00c0c0c0c01c0c0c0c00c0c0c00c00c1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c00c0c7c0c77c0c7c0c70c0c0c70c70c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c00c0ccc0cccc0ccc0cc0c0c0cc0cc0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01001011101111011101101010110110101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- [co]sine tables
cal = {}
sal = {}

function compute_tables()
 for theta=0,359 do
  local angle=theta/360
  local ca = cos(angle) 
  local sa = sin(angle)

  cal[theta] = {}
  sal[theta] = {}

  for x=-8,8 do
   cal[theta][x] = ca * x
   sal[theta][x] = sa * x
  end

 end
end

-- function tprint(str)
--  local tcurrent = time()
--  print(str..": "..tcurrent-tlast)
--  tlast = tcurrent
-- end

function print_label(str, off_y)
 off_y = off_y or 0
 print(str, -(#str)*2, 12+off_y, 8)
end

-- warp gate colors
ep_c = {5,1,12}

function make_warp_gate(x,y,target_system)
 return {
  x=x,
  y=y,
  space=sp_world,
  tspawn=g_tick,
  target_system=target_system,
  sats=make_satellites(30,3),
  radius=3,
  minimap_obj_color=12,
  update=function(t)
   if collides_circles(t, g_p1) then
    make_system(t.target_system) 
    g_p1.x, g_p1.y, g_p1.velocity = 0,0,makev(0)
   end
  end,
  draw=function(t)
   for i,n in pairs({5,4,3,2}) do
    rectfill(
     -n,
     -n*2,
     n,
     n*2,
     ep_c[(-elapsed(t.tspawn)+i)/2%5+1]
    )
   end

   for _, s in pairs(t.sats) do
    local sat_theta = flr((((s.spd*elapsed(t.tspawn)+s.phase)%64)/64)*360)
    local x0 = s.a*cal[sat_theta][1]
    local y0 = s.b*sal[sat_theta][1]

    -- derivatives
    if (x0 < 0 and -y0 < 0) or (x0 > 0 and -y0 > 0) then
     local cr = cal[s.rot][1]
     local sr = sal[s.rot][1]
     local xr = x0*cr-y0*sr
     local yr = y0*cr+x0*sr
     line(xr,yr, xr,yr, 12)
    end
   end

   print_label(t.target_system)
  end
 }
end

function compute_planet_noise(kind, seed)
 srand(seed)
 --  tlast = time()
 sprites_wide = 2
 -- radius=(sprites_wide/2)*8
 radius=sprites_wide*4
 local xmin=0
 local xmax=sprites_wide*8
 local xcenter=(xmax-xmin)/2 + xmin

 local ymin=4*8
 local ymax=(4+sprites_wide)*8
 local ycenter=(ymax-ymin)/2 + ymin

 copies_x = 3
 copies_y = 3
 copies_xy = copies_x*copies_y

 -- using the algorithm from star control 2, noted in the gdc retro game post
 -- mortem - generate a bunch of lines and raise/lower the height map between
 -- those regions, then quantize and map the colors

 -- base height
 --  cls()

 function rnd_point()
   return {
    rnd(xmax-xmin)+xmin,
    rnd(ymax-ymin)+ymin
   }
 end
 local img = {}

 local cmin = 0
 local cmax = 50
 local coff = 0
 if kind == "gasgiant" then
  coff = cmax/4
 end

 for x=xmin,xmax do
  img[x] = {}
  for y=ymin,ymax do
   img[x][y] = flr(cmax/2 + coff)
  end
 end
--  tprint("setup")

 function rnd_line(sp, ep)
  sp=sp or (rnd_point())
  ep=ep or (rnd_point())
  -- print("sp: "..sp[1]..", "..sp[2])
  -- print("ep: "..ep[1]..", "..ep[2])

  local xd = ep[1] - sp[1]
  local yd = ep[2] - sp[2]
  local fac = sp[2]*xd-sp[1]*yd

  return {
   startp=sp,
   endp=ep,
   xd=xd,
   yd=yd,
   fac=fac,
   s_dist=function(t, x, y)
    return (x*t.yd - y*t.xd + t.fac)
   end
  }
 end

 function line_gas_giant()
   local sp = rnd_point()
   sp[1] = xmin 
   local ep = rnd_point()
   ep[1] = xmax

   while abs(ep[2]-sp[2]) > 3 do
    ep =rnd_point()
   end

   return rnd_line(sp,ep)
 end

 -- generate lines and raise stuff where we are on opposite side of the lines
 -- lower where we're on the same side
 for i=0,cmax do
  local l1, l2 = nil, nil
  if kind == "gasgiant" then
   -- ep[2] = sp[2] 
   l1 = line_gas_giant()
   l2 = line_gas_giant()
  elseif kind == "normal" then
   l1 = rnd_line()
   l2 = rnd_line()
  end

  for x=xmin,xmax do
   local ln=img[x]
   for y=ymin,ymax do
    if (l1:s_dist(x,y) < 0) != (l2:s_dist(x,y) < 0) then
     ln[y] = ln[y]+1
    else
     ln[y] = ln[y]-1
    end
   end
  end
 end
--  tprint("noise")

--  local hist = {}
--  hist[1] = 0
--  hist[2] = 0
--  hist[3] = 0
--  hist[4] = 0
 -- quantize
 for x=xmin,xmax do
  local ln=img[x]
  for y=ymin,ymax do
   local val = ln[y]
   -- local c=val
   local c=4
   if val < 0.45*cmax then
    c=1
   elseif val < 0.6*cmax then
    c=2
   elseif val < 0.7*cmax then
    c=3
   end
    
   -- hist[c] +=1 
   ln[y] = c
  end
 end
--  for i=1,4 do
--   print(i..": ".. hist[i])
--  end
--  tprint("quantize")

 -- rotation
 local ycenter = radius+ymin
 local r2 = radius*radius
 for y=ymin,ymax do
  local b = abs(y-ycenter)
  local a = sqrt(r2-b*b)
  local rotation_scale = 2*cal[flr(atan2(a, b)*360)][1]

  for x=xmin,xmax do
   local c = img[x][y]

   for off_y=0,(copies_y-1) do
    local new_y = y+off_y*sprites_wide*8
    for off_x=0,copies_x-1 do
     local rotation_offset = (
      x+rotation_scale*((off_x-copies_xy/2)+off_y*copies_x)
     )%xmax
     local new_x = rotation_offset+off_x*(sprites_wide*8)
     sset(new_x,new_y,c)
    end
   end
  end
 end
--  tprint("rotation")

 -- add poles and make round
 for x=xmin,xmax do
  local xd=x-xcenter
  local xd2=xd*xd
  for y=ymin,ymax do
   local yd=y-ycenter
   local c=1
   -- crop out corners to make look round
   if xd2+yd*yd < r2 then
    -- poles
    if (ymax-y < 2 or y-ymin < 2)  and kind != "gasgiant" then
      c=7
    end
   else
    c=0
   end
   for off_x=0,(copies_x-1) do
    local new_x = x+off_x*sprites_wide*8
    for off_y=0,(copies_y-1) do
     if c == 0 or c==7 then 
      local new_y = y+off_y*sprites_wide*8
      sset(new_x,new_y,c)
     end
    end
   end
  end
 end
 --  tprint("poles")

--  if true then
--   spr(64,0,55,16,16)
--   -- tprint("final")
--   stop()
--   return
--  end
end

function _init()
 stdinit()
 
 compute_tables()

 add(
  g_objs,
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
 g_st = gst_menu
end

gst_menu = 0
gst_playing = 1

function _update()
 stdupdate()
 updateobjs(g_sys_objs)
end

function _draw()
 stddraw()
 drawobjs(g_sys_objs)
end

-- coordinate systems
sp_world = 0
sp_local = 1
sp_screen_native = 2
sp_screen_center = 3

function am_playing()
 return g_st == gst_playing
end

function makev(xf, yf)
 return {x=xf, y=(yf or xf)}
end

-- @TODO: Collect all the rotation code into one place
function vecfromrot(theta, mag)
 theta = (359-theta)
 return vecscale(makev(cal[theta][1], sal[theta][1]), mag or 1)
end


function look_at(this, p, turning_speed)
 local dir_vec = vecnorm(vecsub(p, this))
 local tgt_angle = flr((1-atan2(dir_vec.x, dir_vec.y)) * 360)
 local delta = tgt_angle - this.theta

 -- already at the correct angle
 if abs(delta) < turning_speed then
  this.theta = tgt_angle
  return 0
 end

 if  delta >= 180 then
  delta -= 360
 elseif delta <= -180 then
  delta += 360
 end

 if delta > 0 then
  this.theta += turning_speed
 else
  this.theta -= turning_speed
 end

 this.theta = wrap_angle(this.theta)

 return delta
end


-- rotate a sprite 
function rotate_sprite(angle,tcolor,sspx,sspy)
 local cala = cal[angle]
 local sala = sal[angle]

 for x=-7,6,1 do
  -- @TOKEN: dropping these look ups can save a few tokens (4)?
  -- @{ 
  local cal_x = cala[x]
  local sal_x = sala[x]
  local x_out = x+sspx+16
  -- @}

  for y=-7,6,1 do
   -- 2d rotation about the origin
   local xp = cal_x-sala[y]
   local yp = sal_x+cala[y]

   -- if the pixel is over range,
   -- use the transparent color
   -- otherwise fetch the color from
   -- the sprite sheet
   local c = abs(xp) < 7 and abs(yp) < 7 and sget(xp+sspx,yp+sspy) or tcolor 

   -- set a color in the sprite
   -- sheet next to the currnet sprite
   sset(x_out,y+sspy,c)
  end
 end
 return angle
end

function wrap_angle(angle)
 if angle > 359 then
  angle -= 360
 elseif angle < 0 then
  angle += 360
 end
 return angle
end

-- function make_pushable(x,y)
--  return make_physobj(
--   {
--    x=x,
--    y=y,
--    name="pushable_["..x..","..y.."]",
--    space=sp_world,
--    vis_r=5,
--    draw=function(t)
--     circfill(0,0,5,6)
--     circfill(0,0,2,2)
--     circ(0,0,t.vis_r, 8)
--     circ(0,0,t.radius, 9)
--    end
--   },
--  100
--  )
-- end

-- @{ built in diagnostic stuff
function make_player(pnum)
 return make_physobj(
  {
   x=0,
   y=0,
   pnum=pnum,
   name="player"..pnum,
   space=sp_world,
   vis_r=7,
   sprite=36,
   theta = 0,
   rendered_rot=nil,
   update=function(t)
    -- @TODO: factor this into a player "brain"
    if not am_playing() then
     return
    end

    local thrust = false
    if btn(0, t.pnum) then
     t.theta -= 10
    end 
    if btn(1, t.pnum) then
     t.theta += 10
    end
    t.theta = wrap_angle(t.theta)
    if btn(2, t.pnum) then
     thrust = true
    end
    if btn(3, t.pnum) then
     t.velocity = vecscale(t.velocity, 0.8)
    end
    if thrust then
     accel_forward(t, 3, 5)
    end

    -- @TODO: shift this to an inventory system
    if btnn(4, t.pnum) then
     add_g_sys_objs(make_projectile(t, t.theta, t.velocity))
     -- recoil
     accel_forward(t, -10, 3)
     -- camera shake
     vecset(g_cam, vecadd(g_cam,vecrand(4, true)))
    end
   end,
   draw=function(t)
    print_label("world: " .. t.x .. ", " .. t.y)
    print_label("theta: " .. t.theta, 6)
    print_label("v: " .. vecmag(t.velocity), 12)
    print_label("vfact: " .. vecmag(t.velocity)/5, 18)

    -- local col_list = {}
    -- for _, o in pairs(g_objs) do
    --  if t ~= o and o.is_phys and not collided and collides_circles(t, o) then
    --   col=col+1
    --   add(col_list, o)
    --  end
    -- end
    --
    -- if #col_list > 0 then
    --  local col_str = "colliding:"
    --  for _, o in pairs(col_list) do
    --   col_str = col_str .. " " .. o.name
    --  end
    --  print_label(col_str, 10)
    -- end

    pusht({{3, true},{0,false}})
    rotate_sprite_if_changed(t, 3, 23, 23)
    spr(t.sprite, -7, -7,2,2)
    popt()
    
    circ(0,0,t.radius,11)

    -- local v_loc = vecfromrot(t.theta, 10)
    -- circfill(v_loc.x, v_loc.y, 3, 11)
   end
  },
  5
 )
end

g_friction=0.1
function update_phys(o)
 -- in case we want to play
 -- with time, even though pico
 -- gives us a constant clock
 local dt = 1
 
 o.x, o.velocity.x=compute_force_1d(
  o.x,
  o.force.x,
  o.mass,
  o.velocity.x,
  dt
 )
 o.y, o.velocity.y=compute_force_1d(
  o.y,
  o.force.y,
  o.mass,
  o.velocity.y,
  dt
 )
 
 -- zero out the force & apply drag
 vecset(o.force, vecsub(makev(0), vecscale(o.velocity, g_friction)))
end

function vecstr(v)
 return ""..v.x..", "..v.y
end

-- function vecdot(a, b)
--  return a.x * b.x + a.y * b.y
-- end

function vecadd(a, b)
 return {x=a.x+b.x, y=a.y+b.y}
end

function vecsub(a, b)
 return {x=a.x-b.x, y=a.y-b.y}
end

-- function vecmult(a, b)
--  return {x=a.x*b.x, y=a.y*b.y}
-- end

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

-- function vecrot(v, a)
--  local s = sin(a/360)
--  local c = cos(a/360)
--  return {
--    x=v.x * c - v.y * s,
--    y=v.x * s + v.y * c,
--  }
-- end

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

null_v = makev(0)

function vecnorm(v) 
 local l =
   sqrt(vecdistsq(null_v,v)) 
 return {
  x=v.x/l,
  y=v.y/l,
 }
end


function update_collision(o, o_num)
 -- (checking o, pos is new pos
 -- check boundaries first

--  pos.x, o.velocity.x = collide_walls_1d(
--   g_edges[1],pos.x,o.velocity.x,o.radius)
--  pos.y, o.velocity.y = collide_walls_1d(
--   g_edges[2],pos.y,o.velocity.y,o.radius)
 
 for i=o_num,#g_objs do
  local t = g_objs[i]
  if t.is_phys and t ~= o then
   if collides_circles(t, o) then
    if not t.is_static then
     -- push the objects back
     local r = o.radius + t.radius
     local v = vecsub(o,t)
     local v_n = vecnorm(v)
    
     -- result
     vecset(o, vecadd(vecscale(v_n, r),t))
   
     -- a.v = (a.u * (a.m - b.m) + (2 * b.m * b.u)) / (a.m + b.m)
     -- b.v = (b.u * (b.m - a.m) + (2 * a.m * a.u)) / (a.m + b.m)
     local o_v = o.velocity
     local t_v = t.velocity
     local o_m = o.mass
     local t_m = t.mass
     o.velocity = vecscale(
      vecadd(vecscale(o_v, (o_m-t_m)), vecscale(t_v,2*t_m)),
      1/(o_m+t_m)
     )
     t.velocity = vecscale(vecadd(vecscale(t_v, (t_m-o_m)),(vecscale(o_v,2*o_m))),(1/(o_m+t_m)))
    end
   end
  end
 end
end

function collides_circles(o1, o2)
 local d = vecsub(o1, o2)
 local r_2 = o1.radius + o2.radius

 -- cheat to avoid huge squares
 if abs(d.x) > r_2 or abs(d.y) > r_2 then
  return false
 end

 return vecmagsq(d) < r_2 * r_2
end

-- creates a physics object out
-- of the parent object with a
-- given mass
function make_physobj(p,mass)
 phys = {
  p=p,
  mass=mass,
  force=makev(0),
  velocity=makev(0),
  radius=p.vis_r or 5,
  is_phys=true,
  is_static=false,
 }
 for k,v in pairs(phys) do
   p[k] = v
 end
 return p
end


g_tstack={}

-- takes a list of tuples color, tval
function pusht(tlist)
 -- todo make push/pop work better
 add(g_tstack, tlist)
 for i, ttuple in pairs(tlist) do
  palt(ttuple[1], ttuple[2])
 end
end

function popt(tlist)
 local len = #g_tstack
 local last = g_tstack[len]
 for i, ttuple in pairs(last) do
  palt(ttuple[1], not ttuple[2])
 end
 g_tstack[len] = nil
end

g_spacing = 64
function make_infinite_grid()
 return {
  space=sp_screen_native,
  draw=function(t)
   local g_o_x = 128 - g_cam.x % 128
   local g_o_y = 128 - g_cam.y % 128

   for x=0,3 do
    for y=0,3 do
     -- screen coordinates
     local xc = (x-1.5)*g_spacing + g_o_x
     local yc = (y-1.5)*g_spacing + g_o_y

     rect(xc-1, yc-1,xc+1, yc+1, 5)
     circ(xc, yc, 7, 5)

     -- label
     local smin = vecsub(g_cam, makev(64))
     local str = "w: " .. xc + smin.x .. ", ".. yc + smin.y
     print(str, xc-#str*2, yc+9, 5)
    end
   end
  end
 }
end

-- assumed to be in world space
function make_camera()
 return {
  x=0,
  y=0,
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
  update=function(t)
   -- t.x=g_p1.x
   -- t.y=g_p1.y
   -- @TODO: make the target point lead the player
   vecset(t,veclerp(t,g_p1,0.5,0.3))
  end,
  draw=function(t)
  end
 }
end
-- @}

function make_debugmsg()
 return {
  space=sp_screen_native,
  draw=function(t)
   color(14)
   print("",0,0)
   print("cpu: ".. stat(1))
   print("mem: ".. stat(2))
   -- local vis="false"
   -- if g_p2 and g_cam:is_visible(g_p2) then
   --  vis = "true"
   -- end
   -- if g_p2 then
   --  print("p2 vis: ".. vis)
   --  print(g_cam.x-64-g_p2.vis_r .. ", " ..g_cam.y-64-g_p2.vis_r)
   --  print("vel: ".. vecmag(g_p1.velocity))
   --  print("p_vel: ".. vecmag(g_pushable.velocity))
   -- end
  end
 }
end

function make_satellites(nsats,maxspd)
 local sats = {}
 for i=1,nsats do
  local a=15
  local b=15
  local reduced = rnd(15)
  if rnd(1) < 0.5 then
   a=reduced
  else
   b=reduced
  end

  local spd =rnd(maxspd) 
  if rnd(1) < 0.4 then
   spd *= -1
  end

  add(
   sats,
   {
    a=a,
    b=b,
    rot=flr(rnd(360)),
    phase=rnd(64),
    spd=spd,
    size=rnd(2)
    -- spd=rnd(3)
   }
  )
 end
 return sats
end

function reset_palette()
 for i=0,15 do
  pal(i,i)
 end
end

function set_palette(palmap)
 for i, c in pairs(palmap) do
  pal(i, c)
 end
end

function make_planet(name,x,y,sats,kind,palette, seed)
 compute_planet_noise(kind, seed)
 return {
  x=x,
  y=y,
  minimap_obj_color=3,
  name=name,
  space=sp_world,
  frame=0,
  sats=make_satellites(sats,0.4),
  palette=palette,
  kind=kind,
  update=function(t)
   t.frame +=1 
  end,
  draw=function(t)
   local f = flr(t.frame/64) % copies_xy
   local fx = f % copies_x
   -- local fx = flr(f / 3)
   local fy = flr(f / copies_x)
   -- local fy = f % 4

   -- for i=1,9 do
   --  pal(i,12)
   -- end
   -- for i=10,12 do
   --  pal(i, 3)
   -- end
   -- for i=13,15 do
   --  pal(i, 4)
   -- end
   -- pal(7,7)
   set_palette(t.palette)
   local sprite_index = 64+(16*fy+fx)*sprites_wide
   spr(sprite_index,-radius,-radius,sprites_wide,sprites_wide)
   reset_palette()
   -- print(fx..", "..fy.." ["..sprite_index.."]", -10, 20, 7)

   -- satellite
   for _, s in pairs(t.sats) do
    local sat_theta = flr((((s.spd*t.frame+s.phase)%64)/64)*360)
    local x0 = s.a*cal[sat_theta][1]
    local y0 = s.b*sal[sat_theta][1]
    local cr = cal[s.rot][1]
    local sr = sal[s.rot][1]
    local xr = x0*cr-y0*sr
    local yr = y0*cr+x0*sr
    rectfill(xr,yr, xr+s.size,yr+s.size, 6)
   end

   print_label(t.name)

   -- for i=1,14 do
   --  palt(i,true)
   -- end
   -- pal(15,6)
   -- spr(64+4*(flr((t.frame+8)/4)%4),-2*8,-2*8,4,4)
   -- pal(15,15)
   -- for i=1,14 do
   --  palt(i,false)
   -- end
  end
 }
end

function add_gobjs(thing)
 add(g_objs, thing)
 return thing
end

function add_g_sys_objs(thing)
 add(g_sys_objs, thing)
 return thing
end

-- @TODO: Rings & mmoons
g_sys_size = 500
one_over_g_sys_size_2 = 1/(2*g_sys_size)
g_systems = {
 mercury = {
  gates = {
   {50, 0, "venus"}
  },
  --         name     x  y   sats ptype    palette
  planet = { "mercury", 40,40, 1, "normal", {5,6,7,15}, 2},
  others = {}
 },
 venus = {
  gates = {
   {-50, 0, "mercury"},
   {50, 0, "earth"}
  },
  --         name     x  y   sats ptype    palette
  planet = { "venus", 40,40, 3, "normal", {7,9,10,15}, 8},
  others = {}
 },
 earth = {
  gates = {
   {-250, 0, "venus"},
   {150, 0, "mars"}
  },
  --         name     x  y   sats ptype    palette
  planet = { "earth", 140,140, 40, "normal", {12, 4, 3, 7}, 2},
  others = {}
 },
 mars = {
  gates = {
   {-50, 0, "earth"},
   {50,  0, "jupiter"}
  },
  planet = { "mars", -40,-40, 10, "normal", {2, 4, 9, 7}, 1},
 },
 jupiter = {
  gates = {
   {-50, 0, "mars"},
   {50,  0, "saturn"}
  },
  planet = { "jupiter", -40,-40, 2, "gasgiant", {2,4,8,4}, 1},
 },
 saturn = {
  gates = {
   {-50, 0, "jupiter"},
   {50,  0, "uranus"}
  },
  planet = { "saturn", -40,-40, 2, "gasgiant", {2, 4, 9, 7}, 1},
 },
 uranus = {
  gates = {
   {-50, 0, "saturn"},
   {50,  0, "neptune"}
  },
  planet = { "uranus", -40,-40, 2, "gasgiant", {2, 4, 9, 7}, 1},
 },
 neptune = {
  gates = {
   {-50, 0, "uranus"},
  },
  planet = { "neptune", -40,-40, 2, "gasgiant", {2, 4, 9, 7}, 1},
 },
}

-- lame that i need to implement this
function unpack (t, i)
 i = i or 1
 if t[i] ~= nil then
  return t[i], unpack(t, i + 1)
 end
end

g_sys_objs = {}

function make_system(name)
 local sys =g_systems[name] 
 g_sys_objs = {
  make_planet(unpack(sys.planet))
 }

 for _, wg in pairs(sys.gates) do
  add_g_sys_objs(make_warp_gate(unpack(wg)))
 end

 -- if the system has any npcs in it
 if sys.npcs then
  for _, os in pairs(sys.npcs) do
   add_g_sys_objs(make_npc(unpack(os)))
  end
 end
end

function lerp(v1, v2, amount, clamp)
 -- TOKENS: can compress this with ternary
 local result = (v2 -v1)*amount + v1
 if clamp and abs(result - v2) < clamp then
  result = v2
 end
 return result
end

function veclerp(v1, v2, amount, clamp)
 -- TOKENS: can compress this with ternary
 local result = vecadd(vecscale(vecsub(v2,v1),amount),v1)
 if clamp and vecmag((vecsub(result,v2))) < clamp then
  result = v2
 end
 return result
end
--
-- function vecrand(scale_x,center_x, scale_y, center_y)
--  local off_x = center_x and - scale_x/2 or 0
--  local off_y = center_y and - scale_y/2 or 0
--  
--  return makev(rnd(scale_x) + off_x, rnd(scale_y)+off_y)
-- end

function vecrand(scale,center)
 return vecsub(
  vecscale(vecfromrot(flr(rnd(359))), scale),
  center and makev(scale/2) or null_v
 )
end

function vecset(target, source)
 target.x = source.x
 target.y = source.y
end

function clamp(val, minval, maxval)
 return max(min(val, maxval), minval)
end

function smootherstep(edge0, edge1, x)
  x= clamp((x - edge0)/(edge1 - edge0), 0.0, 1.0);
 return x*x*x*(x*(x*6 - 15) + 10);
end

function accel_forward(t, accel, max_speed)
 accel *= smootherstep(1.0, 0.0, vecmag(t.velocity)/max_speed)
 add_force(t, vecscale(makev(cal[t.theta][1], sal[t.theta][-1]), accel))
end

brain_funcs = {
--  stand_still = function(t) end,
--  spin = function(t)
--   t.theta += 1
--   if t.theta > 359 then
--    t.theta = 1
--   end
--  end,
 face_player = function(t) 
  look_at(t, g_p1, 5)
 end,
 patrol = function(t)
  if t.target_point then
   if d < 9 then
    t.target_point = makev(t.target_point.x,-1*t.target_point.y)
   end
   local dirvec = vecsub(t, t.target_point)
   local d = vecmag(dirvec)
   local theta_delta = look_at(t, t.target_point, 25)
   if theta_delta == 0 then
    accel_forward(t, 1, 3)
   end
  else
   t.target_point = makev(-20)
  end
 end
}

function rotate_sprite_if_changed(t, t_c, spmin_x, spmin_y)
 if t.rendered_rot != t.theta then
  t.rendered_rot = rotate_sprite(t.theta,t_c,spmin_x,spmin_y)
 end
end

function make_npc(start_x, start_y, name, brain, systems, sprite, vis_r)
 return make_physobj(
  {
   x=start_x,
   y=start_y,
   space=sp_world,
   name=name,
   vis_r=vis_r,
   sprite=sprite,
   brain=brain_funcs[brain],
   systems=systems,
   minimap_obj_color=8,
   -- for rotating the sprite
   theta = 0,
   rendered_rot=nil,
   update=function(t)
    t:brain()
   end,
   draw=function(t)
    print_label("theta: "..t.theta)
    if t.target_point then
     print_label("target_point: "..vecstr(t.target_point), 6)
     dirvec = vecsub(t, t.target_point)
     d = vecmag(dirvec)
     print_label("distance: "..d, 12)
     local local_target_point = vecsub(t.target_point, t)
     circfill(local_target_point.x, local_target_point.y, 3, 8)
    end

    -- @TODO: Move spr call into rotate_sprite_if_changed
    --        also move the pusht/popt in, why not
    pusht({{3,true},{0,false}})
    rotate_sprite_if_changed(t, 3, 79, 7)
    spr(t.sprite, -7, -7, 2, 2)
    popt()

    circ(0,0,t.radius,11)
   end
  },
  5
 )
end

g_map_size=32
map_size_times_sys_size=one_over_g_sys_size_2*g_map_size
function map_coords(o)
 return (o.x + g_sys_size) * map_size_times_sys_size + 2,
 (o.y + g_sys_size) * map_size_times_sys_size + 2
end

function make_minimap()
 return {
  space=sp_screen_native,
  draw=function(t)
   -- bg
   -- xxx: if tokens are needed, this can be reduced by 19 tokens by removing
   -- the border and just drawing the background color
   palt(0, false)
   rectfill(0,0,g_map_size, g_map_size,0)
   rect(0,0,g_map_size+1, g_map_size+1, 5)
   palt(0, true)

   -- ship
   local px, py = map_coords(g_p1)
   circfill(px,py,1,11)

   -- visibility square
   -- local minx, miny = map_coords(makev(g_p1.x-64, g_p1.y-64))
   -- local maxx, maxy = map_coords(makev(g_p1.x+64,g_p1.y+64))
   -- rect(minx, miny, maxx, maxy, 11)

   -- gates
   for _, o in pairs(g_sys_objs) do
    c = o.minimap_obj_color
    if c then
     px, py = map_coords(o)
     rectfill(px,py,px,py,c)
    end
   end
  end
 }
end

--[[
Ship structure @TODO:
The way it should work:
ships have a loadout and a brain
the player has a "player controller" brain that reads input

That way they can activate stuff on the loadout.

make_ship becomes more generic
]]--

function make_rocket(x,y, dir)
 return {
  x=x,
  y=y,
  space=sp_world,
  dir=dir,
  speed=1,
  update=function(t)
   vecadd(t, vecscale(t.dir, t.speed))
  end,
  draw=function(t)
   pusht({{3,true},{0,false}})
   spr(1, -4,-4, 1,1)
   popt()
  end
 }
end

function make_smoke(source_p, theta, velocity)
 return {
  x=source_p.x,
  y=source_p.y,
  velocity=velocity,
  space=sp_world,
  tcreate=g_tick,
  update=function(t)
   if elapsed(t.tcreate) > 30 then
    del(g_sys_objs, t)
   end
  end,
  draw=function(t)
   local r = 2*smootherstep(1,0,elapsed(t.tcreate)/32)
   for ang_fact=-1,1,2 do
    local start=null_v
    for i=0,3 do
     start=vecsub(null_v,vecscale(vecfromrot(wrap_angle(theta+45*ang_fact)), i*4))
     if r*i > 1 then
      circfill(start.x,start.y,r*i,6)
     end
    end
   end
  end
 }
end

function make_projectile(source_p,theta,velocity)
 local offset = vecfromrot(theta, 2)
 local initial_position = vecadd(source_p, vecscale(offset, 2))
 sfx(3, -1)

 -- smoke
 add_g_sys_objs(make_smoke(initial_position, theta, velocity))

 return {
  x=initial_position.x,
  y=initial_position.y,
  space=sp_world,
  dir=vecnorm(offset),
  speed=5,
  tcreate=g_tick,
  update=function(t)
   vecset(t, vecadd(velocity, vecadd(t, vecscale(t.dir, t.speed))))
   if elapsed(t.tcreate) > 50 then
    del(g_sys_objs, t)
   end
  end,
  draw=function(t)
   if elapsed(t.tcreate) <= 1 then
    local off = vecrand(2, true)
    circfill(off.x,off.y,8,8)
    off = vecrand(2, true)
    circfill(off.x,off.y,4,7)
   else
    circfill(0, 0, 3, 2)
    circfill(-offset.x, -offset.y, 2, 2)
    circfill(0, 0, 2, 8)
    circfill(-offset.x, -offset.y, 1, 8)
   end
  end
 }
end

function game_start()
 g_objs = {}

 add_gobjs(make_infinite_grid())
 g_map = add_gobjs(make_minimap())

--  add_gobjs(make_rocket(32, -32))

 g_cam = add_gobjs(make_camera())

 --todo add "make_system" whch takes a table and generates all the pieces of
 -- the current system including generating a planet for the system from data

--  add_gobjs(make_planet(32,32))
--  add_gobjs(make_warp_gate(32,-32))

 make_system("earth")
 g_p1 = add_gobjs(make_player(0))
 add_g_sys_objs(make_npc(30,30,"test","patrol",{},11,6))
--  add(g_sys_objs,make_npc(-32,-32,"test","face_player",{},11,6))

 -- add in pushable things
--  for i=0,0 do
--  if false then
--   local collides = true
--   local pushable = make_pushable(10, 10)
--   while collides==true do 
--    pushable.x = rnd(128) - 64
--    pushable.y = rnd(128) - 64
--    collides = false
--    for _, o in pairs(g_objs) do
--     if o.is_phys and not collides and collides_circles(o, pushable) then
--      collides = true
--     end
--    end
--   end
--   add(g_objs, pushable)
--   g_pushable = pushable
--  end

 add_gobjs(make_debugmsg())

 g_st = gst_playing

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

function add_force(o, f)
 vecset(o.force, vecadd(o.force,f))
end

function compute_force_1d(pos, f, m, v, dt)
  local a=0
  if f ~= 0 then
   a = f/m
  end
  
  -- update position half way
  pos += 0.5 * dt * v
  
  -- update velocity (drag)
  v += dt * a
  
  -- update position other half
  pos += 0.5 * dt * v
  
  return pos, v
end

function foreachp(lst, fnc)
 for i, o in pairs(lst) do
  if o.is_phys then
   fnc(o, i)
  end
 end
end

function updateobjs(objs)
 foreach(objs, function(t)
  if t.update then
   t:update(objs)
  end
 end)

 -- update physics code
 foreachp(objs, update_phys)
 foreachp(objs, update_collision)
end

function stddraw()
 cls()
 drawobjs(g_objs)
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   if g_cam and not g_cam:is_visible(t) then
    return
   end
   local cam_stack = 0

   -- i think the idea here is that if you're only drawing local,
   -- then you only need to push -t.x, -t.y
   -- if you're drawing camera space, then the camera will manage the screen
   -- center offset
   -- if you're drawing screen center 
   if t.space == sp_screen_center then
    pushc(-64, -64)
    cam_stack = 1
   elseif t.space == sp_world and g_cam  then
    pushc(g_cam.x - 64, g_cam.y - 64)
    pushc(-t.x, -t.y)
    cam_stack = 2
   elseif not t.space or t.space == sp_local then
    pushc(-t.x, -t.y)
    cam_stack = 1
   elseif t.space == sp_screen_native then
   end

   t:draw(objs)

   for i=cam_stack,0,-1 do
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
00600000333333330007700099999999001010200000000000000088333333333333333333333333333333333333333333333333300000030000000000000000
00660000333333330007700099999999112011210000000000000008333333333333333330000300000003333333333333333333305885030000000000000000
0066600000000033007777009999999921212232033333300000008833000003300000333199000998880333333333300000333330cdef030000000000000000
0066660008666033077777709999999922313233335124330000000833088803308880333199099a98980333333330008880333330cdef030000000000000000
00666500000000337777777799999999333233303bbbbbb300000088330898033089803330009a90088803333333309989800033305775030000000000000000
0066500033333333077777709999999903030001333bb3330000000833088803308880333333a80000000333333309a988888033305665030000000000000000
006500003333333300077000999999991010011200333300000000883309900330099033319a9a03333333333300999000898033305bb5030000000000000000
005000003333333300700700999999992111122300000000000000083309a003300a9033319a9a03333333333319a90030888033300000030000000000000000
0000000000000000000000000000000099999999999993999999999933009900009900333330a800000003333319980300990033000000000000000000000000
1120300000000000000000000000000099944499993933939944444933309a8aa8a9033330009a90088803333300aaa009a90333000000000000000000000000
c1230100000000000000000000000000994444499339333394131114330009a99a9000333199099a989803333330a9a899900333000000000000000000000000
112030000000000000000000000000009966666999333393941113143309900aa0099033319900099888033333099aa9a9033333000000000000000000000000
00000000000000000000000000000000936465699339343399311114330990399309903330000300000003333311900990333333000000000000000000000000
00000000000000000000000000000000936466699943399499411149330110311301103333333333333333333311030110333333000000000000000000000000
00000000000000000000000000000000933533399999499999944499333333333333333333333333333333333333333333333333000000000000000000000000
00000000000000000000000000000000999999999999999999999999333333333333333333333333333333333333333333333333000000000000000000000000
33333300033333333330000333333333333300033333333333333300003333330000000000000000000000000000000033333300003333330000000000000000
3333300c00333333333055003333333330000c00000000333333300cc0033333000066000000000000000000000000003333300cc00333330000000000000000
3333305650333333330066500003333300555555c55550333333305665033333000066600000000000000c000000000033333056650333330000000000000000
3333005650033333330cc665cc03333305666666666660333333006666003333000cc666ccc0000000666666c666600033330066660033330000000000000000
33000c666c000333330000665000333300666666ccc6603333000c6666c000330000006666000000066666666666600033000c6666c000330000000000000000
330c066c660c03333000cc5665c0003300c00c6cccc66033330c066cc660c0330000cc66666c000000666666ccc66000330c066cc660c0330000000000000000
330c56cc765c03330050056cc65550030c00c06ccc76c033330c66c7cc66c0330060066ccc66660000c00c6cccc66000330c66c7cc66c0330000000000000000
300666ccc66600330666666ccc666c0300000566cc666033330c66cccc66c0330666666cccc666c00c00c06cccc6c000330c66cccc66c0330000000000000000
00566666666650030070066c766660033305056666666003300666cccc6660030666666cccc666c000000666cc666000300666cccc6660030000000000000000
05666c565c6665033000cc6666c00033330666660c566c0300665655556566000060066ccc666600000606666666600000665655556566000000000000000000
066c0c060c0c6603330000666000333333006600c056600306660c6666c066600000cc66666c0000000666660c666c0006660c6666c066600000000000000000
000c0006000c0003330cc566cc0333333306066000567033055c0c0660c0c550000000666600000000006600c0666000055c0c0660c0c5500000000000000000
33000066700003333300566000033333330000000c576033000c00066000c000000cc666ccc000000006066000666000000c00066000c0000000000000000000
3333300600333333333066003333333333333330c006003333000066660000330000666000000000000000000c66600033000066660000330000000000000000
3333330003333333333000033333333333333330000003333333300660033333000066000000000000000000c006000033333006600333330000000000000000
33333333333333333333333333333333333333333333333333333300003333330000000000000000000000000000000033333300003333330000000000000000
000000000000ee00000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000eee00000e0e00000e0ee00e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e00000000e0e0000000ee00e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e0000000eeeee00000ee000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eeee0000000e000000ee000e00eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e00e0000000e0000000e000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eeee0000000e000000ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee00000000000000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ee0000eeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000eeee00000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee000000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000e00000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000e0000eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00c77c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06cccc40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc44ccb4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bccbccbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4bcbbcbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44ccc44c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccc440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__gff__
0000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030303030303030303010303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303031503030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303031503030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303150303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0006011e250501d1501d230222401b2501c2601e2601f26021260202501d2501b2502f2502e2502c25025260202601d2601d260241601f260222602426026250282402b2502b2502a2502a2502c2502705022050
0001000e01111011100111001110011100111001110011100111001110011100111001110011200215016330026501925019250192503b4501805003050020500105000000000000000000000000000000000000
0001000e091200912009120091200a1200b1200d120111201712017120141200f1200a120081200915016330026501925019250192503b4501805003050020500105000000000000000000000000000000000000
0002000006050060501e050060501e050060501e060260702607024070200600e0501b0501805014050090500d050080500705000000000000000000000000000000000000000000000000000000000000000000
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
00 00024344
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


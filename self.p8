pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
time_colors={11,3,4,9,10,14,2,8}

-- debug shit can be deleted
function table_to_string(tbl)
 if tbl == nil then
  return "nil"
 end
 if type(tbl) == "boolean" then
  return tbl and "true" or "false"
 end
 if type(tbl) == "table" then 
  local retval = " table{ "
  for k, v in pairs(tbl) do
   retval = retval .. k .. ": ".. table_to_string(v).. ","
  end
  retval = retval .. "} "
  return retval
 end
 return ""..tbl
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

function game_start()
 g_state = 1 -- play!
 g_objs={}
 g_uiobjs={}
 g_violets={}
  
	g_violets={
   make_violet(0) 
   ,
   -- make_violet(1)
 }
 foreach(g_violets, init_phys)
 
 -- the pushable blocks (heart boxes)
 g_blocks={
  -- make_block(50,35)
 }
 foreach(g_blocks, init_phys)

 for i = 0,15 do
  mset(i,0,72)
 end 

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

 if #g_violets > 1 then
  g_violets[2].x = 86
  g_violets[2].direction=0
 end

 
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
 
 g_scroffset = 128
 g_timer=99

 
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
 thing:draw()
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
 

 foreach(g_objs, function(t)
  if t.draw then
   t:draw(g_objs)
  end
 end)

 draw_uiobjs(g_uiobjs)
 
 if g_state == 0 then
  return
 end
 -- height/score display
 color(1)
 local scrl=128-g_scroffset
 rectfill(1,120,
  1+4*(8+numdigits(scrl)),126)
 if shouldscroll() then
  color(11)
 else
  color(3)
 end
 print("height: "..flr(scrl),
  2,121)
 if g_violets[1] then
  color(11)
  g_violets[1].x += g_violets[1].speed
  if next_to_wall(g_violets[1]) then
   color(9)
  end
  g_violets[1].x -= g_violets[1].speed
  print("speed: "..table_to_string(g_violets[1].speed), 2, 116)
  print("jumps: "..table_to_string(g_violets[1].jumps), 2, 110)
 end
 color(5)

 --time remaining display
 color(1)
 rectfill(1,1,
 13+4*(8+numdigits(g_timer)),7)

 local ncolors=#time_colors
 local t_c = max(1+ncolors-min(
 flr((g_timer+10) / 10),
 ncolors),1)

 color(time_colors[t_c])
 print("remaining: "
 ..flr(g_timer),2,2)


 --[[
 pal(0,g_tick%15,1)
 pal(9,flr(rnd(16)),1)
 --]]

 --[[
 --debug offset and ground
 print(off,0,0,7)
 local f,smy,my=g_violets[1]:getflr()
 print(f..' '..smy..' '..my,0,8,7)
 --]]

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
   local mx2 =
   min(15,max(0,mx+1))

   local hit=false
   local off=getlocaloff()
   local mys=getscrmy()

   local myp=
   flr((t.y+t.hby1-off)/8)
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

function make_violet(p)
 return {
  x=27,
  y=64,
  frame=0,
  hbx0=4,
  hbx1=12,
  hby0=0,
  hby1=16,
  holding=nil,
  will_hold=false,
  is_holdable=false,
  breaks_blocks=true,
  jumps=2,
  ---
  update=function(t)
   if t.off then
    t.frame=0
    t.xoff = sin(g_tick/100)*10
    t.yoff = sin(g_tick/200)*10

    if btn(0,p) then
     t.x-=1
    end

    if btn(1,p) then
     t.x+=1
    end

    if t.y > 20 then
     t.y-=1
    end

    if t.y < 88 and btn(5,p)
     then
      t.off=nil
      t.x+=t.xoff
      t.y+=t.yoff
      t.xoff=nil
      t.yoff=nil
      add(g_objs,
      make_pop(t.x,t.y))
     end

     return
    end

    local ground = t:getflr()
    local spdadj=1
    local frameadj=0.5

    --run
    if btn(4,p) then
     spdadj=2 --was 2
     frameadj=1
     t.will_hold=true
    else
     t.will_hold=false
    end

    --left
    if btn(0,p) then
     if t.direction == 1 then
      t.frame = 0
     end
     t.direction = 0
     t.speed =
     max(-2-spdadj,
     t.speed-2*t.speedinc)
     --right
    elseif btn(1,p) then
     if t.direction == 0 then
      t.frame = 0
     end
     t.direction = 1
     t.speed =
     min(2+spdadj,
     t.speed+2*t.speedinc)
     --stop
    else
     if abs(t.speed) < 
      t.speedinc then
      t.speed=0
      --t.frame=(t.frame+0.5)%3
      t.frame = 0
     end
    end

    t.x += t.speed
    local flip = false
    if next_to_wall(t) then
     flip = true
    end
    t.x -= t.speed

    if flip then
     t.jumps = max(t.jumps, 1)
    end

    --jump
    if btnn(5,p) and t.jumps > 0 then
     t.jumps -= 1
    -- if t.y == ground and
    --   t.speedy == 0 then
     t.speedy = -6 - abs(t.speed)
    -- end


    if flip then
     t.speed *= -1
     t.jumps +=1 
    end
   end

   if t.y == ground and t.speedy == 0 then
    t.jumps = 2
   end

   t.frame=(t.frame+frameadj)%3

  end,
  ---
  draw=function(t)
   local sflip =
     (t.direction == 1)
   local s = 4
   
   --duck
   if g_state == 1
     and btn(3,p) then
    s = 14 
   end

   local ground = t:getflr()

   if t.speed ~= 0 then
    if ((sflip and t.speed<0) or
      (not sflip and
        t.speed > 0))
      then
     s=12
    else
     s=2*flr(t.frame)+6
    end
   end
   if p==1 then
    pal(2,3)
    pal(14,11)
    pal(8,2)
   end
   
   if t.y ~= ground then
    s=0
    if g_state == 1
      and (g_tick%4)>2 then
     s = 2
    end
   end
   
   --debug ground detection
   if false then
   line(t.x, ground,
     t.x+16, ground, 7)
   line(t.x,t.y,t.x+16,t.y,8)
   if t.gy then
    line(t.x,t.gy,t.x+16,
     t.gy,11)
   end
   end
   
   if t.holding then
    s+=32
   end
   
   local x = t.x
   local y = t.y
   if t.off then
    s=4
    if t.xoff then
     x+=t.xoff
     y+=t.yoff
    end
   end
   
   spr(s,x,y,2,2,sflip)
   
   pal()
   
   if t.off then
    s=132
    if g_tick%20>10 then
     s=134
    end
    spr(s,x,y,2,2)
   end
  end
  ---
 }
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

function update_phys(o)
 if o.off then
  return
 end
 if o.held_by ~= nil then
  return
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
 
 
 o.y+=o.speedy
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
 if (n==0) return
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
 local i=0
 local empty = nexty%4 > 0
 
 
 --if nexty%4 == 1
 --  and rnd(100) > 20 then
 --  
 -- for i = 0,15 do
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

__gfx__
00000088811000000000001881000000000000888110000000000088811000000000008881100000000000000000000000000011881100000000000000000000
09f001118811000009f0011118110000000001118811000000000111881100000000011188110000000000888110000000000111188100000000000000000000
09f009ff1881000009f009ff11810000000009ff18810000000009ff18810000000009ff188100000000011188110000000001ff118810000000000000000000
0220091ff18110000220091ff18810000000091ff18110000000091ff18110000000091ff1881000000009ff18810000000009fff18880000000008881100000
02209ffff188100002209ffff118100000009ffff188100000009ffff188100000009ffff18810000000091ff18810000000091ff11888800000011188110000
022209fff1881000022209fff1188000000009fff1881000000009fff1881100000009fff118800000009ffff188100000009ffff1111800000009ff18810000
00222099918810000022209999188000000000999188100000000099911881000000009992181000000009fff1188000000009ff2111ff000000091ff1811000
0002222222181000000222222211110000000022221810000000000222211000000000022221000000000099921810000000022222209f0000009ffff1881000
0000222222220000000022222222000000002222222200000000002222222000000000222222000000000002222110000000022222220000000009fff1881000
040022222222200004002222222220000002222222222000009ff22222222f0000000222222200000000f022222200000000029f222200000000009991881000
04000222222222ff04000222222222ff009f202222029f00009f222222209ff000000e22222200000009ff22222200000000029ff22200000000222222221000
042eee22222029ff042eee22222029ff009f00eeee009900000400eeee00099000000ee9ff2e000000009f222eef000000000229222e00000002222242222000
042eeeee22200090042eeeee2220009000000eeeeee0000000042eeeeeee0000000000ee9fe000000000000eeee9f000000000eeeeee00000002222222222000
0000eeeeeee244000000eeeeeee2440000000ee00ee0000000042ee00ee2400000000222ee000000000000eeeeee2400000000e244e020000009feeeeee9f000
000000eeeeee2440000000eeeeee24400000022002200000000000000022400000004444222000000000002220ee2400000000044e2240000009feeeeee99000
000000000eee0040000000000eee0040000044400444000000000000004400000000000444400000000004444000400000000000004400000000444004440000
00000088811000000000001881000000000000888110000000000088811000000000008881100000000000000000000000000011881100000000000000000000
00000111881100000000011118110000000001118811000000000111881100000000011188110000000000888110000000000111188100000000000000000000
000009ff18810000000009ff11810000000009ff18810000000009ff18810000000009ff188100000000011188110000000001ff118810000000000000000000
0000091ff18110000000091ff18810000000091ff18110000000091ff18110000000091ff1881000000009ff18810000000009fff18880000000000000000000
00009ffff188100000009ffff118100000009ffff188100000009ffff188100000009ffff18810000000091ff18810000000091ff11888800000000000000000
000009fff1881000000009fff1188000000009fff1881000000009fff1881100000009fff118800000009ffff188100000009ffff11118000000000000000000
00000099918810000000009999188000000000999188100000000099911881000000009992181000000009fff1188000000009ff211110000000000000000000
09ff22222218100009ff222222111100000000222218100000000022222110000000000222210000000000999218100000000022222220900000000000000000
09f222222222000009f222222222000009ff22222220000009ff22222222000009ff22222222000009ff2222222110000000022222222f900000000000000000
0000222222220000000022222222000009f222222220000009f222222222000009f222222222000009f22222222200000000022222222f900000000000000000
040002222222000004000222222200000000002222000000000000222220000000000e2222220000000000222222000000000222eee000000000000000000000
042eee2222200000042eee2222200000000000eeee000000000400eeee00000000000eeeeeee0000000000022ee00000000002eeeeee00000000000000000000
042eeeee22200000042eeeee2220000000000eeeeee0000000042eeeeeee0000000000eeeee000000000000eeeee0000000000eeeeee00000000000000000000
0000eeeeeee244000000eeeeeee2440000000ee00ee0000000042ee00ee2400000000222ee000000000000eeeeee2400000000e244e020000000000000000000
000000eeeeee2440000000eeeeee24400000022002200000000000000022400000004444222000000000002220ee2400000000044e2240000000000000000000
000000000eee0040000000000eee0040000044400444000000000000004400000000000444400000000004444000400000000000004400000000000000000000
000000000000000000000000000000000000000000000000000004004444444444444444444444444444444444444444dddddddddddddddddddddddddddddddd
000040000004000000000000000000000000000000000000001141004aaaaaaaaaa4aaaaaaa4aaaaaaa4aaaaaaa4aaaaddddd000000ddddddddddddddddddddd
00b35b0000b35b000000000000000000000000000000000001b35b10499999999994a9999994afffff94a99f99f4a999ddd0000000000dddddddd0088880dddd
0b7bbb300bb7bb30000000000000000000000000000000001b7bbb31499999999994a9999994aff9f994a9ff9ff4a999dd000000000000dddddd008888880ddd
0bbbbb300bbbbb30000000000000000000000000000000001bbbb3314444444444444444444444444444444444444444d0000000000000ddddd00889fff800dd
0bbbb3300bbbb330000000000000000000000000000000001bbb333100000000aaaaaaa4aaaaaaa4aaaaaaa4aaaaaaa4d00099ffffff00ddddd0889fffff80dd
0bbb33300bbb3330000000000000000000000000000000000133331000000000a9999994afff9994a99fff94a99999f4d009f000f000fddddd088900ff0088dd
0033330000333300000000000000000000000000000000000011110000000000a9999994aff99994a9fff994a9999ff4d011111111111ddddd0880ffffff088d
000000000000000000000000000000000000000000000000000000001000000044444444000000000000000000000000dd909161f1610ddddd8899f0ff0ff88d
000000000000000000000000000000000000000000000000000000001000000049444494000000000000000000000000dd909111f111dddddd8899fff9fff88d
000000000000000000000000000000000000000000000000000000001000000044444444000000000000000000000000ddd99fff99ffdddddd8809feffff088d
000000000000000000000000000000000000000000000000000000001000000044444444000000000000000000000000dddd99ffffffdddddd88099feeff088d
000000000000000000000000000000000000000000000000000000001000000044444444000000000000000000000000ddddd99eeffddddddd880299fff0008d
000000000000000000000000000000000000000000000000000000000000000044444444000000000000000000000000ddd5559fff555dddddd002499f2220dd
000000000000000000000000000000000000000000000000000000000000000049444494000000000000000000000000dd555557755555ddddde2e244e2e22dd
000000000000000000000000000000000000000000000000000000000000000044444444000000000000000000000000d55555577566555ddd2ee2e2e2e2e2dd
776666770000000000000000000000000000000000000000000000004444444444444444000000000000000000000000dddddddddddddddddddddddddddddddd
788288270000000000000000000000000000000000000000000000004aaaaaaaaaaaaaaa000000000000000000000000ddddd44444dddddddddddddddddddddd
878878820000000000000000000000000000000000000000000000004a99999999999999000000000000000000000000dddd4444444ddddddddddddddddddddd
888888820000000000000000000000000000000000000000000000004a99999999999999000000000000000000000000ddd4449ff444dddddddddddddddddddd
688888260000000000000000000000000000000000000000000000004444444444444444000000000000000000000000dd4449ffff444ddddddddddddddddddd
668882660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd44494ff4ff4ddddddddddddddddddd
766826670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd4494ffff4f44dddddddddddddddddd
776666770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d4449f1ff1ff44dddddddddddddddddd
008810000088100000881000000000000088100000881000000000001111111111111111111111111111111111111111d4449fffffff44dddddddddddddddddd
00ff810000ff810000ff81000088100000ff8100f0ff8100000000001333333313b333b31bbb3bbb1333333313333333d4449fff9fff44dddddddddddddddddd
009f8100009f8100009f810000ff8100009f8100209f81000000000013b333b31bbb3bbb133333331333333313333333d44449effff414dddddddddddddddddd
002228100022281000222810009f810002222f1002222810000000001bbb3bbb13333333133333331333333313b333b3d14149feeff141dddddddddddddddddd
022222f0f222220000222200f222220000f2200000222220000000001111111111111111111111111111111111111111d414139fff3311dddddddddddddddddd
f0eee00000ee2f0000eef000000eef00002220004eeee0f0000000000000000000000000000000000000000000000000d11bb339933b31dddddddddddddddddd
00e0e0004eeee000000ee00000e00e0000eee0000000ee40000000000000000000000000000000000000000000000000d1bbbb3333bbb3dddddddddddddddddd
004040000000040000044000004004000004040000000000000000000000000000000000000000000000000000000000dbbbbbb33bb3bb3ddddddddddddddddd
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
__gff__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081070101010000000000000000000000800f000000000000000000000000000001010000000000000000000000000000010101010100000000
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


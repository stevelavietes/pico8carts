pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


function _init()
 --[[
 g_dbgnohit = false
 g_dbgforcecell = nil
 g_dbgmove = false
 --]]
 
 g_rotbtnfnc = btnn
 
	g_maxcells = 8
 g_rotsignalobjs = {}
 g_score = 0
 g_hiscore = 0
 
 stdinit()
 
 --supports bg color
 g_mazecols = {
  {8,14,176,5},
  {12,13,118,6},
  {3,11},
  {4,9,113,4},
 }
 
 g_mazecol = g_mazecols[1]
 
 

 -- init map cells
 for i = 0,g_maxcells-1 do
  local y = (i%4) * 8
  for j = 0,2 do
   local x = flr(i/4)*32
   rotmapcw(x+j*8,y,x+j*8+8,y,8)
  end
 end
 
 
 
 
 add(g_objs, make_main())
 
end

------------------------------

function stdinit()
 g_tick=0    --time
 g_ct=0      --controllers
 g_ctl=0     --last controllers
 g_cs = {}   --camera stack 
 g_objs = {} --objects
 g_camx = 0
 g_camy = 0
end

function _update()
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

function _draw()
 cls()
 
 
 -- to opt: not animating  
 local n = 8
 local s = g_mazecol[3] or 74
 local l = g_mazecol[4] or 1
 sprcpy(32,s+
   flr((g_tick%(n*l))/n)
     ,1,1)
 
 --pal(14,1)
 --pal(1, g_mazecol[3] or 1)
 map(112,47,0,-(g_tick%8),
   16,17)
 --pal()
 -- -(g_tick%48)/6
 
 pushc(g_camx, g_camy)
 drawobjs(g_objs)
 popc()
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   pushc(-t.x,-t.y)
   t:draw(objs)
   popc()
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

function vecadd(a, b)
 return {x=a.x+b.x, y=a.y+b.y}
end

function vecsub(a, b)
 return {x=a.x-b.x, y=a.y-b.y}
end

function vecscale(v, m)
 return {x=v.x*m, y=v.y*m}
end

function vecrot(v, a)
 local s = sin(a/360)
 local c = cos(a/360)
 return {
   x=v.x * c - v.y * s,
   y=v.x * s + v.y * c,
 }
end


function vecang(a, b)
 local d = vecsub(b, a)
 return atan2(d.x, d.y) * 360
end

function vecdistsq(a, b, sf)
 if sf then
  a = vecscale(a, sf)
  b = vecscale(b, sf)
 end
 
 local distsq =
   (b.x-a.x)^2 + (b.y-a.y)^2
 
 if sf then
  distsq = distsq/sf
 end
 
 return distsq
end

function rectsect(
  x1,y1,x2,y2,x3,y3,x4,y4)
 return (
       x1 <= x4
   and x2 >= x3
   and y1 <= y4
   and y2 >= y3)
end


function linesect(
   x1,y1,x2,y2,x3,y3,x4,y4)

  local sx1 = x2 - x1
  local sy1 = y2 - y1
  local sx2 = x4 - x3
  local sy2 = y4 - y3
  --[[
  local s = (-sy1 * (x1 - x3)
     + sx1 * (y1 - y3)) /
      (-sx2 * sy1 + sx1 * sy2)
  --]]
  local t = ( sx2 * (y1 - y3)
     - sy2 * (x1 - x3)) /
      (-sx2 * sy1 + sx1 * sy2)

  return {
   x = x1 + (t * sx1),
   y = y1 + (t * sy1)
  }
 
end


--todo, sget simpler?
function sprstochcpy(
  dst, src, prob, w, h)
 
 local s = getspraddr(src)
 local d = getspraddr(dst)
 
 local m1 = 15
 local m2 = shl(m1, 4)
 
 w = w or 1
 h = h or 1
 for y=0,h*8-1 do
  
  for x=0,w*4-1 do
   local p = peek(s+64*y+x)
   if p ~= 0 then
     local v1 = band(p, m1)
     local v2 = band(p, m2)
     
     local dp = peek(d+64*y+x)
     
     if v1 > 0 and
       rnd(100) < prob then
      
      dp = bor(
        band(dp, m2), v1)
      
     end
    
     if v2 > 0 and
       rnd(100) < prob then
      dp = bor(
        band(dp, m1), v2)
     end
     
     poke(d+64*y+x, dp)
    
   end
  end
 
 end
 
 
  
end 

--not currently using
--[[
function sprblend(dst, s1, s2,
    ptop,pbot,w,h)
 w = w or 1
 h = h or 1
 pbot = pbot or ptop
 
 local sa1 = getspraddr(s1)
 local sa2 = getspraddr(s2)
 local d = getspraddr(dst)
 local m1 = 15
 local m2 = shl(m1, 4)
 
 local ym = h*8-1
 for y=0,ym do
  local p = y/ym*(pbot-ptop)
    + ptop
  
  for x=0,w*4-1 do
   local v1 = peek(sa1+64*y+x)
   local v2 = peek(sa2+64*y+x)
   
   local v3 = 0
   
   local v = v1
   if (rnd(100) <= p) v = v2
   v3 = band(v, m2)
   
   v = v1
   if (rnd(100) <= p) v = v2
   v3 = bor(band(v, m1), v3)
   
   poke(d+64*y+x, v3)
  end 
 end
end
--]]

--not currently using
--[[


function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
end



function make_trans(f,d,i)
 --if (not i) sfx(0)
 
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
   draw_wave(x*2, 64, g_tick/10)
   
  end
 }
end

------------------------------

function getcell(t,mzx,mzy)
 if (not mzx) mzx = t.mzx
 if (not mzy) mzy = t.mzy
 local cx = flr(mzx/8)
 local cy = flr(mzy/8)
 local row = t.maze.b[cy+1]
 if (not row) return nil
 return row[cx+1]
end

------------------------------

function cango(t, dr)
 local v = g_drdirs[dr]
 local s, ix, iy, cx, cy =
   getmazespr(
     t.maze.b,t.mzx+v[3],
       t.mzy+v[4])
 
 
 if ix == 7 and dr == 1 then
  if not cellhasdr(
    getcell(t),1) or
    not cellhasdr(
      getcell(t, t.mzx+8,
        t.mzy) ,3)
        then
   return false
  end
 end
 
 if ix == 0 and dr == 3 then
  if not cellhasdr(
    getcell(t),3) or
    not cellhasdr(
      getcell(t, t.mzx-8,
        t.mzy) ,1)
        then
   return false
  end
 end
 
 if iy == 0 and dr == 0 then
  if not cellhasdr(
    getcell(t),0) or
    not cellhasdr(
      getcell(t, t.mzx,
        t.mzy-8) ,2)
        then
   return false
  end
 end

 if iy == 7 and dr == 2 then
  if not cellhasdr(
    getcell(t),2) or
    not cellhasdr(
      getcell(t, t.mzx,
        t.mzy+8) ,0)
        then
   return false
  end
 end
 
 return s and s > 0 and
   not fget(s,v[5])
end

function candirs(t,omit)
 result = {}
 for i = 0,3 do
  if omit ~= i
    and cango(t, i) then
   add(result, i)
  end
 end
 return result
end

function char_rotdone(t,maze)
 
 --[[
 local iscur =
   maze.cx == flr(t.mzx/8) and
   maze.cy == flr(t.mzy/8)
 --]]
 local iscur = shouldrot(t)
 
 if not iscur then
  revdrcheck(t)
  return
 end
 
 
 local ox = t.maze.cx * 8
 local oy = t.maze.cy * 8
 
 local ix = t.mzx - ox
 local iy = t.mzy - oy
 
 if maze.state == 0 then
 	-- todo, move in from edges
 elseif maze.state == 2 then
  if t.dr then
   t.dr = (t.dr + 1) % 4
  end
  
  
  -- huh? 6?
  t.mzx = (ox+6)-iy
  t.mzy = oy + ix
 else
  if t.dr then
   t.dr = (t.dr - 1) % 4
  end
  
  
  t.mzx = ox + iy
  t.mzy = (oy+6)-ix
  
  
 end
 
 --reverse direction
 --if now cannot go
 
 revdrcheck(t)
 
 
end

function revdrcheck(t)
 if t.dr then
  if not cango(t, t.dr) then
   t.dr = (t.dr + 2) % 4
   if t.step and t.step ~= 0
     then
    
    --taco
    t.step = t.rate - t.step
    
    
    v = g_drdirs[t.dr]
    t.mzx -= v[1]
    t.mzy -= v[2]
  
   
   end
  end
 end
end


function shouldrot(t)

 local cx = flr(t.mzx/8)
 local cy = flr(t.mzy/8)
 local ix = flr(t.mzx)%8
 local iy = flr(t.mzy)%8
 
 local incell = cx == t.maze.cx
   and cy == t.maze.cy
 
 
 if not incell then
  
  --todo, allow from left
  if cx + 1 == t.maze.cx
    and cy == t.maze.cy
    and t.dr == 1
    and ix == 7
      then
   
   --xxx need to update rotdone
   return true
   
  --      and from top
  elseif cy + 1 == t.maze.cy
    and cx == t.maze.cx
    and t.dr == 2
    and iy == 7
      then
   
   --xxx need to update rotdone
   return true
   
  end
  
  return false
 
 --else
  -- xxx, extends the dir
  --return true
 end
 
 
 
 if t.step then
  
 
  if
    --(t.dr == 0 and iy == 0)
    --or
    (t.dr == 1 and ix == 7)
    or
    (t.dr == 2 and iy == 7)
    --or
    --(t.dr == 3 and ix == 0)
      then
   
   if t.step > 0 then
    return false
   end
   
      
  end
 end
 
 
 return true
 
end


function char_getpos(t)
 local ox, oy =
   t.mzx*8, t.mzy*8
   
 if t.step then
  
  local v = g_drdirs[t.dr]
  
  --[[if not v then
   cls()
   print('bad dr ' .. t.dr,
     0,0,7) 
   stop()
  end
  --]]
  local r = t.step/t.rate
  ox += v[1]*r*8
  oy += v[2]*r*8
 end
   
 if t.maze.state > 0
   and shouldrot(t)
   --[[
   and flr(t.mzx/8) ==
     t.maze.cx
   and flr(t.mzy/8) ==
     t.maze.cy
   --]]
    then
  
  local px = t.maze.cx*64+24
  local py = t.maze.cy*64+24
  
  local x = ox - px
  local y = oy - py
  
  local r =
    vecrot({x=x,y=y},
       t.maze.ang)
  
  ox = -(r.x + px)
  oy = -(r.y + py)
 else
  ox = -ox
  oy = -oy
 end
 return ox, oy, {x=-ox,y=-oy}
end


-- [1] x movement delta
-- [2] y movement delta
-- [3] x map test
-- [4] y map test
-- [5] direction flag
g_drdirs = {
 [0]={0,-1, 0,0, 1},
 [1]={1,0, 1, 0, 2},
 [2]={0,1, 0,1, 1},
 [3]={-1,0, 0,0,2},
}

function make_mark(maze)
 local t = {
  x=0,
  y=0,
  mzx=0,
  mzy=0,
  step=0,
  rate=8,
  dr=1,
  dst=100,
  dstthr=16,
  maze=maze,
  ro=rnd(360),
  rotdone=char_rotdone,
  update=function(t,s)
   
   -- debug
   --if(true)return
   --[[
   if g_dbgmove
     and not btnn(0,1)
     and t.maze.state == 0
      then
    return
   end
   --]]
   
   if (t.maze.state~=0) return
   
   
   
   local flagdst = 
     vecdistsq(
       {x=t.mzx,y=t.mzy},
       {x=g_flag.mzx,
         y=g_flag.mzy})
   
   local dst = 
     vecdistsq(
       {x=t.mzx,y=t.mzy},
       {x=g_pmx,y=g_pmy})
   
   t.dst = dst
   
   
   
   if dst < t.dstthr then
    --moveherdable(t)
    --move away from player
    movetarget(t,
       {mzx=g_pmx,mzy=g_pmy})
   elseif flagdst < 10 then
    --move toward flag
    movetarget(t, g_flag, true)
   else
    moverandom2(t)
   end
   
  end,
  draw=function(t)
   local ox, oy =
     char_getpos(t)
   if rectsect(
     -ox+4,-oy+4,-ox+12,-oy+12,
     g_camx, g_camy,
     g_camx + 127, g_camy + 127)
      then
    
    --[[
    if t.dst < t.dstthr then
     pal(10,8)
     pal(9,2)
    end
    --]]
    
    local r =
      vecrot({x=-1.5,y=0},
        g_tick*10+t.ro)
    
    
    local upset =
      t.dst < t.dstthr
    if not upset then
     r.x = 0
     r.y = 0
    end
    
    pushc(ox+r.x, oy+r.y)
    
    spr(100+g_tick%6,4,4,1,1)
    
    if upset
      and g_tick % 2 == 0 then
     local f= flr(
       (g_tick%8)/2)
     --spr(84+f,1,4)
     --spr(84+f,7,4,1,1,true)
    end
    
    if g_dbgmove then
     pushc(0,-8)
     print(t.step, 10,0,7)
     print(flr(t.mzx)%8, 10,7,7)
     print(flr(t.mzy)%8, 10,14,7)
     print(t.dr, 10,21,7)
     print(shouldrot(t),
       10,28,7)
     
     popc()
     
    
    end
    
    popc()
    --pal()
   else
    draw_radararrow(
      -ox+8,-oy+8,9)
   end
  end

 }
 return t
end

function moverandom2(t)
 
 if t.step == 0 then
  
  --random movement
    
  if not cango(t, t.dr) then
   local drs =
     candirs(t, t.dr)
   local idx = flr(rnd(
     #drs)) + 1
   if (idx > #drs) idx = #drs
   
   
   --xxx
   --[[
   if #drs == 0 then
    return
   end
   --]]
   
   if #drs > 0 then
    t.dr = drs[idx]
   end
  else
   local drs =
     candirs(t, (t.dr+2)%4)
     
   local idx = flr(rnd(
     #drs)) + 1
   if (idx > #drs) idx = #drs
   
   --xxx
   --[[
   if #drs == 0 then
    return
   end
   --]]
   
   if #drs > 0 then
    t.dr = drs[idx]
   end
   
  end
    
 end
 
 t.step += 1
 
 if t.step >= t.rate then
  local cal v = g_drdirs[t.dr]
 
  t.step = 0
  t.mzx += v[1]
  t.mzy += v[2]
 end  
 
end



function movetarget(t,t2,
  towards)
 
 local checkdr = false
 
 if t.step then
  checkdr = t.step == 0
 else
  checkdr = t.mzx % 1 == 0
    and t.mzy % 1 == 0
 end
 
 if checkdr then
 
 
  local lngdrs = {}
  local lngdst = 0
  
  local mult = 1
  if towards then
    mult = -1
    lngdst = -20000
  end
   
  for dr in all(
    candirs(t)) do
     
   local v = g_drdirs[dr]
   local x = t.mzx
     + v[1]
   local y = t.mzy
     + v[2]
     
   local dst = 
     vecdistsq({x=x,y=y},
       {x=t2.mzx,y=t2.mzy})
         *mult
   if dst > lngdst then
    lngdrs = {dr}
    lngdst = dst
   elseif dst == lngdst
     then
    add(lngdrs, dr)
   end
  end
  
  --xxx
  if #lngdrs == 0 then
   return
  end
  
  local idx = flr(rnd(
    #lngdrs)) + 1
  
  --xxx, why?
  if idx > #lngdrs then
   idx = #lngdrs
  end
  if idx <= #lngdrs  then
     
   t.dr = lngdrs[idx]
  end
 end
 
 local v = g_drdirs[t.dr]
 
 if t.step then
  t.step += 1
  if t.step >= t.rate then
   t.step = 0
   t.mzx += v[1]
   t.mzy += v[2]
  end
 else
  t.mzx = t.mzx + v[1]*0.125
  t.mzy = t.mzy + v[2]*0.125
 end

end


function make_enemy2(maze)
 return {
 	x=0,
 	y=0,
  mzx=0,
  mzy=0,
  dr=0,
  step=0,
  rate=10,
  mvmode=flr(rnd(2.99)),
  maze=maze,
  rotdone=char_rotdone,
  update=function(t,s)
   if t.maze.state == 0 then
    
    if t.mvmode == 0 then
     moverandom2(t)
    elseif t.mvmode == 1 then
     movetarget(t, g_player,true)
    else
     movetarget(t, g_player,false)
    end
    
   end
  end,
  draw=function(t)
   local ox, oy =
     char_getpos(t)
   if rectsect(
     -ox+4,-oy+4,-ox+12,-oy+12,
     g_camx, g_camy,
     g_camx + 127, g_camy + 127)
      then
    
    
    
    
    
    pushc(ox,oy)
    
    if g_tick % 2 == 0 then
      pal(5, 6)
    end
    local s = 64 -- + t.dr
    --s += t.mvmode
    spr(s,4,4,1,1)
    
    popc()
    pal()
   else
    draw_radararrow(
     -ox+8,-oy+8,8)
   end
  end
 }

end


function make_flag(maze)
 local t = {
  x=0,
  y=0,
  mzx=0,
  mzy=0,
  maze=maze,
  ups={},
  rotdone=char_rotdone,
  update=function(t,s)
   g_fx = t.mzx
   g_fy = t.mzy
   
   for up in all(t.ups) do
    up:update(t.ups)
   end
  end,
  draw=function(t,s)
   local ox, oy =
     char_getpos(t)
   if rectsect(
     -ox+4,-oy+4,-ox+12,-oy+12,
     g_camx, g_camy,
     g_camx + 127, g_camy + 127)
      then
    pushc(ox, oy)
    
    for up in all(t.ups) do
     local x,y = up:getxy()
     if y >= 0 then
      up:draw()
     end
    end
    
    
    spr(14,0,-4,2,2)
    if t.multval and g_tick % 2 == 0 then
     pal(1, 9)
     clip(0, -oy-g_camy-4 +
       16*(1-t.multval), 128,
       16)
     spr(14,0,-4,2,2)
     clip()
     pal()
    end
    
    
    for up in all(t.ups) do
     local x,y = up:getxy()
     
     if y < 0 then
      up:draw()
     end
    end
    
    popc()
   else
    draw_radararrow(
      -ox+8,-oy+8,3)
   end
  end
 }
 return t
end


function make_player(maze,mzy)
 local t = {
  x=0,
  y=0,
  mzx=0,
  mzy=mzy or 0,
  dr=1,
  --lastdrs=0,
  lastmvdr=1,
  maze=maze,
  trail={},
  stopped=true,
  rotdone=char_rotdone,
  update=function(t,s)
   
   if t.step then
    moverandom2(t)
    return
   end
   
   g_pmx = t.mzx
   g_pmy = t.mzy
   
   if t.maze.state ~= 0 then
    return
   end
   ---
   
   local move = true
   
   if t.stopped then
    move = false
   end
   
   
   if t.mzx % 1 == 0
     and t.mzy % 1 == 0 then
    
    local dr = nil
    if btn(0) then
     dr = 3
    elseif btn(1) then
     dr = 1
    elseif btn(2) then
     dr = 0
    elseif btn(3) then
     dr = 2
    end
    
    if dr then
     t.stopped = nil
    end
    
    if dr
      and (cango(t, dr)
        or not cango(t, t.dr))
       then
      
     t.dr = dr
    end
    
    if not cango(t, t.dr) then
     move = false
     t.stopped = true
    end
   
   else
    if t.dr == 1 then
     if btn(0) then
      t.dr = 3
     end
    elseif t.dr == 3 then
     if btn(1) then
      t.dr = 1
     end
    elseif t.dr == 2 then
     if btn(2) then
      t.dr = 0
     end
    elseif t.dr == 0 then
     if btn(3) then
      t.dr = 2
     end
    end
    
    
   end
   
   
   if move then
    local v = g_drdirs[t.dr]
    
    if t.dr ~= t.lastmvdr then
     t.lastmvdr = t.dr
     sfx(16+t.dr)
    end
    --[[
    if not v then
     cls()
     print(t.dr)
     stop()
    end
    --]]
    t.mzx = t.mzx + v[1]*0.25
    t.mzy = t.mzy + v[2]*0.25
   end
   
   t.maze.cx = flr(t.mzx/8)
   t.maze.cy = flr(t.mzy/8)
   
   --select edge over
   
   cell = getcell(t)
   
   if cellhasdr(cell,t.dr)
    then
    if t.dr == 1 then
     if (t.mzx % 8) > 5.5 and
       t.maze.cx < t.maze.sx-1
        
        and not cellhasdr(
         getcell(t, t.mzx+8,
            t.mzy), 3) 
        
        and btn(1)
        then
      t.maze.cx = t.maze.cx + 1 
     end
    elseif t.dr == 2 then
     if (t.mzy % 8) > 5.5 and
       t.maze.cy < t.maze.sy - 1
        
        and btn(3)
        and not cellhasdr(
         getcell(t, t.mzx,
            t.mzy+8), 0)
        
       then
      t.maze.cy = t.maze.cy + 1 
     end
    elseif t.dr == 0 then
     if (t.mzy % 8) < 1.5 and
       t.maze.cy > 0
        
        and not cellhasdr(
         getcell(t, t.mzx,
            t.mzy-8), 2) 
    
        and btn(2)
        then
      t.maze.cy = t.maze.cy - 1 
     end
    elseif t.dr == 3 then
     if (t.mzx % 8) < 1.5 and
       t.maze.cx > 0
       
       and not cellhasdr(
         getcell(t, t.mzx-8,
            t.mzy), 1) 
       and btn(0)
         then
      t.maze.cx = t.maze.cx - 1 
     end
    end
   end
   
   --don't allow rotate
   --during transition
   if
     (t.mzx % 8) >= 7
     or (t.mzy % 8) >= 7 then
    t.maze.cx = -10
    t.maze.cy = -10
    
   end
   
   --g_camx = t.mzx * 8
   --g_camy = t.mzy * 8
   
   
   g_pmx = t.mzx
   g_pmy = t.mzy
   
   
   
   
  end,
  
  draw=function(t)
   local s = flr(
       (g_tick % 8) / 2)
   
   local fp = t.dr > 1
   
   local ox, oy = char_getpos(t)
   
   if t.maze.state == -2 then
    
    local e = elapsed(
      t.maze.hittime)
    
    local s = nil
    local p = 100
    if e < 20 then
     s = flr(e/20*3)
     p = (20 - e)*5
    elseif e >= 70 then
     if g_lives == 0 then
      return
     end
     s = 3 - flr((e-70)/20*3)
     p = (e-70) * 5
    else
     return
    end
    
    pushc(ox, oy)
    
    sprcpy(48,0)
    sprstochcpy(48,6+s,p)
    spr(48,4,4)
    
    popc()
    
    return
    
   end
   
   local rthr = 64
   local lthr = 64
   
   if -ox - g_camx > rthr
     and g_camx <
       (t.maze.sx-2)*64
       then
    g_camx = g_camx + 1
   elseif -ox - g_camx < lthr
     and g_camx > 0 then
    g_camx = g_camx - 1
   end
   
   if -oy - g_camy > rthr
     and g_camy <
       (t.maze.sy-2)*64
     then
    g_camy = g_camy + 1
   elseif -oy - g_camy < lthr
     and g_camy > 0 then
    g_camy = g_camy - 1 
   end
   
   
   pal(9,1)
   
   for i = 1, #t.trail do
    local xy = t.trail[i]
    sprcpy(48, 0)
    --wow
    
    local p =
      (i-1)/#t.trail * 100
    
    sprstochcpy(48, 10+xy[3],
   	  p)
    
    pushc(xy[1], xy[2])
    spr(48,4,4,1,1,fp,0)
    popc()
   end
   
   add(t.trail, {ox,oy,s})
   if #t.trail == 8 then
    del(t.trail, t.trail[1])
   end
   
   pal()
   pushc(ox, oy)
   
   spr(2+s,4,4,1,1,fp,false)
   
   local fo = 0
   if g_tick % 20 > 9 then
     fo += 2
   end
   spr(144+fo, 0, 0, 2, 2)
   
   --[[
   print(t.mzx .. ' ' ..
     flr(t.mzx/8), 14, 0, 7)
   print(t.mzy .. ' ' ..
     flr(t.mzy/8), 14, 8, 7)
   --]]
   
   popc()
  end
 }
 
 --player placechar
 placechar(t,0,0,0)
 
 return t
end


function basepal(flipcol)
 pal(5,0)
 pal(6,0)
   
 local c1 = g_mazecol[1]
 local c2 = g_mazecol[2]
   
 if flipcol then
  c2,c1 = c1,c2
 end
   
 pal(7, c1)
 pal(13, c2)  
end
  
function placechar(t,cx,cy,
 steps)
 
 local ox, oy = cx*8, cy*8
 local cell = getcell(t,ox,oy)
 
 if cellhasdr(cell, 0)
   then
  t.mzx = ox+3
  t.mzy = oy
  --t.dr = 3
 elseif cellhasdr(cell, 3)
   then
  t.mzy = oy+3
  t.mzx = ox
  --t.dr = 1
 elseif cellhasdr(cell, 2)
   then
  t.mzx = ox+3
  t.mzy = oy+6
  --t.dr = 0
 elseif cellhasdr(cell, 1)
   then
  t.mzx = ox+6
  t.mzy = oy+3
  --t.dr = 3
 --else
  
 --[[ 
  cls()
  print('no dir')
  stop()
  
  --]]
  
 end
 
 local function go()
 
  local drs = candirs(t)
  local dr =
    drs[flr(rnd(#drs-0.01))+1]
  
  if #drs == 0 then
   return
   --[[
   cls()
   print('\ngo no drs',0,20,7)
   print('\n\n'..t.mzx..
     ' '..t.mzy..' ' .. i
         ,0,40,7)
   print('\n\n\n'..
     t.maze.b[1][1].m .. ' '..
      #t.maze.b,
        0,60,10)
   stop()
   --]]
   
  end
  
  local v = g_drdirs[dr]
  t.mzx += v[1]
  t.mzy += v[2]
  
  --[[
  --xxx don't walk off
  if t.mzx % 8 == 7 then
   t.mxz = 6
  end
  if t.mzy % 8 == 7 then
   t.mzy = 6
  end
  --]]
 end
 
 for i = 1, steps do
  go()
 end
 
 --[[
 if t.mzx > 6
   or t.mzy > 6
   or t.mzx < 1
   or t.mzy < 1 then
  go()
 end
 --]]
end
------------------------------
function getcellxy(cell)
 
 if cell.m > 15 then
  --
  return (cell.m - 16) * 8, 48
 end
 
 --(cell.m%4)*8 + flr(cell.m/4)
 
 local mx = flr(cell.m/4)*32
   + cell.r*8
 local my = (cell.m%4)*8
 
 
 return mx, my  
end

------------------------------

function make_maze(sizex,sizey)
 local r = {
  x=0,
  y=0,
  cx=0,
  cy=0,
  sx=sizex,
  sy=sizey,
  state=-1, --0, 1 cw, 2 ccw
  update=function(t,s)
   if t.state == 0 then
    
    if t.cx >= 0 and t.cy >= 0
      then
     if g_rotbtnfnc(4) then
      t.state = 1
      t.rt = g_tick
      sfx(0)
     elseif g_rotbtnfnc(5) then
      t.state = 2
      t.rt = g_tick
      sfx(0)
     end
    end
    
   elseif t.state > 0 then
    if elapsed(t.rt) >= 10 then
     --todo, rotate the block 
     
     local cell =
       t.b[t.cy+1][t.cx+1]
     
     local o = -1
     if t.state == 2 then
      o = 1
     end
     cell.r = (cell.r + o) % 4
     
     -- signal that rotation
     -- is done
     for obj in all(
       g_rotsignalobjs) do
      obj:rotdone(t)
     end
     
     t.rt = nil
     t.state = 0
    end
   end
   
  end,

  draw=function(t)
   
   if not t.skipborder then
    rect(0,0,t.sx*64-1,
      t.sy*64-1,1)
   end
   
   local flipcol = (
     g_tick % 30 > 14)
   
   --flipcol = g_tick % 4 > 1
   --t.basepal(flipcol)
   
   for y = 1, #t.b do
    local row = t.b[y]
    for x = 1, #row do
     local cell = row[x]
      t:drawcell(cell,x,y,
        flipcol)
    end
   end
   
   pal()   
  end,

  drawcell=function(t,cell,
    x,y,flipcol)
   
   local mx,my =
     getcellxy(cell)
   
   
   local sx = (x-1)*64
   local sy = (y-1)*64
   
   local isactive = (
     t.cx == x - 1
     and t.cy == y - 1)
   
   --experiment
   if isactive then
    flipcol = g_tick % 4 > 1
   end
   

    
    if isactive then
     
     if t.state < 1 then
      pal(7, 6)
      pal(13, 6) 
      
      if not t.skipborder then
      clip(sx+1-g_camx,
        sy+1-g_camy,62,62)
      end
      for xy in all({
        {-1,-1},
        {1,1},
        {-1,1},
        {1,-1}}) do
       map(mx,my,sx+xy[1],
         sy+xy[2],8,8)
      end
      clip()
      t.basepal(flipcol)
      map(mx,my,sx,sy,8,8)
     
     elseif t.state > 0 then
      local segs =
        getmapsegments(
          mx,my,8,8)
      
      
      local ang =
        elapsed(t.rt) / 10 *
          90
      if t.state == 2 then
       ang = ang * -1
      end
      
      t.ang = ang
      
      local lc = g_mazecol[2]
      
      
      pushc(-sx,-sy)
      local p1 = {x=-32,y=-32}
      local p2 = {x=32,y=32}
      for s in all(segs) do
       local v1 = vecadd({
         x=s[1],y=s[2]}, p1)
       local v2 = vecadd({
         x=s[3],y=s[4]}, p1)
       
       v1 = vecadd(p2,
         vecrot(v1, ang))
       v2 = vecadd(p2,
         vecrot(v2, ang))
    
       line(v1.x,v1.y,
         v2.x,v2.y, lc)
      end
      popc()
      
     end
    else
     t.basepal(flipcol)
     map(mx,my,sx,sy,8,8)
    end

    if not isactive
     or t.state <= 0 then
     
    if cellhasdr(cell,0)
       then
      local upcell = nil
      if y > 1 then
       upcell = t.b[y-1][x]
      end
      if not
        cellhasdr(
          upcell,2) then
       spr((g_tick % 4)+16,
         sx+28, sy)
      end
    end
     
    if cellhasdr(cell,2)
      then
     local downcell = nil
     if y+1 <= t.sy then
       downcell =
         t.b[y+1][x]
     end
     if not cellhasdr(
       downcell,0) then
      spr((g_tick % 4)+16,
         sx+28, sy+56)
     end
    end
     
    if cellhasdr(cell,3)
      then
     local leftcell = nil
     if x > 1 then
      leftcell =
        t.b[y][x-1]
     end
     if not
       cellhasdr(
         leftcell,1) then
      spr((g_tick % 4)+20,
        sx, sy+28)
     end
    end
     
    if cellhasdr(cell,1)
      then
     local rightcell = nil
     if x < t.sx then
      rightcell =
        t.b[y][x+1]
     end
     if not cellhasdr(
       rightcell,3) then
      spr((g_tick % 4)+20,
        sx+56, sy+28)
     end
    end
   
   end

  end,


  basepal=basepal,
  
  
  
 }
 
 local b = {}
 r.b = b
 
 
 for y = 1, r.sy do
  local row = {}
  add(b, row)
  for x = 1, r.sx do
   local cell = {}
   add(row, cell)
   cell.m = flr(rnd(
     g_maxcells-0.01))
   cell.r = flr(rnd(4))
   
   -- force cell for debug
   if g_dbgforcecell then
    cell.m = g_dbgforcecell
    --cell.r = 3
   end
   
   
  end
 end
 
 return r
end

function cellhasdr(cell, dr)
 if not cell then
  return false
 end
 
 local mx,my =
     getcellxy(cell)
   
 
 local m1,m2 = nil
 --local m1 = mget(mx+3,my+7)
 --local m2 = mget(mx+4,my+7)
   
 if dr == 0 then
  m1 = mget(mx+3,my)
  m2 = mget(mx+4,my)
 elseif dr == 1 then
  m1 = mget(mx+7,my+3)
  m2 = mget(mx+7,my+4)
 elseif dr == 2 then
  m1 = mget(mx+3,my+7)
  m2 = mget(mx+4,my+7)
 elseif dr == 3 then
  m1 = mget(mx,my+3)
  m2 = mget(mx,my+4)
 end
 
 return (
   m1 > 0
   and m2 > 0
   and fget(m1, dr)
   and fget(m2, dr))
   
end

-------------------------------

function getmazespr(b,x,y)
 x = flr(x)
 y = flr(y)
 if (x < 0) return nil
 if (y < 0) return nil
 
 --if (y >= #b*8) return nil
 --if (x >= #b*8) return nil
 
 
 
 local cx = flr(x/8)
 local cy = flr(y/8)
 local ix = x % 8
 local iy = y % 8
 
 local row = b[cy+1]
 if (not row) return nil
 
 local tile = row[cx+1]
 if (not tile) return nil
 
 local mx, my = getcellxy(tile)
 return mget(
   mx + ix,
   my + iy), ix, iy, cx, cy
end

-------------------------------

function draw_radararrow(
  sx,sy,c)
 
 local ang = vecang(
   {x=g_camx+63,y=g_camy+63},
   {x=sx,y=sy})

 local x1, y1, x2, y2 = 0,0,0,0
 if ang >= 45
   and ang < 135 then
  x1 = -4
  x2 = 131
 elseif ang >= 135
   and ang < 225 then
  y1 = -4
  y2 = 131
 elseif ang >= 225
   and ang < 315 then
  x1 = -4
  x2 = 131
  y1 = 127
  y2 = 127    
 else
 	x1 = 127
  x2 = 127
  y1 = -4
  y2 = 131
 end
 local i = 
   linesect(x1, y1, x2, y2,  
     63,63,
     sx-g_camx, sy-g_camy)
     
 i.x = i.x + g_camx
 i.y = i.y + g_camy
     
 local a1 = vecrot(
   {x=-6,y=0}, ang+20)
 local a2 = vecrot(
   {x=-6,y=0}, ang-20)
 
 local v = {
  {-1,0,0},
  {0,-1,0},
  {0,0,c},
 }
 
 for _, e in pairs(v) do
  pushc(e[1],e[2])
  line(i.x, i.y, i.x+a1.x,
    i.y+a1.y,e[3])
  line(i.x, i.y, i.x+a2.x,
    i.y+a2.y,e[3])
  line(i.x+a1.x, i.y+a1.y,
    i.x+a2.x, i.y+a2.y,e[3])
  popc()
 end
 
end


-------------------------------

function getmapsegments(
  x,y,w,h)

 local result = {}
 local current = nil
 
 --horz first
 for yy = 0,h-1 do
  current = nil
  for xx = 0,w-1 do
   local s = mget(x+xx,y+yy)
   --left
   if fget(s,3) then
    if not current then
     current={
       xx*8,yy*8+4,
       xx*8+4,yy*8+4}
     add(result,current)
    else
     current[3] = xx*8+4
    end
   else
    current = nil
   end
   
   --right
   if fget(s,1) then
    if not current then
     current={
       xx*8+4,yy*8+4,
       xx*8+8,yy*8+4}
     add(result,current)
    else
     current[3] = xx*8+8
    end
   else
    current = nil
   end
  end
 
 end
 --for i = x, x+w do
 
 --vert next
 for xx = 0,w-1 do
  current = nil
  for yy = 0,h-1 do
   local s = mget(x+xx,y+yy)
   
   --top
   if fget(s,0) then
    if not current then
     current={
       xx*8+4,yy*8,
       xx*8+4,yy*8+4}
     add(result,current)
    else
     current[4] = yy*8+4
    end
   else
    current = nil
   end
   
   if fget(s,2) then
    if not current then
     current={
       xx*8+4,yy*8+4,
       xx*8+4,yy*8+8}
     add(result,current)
    else
     current[4] = yy*8+8
    end
   else
    current = nil
   end
   
   
  end
 end
 return result

end

-------------------------------

function rotmapcw(
  sx,sy,dx,dy,w)
 w = w - 1
 for y = 0,w do

  local rx = w - y 
  for x = 0,w do
    local ry = x
    
    local sm = mget(sx+x,sy+y)
    
    local dm = sm
    
    if sm > 0 then
     local smi = sm % 4
     local smo = sm - smi
     local dmi = (smi + 1) % 4
     
     
     dm = smo + dmi
     
    end
    
    mset(dx + rx, dy + ry, dm)
  end
 end
 
end

function draw_wave(a,yp,off)
 local b = 0x6000
   
 for y = 0, 127 do
  
  local o = flr(sin(
    y/yp + off) * a)
  
  memcpy(b, b + o, 64)
    b = b + 64
   
 end

end


k_multlen = 60
function make_game(level)
 sfx(0)
 local t = {
  x=0,y=0,
  l=level,
  lives=2,
  mult=1,
  marks={},
  enemies={},
  update=function(t,s)
  
   if t.maze.state < 0 then
    return
   end
   local fx = t.flag.mzx
   local fy = t.flag.mzy
   
   if t.multtime then
    t.multtime -= 1
    
    g_flag.multval =
      t.multtime/k_multlen
    
    if t.multtime < 0 then
     t.multtime = nil
     t.mult = 1
     g_flag.multval = nil
    end
   end
   
   for mark in all(t.marks) do
    
    if mark.mzx == fx
      and mark.mzy == fy then
     
     
     del(t.marks,mark)
     del(g_objs,mark)
     del(g_rotsignalobjs,mark)
     
     local pts = 10
     for i = 1,t.mult-1 do
      pts *= 2
     end
     
     
     add(g_objs,
       make_scorebubble(
         mark.mzx*8,
         mark.mzy*8,
         #t.marks,
         ''..(pts*10),
         t.mult))
     
     add(t.flag.ups,
       make_markup(0,0))
     
     t.multtime = k_multlen
     
     if t.mult == 1 then
      sfx(1)
     else
      sfx(min(9,t.mult-1 + 6))
     end
     
     g_score += pts
     g_next1up -= pts
     if g_next1up <= 0
       then
      g_next1up += 1000
      
      g_lives += 1
      add(g_objs,make1up())
     end
     
     
     t.mult += 1
     
     --only one per cycle
     break
     
     -- x,y,n
    end 
   end
   
   --last mark goes fast
   if #t.marks == 1 then
    t.marks[1].rate = 4
   end
   
   if #t.marks == 0 
    
    and #t.flag.ups == 0 then
     music(-1,300)
     add(g_objs,
       make_trans(function()
        make_game(t.l+1)
    				
    				end))
   
    
   end
   
   
   local pv = {
    x=g_pmx,
    y=g_pmy
   }
   
   local _,_,pv =
     char_getpos(g_player)
  	
   for enemy in all(t.enemies) do
    --debug
    if (g_dbgnohit) break
    
    
    local _,_,ev =
      char_getpos(enemy)
    
    if abs(ev.x - pv.x) <= 2
      and abs(ev.y - pv.y) <= 2
        then
    
     --todo, make a better
     --remove
     for e in all(t.enemies) do
      local _,_,ev =
        char_getpos(e)
      
      local a = vecang(pv,ev)
      local v = vecrot(
        {x=-4,y=0}, a)
      
      add(g_objs,
       make_enemyflyoff(
         ev.x,ev.y,-v.x,-v.y))
      del(t.enemies, e)
      del(g_objs,e)
      del(g_rotsignalobjs, e)
     end
     
     --g_lives -= 1
     
     add(g_objs,
       make_hit(
         t, 0,0))
     return
    end  
   end
   
   
   
  end,
  draw=function(t)
  end
 }
 
 g_objs = {}
 
 add(g_objs,t)
 g_rotsignalobjs = {}
 g_camx = 0
 g_camy = 0
 local sx, sy = 2,2
 if t.l > 2
   and t.l % 2 == 0 then
  --todo, figure out maze size
  if t.l > 8 then
   sx += flr(rnd(2.99))
   sy += flr(rnd(2.99))
  else
   sx = 3
   sy = 3
  end
  
 end
 
 if t.l == 3 then
  sx = 3
 end
  
 local maze = make_maze(sx,sy)
 t.maze = maze
 add(g_objs, maze)
 
 local player = make_player(
   maze)
 g_player = player
 add(g_rotsignalobjs, player)
 t.player = player
 
 
 local nummarks =
   min(10,level + 4)
 for i = 1,nummarks do
  local mark = make_mark(maze)
  placechar(mark,
   flr(rnd(maze.sx-0.01)),
   flr(rnd(maze.sy-0.01)),16)
  add(g_objs, mark)
  add(g_rotsignalobjs, mark)
  add(t.marks, mark)
 end
 
 
 
 local flag = make_flag(maze)
 placechar(flag,flr(rnd(maze.sx)),
   flr(rnd(maze.sy-0.01)),16)
 
 
 add(g_rotsignalobjs, flag)
 add(g_objs, flag)
 t.flag = flag
 g_flag = flag
 
 add(g_objs, player)
 
 add(g_objs,make_levelbegin(t))
 
 --todo experiment with
 --spawn duration increasing
 --with the level(s)
 local ns = min(3,
   flr((level-1)/4)+1)
 for i = 1, ns do
  add(g_objs, make_spawn(t, 300,
     level))
 end
 
 g_mazecol = g_mazecols[
   ((level-1) % #g_mazecols)+1]
 
 
 
 add(g_objs,
   make_trans(nil,nil,1))
 
 
 return t
end

function getsstr(n)
 if (n == 0) return '0'
 return n..'0'
end

function make_scorebubble(
  x,y,n,pts,offset)
 return {
  x=x,
  y=y,
  n=n,
  st=g_tick,
  update=function(t,s)
   if elapsed(t.st) > 30 then
    del(s,t)
   end
  end,
  draw=function(t)
   local e = -elapsed(t.st)
   local xo = sin(g_tick/10)*4
     * (e/-20)
   pushc(xo,0)
   
   sprcpy(28,24,2,2)
   
   
   
   
   if e < -10 then
    local p = 100 -
      (-e-10)/20 * 100
    sprstochcpy(28,26,p,2,2)
    spr(28,-3,e-8,2,2)
   else
    spr(26,-3,e-8,2,2)
   end
   
   
   
   print(t.n,4,e-2,0)
   popc()
   
   pushc(t.x - g_camx +
      (offset-1)*16,
     t.y - g_camy + e + 4)
    
    local l = #pts*4+3
    local x = 130-l
    rectfill(x-2,108,127,116,9)
    rect(x-2,108,127,116,10)
    print(pts, 130-l, 110,0)
   popc()
  end
 }
 
end

function make_markup(x,y)
 local t = {
  x=x,
  y=y,
  st=g_tick,
  getxy=function(t)
   local e = elapsed(t.st)
   
   local v = vecrot({x=-4,y=0},
      e*30)
   
   return v.x,v.y
  end,
  update=function(t,s)
   if elapsed(t.st) > 40 then
    del(s,t)
   end
  end,
  draw=function(t)
   local e = elapsed(t.st)
   
   local x = t:getxy()
   
   spr(100,x+5, -e/3 +5)
  end
 }
 return t
end

function make_levelbegin(game)
 sfx(2)
 return {
  x=0,
  y=0,
  ts=g_tick,
  update=function(t,s)
   local e = elapsed(t.ts)
   if e >= 60 then
    del(s,t)
    game.maze.state=0
    sfx(3)
    --if g.level == 1
    music(0)
   elseif e % 20 == 0 then
    sfx(2)
   end
   
   
   
  end,
  draw=function(t)
   
   pushc(-g_camx, -g_camy)
   local voff = 0
   
   local e = elapsed(t.ts)
   
   if e > 50 then
    voff = (e - 50) * 4
   end
   
   pushc(0,voff)
   
   local txt =
    'level ' .. game.l
   for xyc in all({
     {0,1,0},
     {0,-1,0},
     {1,0,0},
     {-1,0,0},
     {0,0,6}
     }) do
    
    pushc(xyc[1], xyc[2]) 
    print(txt, 50, 50,
      xyc[3])
    
    pal(6, xyc[3])
    
    local e = elapsed(t.ts)
    
    spr(33+flr(e/20),
      60, 58)
    
    pal()
    popc()
   end
   
   popc()
   
   
   if e > 50 then
    pushc(0, -(e - 50))
   end
   draw_stats()
   if e > 50 then
    popc()
   end
   
   popc()
  end
 }
end


function make_spawn(game, dur,
  level)
 local t = {
 	x=0,y=0,
 	mzx=0,mzy=0,
 	st=g_tick,
 	maze=game.maze,
  dur=dur,
  rotdone=char_rotdone,
  hold=function(t)
   t.st = g_tick
  end,
  update=function(t,s)
   
   local e = elapsed(t.st)
   
   if e >= dur then
    del(s, t)
    del(g_rotsignalobjs,t)
    
    
    local e =
      make_enemy2(game.maze)
    e.mzx = t.mzx
    e.mzy = t.mzy
    add(g_rotsignalobjs, e)
    add(game.enemies, e)
    add(g_objs, e)
    
    sfx(6,0)
    
    --freebie on the first
    if level == 1 then
     return
    end
    add(g_objs, make_spawn(
       game, dur))
    
   end
   
  end,
  draw=function(t)
   local en =
     elapsed(t.st)/t.dur
   local s = flr(en * 5)
   
   local ox, oy =
     char_getpos(t)
   
   local copyfrom = 96
   
   if s == 4 then
    
    if g_tick % 8 > 4 then
     copyfrom = 64
    end
    
   
   end
   
   sprcpy(68, 0)
   sprstochcpy(68,copyfrom,
     en*90)
  
   pushc(ox,oy)
   
   spr(68,4,4,1,1)
   
   
   
   popc()
   
  end
 }

 add(g_rotsignalobjs, t)
 
 placechar(t,
   flr(rnd(t.maze.sx-0.01)),
   flr(rnd(t.maze.sy-0.01)),16)
 
 
 
 
 return t
 


end




function draw_stats(top)
 if (not top) pushc(0, -119)
 
 rectfill(0, 0, 128, 10, 1)
 
 if top then
  line(0,10,128,10, 5)
 else
  line(0,-1,128,-1, 5)
 end
 
 spr(97, 1,1)
 spr(36, 8,1)
 print(max(0,g_lives-1),
   14, 2, 7)
 
 local sstr = getsstr(g_score)
 local w = 4 * (#sstr + 6)
 print('score:'..sstr,
      126 - w, 2, 7)
 
 
 if (not top) popc()
end


function make_hit(game,x,y)
 sfx(4)
 game.maze.state=-2
 game.maze.hittime=g_tick
 --todo, stop player?
 --g_player.stopped = true
 return {
  x=x,
  y=y,
  ts=g_tick,
  declife=true,
  update=function(t,s)
   
   local e = elapsed(t.ts)
   
   if t.declife and e >= 30 then
    g_lives -= 1
    t.declife = nil
    --todo, add anim
   end
   
   for i = 1, #g_objs do
    local o = g_objs[i]
    if (o.hold) o:hold()
   end
   
   if e == 60 then
    if g_lives > 0 then
     sfx(5)
    end
   end
   
   if e > 90 then
    del(s,t)
    
    if g_lives < 1 then
     g_hiscore = max(g_score,
       g_hiscore)
       
     --transition?
     g_objs = {}
     add(g_objs, make_main())
    else
     game.maze.state=0
     game.maze.hittime=nil
    end
    
   end
  end,
  draw=function(t,s)
   pushc(-g_camx, -g_camy)
   if g_lives < 1 then
    --todo, black outline
    pal(2,0)
    spr(133, 48,40,4,4)
    pal()
    --print('game over', 48,55,7)
   end
   
   local offset = 0
   
   local x,y =
      char_getpos(g_player)
   
   local top = (-y) - g_camy
     > 90
   
   local e = elapsed(t.ts)
   if e > 70 then
    if top then
     offset = e - 70
     
    else
     offset = -(e - 70)
    end
    
   end
   
   pushc(0, offset)
   draw_stats(top)
   popc()
   
   
   popc()
  end
 }
 
end

function make_main()
 g_camx = 0
 g_camy = 0
 music(-1)
 -- stuff the bees look at
 g_pmx = -100
 g_pmy = -100
 g_flag = {mzx=g_pmx,mzy=g_pmy}
 g_player = g_flag

 add(g_objs,
   make_instructions())
 

 local titleobjs = {}
 local tx = 0
 
 local pc = flr(rnd(9.99)) + 1
 for i = 1, 10 do
  local m = make_maze(1,1)
  m.x = tx
  tx += sget(71+i,65) * 8
  --m.cy = -1
  m.b[1][1].m =
    sget(71+i,64)+16
    
  m.skipborder = true
  
  m.state = 0
  
  
  local p = nil
  
  --special case the a
  local mzy = 0
  if i == 2 then
   mzy = 1
  end
  
  if pc == i then
   p = make_player(m,mzy)
   p.step = 0
   p.rate = 4
  else
   if rnd(100) < 50 then
    p = make_enemy2(m)
    p.mvmode = 0
   else
    p = make_mark(m)
   end
   p.mzy = mzy
  end
  
  
  
  
  
  p.x = m.x
  p.y = m.y
  
  
  
  
  
  
  add(titleobjs, m)
  add(titleobjs, p)
 
 end
 
 
 return {
  x=0,y=0,
  xoff=0,
  update=function(t,s)
   
   updateobjs(titleobjs)
   
   t.xoff -= 2
   if t.xoff < -480 then
    t.xoff = 0
   end
   
   if btnn(5) or btnn(4) then
    g_lives = 3
    
    add(g_objs,
      make_trans(function()
        g_score=0
        g_next1up=500
        make_game(1)
        end))
   end
  end,
  draw=function(t)
   
   if g_tick % 32 > 16 then
    print('press to start',
      36, 120, 7)
   end
   
   
   pushc(-(t.xoff+128),
     -30)
    
   drawobjs(titleobjs)
   
   popc()
   
   rectfill(0,0,128,7,1)
   line(0,7,127,7,5)
   
   local sstr = getsstr(g_score)
   
   print('score:'..sstr,
     2, 1, 7)
   
   local histr =
    getsstr(g_hiscore)
   
   local w = 4 * (#histr + 5)
   print('high:'..histr,
      126 - w, 1, 7)
   
   
   
  end
 }
 
end

function make_instructions()
 local width = 246
 return {
  x=156,
  y=98,
  update=function(t,s)
   t.x-=1
   if t.x < -width then
    t.x += width
   end
  end,
  draw=function(t)
   -- todo, animate the sprs
   
   local x = -t.x
   rectfill(
     x,-6,-t.x+128,10,0)
   rect(
     x-1,-6,-t.x+129,10,5)
   
   
   for i = 0, 1 do
    pushc(i*-width,0)
    print('guide the', 0,0,7)
    spr(100 + g_tick % 6,38,-2)
    
    --[[
    if g_tick % 2 == 0 then
     
     local f= flr(
       (g_tick%8)/2)
     spr(84+f,35,-2)
     spr(84+f,41,-2,1,1,true)
     
    end
    --]]
    
    print('to the', 48,0,7)
    spr(14,72,-5,2,2)
    line(87,-2,87,6,5)
    print('avoid the', 92,0,7)
    if g_tick % 2 == 0 then
      pal(5, 6)
    end
    spr(64,130,-2)
    pal()
    line(141,-2,141,6,5)
    print('rotate the', 146,0,7)
    
    local e = g_tick % 40
    if e < 30 then
     spr(78,189,-2)
    else
     --todo, bake to spr
     --to get token budget
     --back
     spr(128+(e-30)/2,189,-2)
     --[[
     local a = (e-30)*-9
     local v1 = vecrot(
       {x=0,y=-4},a)
     local v2 = vecrot(
       {x=0,y=4},a)
     local v3 = vecrot(
       {x=-4,y=0},a)
     local v4 = vecrot(
       {x=4,y=0},a)
     pushc(-189 - 4, -2)
     line(v1.x,v1.y,v2.x,v2.y,
       14)
     line(v3.x,v3.y,v4.x,v4.y,
       14)
     
     popc()
     --]]
     
    end
    
    print('to escape', 200,0,7)
    line(240,-2,240,6,5)
    popc()
   end
  end
 }
end


function make_enemyflyoff(
  sx,sy,vx,vy)
 return {
  x=sx, y=sy, vx=vx, vy=vy,
  st=g_tick,
  update=function(t,s)
   if elapsed(t.st) > 60 then
    del(s, t)
   else
    t.x += t.vx
    t.y += t.vy
   end
  end,
  draw=function(t)
   spr(64,4,4)
   
    if g_tick % 2 == 0 then
     local f= flr(
       (g_tick%8)/2)
     spr(84+f,1,4)
     spr(84+f,7,4,1,1,true)
    end
  end
 }


end

function make1up()
 sfx(15)
 return {
 x=0,y=0,ts=g_tick,
 update=function(t,s)
  t.e = elapsed(t.ts)
  
  if (t.e > 60) del(s,t)
 end,
 draw=function(t)
  
  pushc(-g_camx,-g_camy)
  sprcpy(93,24,2,2)
  local p = 100
  if t.e >= 30 then 
    p -= (t.e-30)*3.3
  end
  sprstochcpy(
    93, 91, p, 2, 2)
  spr(93,2,118,2,2) 
  popc()
  
 end
 }
end

__gfx__
00000000006000000f0000f00ff00000000ff0000000ff9000000000000000000000000000000000090000900990000000099000000099900000000011000000
000000000066000099f00f99099000ff00f99000ff00f99000f99900000000000000000000000000999009990990009900999000990099900000000176100000
0000000000666000099999900999999900f99900999999000fff999000ff9900000ff00000000000099999900999999900999900999999000000001766510000
0000000000666600009719000097199000f71999099719000bbbbbb00bbbbbb000bbbb0000044000009cc90000999990009cc999099999000000001766510000
00000000006665000097790009977900ff9779990097799004444440044444400044440000044000009cc90009999900999cc99900999990000011bb75100000
0000000000665000099999909994990044499900009999990fff999000ff9900000f900000000000099999909999990099999900009999990011bb3365100000
00000000006500009940049944404990000499000099404400ff99000000000000000000000000009990099999909990000999000099909901bb333365100000
00000000005000000400004000000400000044000444000000000000000000000000000000000000090000900000090000009900099900000011333365100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000113365100000
00000000000000000000000000000000000110000008100000011000000180000000000000000000000000000000000000000000000000000000001165100000
00000000000000000000000000000000000180000001100000081000000110000000000000000000000000000000000000000000000000000000000165100000
01118110081118100181118001181110000110000001800000011000000810000000000000000000000000aaaaa0000000000000000000000000000165100000
0181118001181110011181100811181000081000000110000001800000011000000000000000000000000a99999a000000000000000000000000001766510000
000000000000000000000000000000000001100000081000000110000001800000000000000000000000a9999999a00000000000000000000000001111110000
00000000000000000000000000000000000180000001100000081000000110000000000000000000000a999999999a0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000a999999999a0000000000000000000000000000000000
11110000006666000066660000066600000000000000000000000000000000000000000000000000000a999999999a0000000000000000000000000055555555
10010000006666000066660000066600000000000000000000000000000000000000000000000000000a999999999a0000000000000000000000000055555555
10010000000066000000660000006600006060000000000000000000000000000000000000000000000a999999999a0000000000000000000000000055555555
111100000066660000666600000066000006000000000000000000000000000000000000000000000000a9999999a00000000000000000000000000055555555
0000111100666600006666000000660000606000000000000000000000000000000000000000000000000a99999a000000000000000000000000000055555555
00001001000066000066000000006600000000000000000000000000000000000000000000000000000000aaaaa0000000000000000000000000000055555555
00001001006666000066660000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
00001111006666000066660000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000000000000000000000000776550000000055677000555555550000000000000000556770000007765555555555555555550007765555677000
000000000000000000000000000000000007d655000000005567d0005555555500000000000000005567d0000007d65555555555555555550007d6555567d000
00000000000000000000000000000000000dd65500000000556dd000666666660000000000000000666dd000000dd6665566666666666655000dd655556dd000
00000000000000000000000000000000000d765577dd77dd556d700077dd77dd000d77dd77dd700077dd7000000d77dd556d77dd77dd765577dd7655556d77dd
00000000000000000000000000000000000776557dd77dd7556770007dd77dd700077dd77dd770007dd7700000077dd755677dd77dd776557dd7765555677dd7
000000000000000000000000000000000007d655666666665567d000000000000007d6666667d00000000000000000005567d0000007d6556666665555666666
00000000000000000000000000000000000dd65555555555556dd00000000000000dd655556dd0000000000000000000556dd000000dd6555555555555555555
00000000000000000000000000000000000d765555555555556d700000000000000d7655556770000000000000000000556d7000000776555555555555555555
00555550005555500055555000555550000000000000000000000000000000000010001000000000001000100010001000100010000000000008e00000000000
05ee888505ee888505ee888505ee888500000000000000000006600000066000001000100000000000100010001000100010001001101100000ee00000000000
05e1818505e1818505e1818505e1818500000000000000000067700000677000010101010000000001010101010101010101010101101100000e800000000000
05e1818505e1818505e1818505e18185000000000000000006777000067770001000100000000000100010001000100010001000011011008ee88ee800000000
05ee888505ee888505ee888505ee888500000000000000000677700067777000100010000000000010001000100010001000100001111100ee88ee8800000000
05ee888505ee888505ee888505ee888500000000000000000067700067777000100010000000000010001000100010001000100000001100000ee00000000000
0055555000555550005555500055555000000000000000000006600006776000010101010000000001010101010101010101010100001100000e800000000000
00000000000000000000000000000000000000000000000000000000006600000010001000000000001000100010001000100010000011000008800000000000
0050050000500500005005000050050000000000000000000000000000000000000000000070770077007070aaaaaaaaaaaaa000000000000000000000000000
0005500000055000000550000005500000000000006600000000000000000000000000000070007000707070a99999999999a000000000000000000000000000
005f9500005f9500005f9500005f950000066000067770000006600000066000000000000070070007007770a91919191119a000000000000000000000000000
057aa950057aa950057aa950057aa95000677000067770000067700000677000000000000070700000700070a91919191919a000000000000000000000000000
05f9945005f9945005f9945005f9945000677000006670000067700006777000000000000070777077000070a91919191119a000000000000000000000000000
057aa950057aa950057aa950057aa95000066000000060000006600006776000000000000000000000000000a91911191999a000000000000000000000000000
05f9945005f9945005f9945005f9945000000000000000000000000000660000000000000000000000000000a999999999aaa000000000000000000000000000
0055550000555500005555000055550000000000000000000000000000000000000000000000000000000000aaaaaaaaaa000000000000000000000000000000
0055555000f999000000000000000000000000000000000000000000000000000000000000000000055555550005550000011100000000000000000000000000
0566ddd50fff9990000000000000000000000000000000000000000000000000000000000000000005ee8885005e8850001d5510000000000000000000000000
0565d5d50bbbbbb0000000000000000000555000005550000055500000555000005550000055500005e1818505ee888501ddd551000000000000000000000000
0565d5d504444440000000000000000005aaa50005aaa50005aaa50005aaa50005aaa50005aaa50005e1818505e1818501d1d151000000000000000000000000
0566ddd50fff9990000000000000000005aa950005aaa50005aaa500059aa5000599a50005a9950005ee888505e1818501d1d151000000000000000000000000
0566ddd500ff9900000000000000000005a9950005aa9500059aa5000599a500059995000599950005ee888505ee888501ddd551000000000000000000000000
00555550000000000000000000000000005550000055500000555000005550000055500000555000055555550055555000111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000
10000001011111100000000000000000000000000111111000000000000000000001000000101000000100000000000001110000000011100111110000111110
10000001010000100011110000000000001111000100001000000000000100000010100001000100001010000001000001010110011010100100010000100010
10000001010000100010010000011000001001000100001000010000001010000100010010000010010001000010100001110010010011100100000000000010
10000001010000100010010000011000001001000100001000000000000100000010100001000100001010000001000000000010010000000100111001110010
10000001010000100011110000000000001111000100001000000000000000000001000000101000000100000000000000100010010001000110101001010110
10000001011111100000000000000000000000000111111000000000000000000000000000010000000000000000000000111110011111000000111001110000
11111111000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000001000000000000000
0000e00000000e00e000000e00e00000000e00000000000000000000000000000000000001253467560000000000000000000000000000000000000000000000
0000e00000000e000e0000e000e00000000e00000000000000000000000000000000000064444455350000000000000000000000000000000000000000000000
0000e000ee00e00000e00e00000e00ee000e00002222222222222222220002222222222000000000000000000000000000000000000000000000000000000000
eeeee00000eee000000ee000000eee00000eeeee2111111111111111112021111111112000000000000000000000000000000000000000000000000000000000
000eeeee000eee00000ee00000eee000eeeee0002166666616666661661216616666612000000000000000000000000000000000000000000000000000000000
000e0000000e00ee00e00e00ee00e0000000e0002166666616666661666166616666612000000000000000000000000000000000000000000000000000000000
000e000000e000000e0000e000000e000000e0002166111116611661666666616611112000000000000000000000000000000000000000000000000000000000
000e000000e00000e000000e00000e000000e0002166122216611661666666616612222000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000002166122216611661661616616611120000055500000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000021661111166116616611166166661200005e8850000000000000000000000000000000000000000000000000
00000111111000000000011111000000000000002166116616666661661216616666120005eee885000000000000000000000000000000000000000000000000
00001fff9991000000011ff999100000000000002166116616666661661216616611220005e1e185000000000000000000000000000000000000000000000000
0001fffff9991000001ffffff9910000000000002166116616611661661216616611112005e1e185000000000000000000000000000000000000000000000000
001ff77ff7799100001f77ff77991000000000002166666616611661661216616666612005eee885000000000000000000000000000000000000000000000000
001f777f7779910001f777f777991000000000002166666616611661661216616666612000555550000000000000000000000000000000000000000000000000
001f711f7119910001f711f711991000000000002111111111111111111111111111112000000000000000000000000000000000000000000000000000000000
01bb611b611b210001b611b611bb1000000000002166666616612166166666166666122000000000000000000000000000000000000000000000000000000000
01444444444221000144444444421000000000002166666616612166166666166666612000000000000000000000000000000000000000000000000000000000
01242424242910000142422422291000000000002166116616612166166111166116612000000000000000000000000000000000000000000000000000000000
001ffffff9991000001f999999991000000000002166116616612166166122166116612000000000000000000000000000000000000000000000000000000000
0001ffff99110000001fffff99910000000000002166116616612166166111166116612000000000000000000000000000000000000000000000000000000000
00001111110000000001f99999100000000000002166116616612166166661166666612000000000000000000000000000000000000000000000000000000000
00000000000000000000111111000000000000002166116616611166166661166666122000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000002166116616661666166111166116612000000000000000000000000000000000000000000000000000000000
00001000000001000000000000100000000100002166116611666661166111166116612000000000000000000000000000000000000000000000000000000000
00001000000001000100001000100000000100002166666612166612166666166116612000000000000000000000000000000000000000000000000000000000
00001000110010000010010000010011000100002166666612216122166666166116612000000000000000000000000000000000000000000000000000000000
11111000001110000001100000011100000111112111111112021202111111111111112000000000000000000000000000000000000000000000000000000000
00011111000111000001100000111000111110002222222222002002222222222222222000000000000000000000000000000000000000000000000000000000
00010000000100110010010011001000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000001000000100001000000100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000001000000000000000000100000010000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
83930000839300000083930000000000835353930000000083535393000000008393839300000000835393000000000083535393000000008353535393000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43f39383e363000083e3f39300000000b373d3630000000043c3d36300000000436343630000000043c3a3000000000043c3d3630000000043c37373a3000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43f2f3e3f263000043c3d363000000008353e3630000000043f3e36300000000436343630000000043f393000000000043f3e363000000004363835393000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43c3d3c3d363000043f3e3630000000043c373a30000000043c3d36300000000436343630000000043c3a3000000000043c3d3f3930000004363b3d363000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
4363b3a34363000043c3d3630000000043f353930000000043f3e3630000000043f3e3630000000043f39300000000004363b3d36300000043f353e363000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
b3a30000b3a30000b3a3b3a300000000b37373a300000000b37373a300000000b37373a300000000b373a30000000000b3a300b3a3000000b3737373a3000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
83930000839300839300839300839300835393839300835353938393000083938353938353539300000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43638393436383e3f39343630043630043c3a343630043c3d36343638393436343c3a343c3d36300000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43634363436343c3d36343630043630043f3934363004363436343634363436343f39343f3e36300000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
43f3e3f3e36343f3e36343630043630043c3a34363004363436343f3e3f3e36343c3a343c3d3f393000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
b3d3c3d3c3a343c3d36343f39343f39343630043f39343f3e363b3d3c3d3c3a343f3934363b3d363000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202
00b3a3b3a300b3a3b3a3b373a3b373a3b3a300b373a3b37373a300b3a3b3a300b373a3b3a300b3a3000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020202020202020202020202

__gff__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050a050a060c0903060c090300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3835353e3f353539000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343c373737373d36000000000000000000000000000000000000000000000000000000343f35353900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
34360000000034360000000000000000000000000000000000000000000000000000003b37373d3600000000000000000000000000000000000000000000000000003835353900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343f353535353e3f000000000000000000000000000000000000000000000000353535353900343f00000000000000000000000000000000000000000000000035353e3c3d3f35350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343c373d3c3737370000000000000000000000000000000000000000000000003d3c373d3600343c00000000000000000000000000000000000000000000000037373d3f3e3c37370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3436003436000000000000000000000000000000000000000000000000000000343600343600343600000000000000000000000000000000000000000000000000003b3d3c3a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343f353e36000000000000000000000000000000000000000000000000000000343f353e3f353e3600000000000000000000000000000000000000000000000000000034360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b37373d360000000000000000000000000000000000000000000000000000003b3737373737373a00000000000000000000000000000000000000000000000000000034360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3835353e36000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000034360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343c373d360000000000000000000000000000000000000000000000000000000000003436000000000000000000000000000000000000000000000000000000000000343f3539000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3436003436000000000000000000000000000000000000000000000000000000000000343f3535390000000000000000000000000000000000000000000000000000003b373d3f390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343f353e360038350000000000000000000000000000000000000000000000000000003b37373d3600000000000000000000000000000000000000000000000035353900003b3d360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343c37373a00343c0000000000000000000000000000000000000000000000000000000000003436000000000000000000000000000000000000000000000000373d360000383e360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
343f3535390034360000000000000000000000000000000000000000000000000000003835353e3600000000000000000000000000000000000000000000000000343f39383e3c3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b37373d3f353e36000000000000000000000000000000000000000000000000000000343c37373a000000000000000000000000000000000000000000000000003b3d3f3e3c3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000343c37373a000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000003b37373a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003436000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003436000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000034360000000000000000000000000000000000000000000000000000000000003b3a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3535353e36000000000000000000000000000000000000000000000000000000353535393835353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
373737373a0000000000000000000000000000000000000000000000000000003737373a3b37373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000383900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003436000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0038353e36000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00343c373a000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353e3600003835350000000000000000000000000000000000000000000000003535353e3f35353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37373a0000343c370000000000000000000000000000000000000000000000003737373d3c37373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000038353e3600000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000343c373a00000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003436000000000000000000000000000000000000000000000000000000000000343600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000000000102401020010200102001020010200103001030010300203002030030300303004030050200502006020070200a0300c0300f0301303016040180401b0401f03023030280302d0303103500000
010300000b3000a3000c3000d3000e31412310133100d3100a3100a3200d320103201932018320113200f3200e32016320193201a3201a320143200d320103201831022310223101f31519300143001430027700
00110000000001e020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001900003602036021360213602500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002455122551215511e55119551155410d53107511056510465101631016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00000455106551085510a5510d5511155114551175511d5511d5511a551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000b2010821106211042210322101221012210422105221082210a22109211092110a2110a2010a20109201092010920109201082010720105201022010120101201012000000000000000000000000000
000300000b3000a3000c3000d300123141631017310173101531015320173201c3201c3201b3201832015320173201b3201c3201c3201b3201b320183201e3202331027310283102531519300143001430027700
010300000b3000a3000c3000d30017314193101b3101b310193101c3201f32021320213201f3201c3201b3201d3202132022320203201d3201f3202432028320283102c3102e3103031530300143001430027700
000300000b3000a3000c3000d3001a3141e3102131022310223102232027320273202732024320213202132023320273202632023320263202c3202f3203032034310373103a3103a31530300143001430027700
0114002004031040010405004000041300000004050000000d031000000d050000000d130000000d0500000008031000000805000000081300000008050000000903100000090500000009130000000905009051
011400201975019750187511870119750187001970018701000000000000000000001b7501b7511b755000001c755000000000000000107550000000000000001075500000000000000010755000000000000000
011400001975019750187511870119750187001970018701000000000000000000001b7501b7511b755000001c7550000000000000001b7550000000000000001c7501c7501b7510000019750197501775100000
011400000d0300d0310d051000000d130000000d050000000e0300e0310e051000000e130000000e05000000120301203112051000001213000000120500000010030100311005100000100300f0511005110051
011000001b7501a7511b7511a7511b7411a7311b7210f711197001970118701000001c7001b7011c7001b7011c7501b7511c7511b7511c7411c7311b7211c7111c7001b7011c7011b7011c7011c7011b7011c701
0003000000000000001f3242d0212e32130021303312d03124031223411f0411f3412105124351280612a3712c071323713607138371340613b3513a041353113500133305340003630037300373003830000000
000200003071032711307150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003471036711347150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003171035711367150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002f71034711367150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
01 43420a54
00 41420a0b
02 41420a0c
00 41420d4e
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344


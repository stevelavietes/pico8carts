pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


function _init()
 stdinit()
 
 g_maxcells=5
 g_rotsignalobjs = {}
 
 -- init map cells
 for i = 0,g_maxcells-1 do
  local y = i * 8
  for j = 0,2 do
   rotmapcw(j*8,y,j*8+8,y,8)
  end
 end
 
 make_game()
 
end

function _update()
 stdupdate()
end

function _draw()
 stddraw()
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
 --rectfill(0,0,127,127,5)
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
  local s = (-sy1 * (x1 - x3)
     + sx1 * (y1 - y3)) /
      (-sx2 * sy1 + sx1 * sy2)
  local t = ( sx2 * (y1 - y3)
     - sy2 * (x1 - x3)) /
      (-sx2 * sy1 + sx1 * sy2)

  return {
   x = x1 + (t * sx1),
   y = y1 + (t * sy1)
  }
 
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
   spr(1,-x,2+10*t.i)
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

function round(v)
 if v % 1 < 0.5 then
  return flr(v)
 end
 return flr(v)+1
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
 
 return s and
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
 if maze.cx ~=
   flr(t.mzx/8) then
  return
 end
 
 if maze.cy ~=
   flr(t.mzy/8) then
  return
 end
  
 local ox = flr(t.mzx/8)*8
 local oy = flr(t.mzy/8)*8
 local ix = t.mzx - ox
 local iy = t.mzy - oy
 
 if maze.state == 2 then
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
end

function char_getpos(t)
 local ox, oy = nil
   
 if t.maze.state ~= 0
   and flr(t.mzx/8) ==
     t.maze.cx
   and flr(t.mzy/8) ==
     t.maze.cy
    then
  
  local px = t.maze.cx*64+24
  local py = t.maze.cy*64+24
  
  local x = t.mzx*8 - px
  local y = t.mzy*8 - py
  
  local r =
    vecrot({x=x,y=y},
       t.maze.ang)
  
  ox = -(r.x + px)
  oy = -(r.y + py)
 else
  ox = -t.mzx*8
  oy = -t.mzy*8
 end
 return ox, oy
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
  dr=1,
  maze=maze,
  rotdone=function(t,maze)
   char_rotdone(t,maze)
  end,
  update=function(t,s)
   if (t.maze.state~=0) return
   
   
   if t.mzx % 1 == 0
     and t.mzy % 1 == 0 then
    
    --herdable movement
    local lngdrs = {}
    local lngdst = 0
    
    for dr in all(
      candirs(t)) do
     
     local v = g_drdirs[dr]
     local x = t.mzx
       + v[1]
     local y = t.mzy
       + v[2]
     
     local dst = 
       vecdistsq({x=x,y=y},
        {x=g_pmx,y=g_pmy})
     if dst > lngdst then
      lngdrs = {dr}
      lngdst = dst
     elseif dst == lngdst
       then
      add(lngdrs, dr)
     end
    end
    
   
    local idx = flr(rnd(
     #lngdrs)) + 1
     
    t.dr = lngdrs[idx]
   end
   
    --random movement
    --[[
    if not cango(t, t.dr) then
     --taco
     local drs =
       candirs(t, t.dr)
     local idx = flr(rnd(
       #drs)) + 1
     t.dr = drs[idx]
    else
     local drs =
       candirs(t, (t.dr+2)%4)
     
     local idx = flr(rnd(
       #drs)) + 1
     t.dr = drs[idx]
    end
    
   else
    --huh 
   end
   --]]
   
   
   local v = g_drdirs[t.dr]
   
   t.mzx = t.mzx + v[1]*0.125
   t.mzy = t.mzy + v[2]*0.125
   
  end,
  draw=function(t)
   local ox, oy =
     char_getpos(t)
   if rectsect(
     -ox+4,-oy+4,-ox+12,-oy+12,
     g_camx, g_camy,
     g_camx + 127, g_camy + 127)
      then
    pushc(ox, oy)
    spr(24+t.dr,4,4,1,1)
    popc()
   else
    draw_radararrow(-ox+8,-oy+8,10)
   end
  end

 }
 return t
end

function make_flag(maze)
 local t = {
  x=0,
  y=0,
  mzx=0,
  mzy=0,
  maze=maze,
  rotdone=function(t,maze)
   char_rotdone(t,maze)
  end,
  update=function(t,s)
   g_fx = t.mzx
   g_fy = t.mzy
   
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
    spr(14,0,-4,2,2)
    popc()
   else
    draw_radararrow(
      -ox+8,-oy+8,11)
   end
  end
 }
 return t
end


function make_player(maze)
 local t = {
  x=0,
  y=0,
  mzx=0,
  mzy=0,
  dr=1,
  lastdrs=0,
  maze=maze,
  trail={},
  
  rotdone=function(t,maze)
   char_rotdone(t,maze)
  end,
  
  update=function(t,s)
   
   if t.maze.state ~= 0 then
    return
   end
   ---
   
   local move = true
   
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
    
    if dr
      and (cango(t, dr)
        or not cango(t, t.dr))
       then
      
     t.dr = dr
    end
    
    if not cango(t, t.dr) then
     move = false
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
    if not v then
     cls()
     print(t.dr)
     stop()
    end
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
    
        then
      t.maze.cx = t.maze.cx + 1 
     end
    elseif t.dr == 2 then
     if (t.mzy % 8) > 5.5 and
       t.maze.cy < t.maze.sy - 1
        
        
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
    
        
        then
      t.maze.cy = t.maze.cy - 1 
     end
    elseif t.dr == 3 then
     if (t.mzx % 8) < 1.5 and
       t.maze.cx > 0
       
       and not cellhasdr(
         getcell(t, t.mzx-8,
            t.mzy), 1) 
    
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
   
   local fp = t.dr < 2
   
   local ox, oy = char_getpos(t)
   
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
   for xy in all(t.trail) do
    pushc(xy[1], xy[2])
    spr(10+xy[3],4,4,1,1,fp,0)
    popc()
   end
   
   add(t.trail, {ox,oy,s})
   if #t.trail == 8 then
    del(t.trail, t.trail[1])
   end
   
   pal()
   pushc(ox, oy)
   spr(2+s,4,4,1,1,fp,0)
   popc()
  end
 }
 
 placechar(t,0,0,0)
 
 return t
end

function placechar(t,cx,cy,
 steps)
 
 local ox, oy = cx*8, cy*8
 local cell = getcell(t,ox,oy)
 
 t.mzx = ox
 t.mzy = oy
 if cellhasdr(cell, 0)
   then
  t.mzx = ox+3
  
 elseif cellhasdr(cell, 3)
   then
  t.mzy = oy+3
 elseif cellhasdr(cell, 2)
   then
  t.mzx = ox+3
  t.mzy = oy+7
 elseif cellhasdr(cell, 1)
   then
  t.mzx = ox+7
  t.mzy = oy+3
 end
 
 for i = 1, steps do
  local drs = candirs(t)
  
  local dr =
    drs[flr(rnd(#drs))+1]
  
  local v = g_drdirs[dr]
  t.mzx += v[1]
  t.mzy += v[2]
  
 end

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
  state=0, --0, 1 cw, 2 ccw
  update=function(t,s)
   if t.state == 0 then
    
    if t.cx >= 0 and t.cy >= 0
      then
     if btnn(4) then
      t.state = 1
      t.rt = g_tick
     elseif btnn(5) then
      t.state = 2
      t.rt = g_tick
     end
    end
    --[[
    if btnn(0) then
     if t.cx > 0 then
      t.cx = t.cx - 1
     end
    elseif btnn(1) then
     if t.cx < t.sx - 1 then
      t.cx = t.cx + 1
     end
    elseif btnn(2) then
     if t.cy > 0 then
      t.cy = t.cy - 1
     end
    elseif btnn(3) then
     if t.cy < t.sy - 1 then
      t.cy = t.cy + 1
     end
    end
    --]]
    
    
   else
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

   rect(0,0,t.sx*64-1,
     t.sx*64-1,1)
   local flipcol = (
     g_tick % 30 > 14)
   
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
      
   local mx = cell.r*8
   local my = cell.m*8
   local sx = (x-1)*64
   local sy = (y-1)*64
   
   --cull
   if sx > g_camx + 128
     then
    return
   end
   
   if sx < g_camx
     and sx + 64 < g_camx
     then
    return
   end
   if sy > g_camy + 128
     then
    return
   end
   
   if sy < g_camy
     and sy + 64 < g_camy
     then
    return
   end

   local isactive = (
     t.cx == x - 1
     and t.cy == y - 1)
   
   
   if not isactive
     or t.state == 0 then
     
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
          sx+28, sy+57)
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
         sx+57, sy+28)
      end
     end
      
      
    end
    
    if isactive then
     
     if t.state == 0 then
      pal(7, 6)
      pal(13, 6) 
     
      for xy in all({
        {-1,-1},
        {1,1},
        {-1,1},
        {1,-1}}) do
       map(mx,my,sx+xy[1],
         sy+xy[2],8,8)
      end
     
      t.basepal(flipcol)
      map(mx,my,sx,sy,8,8)
     else
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
      
      local lc = 2
      
      
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
  end,


  basepal=function(flipcol)
   if flipcol then
    pal(7,8)
    pal(13,14)
   else
    pal(7,14)
    pal(13,8)
   end
  end
  
  
 }
 
 local b = {}
 r.b = b
 
 for y = 1, r.sy do
  local row = {}
  add(b, row)
  for x = 1, r.sx do
   local cell = {}
   add(row, cell)
   cell.m = flr(rnd(g_maxcells))
   cell.r = flr(rnd(4))
  end
 end
 
 return r
end

function cellhasdr(cell, dr)
 if not cell then
  return false
 end
 
 local mx = cell.r*8
 local my = cell.m*8
 
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
 if (x >= #b*8) return nil
 if (y < 0) return nil
 if (y >= #b*8) return nil
 
 
 local cx = flr(x/8)
 local cy = flr(y/8)
 local ix = x % 8
 local iy = y % 8
 
 local row = b[cy+1]
 if (not row) return nil
 
 local tile = row[cx+1]
 if (not tile) return nil
 
 
 return mget(
   tile.r*8 + ix,
   tile.m*8 + iy), ix, iy, cx, cy
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


function make_wave()
 return {
  x = 0,
  y = 0,
  update=function(t,s)
  
  
  
  end,
  draw=function(t)
   local b = 0x6000
   
   local a = (sin(g_tick / 50)
       + 1) * 3
   --local a = 1.5
   local yphase = 20-- (sin(g_tick/200)+1) * 30
   
   for y = 0, 127 do
    local o = flr(sin(
        y/yphase + g_tick/10) * a)
    
    local len = 64
    local src = b
    local dst = b + o
    
    
    memcpy(b, b + o, 64)
    b = b + 64
   
   end
  
  end
 }
end


function make_game(level)
 local t = {
  x=0,y=0,
  marks={},
  update=function(t,s)
   local fx = t.flag.mzx
   local fy = t.flag.mzy
   
   for mark in all(t.marks) do
    if mark.mzx == fx
      and mark.mzy == fy then
      del(t.marks,mark)
      del(g_objs,mark)
      del(g_rotsignalobjs,mark)
    end 
   end
   
   if #t.marks == 0 then
   
    add(g_objs,
      make_trans(function()
         make_game(3,3)
    				end))
    
    
   end
   
  end,
  draw=function(t)
  end
 }
 
 g_objs = {t}
 g_rotsignalobjs = {}
 
 
 local maze = make_maze(2,2)
 t.maze = maze
 add(g_objs, maze)
 
 local player = make_player(
   maze)
 add(g_rotsignalobjs, player)
 t.player = player
 add(g_objs, player)
 
 for i = 1,5 do
  local mark = make_mark(maze)
  placechar(mark,flr(rnd(maze.sx)),
   flr(rnd(maze.sy)),16)
  add(g_objs, mark)
  add(g_rotsignalobjs, mark)
  add(t.marks, mark)
 end
 
 local flag = make_flag(maze)
 placechar(flag,flr(rnd(maze.sx)),
   flr(rnd(maze.sy)),32)
 add(g_rotsignalobjs, flag)
 add(g_objs, flag)
 t.flag = flag
 
 
 return t
end
__gfx__
00000000006000000900009009900000000990000000999000000000000000000000000000000000090000900990000000099000000099900000000011000000
00000000006600009990099909900099009990009900999000000000000000000000000000000000999009990990009900999000990099900000000176100000
00000000006660000999999009999999009999009999990000000000000000000000000000000000099999900999999900999900999999000000001766510000
00000000006666000097190000971990009719990997190000071000000770000007700000017000009cc90000999990009cc999099999000000001766510000
00000000006665000097790009977900999779990097799000077000000710000001700000077000009cc90009999900999cc99900999990000011bb75100000
00000000006650000999999099999900999999000099999900000000000000000000000000000000099999909999990099999900009999990011bb3365100000
000000000065000099900999999099900009990000999099000000000000000000000000000000009990099999909990000999000099909901bb333365100000
00000000005000000900009000000900000099000999000000000000000000000000000000000000090000900000090000009900099900000011333365100000
0000000000000000000000000000000000081000000110000001800000011000000aa000000aa000000aa000000aa00000000000000000000000113365100000
000000000000000000000000000000000001100000081000000110000001800000aaaa0000aaaa0000aaaa0000aaaa0000000000000000000000001165100000
00000000000000000000000000000000000180000001100000081000000110000a1a1a900aa1a1900aa1a1900a1a1a9000000000000000000000000165100000
81118111181118111181118111181118000110000001800000011000000810000a1a1a900aa1a1900aa1a1900a1a1a9000000000000000000000000165100000
11811181111811188111811118111811000810000001100000018000000110000aaaaa900aaaaa900aaaaa900aaaaa9000000000000000000000001766510000
00000000000000000000000000000000000110000008100000011000000180000aaaa9900aaaa9900aaaa9900aaaa99000000000000000000000001111110000
000000000000000000000000000000000001800000011000000810000001100000aa940000aa940000aa940000aa940000000000000000000000000000000000
00000000000000000000000000000000000110000001800000011000000810000004400000044000000440000004400000000000000000000000000000000000
00077000000000000007700000000000000770000007700000077000000770000000000000000000000770000007700000077000000000000000000000000000
0007d000000000000007d000000000000007d0000007d0000007d0000007d00000000000000000000007d0000007d0000007d000000000000000000000000000
000dd00000000000000dd00000000000000dd000000dd000000dd000000dd0000000000000000000000dd000000dd000000dd000000000000000000000000000
000d700077dd77dd000d700077dd77dd77dd77dd77dd77dd77dd77dd77dd77dd000d77dd77dd700077dd7000000d77dd000d7000000077dd0000000077dd0000
000770007dd77dd7000770007dd77dd77dd77dd77dd77dd77dd77dd77dd77dd700077dd77dd770007dd7700000077dd70000000000007dd7000770007dd70000
0007d000000000000007d000000000000007d0000007d0000007d0000007d0000007d0000007d000000000000000000000000000000000000007d00000000000
000dd00000000000000dd00000000000000dd000000dd000000dd000000dd000000dd000000dd00000000000000000000000000000000000000dd00000000000
000d700000000000000d700000000000000d7000000d7000000d7000000d7000000d70000007700000000000000000000000000000000000000d700000000000
00000000000770000007700000077000000775660000000066577000666666660000000000000000665770000007756666666666666666660007756666577000
000000000007d0000007d0000007d0000007d566000000006657d0006666666600000000000000006657d0000007d56666666666666666660007d5666657d000
00000000000dd000000dd000000dd000000dd56600000000665dd000555555550000000000000000555dd000000dd5556655555555555566000dd566665dd000
77dd77dd77dd700077dd77dd000d77dd000d756677dd77dd665d700077dd77dd000d77dd77dd700077dd7000000d77dd665d77dd77dd756677dd7566665d77dd
7dd77dd77dd770007dd77dd700077dd7000775667dd77dd7665770007dd77dd700077dd77dd770007dd7700000077dd766577dd77dd775667dd7756666577dd7
0007d0000007d000000000000007d0000007d566555555556657d000000000000007d5555557d00000000000000000006657d0000007d5665555556666555555
000dd000000dd00000000000000dd000000dd56666666666665dd00000000000000dd566665dd0000000000000000000665dd000000dd5666666666666666666
000d7000000d700000000000000d7000000d756666666666665d700000000000000d7566665770000000000000000000665d7000000775666666666666666666
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
82920022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22220022b23232920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222200b2321292220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a2b21212129222b20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92821212922222820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22020000022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22b21212a2b2a2220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2323232323232a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000050a050a0f0f0f0f060c0903010204080e0d0b07050a050a060c0903060c090300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2821212a2b212129000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2228212928212922000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222002222002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222b212a2200222b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222821212a002228000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222000000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222b212121212a22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2121292821212a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2823232a2b290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22282121292b2129000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222b23232a282922000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22282323292b2a2b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222200002b232928000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222b232329002022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2121292b232a22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000222823232a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212a22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212121232a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0028290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222b2900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002b212a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002020282329000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0028212a222b2922000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002228232a002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212a220000282a2b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212a28232a2821000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2823232a28232a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2228232922282329000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2a0022222b212a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


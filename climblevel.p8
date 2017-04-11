pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

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

function num2spr(x,y,w,n)
 local mask = 15
 
 for i = 0, w-1 do
   sset(x,y,
     shr(band(n,mask),i*4))
   x,y = nextsprxy(x,y)
   mask = shl(mask, 4)
 end
 
 return x,y
end


function boardtospr(board,
 sprid)

 local x,y = getsprxy(sprid)
 local sx,sy = x,y
 
 local addr = y*64 + x/2
 
 --blank whole row for now
 memset(addr, 0, 64*8)
 
 --set number of screens
 --by finding the highest
 --item and adding 1 (xxx)
 local numscreens = 1
 for i in all(board.items) do
  numscreens = max(numscreens,
    i.yscr+1)
 end
 
 x, y = num2spr(x,y,2,
   numscreens) 
 
 -- (itemdef)
 -- any item type which needs to
 -- write custom fields to the
 -- serialized level should
 -- implement a function here
 -- which writes to sprite data
 -- and returns the advanced
 -- x,y sprite pixel position
 local writefncs = {
  [it_horzblock]=function(
    item,x,y)
   return num2spr(x,y,1,
     item.width-1)  
  end,
  
  [it_vertblock]=function(
    item,x,y)
   return num2spr(x,y,1,
     item.height-1)  
  end,
  
  [it_platform]=function(
    item,x,y)
   return num2spr(x,y,1,
     item.width-1)  
  end,

  [it_spawn_loc]=function(item, x, y)
   return num2spr(x, y, 1,
     item.width-1)
  end,

  [it_goal]=function(item, x, y)
   x,y = num2spr(x, y, 1,
     item.width-1)
   x,y = num2spr(x, y, 1,
     item.height-1)
   return x,y
  end,
  
  [it_zipup]=function(item, x, y)
   x,y = num2spr(x, y, 1,
     item.width-1)
   x,y = num2spr(x, y, 1,
     item.height-1)
   return x,y
  end,
  
  [it_zipdown]=function(item, x, y)
   x,y = num2spr(x, y, 1,
     item.width-1)
   x,y = num2spr(x, y, 1,
     item.height-1)
   return x,y
  end,
  
  [it_sprobj]=function(item, x, y)
   x,y = num2spr(x, y, 1,
     item.objtype)
   return x,y
  end,
 }
 
 local function
   writeitemhead(item)
  x,y = num2spr(x,y,1,
    item.itemtype)
  x,y = num2spr(x,y,1,
    item.xpos)
  x,y = num2spr(x,y,2,
    item.yscr)
  x,y = num2spr(x,y,1,
    item.ypos)
 end
 
 local sprobjs = {}
 
 for i = 1, #board.items do
  local item = board.items[i]
  
  if item.itemtype ==
    it_sprobj then
   
   add(sprobjs, item)
   
  else
   writeitemhead(item)
  
   local fnc = writefncs[
     item.itemtype]
  
   if fnc then
    x,y = fnc(item, x, y)
   end
  end
  
 end
 
 function qsort(lo, hi)
  if lo < hi then
   local p = partition(lo, hi)
   qsort(lo, p - 1)
   qsort(p + 1, hi)
  end
 end
 
 function swap(i, j)
  local tmp = sprobjs[i]
  sprobjs[i] = sprobjs[j]
  sprobjs[j] = tmp
 end
 
 function gety(item)
  return item.yscr*16+item.ypos
 end
 
 function partition(lo, hi)
  local pivot = sprobjs[hi]
  local i = lo - 1
  for j = lo, hi - 1 do
   if gety(sprobjs[j]) <
     gety(pivot) then
    i += 1
    swap(i, j)
   end
  end
  swap(i+1, hi)
  return i + 1
 end
 
 if #sprobjs > 1 then
  qsort(1, #sprobjs)
 end
 
 for i = 1, #sprobjs do
  local item = sprobjs[i]
  
  writeitemhead(item)
  
  local fnc = writefncs[
    item.itemtype]
  
  if fnc then
   x,y = fnc(item, x, y)
  end
 
 end
 
 --todo figure out width
 --for now, do one row
 size = 64*8
 cstore(addr, addr, size)


end

function table2map(t,
  scrollpos)
 
 if #t == 0 then
  return
 end
 --todo, scrollpos
 for y = 1, 16 do
  for x = 1, 16 do
   mset(x-1, 32-y, t[y][x])
  end
 end


end

function stdinit()
 g_tick=0    --time
 g_ct=0      --controllers
 g_ctl=0     --last controllers
 g_cs = {}   --camera stack 
 g_objs = {} --objects
 g_camx = 0
 g_camy = 0
 
 g_ms=0      --mouseb
 g_msl=0     --last mouseb
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


function updateobjs(objs)
 foreach(objs, function(t)
  if t.update then
   t:update(objs)
  end
 end)
end

function drawobjs(objs)
 foreach(objs, function(t)
  if t.draw then
   pushc(-t.x, -t.y)
   t:draw(objs)
   popc()
  end
 end)
end

function stdupdate()
 g_tick = max(0,g_tick+1)
 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()
 
 --current/last mouse button
 g_msl = g_ms
 g_ms = stat(34)
 --mbtn=stat(34)
 
 
 updateobjs(g_objs)
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

function mbtn(i) 
 return band(
  g_ms, shl(1, i)) > 0
end

function mbtnn(i) 
 return mbtn(i) and
   band(g_msl, shl(1, i)) == 0
end



function stddraw()
 pushc(g_camx, g_camy)
 drawobjs(g_objs)
 popc()
end

-------------------------------
-- base class of editor items
it_base = {
 
 -- utility for converting
 -- from yscr+ypos into a
 -- single y value
 ytomappos=function(t)
  return t.yscr*16+t.ypos
 end,
 
 -- utility for converting
 -- to yscr,ypos from a single
 -- y value
 yfrommappos=function(t, y)
  if y < 0 then
   return 0, 0
  end
  
  return flr(y/16), y % 16
 end,
 
 -- base class first click
 -- stores the mouse position
 -- and x,y pos at the start
 -- the drag for comparison
 clickevent=function(t, mx, my)
  --sfx(0)
  
  t._s_mx = mx
  t._s_my = my
  
  t._s_xpos = t.xpos
  t._s_ypos = t:ytomappos()
  
 end,
 
 -- called while the mouse is
 -- held down on an object
 -- (including in the same
 -- cycle as first clicked)
 -- base behavior implements
 -- movement dragging
 dragevent=function(t, mx, my)
  
  local ox =
    flr((mx - t._s_mx) /8)
  
  t.xpos = min(15,
    max(0, t._s_xpos + ox))
  
  local oy =
    flr((my - t._s_my) /8)
  
  local scr, pos =
    t:yfrommappos(
      t._s_ypos + oy)
  
  t.yscr = max(0, scr)
  t.ypos = max(0, pos)
  
 end,
 
}

it_base_meta = {
  __index=it_base,
}


-- (itemdef)
-- item-specific methods
-- draw and bound are required
-- for interaction
-- update is currently only
-- used for items which track
-- button presses on their own
-- 
-- y increases upward
-- (opposite of screen coords)
--
-- mouse coordinates are in 
-- item-local space

it_horzblock_meta = {
 draw=function(t)
  for j = 1, t.width do
	  spr(m_brick, (j-1)*8, -8)
	 end
	 
	 if not t.selected then
	  return
	 end
	 if t.width > 1 then
	  print('‹', t.width*8+2, -9,
	    5)
	 end
	 if t.width < 16 then
	  print('‘', t.width*8+2, -3,
	    5)
	 end
	 
	 
 end,
 
 -- expressed in item-local
 -- coordinates
 bound=function(t)
  return {0, -8, 8*t.width, 0}
 end,
 
 update=function(t)
  if btnp(0) then
   t.width = max(1, t.width-1)
  end
  
  if btnp(1) then
   t.width = min(16, t.width+1)
  end
 
 end,
}

it_vertblock_meta = {
 draw=function(t)
  for j = 1, t.height do
   spr(m_brick,0, (j*1)*-8)
  end
  
  if not t.selected then
	  return
	 end
	 if t.height > 1 then
	  print('ƒ', -3,
	    t.height*-8-6, 5)
	 end
	 if t.height < 16 then
	  print('”', 5,
	    t.height*-8-6, 5)
	 end
	 
	 
 end,
 
 bound=function(t)
  return {0, -8*t.height, 8, 0}
 end,
 
 update=function(t)
  if btnp(3) then
   t.height = max(1,
     t.height-1)
  end
  
  if btnp(2) then
   t.height = min(16,
     t.height+1)
  end
 
 end,
 
}

it_spawn_loc_meta = {
 draw=function(t)
  spr(m_spawn, -8, -8)
 end,
 bound=function(t)
  return {-8, -8, 0, 0}
 end,
 update=function(t)
 end
}

it_goal_meta = {
 draw=function(t)
  
  for j = 1, t.height do
   for k = 1, t.width do
    spr(m_goal, (k-1)*8,
      (j*1)*-8)
   end
   
  end
  
  if not t.selected then
	  return
	 end
	 if t.height > 1 then
	  print('ƒ', -3,
	    t.height*-8-6, 5)
	 end
	 if t.height < 16 then
	  print('”', 5,
	    t.height*-8-6, 5)
	 end
  
  if t.width > 1 then
	  print('‹', t.width*8+2, -9,
	    5)
	 end
	 if t.width < 16 then
	  print('‘', t.width*8+2, -3,
	    5)
	 end
  
  
 end,
 bound=function(t)
  return {0, -8*t.height,
    8*t.width, 0}
  
 end,
 update=function(t)
  
  -- xxx: for now just call
  -- that these directly as
  -- all they do are the 
  -- button presses for sizing
  it_vertblock_meta.update(t)
  it_horzblock_meta.update(t)
  
 
  
 end
}

it_zipup_meta = {
 draw=function(t)
  
  for j = 1, t.height do
   for k = 1, t.width do
    spr(m_zipup, (k-1)*8,
      (j*1)*-8)
   end
   
  end
  
  if not t.selected then
	  return
	 end
	 if t.height > 1 then
	  print('ƒ', -3,
	    t.height*-8-6, 5)
	 end
	 if t.height < 16 then
	  print('”', 5,
	    t.height*-8-6, 5)
	 end
  
  if t.width > 1 then
	  print('‹', t.width*8+2, -9,
	    5)
	 end
	 if t.width < 16 then
	  print('‘', t.width*8+2, -3,
	    5)
	 end
  
  
 end,
 bound=function(t)
  return {0, -8*t.height,
    8*t.width, 0}
  
 end,
 update=function(t)
  
  -- xxx: for now just call
  -- that these directly as
  -- all they do are the 
  -- button presses for sizing
  it_vertblock_meta.update(t)
  it_horzblock_meta.update(t)
  
 
  
 end
}

it_zipdown_meta = {
 draw=function(t)
  
  for j = 1, t.height do
   for k = 1, t.width do
    spr(m_zipdown, (k-1)*8,
      (j*1)*-8)
   end
   
  end
  
  if not t.selected then
	  return
	 end
	 if t.height > 1 then
	  print('ƒ', -3,
	    t.height*-8-6, 5)
	 end
	 if t.height < 16 then
	  print('”', 5,
	    t.height*-8-6, 5)
	 end
  
  if t.width > 1 then
	  print('‹', t.width*8+2, -9,
	    5)
	 end
	 if t.width < 16 then
	  print('‘', t.width*8+2, -3,
	    5)
	 end
  
  
 end,
 bound=function(t)
  return {0, -8*t.height,
    8*t.width, 0}
  
 end,
 update=function(t)
  
  -- xxx: for now just call
  -- that these directly as
  -- all they do are the 
  -- button presses for sizing
  it_vertblock_meta.update(t)
  it_horzblock_meta.update(t)
  
 
  
 end
}

it_platform_meta = {
 draw=function(t)
  for j = 1, t.width do
   spr(m_platform, (j-1)*8, -8)
  end

  if not t.selected then
   return
  end
  if t.width > 1 then
   print('‹', t.width*8+2, -9,
   5)
  end
  if t.width < 16 then
   print('‘', t.width*8+2, -3,
   5)
  end
 end,
 bound=function(t)
  return {0, -8, 8*t.width, -4}
 end,
 update=it_horzblock_meta.update
}

it_sprobj_meta = {
	
	draw=function(t)
	 
	 local b = t:bound()
	 
	 rect(b[1]-1, b[2]-1,
	   b[3]+1, b[4]+1, 14)
	 print(t.objtype, b[1]+1,
	   b[2]+2, 14)
	 
	 spr(112 + t.objtype,
	   b[1]+1, b[2]) 
	 if not t.selected then
	  return
	 end
	 print('‹', b[1] - 9,
	   b[2] + 2, 6)
	 print('‘', b[1] + 11,
	   b[2] + 2, 6)
	 
	
	end,
	
	bound=function(t)
  return {0, -8, 8, 0}
 end, 

 update=function(t)
  if btnp(0) then
   t.objtype =
     (t.objtype - 1) % 16
  end
  
  if btnp(1) then
   t.objtype =
     (t.objtype + 1) % 16
  end
  
  
 end,

}

-- (itemdef)
-- registry of item-specific
-- method metatables
-- editor items should have one
-- if they're intended to be
-- visible and interactive

it_metas = {
  [it_horzblock]=
    {__index=it_horzblock_meta},
  [it_vertblock]=
    {__index=it_vertblock_meta},
  [it_platform]=
    {__index=it_platform_meta},
  [it_spawn_loc]=
    {__index=it_spawn_loc_meta},
  [it_goal]=
    {__index=it_goal_meta},    
  [it_sprobj]=
    {__index=it_sprobj_meta},
  
  [it_zipup]=
    {__index=it_zipup_meta},    
  [it_zipdown]=
    {__index=it_zipdown_meta},
    
  
}

foreach(it_metas, function(t)
 setmetatable(t.__index, it_base_meta)
end)

-------------------------------

mi_scrollup = 0
mi_scrolldown = 1


function make_board_obj(board)
	
	for i = 1, #board.items do
	 local item = board.items[i]
	 
	 setmetatable(item,
	   it_metas[item.itemtype])
	 
	end

 -- (itemdef)
 -- menu callbacks in this form:
 -- 1) title
 -- 2) requiresselection
 -- 3) action	
 menuactions = {
  {
   'add goal', 
   false,
   function(t, self) 
    local y = flr(t.scrollpos/-8) + 8
    local item = {
     itemtype = it_goal,
     xpos=5,
     ypos=y%16,
     yscr=flr(y/16),
     width=2,
     height=1,
     selected=true
    }
    setmetatable(item, it_metas[it_goal])
     
    for i in all(sel) do
     i.selected = nil
    end
     
    add(t.board.items, item)
   end
  },
  {
   'add spawn loc',
   false,
   function(t, self) 
    local y = flr(t.scrollpos/-8) + 8
    local item = {
     itemtype = it_spawn_loc,
     xpos=5,
     ypos=y%16,
     yscr=flr(y/16),
     width=1,
     selected=true
    }
    setmetatable(item, it_metas[it_spawn_loc])
     
    for i in all(sel) do
     i.selected = nil
    end
     
    add(t.board.items, item)
   end
  },
  {'add horz brick', false,
    function(t, sel)
     local y = flr(
       t.scrollpos/-8) + 8
     
     local item = {
      itemtype=it_horzblock,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      width=3,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_horzblock])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
    end},
  {'add vert brick', false,
    function(t, sel)
     local y = flr(
       t.scrollpos/-8) + 2
     
     local item = {
      itemtype=it_vertblock,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      height=3,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_vertblock])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
    end},
  
  {'add platform', false,
    function(t, sel)
    
     local y = flr(
       t.scrollpos/-8) + 8
     
     local item = {
      itemtype=it_platform,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      width=3,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_platform])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
     
    
    end},
  {'add sprite object', false,
    function(t, sel)
    
     local y = flr(
       t.scrollpos/-8) + 8
     
     local item = {
      itemtype=it_sprobj,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      objtype=0,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_sprobj])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
     
    
    end},
  {'add zipper up', false,
    function(t, sel)
    
     local y = flr(
       t.scrollpos/-8) + 8
     
     local item = {
      itemtype=it_zipup,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      width=3,
      height=3,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_zipup])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
     
    
    end},
  {'add zipper down', false,
    function(t, sel)
    
     local y = flr(
       t.scrollpos/-8) + 8
     
     local item = {
      itemtype=it_zipdown,
      xpos=5,
      ypos=y%16,
      yscr=flr(y/16),
      width=3,
      height=3,
      selected=true,
     }
     setmetatable(item,
       it_metas[it_zipdown])
     
     for i in all(sel) do
      i.selected = nil
     end
     
     add(t.board.items, item)
     
    
    end},
  {'delete selected', true,
    function(t, sel)
    
     for i = 1, #sel do
      del(t.board.items,
        sel[i])
     end
    
    end},
  
  {'duplicate selected', true,
    function(t, sel)
     
     for i in all(sel) do
      setmetatable(i, nil)
      
      local dupi = {}
      
      for k, v in pairs(i) do
       dupi[k] = v
      end
      
      setmetatable(i,
        it_metas[i.itemtype])
      i.selected = nil
      setmetatable(dupi,
        it_metas[i.itemtype])
      
      add(t.board.items, dupi)
     end
     
    end},
    
  {'save', false,
    function(t)
     boardtospr(t.board,
       16)

    end},  
  
 }
	
	
	
	return {
  board=board,	
	 scrollpos=0,
	 
	 itempos=function(t, item)
	  return item.xpos*8,
	    item.yscr*-128 -
	       item.ypos*8
	 end,
	 
	 itemsmpos=function(t,mx,my)
	  local imx = mx
		 local imy = 128 - my
		 imy -= t.scrollpos
	  
	  return imx, imy
	 end,
	 
	 clicktestitems=function
	   (t, mx, my)
	  
	  local newlyselected = false
	  local selitem = nil
   for i = #t.board.items, 1,
     -1 do
    
	   local item =
	     t.board.items[i]
   
    local ix, iy =
      t:itempos(item)
    
    local b = item:bound()
    
    local lmx = mx-ix
    local lmy = -(my+iy)
    
    --item.lmy = lmy
    if lmx >= b[1]
      and lmy >= b[2]
      and lmx < b[3]
      and lmy < b[4]
      then
     selitem = item
     
     if not item.selected then
      newlyselected = true
     end
     item:clickevent(mx, my)
     t.clickitem = item
     
     break
    end
    
   end
   
   
   
   for i = 1, #t.board.items
     do
    local item =
      t.board.items[i]
    
    if item == selitem then
     item.selected = true
    else
     item.selected = nil
    end
   end
   
   return newlyselected
  end,
	 
	 getselected=function(t)
	  local r = {}
	  
	  for i = 1, #t.board.items do
	   local item =
	     t.board.items[i]
	   
	   if item.selected then
	    add(r, item)
	   end
	  end
	  
	  return r
	 end,
	 
	 updatemenu=function(t,
	   mx, my)
	   
	   
	   
	   
	   if mbtnn(0) then
	    local i =
	      flr((my )/12)
	   
	    if (my ) % 12 < 8 then
	     local a = menuactions[i+1]
	      
	     if a then
	     
	      local sel =
	        t:getselected()
	        
	      if a[2] and
	        #sel == 0 then
	       return
	      end
	      sfx(0)
	      a[3](t, sel)
	      
	      
	     end
	    
	    end
	   
	   
	   end
	   
	   
	   --local y = i*12+10
	   --rectfill(8, y, 96, y+8, 0)
	   
	   
	 end,
	 
	 --editor update
	 update=function(t,s)
	  
	  local mx = stat(32)
	  local my = stat(33)

   if btn(4) then
    t:updatemenu(mx, my)
   
    return
   end

	  if mbtnn(0) then
	  
	   local newlyselected = false
	   t.clickitem = nil
	   
	   
	   
	   --t.cmx = mx
	   --t.cmy = my
	   
	   if mx >= 120 then
	    if my < 8 then
	     t.clickitem = mi_scrollup
	    elseif my >= 120 then
	     t.clickitem =
	       mi_scrolldown
	    end
	   
	   end
	     
	   
	   if not t.clickitem then
		   local imx, imy =
		     t:itemsmpos(mx, my)
		   newlyselected =
		     t:clicktestitems(imx,imy)
	    
	    if newlyselected then
	     del(t.board.items,
	       t.clickitem)
	     
	     add(t.board.items,
	       t.clickitem)
	     
	    
	    end
	   
	   end
	   
	   
	  end
	  
	  local ci = t.clickitem
	  
	  if ci then
	   
	   if mbtn(0) then
	    if ci == mi_scrollup then
	     t.scrollpos -= 8 
	    elseif ci ==
	      mi_scrolldown then
	     t.scrollpos = min(0,
	       t.scrollpos + 8)
	    
	    else
	     if type(ci) == 'table'
	       and ci.dragevent then
	       
	      --todo send mouse pos to
	      --item 
	      local imx, imy =
		       t:itemsmpos(mx, my)
		     
		     ci:dragevent(imx, imy)
		     
	     end
	    end
	    
	   else
	    
	    t.clickitem = nil
	    
	    
    
	   end
	   
	  end
	  
	  
	  for i in all(
	    t.board.items) do
	   
	   if i.selected and i.update
	     then
	    i:update(t)
	   end
	  end
	  
	  --[[
	  if not mbtn(0) then
	   t.cmx = nil
	   t.cmy = nil
   end
	  --]]
	  
	  	  
	 end,
	 
	 drawui=function(t)
	  
	  if t.clickitem ==
	    mi_scrollup then
	   pal(5, 6)
	  end
	  spr(74, 120, 0)
	  pal()
	  
	  if t.clickitem ==
	    mi_scrolldown then
	   pal(5, 6)
	  end
	  spr(74, 120, 120, 1, 1,
	    false, true)
	  pal()
	 end,
	 
	 drawmenu=function(t)
	  
	  local selected = false
	  for i = 1, #t.board.items do
	   if t.board.items[i].selected
	     then
	    selected = true
	    break
	   end
	  end
	  
	  for i = 1, #menuactions do
	   
	   local a = menuactions[i]
	   
	   local c = 7
	   
	   if a[2]
	     and not selected then
	    c = 5
	   end
	   
	   local y = (i-1)*12
	   rectfill(8, y, 96, y+8, 0)
	   rect(8, y, 96, y+8, 5)
	   print(a[1], 10, y+2, c)
	  
	  end
	  
	  
	 end,
	 
	 draw=function(t)
	  
	 	pushc(0, t.scrollpos - 128)
	  
	  line(0, -1, 127, -1, 1)
	  
	  
	  for i = 1, #t.board.items do
	   local item =
	     t.board.items[i]
	  
	   
	   local ix, iy =
	     t:itempos(item)
	   
	   pushc(-ix, -iy)
	   
	   item:draw()
	   
	   --print(ix .. ','.. iy, 0,0,7)
	   if item.selected then
	    local b = item:bound()
	   
	    rect(b[1], b[2], b[3], b[4],
	      (g_tick % 10)/5 + 6)
	   
	   
	   end
	   
	   
	   popc()
	   
	  end	
	 
	  popc()
	  
	  t:drawui()
	  
	  if btn(4) then
	   t:drawmenu()
	  end
	  
	  
	 end,
	 x=0,y=0
 }

end



-------------------------------

poke(0x5f2d, 1)

function _init()
 stdinit()
 
 local b = load_board(16)
 
 
 menuitem(1, 'save board',
   function()
    boardtospr(b, 16)
   end)
 
 
 local t = board2table(b)
 table2map(t)
 --boardtospr(b, 32)
 
 add(g_objs, make_board_obj(b))
 
 
 
 
end

function _update()
  stdupdate()
end

function _draw()
 cls()
 stddraw()
 
 
 spr(73, stat(32), stat(33))
 --print( stat(32) .. ',' ..
 --  stat(33), stat(32), stat(33)-8)
 
 
 --[[
 --todo, track scrolling
 for i = 0, 15 do
  pal(i, 1)
 end
 map(0, 16, 0, 0, 16, 16)
 pal()
 --]]
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
72001358000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60083351000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00106c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000011111111000000000000000000000000111111114444444477000000000000000000000000000000000000000000000000000000
0000000000000000000000001333333300000000000000000000000013333333aaa4aaaa75700000000500000000000000000000000000000000000000000000
00000000000000000000000013b333b300000000000000000000000013b333b39994a99975570000005150000000000000000000000000000000000000000000
0000000000000000000000001bbb3bbb0000000000000000000000001bbb3bbb9994a99975557000051115000000000000000000000000000000000000000000
00000000000000000000000011111111000000000000000000000000111111114444444475555700511111500000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000aaaaaaa475757000555555500000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000a999999477075700000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000a999999400007000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003333330011111100000000000090000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003bbbb3501cccc1500000000009a9000220002200000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003b3333501c111150000000009aaa900dd202dd00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003bbbb3501c1cc15000000009aaaaa90ddd2ddd00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003333b3501c11c1500000000aaa9aaa02ddddd200000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003bbbb3501cccc1500000000aa909aa002ddd2000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003333335011111150000000099000990002d20000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000555555005555550000000000000000000200000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b35b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b7bbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbb330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbb3330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100002b0502c0502d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344


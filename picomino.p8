pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-- what we call the save slot for this cart
cartdata("picomino_progress_save_state")

-- in case you need to clear the save data
function clear_data()
 for i=0,63 do
  dset(i, 0)
 end
 for i = 1, #progress do
  progress[i][1] = 0
 end
 starcount = 0
 
end

function _read_bitflag_array()
 -- read a flat list of all the slots
 local bitflags = {}
 for i=0,31 do
  add(bitflags, dget(i))
 end

 -- convert the slots into per-sublevel booleans
 local completed = {}
 local index = 0
 local slot = 1
 local current = bitflags[slot]
 for i=1, 512 do
  add(completed, band(shl(1, index), current) != 0)
  index += 1
  if index == 16 then
   index = 0
   slot += 1 
   current = bitflags[slot]
  end
 end

 return completed
end

function save_progress(progress)
 local slot = 0
 local current = 0
 local saved_in_slot = 0

 for level in all(progress) do
  for i=1, level[2] do
   if i <= level[1] then
    current = bor(current, shl(1, saved_in_slot))
   end
   saved_in_slot += 1
   if saved_in_slot > 15 then
    dset(slot, current)
    current = 0
    saved_in_slot = 0
    slot += 1
   end
  end
 end
end

function _init()
 stdinit()
 
 drawbg = false
 drawhead = false
 
 maxlevel = 113
 workspr1 = 5
 workspr2 = 7
 prevspr = 196
 nextspr = 228

 per_sublevel_completions = _read_bitflag_array()
 
 progress = {}
 startotal = 0
 starcount = 0
 for i = 1,maxlevel do
  local s,p = get_level_data(i)
  local n = (#p - s + 1)

  local completed = 0
  for i=1, n do
   if per_sublevel_completions[startotal + i] then
    completed += 1
    starcount += 1
   end
  end

  -- per level progress
  --             sublevels completed, sublevels total, bitoffset
  progress[i] = {completed,n,startotal}
  startotal += n
 end
  
 --add(g_objs,
 --  make_level_debug())
 
 --todo, transition this on
 --add(g_objs, make_main_menu(1)) 


 add(g_objs, make_trans(
    function()
     drawbg=true
     drawhead=true
     
     local l = min(
       max(dget(63),1),
         maxlevel)
     
     add(g_objs,
       make_main_menu(l, 22))
     
     --add(g_objs,
     --  make_level_debug())
   end))


end

function _update()
  stdupdate()
end

function _draw()
 cls()
 
 
 if drawbg then
 
 --pal(1, 0)
  for i = 2, 15 do
   pal(i, 0)
  end
 
  --local cx = -(g_tick % 80)/2 + 40
  local cx = -(g_tick % 40) + 40
  pushc(cx, g_tick % 40)
   for y = 0, 5 do
    for x = 0, 5 do
     map(16, 0, x*40,
      y*40, 5,5)
    end
   end
  popc()
  pal()
 
  --draw_wave(3, 128, g_tick/50)
 end
 
 if drawhead then
  rectfill(0, 0, 127, 8, 1)
  rectfill(0, 0, 127, 3, 13)
  local c = 0
  if (not drawbg) c = 5
  line(0, 9, 127, 9, c)
 
  if celebrate then
   col_map = {{14 ,15}, {12, 6}, {9, 10}, {3, 11}}
   offset = (flr(elapsed(celebrate)/3)) % 4 + 1
   for i=1, 4 do
    local first = col_map[i]
    local next = col_map[(offset+i)%4+1]
    pal(first[1], next[1])
    pal(first[2], next[2])
   end
  end
  spr(16, 1, 1, 9, 1)
  if celebrate then
   pal()
  end
  local sc = starcount
    .. '/'
    .. startotal
 
  print(sc, 125 - #sc*5, 2, 6)
  pal(5, 0)
  spr(34 + (g_tick%24)/4, 120,
   0)
  pal()
 end
 stddraw()
 
 --[[
 if override_ct then
  if btnd(0) then
   print('‹', 0, 20, 7)
  end
  if btnd(1) then
   print('‘', 10, 20, 7)
  end
  if btnd(2) then
   print('”', 20, 20, 7)
  end
  if btnd(3) then
   print('ƒ', 30, 20, 7)
  end
  if btnd(4) then
   print('Ž', 40, 20, 7)
  end
  if btnd(5) then
   print('—', 40, 20, 7)
  end
  
  
  
  
 end
 --]]
 
end

function lerp(from, to, amt)
 return (from + (to-from)*amt)
end

function smootherstep(x)
 -- assumes x in [0, 1]
 return x*x*x*(x*(x*6 - 15) + 10);
end

function make_big_plus_one()
 local x, y = getsprxy(98)
 local segs, rects, col = get_spr_outline(x, y, 16, 16)
 celebrate = g_tick
 add(
  g_objs,
  {
   x=58,
   y=58,
   start=g_tick,
   scale=1,
   update=function(t)
    local amount = elapsed(t.start)/30
    if amount < 1 then
     t.x = lerp(58, 100, smootherstep(amount))
     t.y = lerp(58, 5, smootherstep(amount))
     t.scale = -3*sin(amount/2) + 1
    else
     del(g_objs, t)
     add(g_objs, make_fill_trans(t.x, t.y, segs))
     celebrate = nil
    end
   end,
   draw=function(t)
    for thing in all({{1, 1}, {0, 11}}) do
     for i=1,#rects do
      local r = rects[i]
      
      local x1 = t.scale*(r[1] - thing[1])
      local y1 = t.scale*(r[2] - thing[1])
      local x2 = t.scale*(r[3] + thing[1])
      local y2 = t.scale*(r[4] + thing[1])
      
      rectfill(x1, y1, x2, y2, thing[2])
    end
   end
  end
  }
 )
end

function make_board(level,
  sublevel)
 drawbg = false
 
 local startcount, seq =
     get_level_data(level)
 
 -- already finished? start
 -- over
 if sublevel then
  if startcount + sublevel
    > #seq then
   sublevel = 0
  end
 end
 
 local fullscale = 7
 local stowedscale = 3
 local stowedypos =
   fullscale*6 - 1
 local stowedxwidth =
   stowedscale*4.5
 
 local blocks = {}

 for i = 1, #seq do
  local b = make_block()
  local bspr = seq[i]
  
  b.getspr = function(t)
   return bspr
  end
  b.scale = 3
  b.x = (i-1) * stowedxwidth
  b.y = fullscale * 5 + 4
  b:updategeo()
  b.state = st_stowed
  b.index = i - 1
  add(blocks, b)
  
 end
 
 blocks[1].state = st_idle
 blocks[1].scale = fullscale
 
 local t = {
  x=flr(128 -
    fullscale*startcount)/2,
  y=58,
  first=true,
  level=level,
  startcount=startcount,
  subcount=sublevel or 0,
  seq=seq,
  blocks=blocks,
  toraise={},
  activeblock=blocks[1],
  
  update=function(t,s)
   
   if t.done then
   	if btnn(5) then
     t:backtomenu(1)	
   	end
   	return
   end
   
   --[[
   if btnn(5, 1) then
    local ba =
      t:getboardarray()
    printh('hi')
    for y = 1, #ba do
     local r = ba[y]
     for x = 1, #r do
      printh(r[x])
     end
    end
   end
   --]]
   
   
   movetot(t, 'x', 'targetx', 1)
   
   updateobjs(t.objs)
   
   if #t.toraise > 0 then
   
    for i = 1, #t.toraise do
     del(t.objs, t.toraise[i])
     add(t.objs, t.toraise[i])
    end
   
    t.toraise = {}
   end
   
   t:setactiveoverlap(s)
   
   
   
  end,
  
  getboardarray=function(t)
   local w = t:getwidth()
   local ba = {}
   
   for y = 1,5 do
    local r = {}
    ba[y] = r
    for x = 1, w do
     r[x] = false
    end
   end
   
   for i = 1, w do
    
    local b = t.blocks[i]
    
    if b.state ~= st_stowed
      then
     
     local bx =
       flr(b.x/b.scale)
     local by =
       flr(b.y/b.scale)
     
     local sx, sy = getsprxy(
       b:getspr())
     
     for y = 0, 4 do
      local yy = y + by
      for x = 0, 4 do
       local xx = x + bx
       if xx >= 0
         and xx < w
         and yy >= 0
         and yy < 5
         and sget(sx+x, sy+y)
           > 0
         then
        ba[yy+1][xx+1] = true
       end
      end
     end
    end
   end
   
   return ba
  
  end,
  
  getbadnegspace=function(t)
 
   local ba = t:getboardarray()
   local w, h = #ba[1], 5
   
   local g2c, c2g = {}, {}
   local busy = {}
   
   function check(x,y, ll)
    
    if x < 0 or x >= w
      or y < 0 or y >= h then
     return nil
    end
    
    local i = y*w+x
    
    if (busy[i]) return
    
    --already there
    if c2g[i] then
     return c2g[i]
    end
    
    
    --filled
    if ba[y+1][x+1] then
     return
    end
    
    --left,right,up,down
    --already in grp?
    
    busy[i] = true
    local g = check(x-1,y)
    if (not g) g = check(x+1,y,1)
    if (not g) g = check(x,y-1,1)
    if (not g) g = check(x,y+1,1)
    busy[i] = nil
    
    if not ll then
     if g then
      add(g, {x,y})
     else
      g = {{x,y}}
      add(g2c, g)
     end
    
     c2g[i] = g
    end
    
    return g
    
   end
   
   
   for y = 1, h do
    for x = 1, w do
     check(x-1,y-1)
    end
   end
   
   local result = {}
   for i = 1, #g2c do
    if #g2c[i] % 5 ~= 0 then
     add(result, g2c[i])
    end
   end
   
   return result
  end,
  
  
  setactiveoverlap=function(t,s)
   if not t.activeblock then
    return
   end
   
   local b = t.activeblock
   local bx = flr(b.x / b.scale)
   local by = flr(b.y / b.scale)
   
   local sx, sy = getsprxy(
     b:getspr())
   
   local o = {}
   
   local w = t:getwidth()
   local ongrid = false
   
   for y = 0, 4 do
    for x = 0, 4 do
     if sget(sx+x, sy+y) > 0
       then
      
      
      if x + bx >= w
        or x + bx < 0
        or y + by > 4
        or y + by < 0
          then
        add(o, y*5+x)
        
      else
       ongrid = true
       -- todo check against
       -- stowed blocks
       
       for bi = 1, #t.blocks do
        local b2 = t.blocks[bi]
        
        if b != b2
          and b2.state ==
            st_placed then
         
         local b2x =
           flr(b2.x / b2.scale)
         
         local b2y =
           flr(b2.y / b2.scale)
         
         local s2x, s2y =
           getsprxy(
             b2:getspr())
         
         local dx =
           bx - b2x + x
         local dy =
           by - b2y + y
         
         if dx >= 0
           and dx < 5
           and dy >= 0
           and dy < 5
           and sget(s2x + dx,
             s2y + dy) > 0 then
          
          add(o, y*5+x)
         end
         
         
         -- todo, find spr
         -- offset
         
         
        end
       
       end
       
      end
     end
    end
   end
   
   b.overlap = o
   b.ongrid = ongrid
   -- now check if the rest
   -- are placed
   if #o == 0 then
    
    local allplaced = true
    for i = 1, w do
     local b2 = t.blocks[i]
     if b2 != b and
       b2.state != st_placed
         then
      allplaced = false
      break  
     end
    end
   
    if allplaced then
     t.subcount += 1
     
     local p = progress[t.level]
     if t.subcount > p[1]
      and not override_ct then
      
       p[1] = t.subcount
       save_progress(progress)
       starcount += 1
       --todo, juice

       make_big_plus_one()
     end
     
     
     local w = t:getwidth() - 1
     local cx = w*fullscale/2
     local cy = w*2.5
      
     local segs = {}
     for i = 1, w do
      	
     	b = t.blocks[i]
       
      local x = b.x
      local y = b.y
       
      for j = 1, #b.segs do
       local seg = b.segs[j]
        
       local x1 =
         (seg[1]*fullscale + x)
           - cx
       local y1 =
         (seg[2]*fullscale + y)
           - cy
        
       add(segs, {x1,y1})
        
      end
      	
     end
      
     add(g_objs,
       make_fill_trans(
        cx+t.x, cy+t.y, segs))
      
     play_escalate(
       t:getwidth()-1)
     
     
     if t:getwidth() >
       #t.blocks then
      t.done = true
      --don't get wider
      t.subcount -= 1
     else
      local x = t.x
      
      --todo capture positions
      --from center
      
      
      t:updategeo()
      
      t.targetx = t.x
      t.x = x
     end
     
    end
    
   end
   
   
  end,
  
  
  
  
  draw=function(t,s)
   --print ('Ž—', 0, 0, 5) 
   --print (#t.pieces, 0, 8)
   
   line(-t.x, -t.y + 120,
     -t.x + 127, -t.y + 120, 1)
   rectfill(-t.x, -t.y + 121,
     -t.x + 127, -t.y + 127, 13)
   print('level '
     .. level
     ..'-'
     .. t.subcount + 1,
       -t.x + 1, -t.y + 122, 1)
   
   if t.done then
    if g_tick % 40 < 20 then
     print('press — to return',
        -t.x + 30, -12, 6)
    end
   end
   --line(-t.x, -t.y+9,
   --  -t.x+127, -t.y+9, 5)
   
   --[[
   sprcpy(workspr1, 0)
   sprstochcpy(
     workspr1, t.activeblock:getspr(), 50)
   spr(workspr1, -30, 20)
   --]]
   
   local s = fullscale
   
   --line(-t.x, s * 7,
   --  -t.x+127, s*7, 5)
   
   
   local w = t.startcount +
     t.subcount
   
   local tw = #t.blocks
   
   rectfill(-2, -2,
     w*s+2, s*5+2, 0)
   
   for i = 0, 5 do
    line(0, i*s, s*w, i*s, 1)
   end
   for i = 0, w do
    line(i*s, 0, i*s, s*5, 1)
   end
   
   local bn =
     t:getbadnegspace()
   
   for i = 1 ,#bn do
    local grp = bn[i]
    for j = 1, #grp do
     local cell = grp[j]
     local x,y =
       cell[1],cell[2]
       
     local off = 3
     --if g_tick % 30 > 14 then
     -- off = 2
     --end
     rectfill(x*s+off, y*s+off,
       (x+1)*s-off,
         (y+1)*s-off, 1)
    end
   
   end
   
   
   rect(-2, -2, s*w + 2,
     s*5 + 2, 1)
   
   drawobjs(t.objs)
  end,
  
  getwidth=function(t)
   return t.startcount + 
     t.subcount
  end,
  
  updategeo=function(t)
   t.objs = {}
   
   local width = t:getwidth()
   
   --todo, anim target  
   t.x = 
     flr((128 -
       fullscale*width)/2)
   
   local blocks = t.blocks
   local board = t
   
   function pnfnc(t)
    local prev =
      (t.index - 1) % width
    local next =
      (t.index + 1) % width
    t:makeblockmenuspr(
      prevspr, blocks[
        prev + 1]:getspr())
    t:makeblockmenuspr(
      nextspr, blocks[
        next + 1]:getspr())
   end
   
   function getresetpos(t)
    return (flr(width/2) - 2)
        * fullscale,
          -6 * fullscale
   end
   
   function atresetpos(t)
    local x,y = t:getresetpos()
    return t.x == x
      and t.y == y
   end
   
   function resetpos(t)
    local x,y = t:getresetpos()
    t.x = x
    t.y = y
   end
   
   function goblock(t, o)
    local n =
      (t.index + o) % width
    
    local b = blocks[n+1]
    b.scale = fullscale
    
    if b.state != st_placed
      then
      
     b:resetpos()
     
    end
    
    
    b.state = st_blockmenu
    
    
    
    b.skip = 1
    
    b:setprevnext()
    board.activeblock = b
    b.targetx = nil
    b.targety = nil
    b.targetscale = nil
    
    --sfx(0)
    
    local snd = 2
    if #t.overlap > 0 then
     
     board:stowblock(t)
     
    else
     t.state = st_placed
     
     --count placed
     for i = 1, width do
      local st = 
        board.blocks[i].state
      if st ~= st_stowed then
       snd += 1
      end
     end
     
    end
    sfx(snd)
    
    t.overlap = {}
    
    add(board.toraise, b)
    
   end
   
   function prevblock(t)
    goblock(t, -1)
   end
   
   function nextblock(t)
    goblock(t, 1)
   end
   
   function stowothers(t)
    sfx(16)
    for i = 1, width do
     local b = board.blocks[i]
     
     if b != t
       and b.state == st_placed
         then
       board:stowblock(b)
      
     end
     
    end
   end
   
   local seqn = flr(
     (width - 2)/2)
   
   function getprevseq(t)
    local r = {}
    
    for i = 1, seqn do
     add(r, blocks[
      ((t.index - 1 - i)
        % width) + 1]:getspr())
    end
    
    return r
   end
   
   function getnextseq(t)
    local r = {}
    
    for i = 1, seqn do
     add(r, blocks[
      ((t.index + 1 + i)
        % width) + 1]:getspr())
    end
    
    return r
   end
   
   function backtomenu(t)
    board:backtomenu()
   end
   for i = 1, width do
    local b = t.blocks[i]
    if b != t.activeblock then
     add(t.objs, b) 
     
     if b.state == st_stowed
       then
      t.scale = 3
      t:stowblock(b)
     end
    end
    
    b.setprevnext = pnfnc
    b.nextblock = nextblock
    b.prevblock = prevblock
    b.stowothers = stowothers
    b.resetpos = resetpos
    b.getresetpos = getresetpos
    b.atresetpos = atresetpos
    b.getprevseq = getprevseq
    b.getnextseq = getnextseq
    b.backtomenu = backtomenu
   end
   
   if t.first then
    t.activeblock:resetpos()
    t.first = nil
   end
   add(t.objs, t.activeblock)
   
  end,
  
  stowblock=function(t,b)
   b.targetscale = 3
   b.state = st_stowed
    
   b.targetx = (b.index) *
     stowedxwidth
   b.targety = stowedypos
   
   t:packstowedblocks()
  end,
  
  packstowedblocks=function(t)
   local stowedcount =   0
   local index = 0
   for i = 1, t:getwidth() do
    local b = t.blocks[i]
    
    if b.state == st_stowed
      then
     stowedcount += 1
     
    end
   end
   
   
   local cx = (t:getwidth() *
     fullscale / 2)
   
   local xmin = cx -
     (stowedcount *
       stowedxwidth / 2)
   
   
   for i = 1, t:getwidth() do
    local b = t.blocks[i]
    if b.state == st_stowed
      then
     
     b.targetx = xmin +
       stowedxwidth*index
     index += 1
    end
   
   end 
  end,
  
  backtomenu=function(t, next)
   t.trans = true
   add(g_objs, make_trans(
    function()
     next = next or 0
     local l = min(
       t.level + next,
         maxlevel)
     add(g_objs, make_main_menu(
       l)) 
     del(g_objs, t)
   
   end))
    
   
   
   
  end,
  
  objs={}
 }

 t:updategeo()
 
 
 menuitem(1, 'exit puzzle',
  function()
   t:backtomenu()
  end
 )
 
 menuitem(2, '------',
   function()end)
 
 return t
 
end

-- block states
st_idle = 0
st_xformmenu = 1
st_rotateleft = 2
st_rotateright = 3
st_blockmenu = 4
st_stowed = 5
st_placed = 6
 
function make_block()
 
 local k_transduration = 4
 
 
 
 local dir_left={-1,0}
 local dir_right={1,0}
 local dir_up={0,-1}
 local dir_down={0,1}
 local dirs={
  dir_left,
  dir_right,
  dir_up,
  dir_down,
 }
 
 
 local t = {
  x=0,y=0,
  which=0,
  count=12,
  scale=8,
  
  overlap={},
  state=st_idle,
  m1=1,m2=2, --no menu on init
  
 update_state=function(t,s)
  
  
  if t.m1 then
   if not btnd(4) then
    t.m1 = nil
   end
  end
  if t.m2 then
   if not btnd(5) then
    t.m2 = nil
   end
  end
   
   
  if t.state == st_idle then
   t:update_idle(t,s)
  elseif t.state ==
    st_xformmenu then
   t:update_xformmenu(t,s) 
  elseif t.state ==
    st_blockmenu then
   t:update_blockmenu(t,s) 
   
  end
  
  
 end,
 
 movetotarget=function(t)
  
  local rate = 4
  
  movetot(t, 'x', 'targetx',
    rate)
  
  movetot(t, 'y', 'targety',
    rate)
  
  movetot(t, 'scale',
    'targetscale', 1)
  
 end,
 
 update_idle=function(t,s)
  
  if not t.m1 and btnn(4) then
   t.state = st_xformmenu
   t.xformstatecount = 
     k_transduration + 1
   sfx(20)
  elseif not t.m2 and btnn(5)
    then
   t.state = st_blockmenu
   t.xformstatecount = 
     k_transduration + 1
   t:setprevnext()
   sfx(20)
  end
  
  if t.state ~= st_idle then
   t:update_state(t,s)
  else
   
  
  --movement
  --todo constrain
  if btnpp(0) then
   t.x -= t.scale
   sfx(0)
  end
  if btnpp(1) then
   t.x += t.scale
   sfx(0)
  end
  if btnpp(2) then
   t.y -= t.scale
   sfx(0)
  end
  if btnpp(3) then
   t.y += t.scale
   sfx(0)
  end
  end
  
 end,
 
 update_xformmenu=function(t,s)
  
  if not btnd(4) then
   t.state = st_idle
   
   if btnd(5) then
    sfx(20)
    --todo share this code
    t.state = st_blockmenu
    t.xformstatecount = 
     k_transduration + 1
    t:setprevnext()
   end
   
   return
  end
  
  if t.xformstatecount then
   t.xformstatecount -= 1
   if t.xformstatecount < 1
     then
    t.xformstatecount = nil
   end
  end
  
  if btnn(0) then
    t:syncin()
    sprcpy(workspr2, workspr1)
    rotate_spr_data(
      workspr2*8, 0, workspr1*8,
        0, 5, false)
    t:syncout()
    sfx(1)
  elseif btnn(1) then
    t:syncin()
    sprcpy(workspr2, workspr1)
  
    rotate_spr_data(
      workspr2*8, 0, workspr1*8,
        0, 5, true)
    t:syncout()
    sfx(1)
  elseif btnn(2) then
   t:syncin()
   sprcpy(workspr2, workspr1)  
  	flip_spr_data(
  	 workspr2*8, 0, workspr1*8,
        0, 5)
   t:syncout()
   sfx(15)
  elseif btnn(3) then
   t:syncin()
   sprcpy(workspr2, workspr1)  
  	flip_spr_data(
  	 workspr2*8, 0, workspr1*8,
        0, 5, true)
   t:syncout()
   sfx(15)
  end
  
 
  
 end,
 
 nextblock=function(t)
  t.which = (t.which + 1) %
    t.count
  t:updategeo()   
  t:setprevnext()
 end,
 
 prevblock=function(t)
  t.which = (t.which + 1) %
     t.count
  t:updategeo()
  t:setprevnext()
 end,
 
 --placeholder
 stowothers=function(t)
 
 end,
 
 update_blockmenu=function(t,s)
  if not btnd(5) then
   t.state = st_idle
   
   
   if btnd(4) then
    --todo share this code
    t.state = st_xformmenu
    t.xformstatecount = 
     k_transduration + 1
    sfx(20)
   end
   
   return
  end
  
  --todo, share
  if t.xformstatecount then
   t.xformstatecount -= 1
   if t.xformstatecount < 1
     then
    t.xformstatecount = nil
   end
  end
  
  if btnn(0) then
   t:prevblock()
  elseif btnn(1) then
   t:nextblock()  
  elseif btnn(3) then
   t.stowcount = 0
  elseif btnn(2) then
   
   if t:atresetpos() then
    t.backcount = 0 
   else
    t:resetpos()
    sfx(2)
   end
   
  else
   
   if t.stowcount then
    if btnd(3) then
     t.stowcount += 1
     if t.stowcount > 12 then
      t:stowothers()
      t.stowcount = nil
     end
    else
     t.stowcount = nil
    end
   elseif t.backcount then
    if btnd(2) then
     t.backcount += 1
     if t.backcount > 12 then
      t:backtomenu()
      t.backcount = nil
     end
    else
     t.backcount = nil
    end
   
   
   end
  end
  
  
 end,
 
 update=function(t,s)
 
  if t.skip then
   t.skip = nil
   return
  end
  t:movetotarget()
  t:update_state(t,s)
 end,

 getspr=function(t)
  --todo, this will replace
  --which as a fixed function
  --deal
  return t.spr or 1
  --return t.which+48
 end,
 
 syncout=function(t)
  sprcpy(t:getspr(), workspr1)
  t:updategeo()
 end,
 
 syncin=function(t)
   sprcpy(workspr1, t:getspr())
 end,
 
 updategeo=function(t)
  
  local x, y =
    getsprxy(t:getspr())
  
  local segs, rects, col =
    get_spr_outline(
       x, y, t.w or 5,
         t.h or 5)
  
  t.segs = segs
  t.rects = rects
  t.col = col
 end,
 
 drawmenu=function(t,
   leftspr,
   rightspr,
   upspr,
   downspr)
  local s = t.scale
  local cy = s*5/2
  local bc = 0
  local radius = s * 5 / 2 + 9
  
  if t.xformstatecount then
   radius = radius * (1 - (
     t.xformstatecount
       / k_transduration))
  end
  
  circ(cy+1,cy+1, radius, 0)
  circ(cy,cy, radius, 6)
  rect(cy-1,cy-1,cy+1,cy+1,5)
  
  if leftspr then
   t:drawmenuicon(1, leftspr,
     radius, cy)
  end
  
  if rightspr then
   t:drawmenuicon(2, rightspr,
     radius, cy)
  end
  
  if upspr then
   t:drawmenuicon(3, upspr,
     radius, cy)
  end
  
  if downspr then
   t:drawmenuicon(4, downspr,
     radius, cy)
  end
  
 end,
 
 drawmenuicon=function(
   t, wdir, wspr, radius, cy)
  
  local bc = 0
  
  if btnn(wdir-1) then
   pal(6, 0)
   bc = 9
  end
  
  local dirv = dirs[wdir]
  
  local icx =
    cy + radius*dirv[1]
  
  local icy =
    cy + radius*dirv[2]
  
  rectfill(icx-7, icy-7, icx+6,
    icy+6, bc)
  
  line(icx-6, icy+7, icx+7,
    icy+7, 1)
  
  line(icx+7, icy-6, icx+7,
    icy+7, 1)
  
  rect(icx-7, icy-7, icx+6,
    icy+6, 6)
  
  if type(wspr) == 'function'
    then
   wspr(t, icx-7, icy-7)
  else
   spr(wspr, icx - 8, icy - 8,
     2, 2) 
  end
  
  pal()
  
 end,
 
 drawprevicon=function(t,x,y)
  spr(prevspr, x-1, y-1,
     2, 2)
  
  local sq = t:getprevseq()
  if (#sq == 0) return
  
  local l = x-#sq*6
  local r = x-1
  rectfill(l, y+3,r,y+9,0)
  line(l, y+3, r, y+3, 1)
  line(l, y+9, r, y+9, 1)
  
  for i = 1,#sq do
   spr(sq[i], x - i*6, y+4)
  end
 end,
 
 drawnexticon=function(t,x,y)
  spr(nextspr, x-1, y-1,
     2, 2)
  
  local sq = t:getnextseq()
  if (#sq == 0) return
  
  local l = x+14
  local r = l+#sq*6
  rectfill(l, y+3,r,y+9,0)
  line(l, y+3, r, y+3, 1)
  line(l, y+9, r, y+9, 1)
  for i = 1,#sq do
   spr(sq[i], x + i*6 + 9, y+4)
  end
  
 end,
 
 drawstowallicon=function(t,
   x,y)
  
  
  rectfill(
     x+1, y+1, x+12, y+12,0)
   
  if t.stowcount then 
   rectfill(x+1,
     y+12 - t.stowcount,
       x+12, y+12, 9)
   
  end
  
  spr(198, x-1, y-1,
     2, 2) 
 end,
 
 drawbackicon=function(t, x, y)
  rectfill(
     x+1, y+1, x+12, y+12,0)
   
  if t.backcount then 
   rectfill(x+1,
     y+12 - t.backcount,
       x+12, y+12, 9)
  end
  
  spr(32, x-1, y-1,
     2, 2) 
 end,
 
 
 setprevnext=function(t)
  
 end,
 
 makeblockmenuspr=function(t,
   dst, src)
   
  local sx, sy = getsprxy(src)
  local dx, dy = getsprxy(dst)
  
  for y = 0, 4 do
   for x = 0, 4 do
    local p = sget(sx+x,sy+y)
    
    
    sset(dx+x*2+3, dy+y*2+3, p)
    sset(dx+x*2+4, dy+y*2+3, p)
    sset(dx+x*2+3, dy+y*2+4, p)
    sset(dx+x*2+4, dy+y*2+4, p)
    
   end
  end
  
 end,
 
 draw=function(t)
  local s = t.scale
  
  if t.state == st_xformmenu
    then
   t:drawmenu(224, 192, 194,
     226)
  
  elseif t.state == st_blockmenu
    then
   
   local upmenu = 230
   
   if t:atresetpos() then
    upmenu = t.drawbackicon
   end
   
   t:drawmenu(
     t.drawprevicon,
     t.drawnexticon,
     upmenu,
     t.drawstowallicon)
  end
 
  t:drawblock(t.segs,
    t.rects, t.col, s)
  
 end,
 
 
 drawblock=function(
   t, segs, rects, col, s)
  for i=1,#rects do
   local r = rects[i]
   
   local x1 = r[1]*s
   local y1 = r[2]*s
   local x2 = r[3]*s
   local y2 = r[4]*s
   
   rectfill(x1, y1, x2, y2, col)
   
   --clipc(x1,y1,x2-x1+1,y2-y1+1)
   --map(0,0,-(g_tick % 8)-8,0,10,10)
   --clip()
   
  
  end
  
  if col == 8 then
   pal(7, 13)
  else
   pal(7, 8)
  end
  
  if t.ongrid then
   for i = 1, #t.overlap do
    local v = t.overlap[i]
    local y = flr(v/5)*s
    local x = (v%5)*s
   
    clipc(x,y,s+1,s+1)
    map(0,0, 0, -(g_tick%8), 6,6)
    clip()
   end
  end
  pal()
  
  local outline = 
    g_tick % 16 > 7
    and t.state != st_stowed
    and t.state != st_placed
  
  if outline then
   for i=0,#segs/2 -1 do
    local p1 = segs[i*2+1]
    local p2 = segs[i*2+2]
  
    local horz = p1[2] == p2[2]
    
    if horz then
     local yo = 1
     if p1[3] then
      yo = -1
     end
     line(p1[1]*s, p1[2]*s+yo,
       p2[1]*s, p2[2]*s+yo, 6)
    else
     local xo = 1
     if p1[3] then
      xo = -1
     end
         
    line(p1[1]*s+xo, p1[2]*s,
      p2[1]*s+xo, p2[2]*s, 6)
    end
   end 
  end  
  
  local placed =
    t.state == st_placed
  
   
  for i=0,#segs/2 -1 do
   local p1 = segs[i*2+1]
   local p2 = segs[i*2+2]
  
   local c = 5
   if p1[3] then
    c = 7
   end
   if placed then
    c = 1
   end
   line(p1[1]*s, p1[2]*s,
     p2[1]*s, p2[2]*s, c)
  end
  
 end
 
 }
 
 t:updategeo()
 
 return t
end

function make_fill_trans(
  x, y, segs)
 return {
  x=x,y=y,segs=segs,
  count=-1,
  update=function(t,s)
   t.count += 1
   t.y -= 1
   if t.count >= 30 then
    del(s, t)
   end
  end,
  draw=function(t)
   for i = 1, #t.segs/2 do
    local s1 = t.segs[
      (i-1)*2 + 1]
    local s2 = t.segs[
      (i-1)*2 + 2]
    local s = 1 + t.count * 0.25
    
    local c = 7
    
    if g_tick % 2 == 0 then
     c = 9
    end
    line(s1[1]*s, s1[2]*s,
      s2[1]*s, s2[2]*s, c)
   
   end
  end
 
 }

end

function make_level_debug()
 return {
  x=0,y=0,
  level = 1,
  update=function(t,s)
   if btnp(0) then
  	 if t.level > 1 then
     t.level = t.level - 1
    end 
   end
   if btnp(1) then
  	 t.level = t.level + 1
   end
  end,
  draw=function(t)
   print(t.level, 0, 100, 7)
 
   local count, pieces =
     get_level_data(t.level)
   
   print(count, 16, 100, 6)
 
   for i = 1,#pieces do
    spr(pieces[i], 24+i*6, 100)
   end
  
  end
 
 }
end


function make_letter_block(
  sprite)
 local b = make_block()
 b.spr = sprite
 b.state = st_placed
 b.h = 7
 b.w = 7
 --b.y = 32
 b.scale = 1.5
 b:updategeo()
 return b
end

function make_title()
 local t = {
  x=0,y=0,
  objs={},
  update=function(t,s)
   for i = 1, #t.objs do
    t.objs[i].scale = 2 +
      sin(g_tick/20)/2
   end
  
  end,
  draw=function(t)
   for i = 1, #t.objs do
    local o = t.objs[i]
    
    pushc( -o.x + o.scale/2,
      -o.y + o.scale/2)
    o:draw()
    popc()
   end
   --drawobjs(t.objs)
  end
 }

 for i = 0,7 do
  local b = make_letter_block(
    16+i)
  b.x = i*16
  add(t.objs, b)
 end

 return t

end


function make_main_menu(level,
  growon)
 drawbg = true
 
 dset(63, level)
 
 local t = {
  level=menulevel_override
    or level,
  sel=0,
  growon=growon,
  buttondown=true,
  update=function(t,s)
   --taco
   if t.done or t.trans or
     t.off or t.growon then
    return
   end
   
   if t.buttondown
     and not btn(5) then
    t.buttondown = nil
   end  
   
   if t.sel == 0 then
    if btnp(0) then
     if t.level > 1 then
      t.level -= 1
      dset(63, t.level)
      sfx(0)
 
     end
    elseif btnp(1) then
     if t.level < maxlevel then
      t.level += 1
      dset(63, t.level)
      sfx(0)
     end
    end
   end
   
   if btnp(2) and t.sel > 0
     then
    t.sel -= 1
    sfx(0)
   end
   
   if btnp(3) and t.sel < 2
     then
    t.sel += 1
    sfx(0)
   end
   
   if not t.buttondown then
    if btnp(5) then
     
     if t.sel == 0 then
      add(s, make_trans(
       function()
        del(s, t)
        add(s, make_board(
        t.level, 
          progress[t.level][1]))
        end))
        
     elseif t.sel == 1 then
      
      -- reset block positions
      for i = 1, 14 do
       sprcpy(i, 176+i)
      end
        
      add(s, make_trans(
       function()
        del(s, t)
        
        
 
        add(s, make_board(
          1, 0))
        
        menulevel_override = 
          t.level
        
        howtoplay(s)
      
       end))
         
     elseif t.sel == 2 then
      sfx(18)
      t.off = true
      add(s, make_menu({
         'cancel',
         'reset all data'},
       function(mt, mi, ms)
        t.off = nil
        del(ms, mt)
        
        if mi == 1 then
         sfx(16)
         clear_data()
         t.level = 1
        end
        
       end   
         
      ))
         
     end
    
     
    end
   end
   
  end,
  mitems = {
    'how to play',
    'reset',
  },
  draw=function(t)
  
   local top = -13
   local bot = 40
   
   
   if t.growon then
    t.growon -= 1
    if t.growon == 0 then
     t.growon = nil
    end
   end
   
   if t.growon then
    top += t.growon*2
    bot -= t.growon*2
   end
   
   rectfill(0, top, 127, bot, 0)
   local c = 6
   if (t.off) c = 5
   line(0, top-1, 127, top-1, c)
   line(0, bot+1, 127, bot+1, c)
   
   if t.growon then
    return
   end
   --spr(128, 10, -40, 3, 4)
   local s = 'level ' .. t.level
   
   c = 5
   if t.sel == 0 then
    c = 7
    
    if not t.done and
      g_tick % 40 < 20 then
     print('press — to begin',
       1, -10, 5)
    end
   end
   print(s, 10, 0, c)
   local l = progress[t.level]
   
   local x = #s*5 + 8
   for i = 1,l[2] do
    palt(9, i > l[1])
    palt(10, i > l[1])
    palt(15, i > l[1])
    spr(34 + (g_tick%24)/4,
      x, -2)
    
    x += 9
   end
   palt()
   
   if t.sel == 0 then
    spr(50, 1, -1)
    spr(50, 117, -1, 1, 1, true)
   end
   
   
   for i = 1, #t.mitems do
    c = 5
    if t.sel == i then
     c = 7
     spr(50, -1, i*10-1,
       1, 1, true)
     
    end
    print (t.mitems[i], 10,
      i*10, c)
   
   
   end
   
    
   
   --c = 5
   --if (t.sel == 2) c = 7
   --print ('reset', 10, 20, c)
    
   
   
    
  end,
  x=0,y=50,
 }

 menuitem(1, nil, nil)
 
 if menulevel_override then
  menulevel_override = nil
 end
 
 return t
end




function get_spr_outline(
  x, y, w, h)
 local result = {}
 local rects = {}
 
 local start = nil
 local rstart = nil
 local firstcolor = nil
 
 --horizontal
 for yy = 0,h do
  start = nil
  rstart = nil
  
  for xx = 0,w-1 do
   local p =
     sget(x+xx, y+yy)
     
   if p > 0 then
    if not firstcolor then
     firstcolor = p
    end
    p = true
    
   else
    p = false
   end
   
   
   if p then
    if not rstart then
     rstart = {xx,yy}
     add(rects, rstart)
    end
   else
    if rstart then
     add(rstart, xx)
     add(rstart, yy+1)
     rstart = nil
    end
   end
   
   local statechg = false
   
   if yy == 0 then
    statechg = p
   else
    statechg = 
      ((sget(x+xx, y+yy-1) > 0)
          != p)
   end
   
   if statechg then
    if not start then
     start = xx
     add(result, {xx, yy, p})
    end
   else
    if start then
     add(result, {xx, yy, p})
     start = nil
    end
   end
  end
  
  if start then
   add(result, {w, yy, p})
  end
  
  if rstart then
   add(rstart, w)
   add(rstart, yy+1)
  end
  
 end
 
 for xx = 0,w do
  start = nil
  
  for yy = 0,h-1 do
   local p =
     sget(x+xx, y+yy) > 0
   
   local statechg = false
   
   if xx == 0 then
    statechg = p
   else
    statechg = 
      ((sget(x+xx-1, y+yy) > 0)
          != p)
   end
   
   if statechg then
    if not start then
     start = yy
     add(result, {xx, yy, p})
    end
   else
    if start then
     add(result, {xx, yy})
     start = nil
    end
   end
  end
  
  if start then
   add(result, {xx, h})
  end
  
 end
 
 
 return result, rects,
   firstcolor
 
 
end

-- begin level data functions

function get_level_xy(n)
 return flr((n-1)/32) * 16 + 64,
   96+((n-1)%32)
end

function get_level_data(n)
 local x,y = get_level_xy(n)
 
 local start = sget(x, y)
 
 local pieces = {}
 for i = 0, 11 do
  local p = sget(x+2+i, y)
  if p == 0 then
   break
  end
  
  add(pieces, p)
  
  --debug shorter boards
  --if (n == 1 and i == 3) break
 end
 
 return start, pieces
 
end


-- end level data functions

function getsprxy(n)
 return (n % 16) * 8,
   flr(n/16) * 8
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

function rotate_spr_data(
  x, y, dx, dy, size, cw)
 local dxx, dyy = nil
 for yy = 0,size-1 do
  for xx = 0, size-1 do
   if cw then
    dxx = size - 1 - yy
    dyy = xx
   else
    dxx = yy
    dyy = size - 1 - xx
   end
   sset(dx+dxx, dy+dyy,
     sget(x+xx,y+yy))   
  end
 end
end

function flip_spr_data(
  x, y, dx, dy, size, vert)
 local dxx, dyy = nil
 for yy = 0,size-1 do
  for xx = 0, size-1 do
   if vert then
    dxx = xx
    dyy = size - 1 - yy
   else
    dxx = size - 1 - xx
    dyy = yy
   end
   sset(dx+dxx, dy+dyy,
     sget(x+xx,y+yy))   
  end
 end
end

--[[
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
--]]
-------------------------------

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
 
 if override_ct then
  ct, ctl =
    override_ct:update()
 
  if ct then
   g_ct = ct
   g_ctl = ctl
  else
   override_ct = nil
  end
 end
 
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
 pushc(g_camx, g_camy)
 drawobjs(g_objs)
 popc()
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

--returns state,changed
function btns(i,p)
 local c, cng =
   _btn(i,p,g_ct),
   _btn(i,p,g_ctl)
 
 return c,c~=cng
 --[[
 i=shl(1,i)
 if p==1 then
  i=shl(i,8)
 end
 local c,cng =
   band(i,g_ct),
   band(i,g_ctl)
 return c>0,c~=cng
 --]]
end

function _btn(i,p,ct)
 i=shl(1,i)
 if p==1 then
  i=shl(i,8)
 end
 return band(i,ct)>0
end


--returns new press only
function btnn(i,p)
 if p==-1 then --either
  return btnn(i,0) or btnn(i,1)
 end
 local pr,chg=btns(i,p)
 return pr and chg
end

function btnd(i,p)
 if override_ct then
  return _btn(i,p,g_ct)
 end
 return btn(i,p)
end

function btnpp(i,p)

 -- xxx: cut corner for
 -- automated case and don't
 -- do the repeats
 if override_ct then
  return btnn(i,p)
 end
 
 return btnp(i,p)
end

function make_automator(
  entries)
 
 return {
  entries = entries,
  index=1,
  count=0, 
  update=function(t,s)
   
   
   local entry =
     t.entries[t.index]
   
   
   
   local ct = entry[2]
   local ctl = ct
   
   if t.count == 0 then
    ctl = 0
    if t.index > 1 then
     ctl =
       t.entries[t.index - 1][2]
    end
   end
   
   t.count += 1
   
   if t.count >= entry[1] then
    t.index += 1
    t.count = 0
   end
   
   if t.index > #t.entries then
   	--todo, callback
   	return nil
   end
   
   return ct, ctl
   
  end
 }

end

function fields(...)
 local f = {...}
 
 local r = 0
 
 for i = 1, #f do
  r = bor(r, shl(1, f[i]))
 end
 return r
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

function clipc(x,y,w,h)
 if #g_cs > 0 then
  x -= g_cs[#g_cs][1]
  y -= g_cs[#g_cs][2]
 end
 clip(x,y,w,h)
end

function moveto(s, e, d)
 if abs(s - e) <= d then
  return e, true
 end
 if s > e then
  return s - d
 else
  return s + d
 end
end

function movetot(t, f1, f2, d)
 if (not t[f2]) return
 local v, done =
   moveto(t[f1], t[f2], d)
 t[f1] = v
 if (done) t[f2] = nil
end

function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
end

function trans(s)
 if s<1 then
  return
 end
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
 if not i then
  sfx(17)
 end
 return {
  d=d,
  e=g_tick,
  f=f,
  i=i,
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
  end,
  x=0,y=0
 }
end

--[[
function draw_wave(a,yp,off)
 local b = 0x6000
   
 for y = 0, 127 do
  
  local o = flr(sin(
    y/yp + off) * a)
  
  memcpy(b, b + o, 64)
    b = b + 64
   
 end

end
--]]

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
    rect(-x,0,x,t.h,6)
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
   spr(50,-x-1,3+10*t.i,1,1,1)
  end,
  update=function(t,s)
   if t.off then 
    return
   end
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
    sfx(0)
   end
   if btnn(3,t.p) and
     t.i<(#lbs-1) then
    t.i+=1
    sfx(0)
   end
  end
 }
 for l in all(lbs) do
  m.tw=max(m.tw,#l)
 end
 return m
end

function make_textbox(
  text, x, y, dur, lines,
    donefnc)
 
 return {
  x=x,y=y,count=0,
  update=function(t,s)
   
   if btn(4) then
   
    for i = 1, #g_objs do
     --taco
     if g_objs[i].backtomenu
       then
      override_ct = nil
      g_objs[i]:backtomenu()
      break
     end
    end
    del(s, t)
    return
   end
   
   t.count += 1
   if t.count > dur then
    if donefnc then
     donefnc(t, s)
    end
    del(s, t)
    
   end
  end,
  draw=function(t)
   if (not text) return
   
   local top = -3
   local bot =
     -3 + 7*lines + 3
   
   local h = bot - top
   
   if t.count < h then
    top += (h - t.count)/2
    bot -= (h - t.count)/2
   end
   
   rectfill(-t.x, top,
     -t.x + 127, bot, 0)
   line(-t.x, top-1, -t.x+127,
     top-1, 6)
   line(-t.x, bot+1, -t.x+127,
     bot+1, 6)
    
   
   local delay = 20
   if t.count > delay then
    local str = text
   
    if t.count - delay <
      #text then
     str = sub(text, 0,
       t.count - delay)
     sfx(19)
    end
  
    print(str, 10, 0, 7)
   end
   
  end,
 
 }
  
end

function howtoplay(s)
 local off1 = {1,0}
 
 override_ct = make_automator({
  {80, 0}, --initial wait
  --move
  {10, fields(3)}, off1,
  {10, fields(3)}, off1,
  {10, fields(3)}, off1,
  
  {8, fields(0)}, off1,
  {8, fields(0)}, off1,
  {8, fields(0)}, off1,
  {8, fields(1)}, off1,
  {8, fields(1)}, off1,
  {8, fields(1)}, off1,
  
  {8, fields(1)}, off1,
  {8, fields(3)}, off1,
  {8, fields(1)}, off1,
  {8, fields(2)}, off1,
  {8, fields(0)}, off1,
  {7, fields(0)}, off1,
  {6, fields(3)}, off1,
  
  {45, 0},
  
  -- xform menu
  -- rotate
  {120, fields(4)},
  {10, fields(4, 0)},
  {1, fields(4)},
  {1, fields(4,0)},
  {30, fields(4)},
  {1, fields(4,1)},
  {10, fields(4)},
  {1, fields(4,1)},
  {60, fields(4)},
  
  -- flip
  {1, fields(4,2)},
  {60, fields(4)},
  {1, fields(4,3)},
  {20, fields(4)},
  
  {10, 0},
  {1, fields(3)}, {10, 0},
  {1, fields(3)}, {30, 0},
  
  {160, fields(5)},
  {1, fields(5,0)},
  {30, fields(5)},
  {1, fields(5,0)},
  {6, fields(5)},
  {1, fields(5,1)},
  {6, fields(5)},
  {1, fields(5,0)},
  {6, 0},
  {1, fields(3)}, {5,0},
  {1, fields(3)}, {5,0},
  {1, fields(3)}, {5,0},
  
  {1, fields(4,0)},
  {12, fields(4)},
  {1, fields(4,0)},
  {12, fields(4)},
  
  {8, fields(3)}, off1,
  {8, fields(3)}, off1,
  {8, fields(3)}, off1,
  {8, fields(0)}, off1,
  {8, fields(3)}, off1,
  
  {15, 0},
  {15, fields(5,1)},
  {5, 0},
  
  {5, fields(3)}, off1,
  {5, fields(3)}, off1,
  {5, fields(3)}, off1,
  {5, fields(3)}, off1,
  {5, fields(3)}, off1,
  {5, fields(4,0)},
  {5, fields(4)},
  {5, fields(4,0)},
  {5, fields(3)}, off1,
  {5, fields(3)}, off1,
  {5, fields(3)},
  {180, 0},
  
  {15, fields(5)},
  {120, fields(5,2)},
  {120, fields(5,3)},
  {120, fields(5,2)},
  
 })
        
        
 add(s, make_textbox(
  'fit all pieces to cover\n'
     .. 'the board.',
   0, 4, 90, 2,
 function(t,s)
  add(s, make_textbox(
   'move the block with\n'
   .. '‹ ‘ ” ƒ',
   0, 4, 120, 2,
 function(t,s)
  add(s, make_textbox(
   'hold Ž to open the\n'
   .. 'transformation menu',
   0, 110, 120, 2,
 function(t,s)
  add(s, make_textbox(
   'press ‹ and ‘ while\n'
   .. 'holding Ž to rotate',
   0, 110, 120, 2,
 function(t,s)
  add(s, make_textbox(
   'press ” and ƒ while\n'
   .. 'holding Ž to flip',
   0, 110, 120, 2,
 function(t,s)
  add(s, make_textbox(
   'hold — to open the\n'
   .. 'block menu',
   0, 4, 120, 2,
 function(t,s)
  add(s, make_textbox(
   'press ‹ and ‘ while\n'
   ..'holding — to pick blocks',
   0, 4, 100, 2,
 function(t,s)
  add(s, make_textbox(
   nil, 0, 4, 300, 2,
 function(t,s)
  add(s, make_textbox(
   'press ” while holding —'
   ..'\nto move off the board'
   , 0, 4, 100, 2,
 function(t,s)
  add(s, make_textbox(
   nil, 0, 4, 80, 2,
 function(t,s)
  add(s, make_textbox(
   'press and hold ƒ while'
 ..'\nholding — to stow blocks'
   , 0, 110, 80, 2,
 function(t,s)
  add(s, make_textbox(
   nil, 0, 110, 30, 2,
 function(t,s)
  add(s, make_textbox(
   'press and hold ” while'
 ..'\nholding — to exit'
   , 0, 110, 100, 2,
 function(t,s)
 
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 end))
 
end

function play_escalate(total)
 add(g_objs, {
  x=0,y=0,count=0,step=0,
  update=function(t,s)
   if t.step == 0 then
    sfx(3+(total-t.count),3)
   end
   
   t.step += 1
   if t.step >= 4 then
    t.step = 0
    t.count += 1
    
    if t.count >= total then
     del(s, t)
    end
   end
  end
 })

end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070007
000000000000000000200000033300000040000000000000006000000000000000800000090000000000000000bb00000c00000000dd00000e00000000700070
00000000fffff00002200000003000000040000000000000006600000000000008880000090000000aaa00000bb000000c00000000d000000ee0000007000700
000000000000000002000000003000000440000000000000066000000000000000800000090000000a0a00000b0000000ccc00000dd000000ee0000070007000
00000000000000000200000000000000004000000000000000000000000000000000000009900000000000000000000000000000000000000000000000070007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070007000
fffff006666660aa000aa0bbbbbb00fffff0066000660aaaaaa0bb000bb00fffff00000000000000000000000000000000000000000000000000000000000000
ffffff06666660aaa00aa0bbbbbb0fffffff066606660aaaaaa0bbb00bb0fffffff0000000000000000000000000000000000000000000000000000000000000
ff00ff06600000aaaa0aa000bb000ff000ff06666666000aa000bbbb0bb0ff000ff0000000000000000000000000000000000000000000000000000000000000
eeeeee0ccccc00999999900033000ee000ee0ccccccc0009900033333330ee000ee0000000000000000000000000000000000000000000000000000000000000
eeeee00cc00000990999900033000ee000ee0cc0c0cc0009900033033330ee000ee0000000000000000000000000000000000000000000000000000000000000
ee00000cccccc0990099900033000eeeeeee0cc000cc0999999033003330eeeeeee0000000000000000000000000000000000000000000000000000000000000
ee00000cccccc09900099000330000eeeee00cc000cc09999990330003300eeeee00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000055500000555000005550000055500000555000005550000000000000000000000000000000000000000000000000000000000000000000
000000000000000005fff50005fff50005fff50005fff50005fff50005fff5000000000000000000000000000000000000000000000000000000000000000000
00000000000000005faaaf505faaaf505faaaf505faaaf505faaaf505faaaf500000000000000000000000000000000000000000000000000000000000000000
00006000000000005aaa99505aaaa95059aaaa50599aaa505a99aa505aa99a500000000000000000000000000000000000000000000000000000000000000000
00006006000000005aa9995059aa9950599aa9505999aa5059999a505a9999500000000000000000000000000000000000000000000000000000000000000000
00006066000000000599950005999500059995000599950005999500059995000000000000000000000000000000000000000000000000000000000000000000
00006666666660000055500000555000005550000055500000555000005550000000000000000000000000000000000000000000000000000000000000000000
00006666666660000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006066000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006006000000000656000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006000000000006556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000656000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011111111110000000000000000000000000000000000000000000000000000000000000000000000000000019999999999999991ccccccccccc188888888888
01fffffffff1000000000000000000000000000000000000000000000000000000000000000000000000000019999999999999991ccccccccccc188888888888
01ffffffffff100000000000000000000000000000000000000000000000000000000000000000000000000019999999999999991ccccccccccc188888888888
01fffffffffff1000000000000000000000000000000000000000000000000000000000000000000000000001111111111111999111111111111111118881111
01ffff111fffff1000000000000000000000000000000000000000000000000000000000000000000000000033333333122219991ddd12222222222218881333
01ffff1001ffff1000000000000000000000000000000000000000000000000000000000000000000000000033333333122219991ddd12222222222218881333
01ffff1001ffff1000000000000000000000000000000000000000000000000000000000000000000000000033333333122219991ddd12222222222218881333
01eeee111eeeee1000000000000000000000000000000000000000000000000000000000000000000000000013331111122211111ddd11111111122211111111
01eeeeeeeeeee10000000000000000000000000000000000000000000000000000000000000000000000000013331222222218881ddddddddddd122222221666
01eeeeeeeeee100000000000000000000000000000000000000000000000000000000000000000000000000013331222222218881ddddddddddd122222221666
01eeeeeeeee1000000000000000000000000000000000000000000000000000000000000000000000000000013331222222218881ddddddddddd122222221666
01eeee11111000000000000000000000000000000000000000000000000000000000000000000000000000001333122211111888111111111ddd111111111666
01eeee10000000000000000000000000000000000000000000000000000000000000000000000000000000001333122218888888888813331ddd166666666666
01eeee10000000000000000000000000000000000000000000000000000000000000000000000000000000001333122218888888888813331ddd166666666666
01111110000000000000000000000000000000000000000000000000000000000000000000000000000000001333122218888888888813331ddd166666666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111122211111888111113331111111116661111
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb12221aaa18881aaa13333333333316661bbb
0000000000111100000000000000000000000000000000000000000000000000000000000000000000000000bbbb12221aaa18881aaa13333333333316661bbb
00000000011bb10000000000000bb00000000000000000000000000000000000000000000000000000000000bbbb12221aaa18881aaa13333333333316661bbb
0000000011bbb1000000000000bbb00000000000000000000000000000000000000000000000000000000000111111111aaa11111aaa13331111111111111bbb
000000001bbbb100000000000bbbb000000000000000000000000000000000000000000000000000000000001eeeeeee1aaaaaaaaaaa13331eeeeeee1bbbbbbb
001111001bbbb100000000000bbbb000000000000000000000000000000000000000000000000000000000001eeeeeee1aaaaaaaaaaa13331eeeeeee1bbbbbbb
001bb100133bb1000000bb00000bb000000000000000000000000000000000000000000000000000000000001eeeeeee1aaaaaaaaaaa13331eeeeeee1bbbbbbb
111bb111111bb1000000bb00000bb000000000000000000000000000000000000000000000000000000000001eeeeeee11111111111111111eeeeeee1bbb1111
1bbbbbb1001bb10000bbbbbb000bb000000000000000000000000000000000000000000000000000000000001eeeeeeeeeee1222222222221eeeeeee1bbb1444
1bbbbbb1001bb10000bbbbbb000bb000000000000000000000000000000000000000000000000000000000001eeeeeeeeeee1222222222221eeeeeee1bbb1444
133bb331001bb1000000bb00000bb000000000000000000000000000000000000000000000000000000000001eeeeeeeeeee1222222222221eeeeeee1bbb1444
111bb111111bb1110000bb00000bb0000000000000000000000000000000000000000000000000000000000011111111111111111111122211111eee11111444
001331001bbbbbb1000000000bbbbbb000000000000000000000000000000000000000000000000000000000144444441ddd1eeeeeee122222221eee14444444
001111001bbbbbb1000000000bbbbbb000000000000000000000000000000000000000000000000000000000144444441ddd1eeeeeee122222221eee14444444
0000000013333331000000000000000000000000000000000000000000000000000000000000000000000000144444441ddd1eeeeeee122222221eee14444444
0000000011111111000000000000000000000000000000000000000000000000000000000000000000000000111111111ddd1eeeeeee11111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddddddddddd1eeeeeeeeeee1ccc1aaaaaaaaaaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddddddddddd1eeeeeeeeeee1ccc1aaaaaaaaaaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddddddddddd1eeeeeeeeeee1ccc1aaaaaaaaaaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddd111111111111111111111ccc1aaa11111aaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddd1fffffffffffffffffff1ccc1aaa18881aaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddd1fffffffffffffffffff1ccc1aaa18881aaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ddd1fffffffffffffffffff1ccc1aaa18881aaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111ccc111118881111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000200000033300000040000000000000006000000000000000800000090000000000000000bb00000c00000000dd00000e00000000000000
00000000fffff00002200000003000000040000000000000006600000000000008880000090000000aaa00000bb000000c00000000d000000ee0000000000000
000000000000000002000000003000000440000000000000066000000000000000800000090000000a0a00000b0000000ccc00000dd000000ee0000000000000
00000000000000000200000000000000004000000000000000000000000000000000000009900000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000030943ebdc20000006094e63bad00000090194ea63b800000701942a38cde0000
0000000000000000000000000000000000000000000000000000000000000000302ea9d43b0000006042ead36b0000009012cead63b0000070142ce6b83d0000
0000000000000000000000000000000000000000000000000000000000000000309ce42ad60000006092ca6b43000000901942ceab8000007094ca6382b10000
0000000060000000000000000000000000000000000000000000000000000000304ea2c6b30000006092ce63bd00000090142ead6380000070194eadb8630000
00000000660000000000006006000000000000000000000000006600006600003092cda34b000000609cea6324000000901942c63b8000007092ce63ba140000
000000666660000000000660066000000000000000000000000006600660000030ea64329b0000004092cda3e861b00090942cad638000007019cead86b20000
0000060066000000000060600606000000000000000000000000006666000000309ced4b260000004094a6dc8e123000901942ced3b000007014cad3be860000
0000600060000000000600600600600000000000000000000000000660000000509ea6b4d2c000004094ce6b2ad310009019cead3b80000070942e63b81d0000
00006000006000000000606006060000000000000000000000000066660000005042eadc39600000404ea6389cbd2000901942ad6b8000007014ead632b80000
00006000006000000000066006600000000000000000000000000660066000005094c3bd6ae000004094edb2361a800070194eab83c6000070942cedb8610000
0000060006000000000000600600000000000000000000000000660000660000502cea6b9d300000409ea684123bc0007094ed63b82a000070194a638d2c0000
000000666000000000000000000000000000000000000000000000000000000050942eb3c6a000004094eb2acd81600070192cad346e000070142ca3be860000
0000000000000000000000000000000000000000000000000000000000000000509ead362b4000004042c361db98a0007094e63b81dc00007092ca3b816e0000
0000000000000000000000000000000000000000000000000000000000000000509ceab243d00000409ced46b123800070142ca6b9e800007019ea63bdc40000
00000000000000000000000000000000000000000000000000000000000000005092e3bd46c000004094e3b21ca8d000709ce63b8da2000070192ad63c8b0000
00000000000000000000000000000000000000000000000000000000000000005094cad6b23000004042eacd81b630007042ead63c81000070942ca68bd30000
0000000000000000000000000000000000000000000000000000000000000000509ce6b4a32000004094cad1638eb00070192ea38bd400007019ced3b8420000
000000000000000000000000000000000000000000000000000000000000000050942ab6ecd000005092e3bdc1a46000701cead6b24900000000000000000000
0000000000000000000000000000000000000000000000000000000000000000504cedb263a0000050942ce3b861d00070142ca386bd00000000000000000000
00000006000000000000000660000000000000000000000000000000000000005094ce6a3db00000509ea6b1d2c3800070192ed3b68a00000000000000000000
00000066000000000000006006000000000000000000000000006666666600005094edb2ac3000005042ead98c3b100070142cad63b900000000000000000000
000006666600000000000600006000000000000000000000000000066000000060942a63de000000504cedb2318a60007094cad6b81200000000000000000000
00000066006000000000666666660000000000000000000000000066660000006092ced634000000502cea684913b000702cea63849b00000000000000000000
00000006000600000000000000000000000000000000000000000666666000006094ed6bca000000509ea3862d4c100070194ca6bed800000000000000000000
00000600000600000000000000000000000000000000000000000006600000006092cea3b6000000509ce6b1a38d40007094cedb83a100000000000000000000
0000060000060000000066666666000000000000000000000000000660000000604cea3b9d000000509ead341826b0007014ead3b2c600000000000000000000
00000060006000000000060000600000000000000000000000000006600000006094cd63eb0000005094c3bd61a820007012cea68b3d00000000000000000000
00000006660000000000006006000000000000000000000000000006600000006092cea6d30000005092ead814b6c0007092ed63bc8400000000000000000000
0000000000000000000000066000000000000000000000000000000660000000602cead364000000509ceab486d2300070192ed6384c00000000000000000000
0000000000000000000000000000000000000000000000000000000000000000602cead64b000000901942cead6000007012cead389b00000000000000000000
00000000000000000000000000000000000000000000000000000000000000006042ce3bda000000904cead63b80000070194a63bd2800000000000000000000
00000000000000000000000000000000000000000000000000000000000000006092ad63c400000090192ced638000007042ced63b8a00000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f00000000004b4c4d4e4f0000520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f00000000005b5c5d5e5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f00000000006b6c6d6e6f7071720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f00000000007b7c7d7e7f8081820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f00000000008b8c8d8e8f9091920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f00000000009b9c9d9e9fa0a1a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0000000000abacadaeafb0b1b20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0000000000bbbcbdbebfc0c1c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100000c0100b010080100401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000037110471107711097110c7110f7111171111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000030511047150a7010d701157011c7012370111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f000001711047110a7010d701157011c7012370111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000271105715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000371106715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000471107715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000571108715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000671109715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f0000077110a715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f0000087110b715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f0000097110c715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000a7110d715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000b7110e715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000c7110f715193050d701157011c7011b10111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000017711127110c711077110c711127111e71111500165001c5001e500380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000711309110061100311101111011110111103111031110411104110041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000a5110e011125121501112511100120c51109011055110301102515010150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000007010090100b0100f01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001951000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000087140d711137111871100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


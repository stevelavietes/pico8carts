pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
cartdata "picodepon_high_scores"
hiscores = {dget(0), dget(1),
  dget(2)}

function hexstr2array(s, off)
 local a = {}
 off = off or 0
 for i = 1, #s do
  add(a, tonum(
    '0x' .. sub(s, i, i)) + off)
 end
 return a
end


function resethiscores()
 for i = 1, 3 do
  hiscores[i] = 0
  dset(i - 1, 0)
 end
end


function palt00()
 palt(0, false)
end

function palt131()
 palt(13, true)
end

--constants
bounceframecount = 10
coyotehangtime = 12
manualraiserepeatframes = 5
squashholdframes = 3
flashframes = 45
--faceframes = 26
flashandfaceframes = 71
popoffset = 9
--chainresetcount = 7
--postclearholdframes = 3
boardxpos = {3, 77}
--toppedoutboardframelimit = 120

blocktileidxs = {
  1, 17, 33, 49, 8, 24, 40
}

autoraisespeedstart = {
 60, 20, 12,
}

autoraisespeeddec = {
 1000, 600, 600,
}

autoraiseholdmult = {
 60, 45, 30,
}

garbageprob = {
 32, 64, 96
}

garbagesizes = {
 {3, 1}, {4, 1}, {5, 1},
 {6, 1}, {6, 2},
}

garbagerange = {
 2, 4, 5
}

function defconsts()
 shakesmall = hexstr2array(
  "010011001110001111")
 shakelarge = hexstr2array(
  "010101010101010010010011001100111023332111456665422269abbbba8"
 )

 bubdeltax = hexstr2array(
  "444444444444444444444444444444444444444400112222333343443434344445558",
  -4
 )
 
 bubdeltay = hexstr2array(
  "555554545454544544445444444444444445444481233444444544455455555577777",
  -4
 )
end

--game state
gs_mainmenu = 0
gs_selectmenu = 1
gs_gamestart = 2
gs_gameplay = 3
gs_gameend = 4

function _init()
 frame = 2
 pframe = 1
 cstate = 0
 prevcstate = 0
 squashframe = 0
 squashcount = 0

 defconsts()

 g_numplayers = 1
 g_levels = {2, 2}
 g_wins = {0, 0}

 g_gamestate = gs_mainmenu
 
 g_chars = {1, 4}
 
 menuitem(2, "reset hi scores",
   resethiscores)
end


function _update60()
 pframe = frame
 frame += 1
 
 prevcstate = cstate
 cstate = btn()
 
 if g_gamestate == gs_mainmenu
   then
  mainmenu_step()
 elseif g_gamestate
   == gs_selectmenu then
  selectmenu_step()
 else
  
  if g_gamestate == gs_gameplay
    then
   
   if g_musicstate !=
     g_anysquashed then
    g_musicstate = g_anysquashed
    if g_musicstate then
     music(3)
    else
     music(0)
    end
   end

   g_anysquashed = false

   g_ticks += 1
   if g_ticks >= 60 then
    g_ticks = 0
    g_seconds += 1
    
    if g_seconds >= 60 then
     g_seconds = 0
     g_minutes += 1
    end
   end
  end
 
  
  updategame()
 end
 
 if g_gamestate == gs_gameend
   then
  
  if g_gamecount < 180 then
   g_gamecount += 1
  else
   for i = 1, g_numplayers do
    if newpress(4, i - 1) or
      newpress(5, i - 1) then
      
      startselectmenu()
      break
    end
   end
  end
     
 end

end

function _draw()
 cls()
 
 if g_gamestate == gs_mainmenu
   then
  mainmenu_draw()
 elseif g_gamestate == 
   gs_selectmenu then
  selectmenu_draw()  
 else
  rectfill(0, 0, 127, 127, 5)
  
  
  if g_numplayers == 2 then
   for i = 1, 4 do
    map (0, 0, (i - 1) * 16,
      -boards[1].raiseoffset,
        2, 17)
    map (2, 0, 64 + (i - 1) * 16,
      -boards[2].raiseoffset,
        2, 17)
   end
  else
   for i = 1, 9 do
    map (4, 0, (i - 1) * 16,
      -boards[1].raiseoffset,
        2, 17)
   end
  end
  
  palt00()

  foreach(boards, board_draw)


  if #boards > 1 then
   wins_draw(53, 33)
   
   
   char_draw(g_chars[1],
    charidlefr(boards[1]),
      41, 0, true)
   char_draw(g_chars[2],
    charidlefr(boards[2]),
      66, 0)
   
   clock_draw(53, 24)
  else
   clock_draw(69, 82)
  end
  
  palt()--0, true)
  
  foreach(matchbubs,
    matchbub_draw)
  
  if g_gamestate == gs_gamestart
    and g_gamecount < 20 then
   trans(
      flr((20 - g_gamecount) / 4))
    
  end
  
 end
end


function wins_draw(x, y)
 rectfill(
    x + 1, y - 1, x + 20,
      y + 13, 1)
  
 rectfill(
   x + 2, y + 6, x + 9,
     y + 12, 12)
 
 rectfill(
   x + 11, y + 6, x + 19,
     y + 12, 14)
     
 print("wins", x + 4, y, 7)
 
 local p = function(x, y, v)
  if v < 10 then
   x += 2
  end
  print(v, x, y, 7)
 end
 
 p(x + 3, y + 7, g_wins[1])
 p(x + 12, y + 7, g_wins[2])
 
 if g_gamestate == gs_gameend
   and g_gamecount < 18 then
  palt(12, true)
  puff_draw(x + 5, y + 4,
    g_gamecount)
  palt(12, false)
 end
 
end

function clock_draw(x, y)
 
 rectfill(x - 2, y - 1,
   x + 24, y + 5, 1)
 
 if g_minutes < 10 then
  print("0", x, y, 7)
  x += 5
 end
 
 
 
 
 print(g_minutes, x, y, 7)
 print(":", x + 5, y, 7)
 if g_seconds < 10 then
  print("0", x + 10, y, 7)
  x += 5
 end
 print(g_seconds, x + 10, y, 7)
 
 
end


function mainmenu_step()
 if newpress(2, 0) then
  if g_numplayers == 2 then
   g_numplayers = 1
  end
 end
 if newpress(3, 0) then
  if g_numplayers == 1 then
   g_numplayers = 2
  end
 end
 
 for c in all(clouds) do
  c.x += c.speed
  if c.x + c.w * 8 < 0 then
   
   del(clouds, c)
   add(clouds,
     rndcloud(128, c.y))
  end
 end
 
 if newpress(5, 0) then
  startselectmenu()
 end
end

function solo_draw(x, y)
 palt131()
 palt00()
 spr(85, x, y, 3, 2)
 spr(86, x + 24, y, 1, 2)
 palt()
end

function vs_draw(x, y)
 palt131()
 palt00()
 spr(88, x, y, 1, 2)
 spr(85, x + 8, y, 1, 2)
 palt()
end


function cloud_new(
  sx, sy, w, h, x, y, speed)
  
 local c = {
  sx = sx,
  sy = sy,
  w = w,
  h = h,
  x = x,
  y = y,
  speed = speed,
  tx = flr(rnd(10)) + 6,
  ty = flr(rnd(4)) + 5
 }
 
 return c
end

function cloud_draw(c)
 palt00()
 map(c.tx, c.ty, c.x, c.y,
   c.w, c.h)
 palt()
 pal(1, 0)
 map(c.sx, c.sy, c.x, c.y,
   c.w, c.h)
 pal()
end

clouddefs = {
 {6, 0, 6, 4},
 {12, 0, 4, 3},
 {16, 0, 5, 3},
 {17, 3, 3, 2}
}

function rndcloud(x, y)
 local def = clouddefs[
   flr(rnd(#clouddefs)) + 1]

 return cloud_new(
   def[1], def[2], def[3],
     def[4], x, y,
       -rnd(0.25) - 0.25)
end

clouds = {
 rndcloud(30, 7, -1),
 rndcloud(90, 45, -1),
}

function mainmenu_draw()
 rectfill(0, 0, 127, 86, 12)
 rectfill(0, 86, 127, 88, 5)
 rectfill(0, 89, 127, 128, 13)
 
 
 for c in all(clouds) do
  cloud_draw(c)
 end
 
 
 local drawlogo = function(y)
  spr(112, 1, y, 3, 1)
  spr(115, 26, y, 2, 1)
  spr(117, 43, y, 2, 1)
  spr(71, 1, y + 11, 8, 1)
 end
 
 pal(7, 0)
 pal(6, 0)
 drawlogo(67)
 pal()
 drawlogo(66)
 
 line(0, 86, 128, 86, 0)
 solo_draw(45, 92)
 vs_draw(45, 110)
 
 local y = 95
 if g_numplayers > 1 then
  y = 112
 end
 spr(15, 36, y)
end

function startselectmenu()
 g_gamestate = gs_selectmenu
 g_accepted = {0, 0}
 menuitem(1)
 matchsfx(1)
 music(-1)
--menuitem(2)
end

function selectmenu_step()
 
 local acceptedmin = 3
 local acceptedmax = 0
 
 local fields = {
  {g_levels, 3},
  {g_chars, 8},
 }
 for i = 1, g_numplayers do
  
  acceptedmin = min(
    acceptedmin, g_accepted[i])
  
  acceptedmax = max(
    acceptedmax, g_accepted[i])
  
  if g_accepted[i] > 0 then
   if newpress(4, i - 1) then
    g_accepted[i] -= 1
   end
  end
  
  if g_accepted[i] < 2 then
   
   if newpress(5, i - 1) then
     g_accepted[i] += 1
   end
  end
  
  if g_accepted[i] < 2 then
   local f = fields[
     g_accepted[i] + 1]
   
   if newpress(0, i - 1) then
    if f[1][i] > 1 then
     f[1][i] -= 1
    end
   end
   
   if newpress(1, i - 1) then
    if f[1][i] < f[2] then
     f[1][i] += 1
    end
   end
   
   if newpress(2, i - 1) then
    if f[1][i] > 4 then
     f[1][i] -= 4
    end
   end
   
   if newpress(3, i - 1) then
    if f[1][i] + 4 <= f[2] then
     f[1][i] += 4
    end
   end

  end
  
 end
 
 if acceptedmin == 2 then
  startgame()
 end
 
 if acceptedmax == 0 then
  for i = 1, g_numplayers do
   if newpress(4, i - 1) then
    g_gamestate = gs_mainmenu
   end
  end
 end
 
end

function char_draw(
  idx, fr, x, y, flp)
 rectfill(x, y,
    x + 21, y + 21, 1)
  
 rect(x + 1, y + 1,
    x + 20, y + 20, 6)
  
 spr(126 + 2 * idx + 32 * fr,
   x + 3, y + 3, 2, 2, flp)
  
end

function hiscore_draw(x, y)
 drawlabeledtext(x, y,
    "hi score",
       hiscores[g_levels[1]])
end


names = {
 "jelpi",
 "bal",
 "danz-h",
 "space8",
 "paul n",
 "m-burg",
 "rainy",
 "ana",
}


function selectmenu_draw()
 rectfill(0, 0, 127, 20, 13)
 
 levelselect_draw(1, 1, 25)
 
 if g_numplayers == 1 then
  solo_draw(3, 3)
  hiscore_draw(65, 35)
 else
  levelselect_draw(2, 65, 25)
  vs_draw(3, 3)
 end

 rectfill(0, 50,  127, 127, 1)
 
 line(0, 50, 127, 50, 1)
 

 local drawcurs = function(
   x, y, c, p)
  
  pal(7, c)
  palt131()
  palt00()
  
  local off = 0
  if p then
   if (frame + p) % 32 < 16 then
    off = 1
   end
  end
  
  spr(16, x - 4 - off,
    y - 4 - off)
  
  spr(16, x + 18 + off,
    y - 4 - off, 1, 1, true,
      false)
  
  
  spr(16, x  - 4 - off,
    y + 18 + off, 1, 1, 
      false, true)
  
  spr(16, x + 18 + off,
    y + 18 + off, 1, 1, 
      true, true)
  
  
  pal()
  palt() 
 end
 
 for i = 1, 8 do
  local x = 2 + (i - 1) * 32
  local y = 56
  if i > 4 then
   y += 34
   x -= 128
  end

  palt00()
  
  local fr = 0
  for j = 1, 2 do
   if g_accepted[j] == 2 and
     g_chars[j] == i then
    fr = 2
   end
  end
  
  char_draw(i, fr, x + 3, y)
  print(names[i], x + 4,
    y + 24, 6)
  local f1 = function(j, c)
   if j > g_numplayers then
    return
   end
   if i == g_chars[j] and
     g_accepted[j] > 0 then
    local p
    if g_accepted[j] == 1 then
     p = 0
    end
    drawcurs(x + 3, y, c, p)
   end
  end

  if (frame + 8) % 32 < 16 then
   f1(1, 12)
   f1(2, 14)
  else
   f1(2, 14)
   f1(1, 12)
  end
  
 end
 

end


lvlnames = {
 "easy", "med", "hard"}

lvlcolors = {3, 9, 8}
playercolors = {12, 14}
function levelselect_draw(
  idx, x, y)
  
 spr(68 + idx, x, y)
 y += 10
 
 if g_accepted[idx] == 0 then
  rect(x - 1, y - 1, x + 55,
    y + 9, playercolors[idx])
 end
 
 for i = 1, 3 do
  local bgcolor = 0
  local fgcolor = 1
  
  if g_levels[idx] == i then
   bgcolor = lvlcolors[i]
   fgcolor = 0
  end
  
  rectfill(x, y, x + 18, y + 8,
    bgcolor)
  
  rect(x, y, x + 18, y + 8, 1)
  
  local xx = x + 2
  if i == 2 then
   xx += 2
  end
  print(lvlnames[i],
    xx, y + 2, fgcolor)
  x += 18
 end
 
end








function startgame()
 
 menuitem(1, "cancel game", 
   startselectmenu)
 
 g_gamestate = gs_gamestart
 g_gamecount = 0
 
 g_minutes = 0
 g_seconds = 0
 g_ticks = 0
 
 g_musicstate = false

 matchbubs = {}
 boards = {}
 boards[1] = board_new()

 if g_numplayers > 1 then
  boards[2] = board_new()
  boards[1].target = boards[2]
  boards[2].target = boards[1]
 end

 local s = rnd(31767)
 local nlrd =
   boards[1].nextlinerandomseed
 for i = 1, #boards do
  local b = boards[i]
  b.idx = i
  b.level = g_levels[i]
  b.autoraisespeed = 
    autoraisespeedstart[
      g_levels[i]]
  
  if b.level == 3 then
   b.blocktypecount = 6
  end
  srand(s)
  board_fill(b, 6)
  b.nextlinerandomseed = nlrd
  if #boards > 1 then
   b.x = boardxpos[i]
   b.contidx = i - 1
  end
  
 end

 

end

--block state
bs_idle = 0
bs_matching = 1
bs_swapping = 2
bs_coyote = 3
bs_postclearhold = 4
bs_garbage = 5
bs_garbagematching = 6

bounceframes = {
 0, 3, 3, 3,
 4, 4, 4, 4, 2, 2, 2, 0
}

squashframes = {
 2, 0, 3, 4, 3, 0
}

function block_new()
 return {
  btype=0,
  state=bs_idle,
  count=0,
  count2=0,
  fallframe=0,
  chain=0,
  fallenonce=false,
  garbagex=0,
  garbagey=0,
  garbagewidth=0,
  garbageheight=0,
 }
end

--cursor state
cs_idle = 0
cs_swapping = 1

function board_new()
 local b = {}

 b.blocks = {}
 for i = 1, 13 do
  local row = {}
  b.blocks[i] = row
  
  for j = 1, 6 do
   row[j] = block_new()
  end
 end

 b.blocktypecount = 5


 b.cursx = 0
 b.cursy = 6
 b.cursstate = cs_idle
 b.curscount = 0
 b.cursrepeatpause = 0
 b.cursrepeatcount = 0
 b.cursbumpx = 0
 b.cursbumpy = 0
 b.contidx = 0
 
 b.rowstart = 0
 b.raiseoffset = 0
 b.manualraise = 0

 b.nextlinerandomseed =
   rnd(32767)
 
 b.x = 8
 b.y = 32
 
 b.matchrecs = {}
 
 b.autoraisehold = 0
 b.autoraisecounter = 0
 b.autoraisespeed = 60
 
 b.autoraisedeccounter
   = 0

 b.shakecount = 0
 
 b.pendinggarbage = {}
 b.pendingoffset = 0
 
 b.toppedoutframecount = 0
 
 b.score = 0

 --b.lost = false
 return b

end


function board_getrow(b, idx)
 return b.blocks[(
   (idx + b.rowstart - 1) % 13
     ) + 1]
    
end

function board_fill(b, startidx)
 local horzruntype = 0
 local vertruntype = 0
 for y = 13, startidx, -1 do
  local row = board_getrow(b, y)
  for x = 1, 6 do
   if (x == 3 or x == 4) and
     y < 10 then
    goto cont
   end
   
   
   horzruntype = 0
   if x > 2 then
    if row[x - 2].btype ==
      row[x - 1].btype then
     horzruntype =
       row[x - 1].btype
    end
   end
   vertruntype = 0
   if y < 11 then
    local row2 =
      board_getrow(b, y + 1)
    local row3 =
      board_getrow(b, y + 2)
  
      
    if row2[x].btype ==
      row3[x].btype then
     vertruntype =
       row2[x].btype
    end 
   end
   
   
   
   
   if horzruntype > 0 or
     vertruntype > 0 then
   
    local types = {}
    for t = 1, b.blocktypecount
      do
     if t != horzruntype and
       t != vertruntype then
      types[#types + 1] = t
     end
    end
 
    row[x].btype = types[
      flr(rnd(#types)) + 1]
  
   else    
    row[x].btype =
      flr(rnd(
        b.blocktypecount)) + 1
   end
  
   
   ::cont::
   
  end
 end
 
 
end

function board_addgarbage(b,
  x, y, width, height,
    forcey, forceh)
 
 for yy = y - (height - 1), y do
  
  if yy > 0 then
   local row =
     board_getrow(b, yy)
   
   for xx = x, x + width - 1 do
    local bk = row[xx]
    
    bk.state = bs_garbage
    bk.garbagex = xx - x
    bk.garbagey = -(yy - y)
    bk.garbagewidth = width
    bk.garbageheight = height
    bk.btype = 10
    bk.fallenonce = false
    bk.fallframe = frame
    if forcey then
     bk.garbagey = forcey
    end
    if forceh then
     bk.garbageheight = forceh
    end
   end
  end 
 end

end


function _cursdir(b, bidx)
 
 if not press(bidx, b.contidx)
   then return end
  
 if newpress(bidx, b.contidx)
   then
  b.cursrepeatpause = 0
  b.cursrepeatcount = 0
 end

 if b.cursrepeatpause == 0
   then
  if b.cursrepeatcount == 0
    then
   b.cursrepeatcount = 1
   b.cursrepeatpause = 8

  else
   b.cursrepeatpause = 0
   if frame % 2 > 0 then
     -- play sound
   end
   
  end
  return true
 else
  b.cursrepeatpause -= 1
 end

end

function stateisswappable(s)
 if s == bs_idle
   or s == bs_postclearhold
   then
  return true
 end
end

function hasblock(bk, bkbelow)
 if not bk then
  return
 end
 if bk.btype > 0 and
   (not bkbelow or
     bkbelow.btype > 0)
   then
  return true
 end
end

function canswap(bk, bkbelow)
 if bk.btype == 0 or (
    not bkbelow
    or bkbelow.btype > 0
    ) then
  return true
 end
end

function board_getcursblocks(
  b, below)
 local off = 1
 if below then
  off += 1
 end
 local row =
    board_getrow(b, b.cursy
      + off)
 
 return row[b.cursx + 1],
   row[b.cursx + 2]
end

cursshakeframes =
  hexstr2array("00112211", -1)

function board_cursinput(b)
 if g_gamestate != gs_gameplay
   then
  return
 end

 b.cursbumpx = 0
 b.cursbumpy = 0
 
 if b.cursstate != cs_idle then
  return
 end
 
 if newpress(5, b.contidx) then
  local bk1, bk2 =
    board_getcursblocks(b)
   
  local bk1below
  local bk2below
  if b.cursy < 12 then
   bk1below, bk2below =
     board_getcursblocks(b, 1)
  end
  
  if stateisswappable(bk1.state)
    and stateisswappable(
      bk2.state)
    and (hasblock(bk1, bk1below)
     or hasblock(bk2, bk2below))
    and (canswap(bk1, bk1below)
     and canswap(bk2, bk2below))
    then
   
   bk1.state = bs_swapping
   bk2.state = bs_swapping
   b.cursstate = cs_swapping
   b.curscount = 0
   sfx(1)
   return
  else   
   maskpress(bnot(shl(1, 5)),
     b.contidx)
   
   if (
     stateisswappable(bk1.state)
     and hasblock(bk1, bk1below)
     and canswap(bk1, bk1below)
     ) or (
     stateisswappable(bk2.state)
     and hasblock(bk2, bk2below)
     and canswap(bk2, bk2below)
     ) then
    
    b.cursbumpx = 
      cursshakeframes[
        (frame % 8) + 1]
   end
  end
 
 
 
 end
 
 
 if b.cursy > 0 and
   (not (b.cursy == 1
     and b.raiseoffset > 3))
   and _cursdir(b, 2) then
  b.cursy -= 1
  sfx(3)
 end
 
 if b.cursy < 11 and
   _cursdir(b, 3) then
  b.cursy += 1
  sfx(3)
 end
 
 if b.cursx > 0 and
    _cursdir(b, 0) then
  b.cursx -= 1
  sfx(3)
 end
 
 if b.cursx < 4 and
   _cursdir(b, 1) then
  b.cursx += 1
  sfx(3)
 end
 
end



function board_raise(b)
 local toprow =
   board_getrow(b, 1)

 for i = 1, 6 do
  if toprow[i].btype > 0 then
   b.manualraise = 0
   return
  end
 end

 b.raiseoffset += 1
 
 if b.raiseoffset == 8 then
  b.raiseoffset = 0
  if b.cursy > 0 then
   b.cursy -= 1
  end
  b.rowstart =
    (b.rowstart + 1) % 13
  
  b.nextlinerandomseed += 1
  srand(b.nextlinerandomseed)
  
  local botrow =
    board_getrow(b, 13)
  
  local runlen = 0
  local lasttype = 255
  for i = 1, 6 do
   local t = flr(
     rnd(b.blocktypecount))
   
   if t == lasttype then
    runlen += 1
    if runlen > 2 then
     t = t + flr(rnd(
       b.blocktypecount - 1)
         ) + 1
     t = t % b.blocktypecount
     runlen = 1
    end
   else
    runlen = 1
   end
   
   if rnd(128) < 8 then
    t = 6
   end 
   
   botrow[i].count = 0
   botrow[i].chain = 0
   botrow[i].state = bs_idle
   botrow[i].btype = t + 1
   lasttype = t
  end
  
  for mrec in all(b.matchrecs)
    do
   mrec.y -= 1
  end
  
  if not b.target then
   if rnd(256) < 
     garbageprob[
       b.level] then

    local s =
      garbagesizes[
        flr(rnd(
          garbagerange[
            b.level])) + 1]

    board_appendgarbage(b,
      s[1], s[2])
   end
  end
  
 
 elseif b.raiseoffset == 2 then
  if b.cursstate == cs_idle and
    b.cursy == 0 then
   b.cursy = 1
  end
 end

end

function runrec_new()
 return {btype=0, len=0}
end

function matchrec_new()
 return {
  x=0,
  y=0,
  dur=0,
  chain=0,
  seqidx=0,
  puffcount=255,
 }
end


function board_step(b)
 if g_gamestate != gs_gameplay
   then
  return
 end

 b.autoraisedeccounter += 1
 if b.autoraisedeccounter >=
   autoraisespeeddec[
     b.level] then
  
  b.autoraisedeccounter = 0
  if b.autoraisespeed > 3 then
    b.autoraisespeed -= 1
  end
 end
 
 if press(4, b.contidx) then
  
  local raise = true
  if b.raiseoffset == 0 then
   if newpress(4, b.contidx)
     then
    b.manualraise =
      manualraiserepeatframes
   else
    b.manualraise -= 1
    if b.manualraise > 0 then
     raise = false
    end
   end
  else
   b.manualraise =
     manualraiserepeatframes
  end
  
  if raise then
   board_raise(b)
  end
 elseif b.raiseoffset > 0 and
   b.manualraise > 0 then
   board_raise(b)
 else
  b.manualraise = 0
  
  if b.autoraisehold > 0 then
   b.autoraisehold -= 1
  end
  
  if #b.matchrecs == 0
    and b.autoraisehold == 0
    then
   b.autoraisecounter += 0.5
   if b.autoraisecounter >=
     b.autoraisespeed then
    b.autoraisecounter = 0
    board_raise(b)
   end
  
  end
  
 end
 
 board_cursinput(b)
 
 if b.cursstate == cs_swapping
   then
  local bk1, bk2 =
    board_getcursblocks(b)
  
  if b.curscount < 3 then
   b.curscount += 1
  else
   b.cursstate = cs_idle
   local t = bk1.btype
   bk1.btype = bk2.btype
   bk2.btype = t
   bk1.state = bs_idle
   bk2.state = bs_idle
   
   
   
   function postswap(x, y)
    local bmid = board_getrow(
      b, y)[x]
    
    local bdown
    if y < 13 then
     bdown = board_getrow(
      b, y + 1)[x]
    end
    
    local bup
    if y > 1 then
     bup = board_getrow(
      b, y - 1)[x]
    end
    
    if bmid.btype > 0 then
     if bdown then
      if bdown.btype == 0 then
       bdown.state = bs_coyote
       bdown.count =
         coyotehangtime
      end
     end
     bmid.count = 0
    else
     if bup then
      if bup.btype > 0 then
       bmid.state = bs_coyote
       bmid.count = coyotehangtime
      end
     end
    end
   end
   
   postswap(b.cursx + 1,
     b.cursy + 1)
   postswap(b.cursx + 2,
     b.cursy + 1)
     

   maskpress(bnot(7),
     b.contidx)
   
  end
 end
 
 -- board scan
 local rows = {}
 for i = 1, 13 do
  rows[i] = board_getrow(b, i)
 end
 
 local horzrun = runrec_new()
 local vertruns = {}
 
 for i = 1, 6 do
  vertruns[i] = runrec_new()
 end
 
 local newmatchminx = 7
 local newmatchminy = 13
 
 local matchseqmap = {}
 local newmatchseqs = {}
 
 local newmatchchainmax = 0
 local garbagefallarea = 0
 
 local metalcount = 0
 
 local checkhorzrun =
   function(x1, y1)
  if horzrun.len < 3 then
   return
  end
  
  if horzrun.btype == 7 then
   metalcount += horzrun.len
  end
  
  local matchseq = {}
  add(newmatchseqs, matchseq)
  local row = board_getrow(
    b, y1)
  local pad = flashandfaceframes
  local dur = pad +
      horzrun.len * popoffset
  
  
  local chainmax = 0
  
  local rx = x1 - horzrun.len
  newmatchminy = min(
     newmatchminy, y1)
  
  for r = 1, horzrun.len do
   local runbk =
     row[rx]
   
   runbk.state = bs_matching
   runbk.count = 0
   runbk.count2 = pad

   matchseqmap[
     rx + shl(y1, 4)] =
       matchseq

   local mrec = matchrec_new()
   mrec.x = rx
   mrec.y = y1
   mrec.dur = dur
   mrec.seqidx = r - 1
   add(matchseq, mrec)
   
   chainmax = max(chainmax,
     runbk.chain + 1)
   mrec.chain = chainmax
   newmatchminx = min(
     newmatchminx, rx)
     
   pad += popoffset
   rx += 1
  end
  
  --if chainmax > 1 then
   for mrec in all(matchseq) do
    mrec.chain = chainmax
   end
  --end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 end
 
 local checkvertrun = function(
   x1, y1)
  if vertruns[x1].len < 3 then
   return
  end
  local runlen =
    vertruns[x1].len
  local runlendur =
    runlen * popoffset
  
  newmatchminx = min(
     newmatchminx, x1)
     
  local pad = flashandfaceframes
  local dur = pad + runlendur
  local ry = y1
  local chainmax = 0
  local crosschainmax = 0
  local runoffset = 0
  local runbtype =
    vertruns[x1].btype
  
  local hmatchseq
  
  for r = 1, runlen do
   local runbk =
     board_getrow(b, ry)[x1]
   
   local key = x1 + shl(ry, 4)
   if not hmatchseq and
     matchseqmap[key] then
    hmatchseq =
      matchseqmap[key]
    
    pad = hmatchseq[1].dur
    dur = pad + runlendur
    
    for mrec in all(hmatchseq)
      do
     mrec.dur = dur
    end
    
    chainmax = max(chainmax,
      hmatchseq[1].chain)
   else
    if runbk.btype == 7 then
     metalcount += 1
    end
    chainmax = max(chainmax,
      runbk.chain + 1)
   end
     
   
   ry += 1
  end
 
  local matchseq
  if hmatchseq then
   matchseq = hmatchseq

   for mrec in all(matchseq) do
    mrec.chain = chainmax
   end

   runoffset = #matchseq - 1
  else
   matchseq = {}
   add(newmatchseqs, matchseq) 
  end
  
  local mrec
  ry = y1
  for r = 1, runlen do
   local runbk =
     board_getrow(b, ry)[x1]
   
   if runbk.state ==
     bs_matching then
    goto cont
   end
   
   runbk.state = bs_matching
   runbk.count = 0
   runbk.count2 = pad
   
   mrec = matchrec_new()
   mrec.x = x1
   mrec.y = ry
   mrec.dur = dur
   mrec.chain = chainmax
   mrec.seqidx =
     r - 1 + runoffset
   add(matchseq, mrec)
   
   newmatchminy = min(
     newmatchminy, ry)
   
   ::cont::
   
   ry += 1
   pad += popoffset
  end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 
 end
 
 local prevrow
 local row
 for y = 12, 1, -1 do
  row = rows[y]
  horzrun.len = 0
  horzrun.btype = 0
  for x = 1, 6 do
   
   local bk = row[x]
   if bk.state == bs_coyote or
     bk.state ==
       bs_postclearhold
     then
    bk.count -= 1
    if bk.count <= 0 then
     bk.state = bs_idle
    end
   end
  
   if bk.state == bs_idle
     and bk.btype > 0 then
    
    if prevrow then
    
     local bkbelow = prevrow[x]

     if bkbelow.state == bs_idle
       and bkbelow.btype == 0
       then
       
      bkbelow.btype = bk.btype
      bkbelow.fallframe =
        frame
      bkbelow.count = 0
      bkbelow.chain = bk.chain
      
      bk.btype = 0
      bk.count = 0
      bk.chain = 0
      
      horzrun.len = 0
      horzrun.btype = 0
      
      goto cont
      
     end
    end
    
    -- was falling but stopped
    if bk.fallframe ==
      pframe then
     bk.count =
       bounceframecount
     --sfxdrop
     sfx(2)
    else
     -- not falling
     if bk.count > 0 then
      bk.count -= 1
      
      -- chainresetcount
      if bk.count == 7 then
       bk.chain = 0
      end
     
     end
    
     
    end
    
    if (bounceframecount -
      bk.count) < 2 then
     
     checkhorzrun(x, y)
     horzrun.btype = 0
     horzrun.len = 1
     
     checkvertrun(x, y + 1)
     vertruns[x].btype = 0
     vertruns[x].len = 1
    
    else
     
     if horzrun.btype ==
       bk.btype then
      horzrun.len += 1
     else
      checkhorzrun(x, y)
      horzrun.btype = bk.btype
      horzrun.len = 1
     end
     
     if vertruns[x].btype ==
       bk.btype then
      vertruns[x].len += 1
      
      if y == 1 then
       checkvertrun(x, 1)
      end
     else
      checkvertrun(x, y + 1)
      vertruns[x].btype =
        bk.btype
      vertruns[x].len = 1
     end
     
     
    end
    
   else
    checkhorzrun(x, y)
    horzrun.btype = 0
    horzrun.len = 0
    
    checkvertrun(x, y + 1)
    vertruns[x].btype = 0
    vertruns[x].len = 0
    
    if prevrow and
      bk.state == bs_garbage and
      bk.garbagex == 0 then
      
      
      local clearbelow = true
      for i = x,
        x + bk.garbagewidth - 1
        do
       local bbk = prevrow[i]
       if bbk.state != bs_idle
         or bbk.btype != 0 then
        clearbelow = false
        break
       end
      end
      
      if clearbelow then
       for i = x,
         x + bk.garbagewidth - 1
         do
        prevrow[i] = row[i]
        row[i] = block_new() 
        prevrow[i].fallframe =
          frame
       end     
       
       if y == 1 and
         bk.garbagey <
          bk.garbageheight - 1
          then
        board_addgarbage(b, x, 1,
          bk.garbagewidth, 1,
          bk.garbagey + 1,
          bk.garbageheight)
       end
      
      else
       if bk.fallframe ==
         pframe then
         
        sfx(2)
       elseif bk.garbagey == 0
         and not bk.fallenonce
         then
        bk.fallenonce = true
        garbagefallarea = 
          garbagefallarea +
            bk.garbagewidth *
            bk.garbageheight
            
        
       end
      end
      
    end
    
   end
   
   ::cont::
   
  end
  checkhorzrun(7, y)
  prevrow = row
 end
 
 local matchcount = 0
 
 
 if #newmatchseqs > 0 then
  local seqidxstartr = {0}
  
  for ms in all(newmatchseqs)
    do
   matchcount += #ms
   for j = 1, #ms do
    local m = ms[j]
    add(b.matchrecs, m)
    
    local _breakgarb =
      function(xo, yo)
     if board_getrow(b,
       m.y + yo)[
         m.x + xo].state ==
           bs_garbage then
      
      board_breakgarbage(
       b, m.x + xo, m.y + yo,
         m.dur, m.chain,
           seqidxstartr) 
     end
    end
    
    
    -- left
    if m.x > 1 then
     _breakgarb(-1, 0)
    end
    
    if m.x < 6 then
      _breakgarb(1, 0)
    end
    
    if m.y > 1 then
     _breakgarb(0, -1)
    end
    
    if m.y < 12 then
     _breakgarb(0, 1)
    end
    
   end
   
  end
  --transfer to active match
 end
 
 local activematches = {}
 
 for m in all(b.matchrecs) do 
  local keep = true
  if m.dur > 0 then
   local bk = board_getrow(b,
     m.y)[m.x]
   
   bk.count = bk.count + 1
   
   if bk.count >= m.dur then
    m.dur = 0
    -- postclearholdframes
    bk.count = 3
    if bk.state == bs_matching
      then
     bk.state =
       bs_postclearhold
     
     
     bk.btype = 0
     bk.chain = 0
     
     -- walk up and max chain
     for y = m.y - 1, 1, -1 do
      local runbk =
        board_getrow(b, y)[m.x]
       
      if runbk.btype == 0 or
        (runbk.state != bs_idle
        and runbk.state !=
          bs_garbage) then
       break
      end
      
      runbk.chain = max(
        runbk.chain, m.chain)
     end
     
    elseif bk.state ==
      bs_garbagematching then
     bk.state =
       bs_postclearhold 
     bk.chain = max(bk.chain,
       m.chain)
     
     bk.fallframe = frame
    
    end
   elseif bk.count == bk.count2
     then
    m.puffcount = 0
    --sfxpop
    sfx(0, -1, min(
      m.seqidx, 31), 1)
   end
  
  end
  
  if m.puffcount != 255 then
   if m.puffcount >= 18 then
    if m.dur == 0 then
     keep = false
     
    end
   else
    m.puffcount += 1
   end
  end
  
  
  if keep then
   add(activematches, m)
  end
 end
 
 b.matchrecs = activematches
 
 local holdtotal = 0
 
 local lastbub
 
 local buboffset = 0
 
 
 local mx =
    (newmatchminx - 1) * 8
      + b.x - 4
 local my =
    (newmatchminy - 1) * 8
      + board_getyorg(b) - 4
 
 
 if metalcount >= 3 then  
  matchcount -= metalcount
  if matchcount <= 0 then
   newmatchchainmax = 0
  end
  
  
  local bub = matchbub_new(
    0, matchcount, mx, my)
  add(matchbubs, bub)
  
  bub.matchcount = 0
  bub.matchchain =
    metalcount - 2

  matchsfx(bub.matchchain)

  if b.target then
   bub.target = b.target 
  else
   bub.target = b
   bub.targetpos =
     {70, b.y}
  end
    
 end

 
 if matchcount > 3 then
  lastbub = matchbub_new(
    0, matchcount, mx, my)
  add(matchbubs, lastbub)
 
  buboffset = 11
  holdtotal = matchcount - 1
 end
 
 if newmatchchainmax > 1 then
  
  my -= buboffset
  
  lastbub = matchbub_new(1,
    newmatchchainmax, mx, my)
  add(matchbubs, lastbub)
  
  if holdtotal == 0 then
   holdtotal = 2
  end
  
  holdtotal *= newmatchchainmax
  
 end
 
 if holdtotal > 0 then
  holdtotal = holdtotal *
    autoraiseholdmult[b.level]
   
  b.autoraisehold += holdtotal
  
 end
 
 if lastbub then
  if b.target then
   lastbub.target = b.target
  else
   lastbub.target = b
   lastbub.targetpos =
     {70, b.y}
  end
  
  lastbub.matchcount = 
    matchcount
  lastbub.matchchain =
    newmatchchainmax

  matchsfx(newmatchchainmax)

 end
 
 if garbagefallarea > 0 then
  if garbagefallarea > 4 then
   b.shakevalues = shakelarge
  else
   b.shakevalues = shakesmall
  end
  b.shakecount = #b.shakevalues
 end
 
 board_pendingstep(b)
 
 local anyattop = false
 local toprow =
   board_getrow(b, 1)
 for i = 1, 6 do
  if toprow[i].btype > 0 then
   anyattop = true
   break
  end
 end
 
 if anyattop then
  if b.autoraisehold == 0 and
    #b.matchrecs == 0 then
   b.toppedoutframecount += 1
   
   -- toppedoutboardframelimit
   if b.toppedoutframecount >=
     120 then
    board_lose(b) 
   end
  end
 else
  b.toppedoutframecount = 0  
 end
 
 
end


function matchsfx(n)
 sfx(4, -1, 0, min(n + 2, 7))
end

function board_lose(b)
 b.lose = true
 music(-1)
 sfx(7)
 if b.target then
  g_wins[b.target.idx] += 1 
 end
 
 for i = 1, 13 do
  local row = board_getrow(b, i)
  for j = 1, 6 do
   local bk = row[j]
   if bk.btype > 0 then
    if bk.state != bs_garbage
      and bk.state !=
        bs_garbagematching
      then
     bk.state = bs_matching
      
    else
     bk.state =
       bs_garbagematching
    end
    bk.count2 = 100
    bk.count = flashframes + 2
   end
  end
 end
 
 g_gamestate = gs_gameend
 g_gamecount = 0
 
 matchbubs = {}
 
 b.shakevalues = shakelarge
 b.shakecount = #shakelarge
 
 
end

function block_draw(b, x, y, ry,
  squashed)
 if b.btype == 0
   or b.bstate == bs_swapping
   then
  return
 end
 
 if b.state == bs_idle then
  local idx = blocktileidxs[
    b.btype]
  
  if b.count > 0 then
   idx += bounceframes[b.count]
  elseif squashed then
   idx = idx + squashframes[
     squashframe + 1]
  end

  spr(idx, x, y)
 
 
 elseif b.state == bs_matching
   then
  
  local idx = blocktileidxs[
    b.btype]
  
  if b.count < flashframes then
   if frame % 2 == 0 then
    idx += 6
   end
  elseif b.count < b.count2 then
   idx += 5
  else
   return
  end
  
  spr(idx, x, y)
 
 elseif b.state == bs_garbage
   then
  
  
  if b.garbagex == 0 and
    b.garbagey == 0 then
   
   local top = y -
     (b.garbageheight - 1) * 8
   
   local right = x +
     b.garbagewidth * 8 - 1
   
   local left = x
   local bottom = y + 7
   
   local bg = 0
   local fg = 5
   if b.btype > 10 then
    bg = 5
    fg = 0
   end
   
   rectfill(left, top, right,
     bottom, bg)
   rect(left + 1, top + 1,
     right - 1, bottom - 1, fg)
   
   palt131()
   
   local idx = 31
   if (frame % 120) < 10 then
    idx = 47
   end
   
   spr(idx,
     (right - left) / 2 +
     left - 3,
     (bottom - top) / 2 +
     top - 3, 1, 1,
      frame % 320 < 160
       )
    
   palt(13, false)
  
  end
    
 
 elseif b.state ==
   bs_garbagematching then
  
  local idx = 62
  if b.count < flashframes then
   if frame % 2 == 0 then
    idx = 63
   end
  elseif b.count < b.count2 then
  else
   idx = blocktileidxs[
    b.btype]

  end
  
  spr(idx, x, y)
  
 end
 
end

function board_getyorg(b)
 local y = b.y - b.raiseoffset
 
 if b.shakevalues then
  y = y - b.shakevalues[
    max(1, min(b.shakecount,
      #b.shakevalues))] / 2
 end

 return y
end

function puff_draw(x, y, pc)
 
 local n = pc / 17
 local g = n * 16
 local d = (n^0.75) * 16
 spr(48, x - d, y - d + g)
 spr(48, x + d, y - d + g)
 spr(48, x - d, y + d + g)
 spr(48, x + d, y + d + g)

end

function board_draw(b)
 local x = b.x
 local y = b.y
  
 palt(0, true)
 local lvlpos = 8
 if x < 63 then
  spr(69, 0, 0)
 else
  lvlpos = 111
  spr(70, 121, 0)
 end
 
 
 rectfill(lvlpos, 0,
   lvlpos + 8, 8,
   lvlcolors[b.level])
 rect(lvlpos, 0,
   lvlpos + 8, 8, 1)
 
 spr(120 + b.level, lvlpos + 1,
  1)
 
 
 palt00()
 
 
 rectfill(x - 2, y - 1,
   x + 1 + 6 * 8,
   y + 1 + 12 * 8, 13)
 
 rect(x - 1, y,
   x + 6 * 8,
   y + 1 + 12 * 8, 1)
   
 rect(x - 2, y - 1,
   x + 1 + 6 * 8,
   y + 1 + 12 * 8, 7)
   
 
 local r1 = board_getrow(b, 1)
 local r2 = board_getrow(b, 2)
 local squashed = {}

 local _sqtest = function(bk)
  if bk.btype > 0
    and bk.fallframe != frame
      then
   return true
  end
 end
 
 for i = 1, 6 do
  squashed[i] = (
    _sqtest(r1[i]) or
      _sqtest(r2[i]))
  if squashed[i] then
   g_anysquashed = true
  end
 end
 
 clip(0, y, 128, 128 - y)
 
 y -= b.raiseoffset
 
 if b.shakecount > 0 and
   b.shakevalues then
  
  b.shakecount -= 1
  y = y - b.shakevalues[
    b.shakecount + 1] / 2
 else
  b.shakevalues = nil
 end
 
 local yy = y
 
 -- draw blocks
 for ty = 1, 13 do
  local row = board_getrow(b, ty)
  local xx = x
  
  for tx = 1, 6 do
   local bk = row[tx]
   
   block_draw(bk, xx, yy, ty,
     squashed[tx])
   
   xx += 8
  end
 
  yy += 8
 end
 
 
 -- shadow
 palt(0, true)
 map(6, 4, x, yy - 8, 6, 1)
 palt00()
 
 clip()
 
 palt(12, true)
 for m in all(b.matchrecs) do 
  if m.puffcount != 255 and 
    m.puffcount < 18 then
  
   puff_draw((m.x - 1) * 8 + x,
     (m.y - 1) * 8 + y,
       m.puffcount)
   
  end
 
 end
 palt(12, false)
 
 if b.autoraisehold > 0 then
  local top = max(b.y, 128 -
    (b.autoraisehold / 2))
    
  local x = b.x - 2
  if b.x > 63 then
   x = b.x + 49
  end
  
  line(x, top, x, 127, 11) 
 
 end
 
 -- draw cursors
 if g_gamestate != gs_gameend
   then
  local cx = x + b.cursx * 8
  local cy = y + b.cursy * 8
  
  cx += b.cursbumpx
  cy += b.cursbumpy
  
  if b.cursstate == cs_swapping
    then
   local bk1, bk2 =
      board_getcursblocks(b)
    
   if bk1.btype > 0 then
    local idx = blocktileidxs[
      bk1.btype]
    
    spr(idx, cx + b.curscount * 2,
      cy)
   end
   
   if bk2.btype > 0 then
    local idx = blocktileidxs[
      bk2.btype]
      
    spr(idx, cx + 8
      - b.curscount * 2, cy)
   end
   
  end
  
  local off = 0
  if frame % 32 < 15 then
   off = 1
  end
  
  palt131()
  spr(16, cx - 4 - off,
    cy - 4 - off)
  spr(16, cx - 4 - off,
    cy + 3 + off, 1, 1,
      false, true)
  spr(16, cx + 12 + off,
    cy - 4 - off, 1, 1,
      true, false)
  spr(16, cx + 12 + off,
    cy + 3 + off, 1, 1,
      true, true)
  spr(32, cx + 4,
    cy - 4 - off, 1, 1)
  spr(32, cx + 4,
    cy + 3 + off, 1, 1,
      false, true)
 end
 
 board_drawpending(b)
 palt(13, false)
 
 if g_gamestate == gs_gamestart
   then
  
  local num =
    flr(g_gamecount/60)
  
  local w = 2
  local x = b.x + 16
  local y = b.y + 36
  
  if num == 2 then
   w = 1
   x += 6
  end
  
  palt131()
  spr(80 + num * 2, x, y,
    w, 2)
  palt(13, false)
  
 end
 
 
 if g_gamestate == gs_gameend
   then
  
  palt131()
  local y = b.y + 32
  local x = b.x + 10
  if b.lose then
   local s =
     sin(frame / 60) - 0.5
   x += s * 3
   spr(87, x, y, 1, 2)
   spr(86, x + 7, y, 1, 2)
   spr(85, x + 14, y, 1, 2)
   spr(89, x + 21, y, 1, 2)
   
  else
   local s =
     sin(frame / 30)
   y += s * 6
   x += 4
   spr(90, x, y, 2, 2)
   spr(92, x + 15, y, 1, 2)
   
  end
  palt(13, false)
  
  if g_gamecount >= 160 then
   local yy = 114 +
     (180 - g_gamecount)
   
   rect(31, yy - 1, 97, yy + 7,
    0)
   rectfill(32, yy, 96,
     yy + 6, 1)
   print("❎ to continue",
     34, yy + 1, 7)
   
  end
 end
 
 if not b.target then
  board_drawsolohud(b)
 end
 
end

function charidlefr(b)
 if b.shakevalues then
  return 3
 end
 if frame % 120 > 59 then
  
  if g_gamestate == gs_gameend
    then
    
   if b.lose then
    return 3
   end
   
   return 2
  elseif b.autoraisehold > 0 then
   return 2
  end
  
  return 1
 end
 return 0
end


function drawlabeledtext(
   x, y, label, value)
  local w = #label * 5
  local wf = w + 19
  rectfill(x, y,
    x + wf, y + 8, 1)

  print(label, x + 2, y + 2, 7)
  x += w - 2
  rectfill(x, y + 1,
    x + 20, y + 7, 13)

  print(value,
    x + 2, y + 2, 7)
end



function board_drawsolohud(b)
 local x = b.x + 60
 local y = b.y
 
 hiscore_draw(18, 0)
 
 drawlabeledtext(x, y,
   "score", b.score, 0)
 drawlabeledtext(x, y + 12,
   "speed",
     61 - b.autoraisespeed, 12)


 char_draw(g_chars[1],
   charidlefr(b), 68, 56)
 
 
 
end

function board_breakgarbage(
  b, x, y, basedur, chain,
    seqidxstartr)
 local bk =
   board_getrow(b, y)[x]
 
 if bk.state != bs_garbage then
  return 0
 end
 
 chain = max(bk.chain, chain)
 
 x -= bk.garbagex
 y += bk.garbagey
 
 bk = board_getrow(b, y)[x]
 
 if bk.state != bs_garbage then
  return 0
 end
 
 bk.state = bs_garbagematching
 
 local w = bk.garbagewidth
 local h = bk.garbageheight
 
 -- trim off top
 if y < h then
  local extrarows = h - y
  h -= extrarows
  --todo, prepend rest
 end
 
 local numblocks = w * h
 
 local hmax = 12
 local wmax = 6
 
 local dur = basedur + (
   numblocks * popoffset)
 local pad = basedur
 
 local maxdur = dur
 --local maxdurtmp = nil
 
 local matchrecs = {}
 
 local seqidx = seqidxstartr[1]
 seqidxstartr[1] += numblocks
 
 for i = 0, h - 1 do
  if y < 1 then
   break
  end
  local rx = x + (w - 1)
  
  local bk = board_getrow(
    b, y)[rx]
  
  
  local _check = function
    (xx, xo, yo)
   local bk2 =
     board_getrow(b, y + yo)[
       xx + xo]
   
   if bk2.state == bs_garbage
     and bk2.btype ==
       bk.btype then
    return max(
      board_breakgarbage(b,
        xx + xo, y + yo, dur,
          chain,
            seqidxstartr),
              maxdur)
   end
   
   return maxdur
  end
  
  
  -- check left
  if x > 1 then
   maxdur = _check(x, -1, 0)
  end
  
  
  -- check right
  if rx < wmax then
   maxdur = _check(rx, 1, 0)
  end
  
  for j = 0, w - 1 do
   
   bk = board_getrow(b, y)[rx]
   
   --check down
   if i == 0 and y < 12 then
    maxdur = _check(rx, 0, 1) 
   end
   
   --check up
   if y > 1 and i == h - 1 then
    maxdur = _check(rx, 0, -1)
   end
   
   
   local m = matchrec_new()
   m.x = rx
   m.y = y
   m.dur = dur
   m.chain = chain
   seqidx += 1
   m.seqidx = seqidx
   bk.count = 0
   bk.count2 = pad
   bk.btype = flr(rnd(
     b.blocktypecount)) + 1
   bk.state =
     bs_garbagematching
   rx -= 1
   pad += popoffset
   
   add(b.matchrecs, m)
   add(matchrecs, m)
  end
  
  y -= 1
 end
 
 if maxdur > dur then
  for mrec in all(matchrecs) do
   mrec.dur = maxdur
  end
 end
 
 return maxdur   
end

function _press(
  bidx, cidx, state)
 if cidx > 0 then
  bidx += 8
 end
 local i = shl(1, bidx)
 
 if band(i, state) > 0 then
  return true
 end
 
end

function press(bidx, cidx)
  return _press(
    bidx, cidx, cstate)
end

function newpress(bidx, cidx)
 if not press(bidx, cidx) then
  return
 end

 if _press(bidx, cidx,
   prevcstate) then
  return
 end
 
 return true
end

function maskpress(bidx, cidx)
 local v
 if cidx > 0 then
  v = shl(bidx, 8) + 255
 else
  v = shl(255, 8) + bidx
 end
 
 cstate = band(cstate, v)

end

function updategame()
 squashcount =
   (squashcount + 1) % 3
 
 if squashcount == 0 then
  squashframe =
    (squashframe + 1) % 6
 end
 
 if g_gamestate == gs_gamestart
   then
  
  if g_gamecount < 180 then
   if g_gamecount % 60 == 0 then
    sfx(5)
   end

   g_gamecount += 1
   
   if g_gamecount == 180 then
    g_gamestate = gs_gameplay
    sfx(6)
    music(0)
   end

  end
  
  return
 end
 
 foreach(boards, board_step)
 
 local newmatchbubs = {}
 for mb in all(matchbubs) do
  mb.count += 1
  
  if mb.count == 40 then
   if not mb.target then
    goto skip
   end
  
  elseif mb.count == 77 then
   
   local gt = mb.matchcount
   if gt < 10 then
    gt -= 1
   end
   
   gt *= mb.matchchain
   
   local sendfnc = 
     board_appendgarbage
     
   if mb.targetpos then
     sendfnc =
       board_addtoscore
   end
   
   if mb.matchcount == 0 then
    for i = 1, mb.matchchain do
     if mb.targetpos then
      sendfnc(
        mb.target, 9, 1)
     else
      sendfnc(
        mb.target, 6, 1).metal =
         true
     end
    end
    
   elseif gt <= 6 then
    sendfnc(
      mb.target, gt, 1)
   else
    local rem = gt % 6
    if rem == 0 or rem >= 3
      then
     
     sendfnc(
       mb.target, 6,
         flr(gt / 6))
     
     if rem > 0 then
      sendfnc(
        mb.target, rem, 1
          ).count = 0
     end
    else
     local dur = 60
     
     local trimtotal = gt - 3
     while trimtotal > 0 do
      if trimtotal < 6 then
       sendfnc(
        mb.target, trimtotal, 1
          ).count = dur
       break
      else
       sendfnc(
        mb.target, 6, 1
          ).count = dur
       
       trimtotal -= 6
      end
      dur = 0
     end
     
    end
   end
   
   goto skip
  elseif mb.count == 69 then
   if mb.target then
    
    if mb.targetpos then
     mb.dx = 
       (mb.targetpos[1] - 
         mb.x) / 8
     mb.dy = 
       (mb.targetpos[2] - 
         mb.y) / 8
    else
     mb.dx = (mb.target.x + 2 - 
       mb.x) / 8
     
     mb.dy = (mb.target.y - 16 - 
       mb.y) / 8  
    end
   end
  end
  
  if mb.dx then
   mb.x += mb.dx
   mb.y += mb.dy
  else
   
   mb.y = mb.y -
    bubdeltay[mb.count] / 2
   
   local div = 2
   if mb.x > 64 then
    div = -2
   end
   mb.x = mb.x +
     bubdeltax[mb.count] / div
   
  end
  
  add(newmatchbubs, mb)
  ::skip::
 end
 matchbubs = newmatchbubs
 
end



function matchbub_new(
  bubtype, value, x, y)
 return {
  bubtype = bubtype,
  value = value,
  x = x,
  y = y,
  count = 0
 }
end

function matchbub_draw(mb)
 if mb.count > 40 then
  if frame % 3 == 0 then
   pal(5, 7)
  end
  spr(61, mb.x, mb.y)
  pal(5, 5)
  return
 end
 
 palt131()
 palt00()
 local offset = 7
 local textoffset = 6
 local bgs = 64
 if mb.bubtype > 0 then
  pal(3, 8)
  if mb.bubtype == 2 then
   pal(3, 1)
   bgs = 67
  end
  
  offset = 8
  textoffset = 8
 end

 spr(bgs, mb.x, mb.y)
 spr(bgs, mb.x +
   offset, mb.y,
     1, 1, true, false)
 
 spr(bgs + 1, mb.x, mb.y + 8)
 spr(bgs + 1, mb.x + offset,
    mb.y + 8, 1, 1, true, false)
 
 if mb.bubtype > 0 then
  spr(66, mb.x + 4, mb.y + 6)
 end
 
 local v = mb.value
 if v > 9 then
  v = "+"
 elseif v == 0 then
  v = "!"
 end
 print(v,
   mb.x + textoffset,
     mb.y + 6, 0)
 
 print(v,
   mb.x + textoffset,
     mb.y + 5, 7)
 
 pal()
 palt()
end


function pendinggarbage_new(
  width, height, forcex)
 
 local pg = {
  count = 60,
  width = width,
  height = height,
  forcex = forcex
 }
 
 if height > 1 then
  pg.bub = matchbub_new(
    2, height, 0, 0)
 end
 
 return pg
end

function board_appendgarbage(b,
  width, height, forcex)
 
 local pg = pendinggarbage_new(
   width, height, f0rcex)
 add(b.pendinggarbage, pg)
 
 return pg 
end


function board_addtoscore(b,
  width, height)
 b.score += width * height

	local l = g_levels[1]
 hiscores[l] = max(
   hiscores[l],
     b.score)

 dset(l - 1, hiscores[l])

 return {}
end

function board_pendingstep(b)

 if b.pendingoffset > 0 then
  b.pendingoffset -= 1
 end
 
 
 while #b.pendinggarbage > 0 do
  local pg =
    b.pendinggarbage[1]
  
  if pg.count > 0 then
   pg.count -= 1
   return
  end 
  
  local row =
    board_getrow(b, 1)
  
  local dropx
  if b.forcex then
   for i = b.forcex,
     b.forcex + pg.width - 1 do
    
    if row[i].state != bs_idle
      or row[i].btype > 0 then
     return
    end  
    dropx = b.forcex
   end
  else
   local possiblespots = {}
   
   for i = 1, 7 - pg.width do
    
    for j = 1, pg.width do
     local bk = row[i + j - 1]
     
     if bk.state != bs_idle or
       bk.btype != 0 then
      goto cont 
     end
     
    end  
    
    add(possiblespots, i)
    
    ::cont::
   end
   
   if #possiblespots > 0 then
    dropx = possiblespots[
      flr(rnd(
        #possiblespots)) + 1]
   end
  end
  
  if not dropx then
   return
  end
  
  del(b.pendinggarbage, pg)
  
  board_addgarbage(b, dropx, 1,
    pg.width, pg.height)
  b.pendingoffset += 8
  
  if pg.metal then
   local row =
     board_getrow(b, 1)
   
   for i = 1, 6 do
    row[i].btype = 11
   end
  end
  
  
 end
 
end

function board_drawpending(b)
 local x = b.x
   + b.pendingoffset
 
 if b.idx > 1 then
  x += 10
 end

 local y = b.y - 11
 for i = 1, min(4,
   #b.pendinggarbage) do
  
  palt131()
  --palt00()
  
  local pg =
    b.pendinggarbage[i]
  
  if pg.bub then
   
   pg.bub.x = x - 1
   pg.bub.y = y - 5
   
   matchbub_draw(pg.bub)
   x += 11
   
   palt00()
  else
   
   spr(53 + pg.width, x, y)
   x += 9
  end
  
  
 end

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

__gfx__
0000000082222220505050508222222082828220888888200222222087777778e222222010000000e2222220e2eee220eeeeee2002222220e777777e00700000
000000002282822005050505222222202888882028888820222222227787877822eee22010000000222222202eeeee202eeeee202222222277eee77e00770000
00700700288888205050505022222220288888202288822022822822788888782eeeee2011000000222222202eeeee202eeeee2022e22e227eeeee7e00717000
00077000288888200505050528828820228882202228222022822822788888782eeeee20110000002eeeee202eeeee2022eee22022e22e227eeeee7e00711700
00077000228882205050505088888880222822202222222022222222778887782eeeee2001100000eeeeeee022eee22022222220222222227eeeee7e00717100
007007002228222005050505288888202222222022222220228888227778777822eee22000110000eeeeeee0222222202222222022eeee2277eee77e00771000
000000002222222050505050228882202222222022222220222222227777777822222220000111002eeeee202222222022222220222222227777777e00710000
0000000000000000050505050000000000000000000000000222222088888888000000000000000000000000000000000000000002222220eeeeeeee00100000
ddddddddc111111000000000c1111110c11c1110c1ccc11001111110c777777ca999999000000000a9999990aaaaaa90aaaaaa9009999990a777777adddddddd
dddddddd111c1110001110001111111011ccc1101ccccc1011111111777c777c9aaaaa9000000000999999909aaaaa9099aaa990999999997aaaaa7adddddddd
dd00000d11ccc11000001100111111101ccccc1011ccc11011c11c1177ccc77c9aaaaa90000000009999999099aaa99099aaa99099a99a997aaaaa7adddddddd
dd07770d1ccccc10000001101111111011ccc110111c111011c11c117ccccc7c99aaa990000000009999999099aaa990999a999099a99a9977aaa77ad17dd17d
dd07000d11ccc110000000111ccccc10111c1110111111101111111177ccc77c99aaa99000000000aaaaaaa0999a9990999999909999999977aaa77ad77dd77d
dd070ddd111c111000000011ccccccc0111111101111111011cccc11777c777c999a9990000000009aaaaa90999999909999999099aaaa99777a777adddddddd
dd000ddd11111110000000011ccccc101111111011111110111111117777777c999999900000000099aaa9909999999099999990999999997777777adddddddd
dddddddd000000000000000100000000000000000000000001111110cccccccc000000000000000000000000000000000000000009999990aaaaaaaadddddddd
ddddddddb333333000000001b3333330b33b3330b3bbb33003333330b777777b65555550000000006555555065565550655655500555555067777776dddddddd
dddddddd333b3330000000013333333033bbb33033bbb33033333333777b777b55565550000000005555555055565550555655505555555577767776dddddddd
d00000dd33bbb330000000013333333033bbb3303bbbbb3033b33b3377bbb77b55565550000000005555555055565550555555505565565577767776dddddddd
d07770dd33bbb33000000001333333303bbbbb303bbbbb3033b33b3377bbb77b55565550000000005566655055555550555655505565565577767776dddddddd
d00700dd3bbbbb30000000013bbbbb303bbbbb3033333330333333337bbbbb7b55555550000000005566655055565550555555505555555577777776d55dd55d
dd070ddd3bbbbb3000000001bbbbbbb0333333303333333033bbbb337bbbbb7b55565550000000005555555055555550555555505566665577767776dddddddd
dd000ddd3333333000000001bbbbbbb03333333033333330333333337777777b55555550000000005566655055555550555555505555555577777776dddddddd
dddddddd000000000000000100000000000000000000000003333330bbbbbbbb00000000000000000000000000000000000000000555555066666666dddddddd
cccccccc94444440cccccccc9444444099949940999999400444444097777779dddddddddddddddddddddddddddddddd0000000d005555005555555555555555
cccccccc49949940cccccccc4444444049999940449994404444444479979979dddddddddddddddddddddddddddddddd0101010d051111505000000557777775
ccc76ccc49999940cccccccc4444444044999440499999404494494479999979ddddddddd00000dd0000000d0000000d0000000d515555155050050557577575
cc7665cc44999440cccccccc9994999049999940499499404494494477999779ddddddddd01010dd0101010d0101010d5010105d515555155050050557577575
cc6655cc49999940cccccccc99999990499499404444444044444444799999790000000dd00000dd0000000d0000000d0000000d515555155000000557777775
ccc55ccc49949940cccccccc99999990444444404444444044999944799799790101010dd01010dd5010105d0101010d0101010d515555155055550557555575
cccccccc44444440cccccccc99949990444444404444444044444444777777790000000dd00000ddd00000dd0000000d0000000d051111505000000557777775
cccccccc00000000cccccccc00000000000000000000000004444440999999995555555dd55555ddd55555dd5555555d5555555d005555005555555555555555
dddddddddd7333337d7dddddddddddddd050000011111110222222207777700770077770077770000077777007777700007777700077770077000770cccccc11
dddddddddd733333070dddddddddddddd05000001ccccc102eeeee207777770770777770777777000077777707777700007777770777777077700770cccc1170
dddddddddd733333707ddddddd000000d05000001c111c10211111207700770770770000770077000077007707700000007700770770077077770770ccc17700
dddd7777dd0733330d0dddddd0555555d05555551cc1cc102e1e1e206666660660660000660066000066006606666000006666660660066066666660cc170000
ddd73333ddd07777ddddddddd0500000dd0000001cc1cc102e1e1e206666600660660000660066000066006606600000006666600660066066066660c1700000
dd733333dddd0000ddddddddd0500000dddddddd1c111c10211111206600000660666660666666000066666606666600006600000666666066006660c1700000
dd733333ddddddddddddddddd0500000dddddddd1ccccc102eeeee20660000066006666006666000006666600666660000660000006666006600066010000000
dd733333ddddddddddddddddd0500000dddddddd1111111022222220000000000000000000000000000000000000000000000000000000000000000010000000
dddddddddddddddddddddddddddddddddddddddddd00000ddd000ddd0000dddd0000000d0000000d0000d0000d0000dd00000ddd11cccccc0000000110000000
ddd00000000dddddddd00000000ddddd00000dddd077770dd07770dd0770dddd0770770d0777770d0770d0770d0770dd077770dd0011cccc0000000110000000
ddd077777770ddddddd077777770dddd07770ddd0777770d0777770d0770dddd0770770d0777770d0770d0770d0770dd0777770d00001ccc0000001cc1000000
ddd0777777770dddddd0777777770ddd07770ddd0770000d0770770d0770dddd0770770d0770000d0770d0770d0770dd0770770d000001cc0000001cc1000000
ddd0000000770dddddd0000000770ddd00770ddd0770555d0770770d0770dddd0770770d0770555d0770d0770d0770dd0770770d0000001c000001cccc100000
ddd5555550770dddddd5555550770ddd50770ddd07700ddd0770770d0770dddd0770770d077000dd0770d0770d0770dd0770770d0000001c00001cccccc10000
dddd000000770dddddddd00000770dddd0770ddd077770dd0770770d0770dddd0770770d077770dd0770d0770d0770dd0770770d000000010011cccccccc1100
dddd077777705ddddddd077777770dddd0770ddd5077770d0770770d0770dddd0770770d077770dd077000770d0770dd0770770d0000000111cccccccccccc11
dddd07777770ddddddd0777777705dddd0770dddd500770d0770770d0770dddd0770770d077000dd077070770d0770dd0770770d000000001111111100000000
dddd000000770dddddd077000005ddddd0770dddddd0770d0770770d0770dddd0770770d077055dd077070770d0770dd0770770d000000000000000000000000
dddd555550770dddddd07705555dddddd0770ddd0000770d0770770d0770000d0777770d0770000d077070770d0770dd0770770d000000000000000000000000
ddd0000000770dddddd0770000000ddd007700dd0777770d0777770d0777770d5077705d0777770d077777770d0770dd0770770d000000000000000000000000
ddd0777777770dddddd0777777770ddd077770dd0777705d5077705d0777770dd50705dd0777770d507707705d0770dd0770770d000000000000000000000000
ddd0777777705dddddd0777777770ddd077770dd000005ddd50005dd0000000ddd505ddd0000000dd5000005dd0000dd0000000d000000000000000000000000
ddd000000005ddddddd0000000000ddd000000dd55555ddddd555ddd555555ddddd5dddd5555555ddd55555ddd5555dd5555555d000000000000000000000000
ddd55555555dddddddd5555555555ddd555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000011111111
00000000000000000000000000007070000000000000007000000000000000000000000000000000000000000000000000000000000000000000000100000000
000070000000000000000000000007070000000000070000000000000c000c000e000e000011110001101100010001000d000d00000111000000000100000000
70000000000077777000000000777000000070007777777007700000000000000000000000100000011111000100010000000000001177000000001100100000
70070000000000007000000000000000007700000007000000070070000c000c000e000e001100000101010001111100000d000d011700000000001100100000
77700077777000007007777707777700777000000707070000000700000000000000000000100000010001000100010000000000117000000000011000110000
700000000000000070000000000700000070000070070070000070000c000c000e000e000011110001000100010001000d000d00117000000000110000011000
70000000000077777000000000070000007000000007000000070000000000000000000000000000000000000000000000000000170000000011100000001111
07777000000000000000000000700000000000000070000007700000000c000c000e000e000000000000000000000000000d000d170000000000000000000011
ccccccccccccccccdddddddddddddddd0000000000000000222214412222222288888888888888883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccddddddddd00000dd0000000000000000222114411111122288422222888888883333333333333333eeeeeeeeeeeeeeee9999990009999999
ccccffccccccffccddddddd00000000d0006666666666000221499999999412288442222288888883333331111113333eeee222222222eee9999901220999999
ccccffccccccffccddddddd00000000000066666666660002149999aaaa994128242249924888888333331fff9991333eee22222222222ee9990012244009999
ccffffffffffffccddddddd44444400000066766667660002199999aaaaa9912842ffff99248888833331fffff999133ee222222222222ee9901012444040999
ccffffffffffffccddddddd6774444400006767667676000221dddddddaa991284fffff112f888883331ff77ff779913ee22ff22222222ee9990102440409999
cc11ffffff11ffccdddddd47074677440006666666666000221cccc777ca988184ffff1ff29888883331f777f7779913ee21fff1222222ee9999010004000999
cc11ffffff11ffccdd222247744707440006666666666000221c1cc7c7ca98818811fff1f42888883331f711f7119913ee21fff1f2f22eee9990801241080999
cceeffffffffeeccd2222044444777400006666666666000221c1cc7c7ca9881888f1ffff4288888331cc611c611c213eeeffffff2feeeee999080eef7000999
cceeffffffffeecc12442004224444400006667767666000221cccc777ca98818888ffff922888883314444444442213eeeefffee2eeeeee99900200000f0099
cccccc222222cccc11444000024444000006666666666000221ddddcccaa94128888ff44422118883312424242429133eeeee888888eeeee9990f05670d01099
cccccc222222cccc111111000000000200066666666660002199999aaaaa991288888442421111183331ffffff999133eeeee8887788eeee9990000000a79099
cccccc888888cccc111111111000002266700666666007662199194aaaaa9912888888444911111133331ffff9911333eeeee2887788eeee9999901240a79099
cccccc888888cccc11111111112444426666666666666666221111555551112288888112991111113333311111133333eeee222e222eeeee9999900040dd1099
ccccccffccffccccd1111111111444446666666666666666222221d5ddd5122288881111f11111113333333333333333eeeeeeeeeeeeeeee9999999900000099
ccccccffccffccccdddd1111111144416666666666666666222221d5dddd512288881111111111113333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccdddddddddddddddd0000000000000000222214412222222288888888888888883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccdddddddd00000ddd0000000076660000222114411111122288888888888888883333333333333333eeee222222222eee9999990009999999
ccccccccccccccccdddddd00000000dd0000766666660000221499999999412288884422222888883333311111333333eee22222222222ee9999901220999999
ccccffccccccffccdddddd000000000d00666666667670002149999aaaa99412888824422224888833311ff999133333ee222222222222ee9990012244009999
ccccffccccccffccdddddd444444000d00666766676760002199999aaaaa9912888444ff49224888331ffffff9913333ee22ff22222222ee9901012444040999
ccffffffffffffccdddddd67444444000066767666666000221dddddddaa991288842ffff9924888331f77ff77991333ee21fff1222222ee9990102440409999
ccffffffffffffccddddd407746744400076666666666000221cccc777ca98818888fffffff2f88831f777f777991333ee21fff1f2f22eee9999010004000999
cc11ffffff11ffccdd222477740774400006666666666700221cccc777ca9881888811ff11f2988831f711f711991333eeeffffff2feeeee9990801241080999
cc11ffffff11ffccd2220444447774000006666666766600221111ccccca988188888f1ffff4288831c611c611cc1333eeeefffee2eeeeee999080eef7000099
cceeffffffffeecc124400422444440d0007667767666600221cccc777ca988188888fffff9428883144444444421333eeeee888888eeeee9999020000d01099
cceeffffffffeecc11440002244440020000666666666600221ddddcccaa9412888888f4442221883142422422291333eeeee8887788eeee9990005670a79099
cccccc222222cccc111110000000002200006666666600762199999aaaaa99128888884424221111331f999999991333eeee28887788eeee9990f00000a79099
ccccff888888cccc111111110000022200000066666666662199194aaaaa99128888812444911111331fffff99913333eeee2288888eeeee9999001240dd1099
ccccff888888cccc111111111124444200766666666666662211115555511122888811119f9111113331f99999133333eeeee22ee22eeeee9999901200000099
ccccccccccffccccd1111111111444446666666666666666222221d5ddd51222888811111f1111113333111111333333eeeeeeeeeeeeeeee9999900099999999
ccccccccccffccccdddd1111111144416666666666666666222221d5dddd512288881111111111113333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccffccccccffccdddddddd00000ddd6000666006000060222221122222222288888888888888883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccffccccccffccdddddd00000000dd0000060066600000222214412222222288888882442888883333331111113333eeeeeeeeeeeeeeee9999000009999999
ccffffffffffffccdddddd000000000d660600000600606622211441111112228888882242222888333331fff9991333eee222222222eeee9990124420999999
cc111fffff111fccdddddd444444000d66000000000000662214999999994122888888424222228833331fffff999133ee222222222222ee9990124440999999
cc1f1fffff1f1fccdddddd000444440d66066666666660662149999aaaa994128888884ffff422883331ffffff999913ee222222222222ee9001112222200999
ccffffffffffffccddddd4040400044d67066666666660762199999aaaaa9912888888ffffff92483331f111ff111913ee222222222222ee90f0000000009999
cceffffffffffeccdd44d4444404044d6006676666766006221dddddddaa9912888888f1fff194983331f1f1ff191913ee2222f2222222ee90e0014410800999
cceeffffffffeeccdd4404424444440d6006767667676006221cccc777ca98818888881f1f1f12f8331cc6ffc699c213ee22ffffff2f2eee99050eeff0020999
cccccc222222ccccd22200422444440d6006666666666006221d1dc6c6ca9881888888ffffff922833162b242429b213eee111f1112feeee99900e00f00f0099
cccccc222222cccc122200002244400270066666666660072211c1cc7cca9881888888fffff992883314444444442213ee71f1f1f1877eee9999000000d01099
ccccff888888cccc11122000000000220006666666666000221cccc777ca988188f88894224942883312424288429133ee77ffffff877eee9999056770a79099
ccccff888888cccc11111122000444420006677777766006221ddddcccaa941288fff884224428883331ffff88999133eeeee888888eeeee9999000000a79099
ccccccccccccffcc111111112224444406066777777660602199999aaaaa991288fff8144442288833331ffff9911333eeee88228888eeee9990111240dd1099
ccccccccccccffcc111111111122444200066677776660002155194a555a991288ff9112442111883333311111133333eeee82222888eeee9990009900000099
ccccccccccccccccd1111111111222226670066666600766167611516761112288111111991111883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccdddd1111111122216666666666666666177711d17771512288111111f11111183333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccdddddddd0ddd0ddd0000000000077000222211222227222288888888888888883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccd0dd0ddd0dd0dddd0000007666077000272144122222222288888888888888883333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccccccccccccdd0dd0ddddddddd00076666666077700221144111111227288888888888888883333333333333333eeee2e222e2eeeee9999999999999999
ccccccccccccccccddd0ddd00000dd0d6666666676707700214999999994122288422222288888883333331111113333eee222222222eeee9999000000099999
ccccccccccccccccddddd00000000ddd6667666767607700149999aaaa9941228844222222888888333331fff9991333ee222222222222ee9990201220409999
ccccccccccccccccd000d000000000d06676766676600000199999aaaaa99122824224992248888833331fffff999133ee22fff222222eee9902012244040999
ccccffccccccffccddddd444444000dd7667666666600770214444888aa991228442ffff922888883331fffffff99913ee2fff1122f222ee9902012444040999
ccccffccccccffccdd222040444440dd066666666667077021eeeefffea98812848ffff1f92f88883331f1f1f1f19913ee21ff11f2f22eee9990202440400999
ccffffffffffffccd22244044040444d0666677777660000211eeeffeea988128881ff11192988883331ff1fff199913eeeffffff22e2eee9990020004000099
ccffffffffffffcc122240404404444d076677777766000021e1eefefea9881288111ff1f9288888331cc1c1c161c213ee2ffff22effeeee990e002241d01099
cc1f1ffff1f1ffcc144044444040402d006677777666000021eeeefffea988128881fffff42888883312424242429133eef2888888ffeeee990f056770a79099
ccf1ffffff1fffcc14400422444440220066666666007666218888eeeaa941228888f422422118883331ffffff999133eeee888888eeeeee9900000000a79099
cc1e1ffff1f1eecc11400002244400226700666666666666199999aaaaa99122888882444211111833331ffff9911333eee22888882eeeee9999011240dd1099
cceeffffffffeecc11110000000002226666666666666666199194aaaaa9912288888844491111183333311111133333eeee22eee22eeeee9999000900000099
cccccc222222ccccd1111110000044426666666666666666211115555551122288888112991111113333333333333333eeeeeeeeeeeeeeee9999999999999999
ccccccffccffccccdddd1111111144416666666666666666222221d5dddd512288888111f11111113333333333333333eeeeeeeeeeeeeeee9999999999999999
__label__
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
57777777777777777777777777777777777777777777777777777555555555555555555555577777777777777777777777777777777777777777777777777775
57111111111111111111111111111111111111111111111111117555555555555555555555571111111111111111111111111111111111111111111111111175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
571dddddddddddddddddddddddddddddddddddddddddddddddd17555555555555555555555571dddddddddddddddddddddddddddddddddddddddddddddddd175
57182222220e2222220ddddddddddddddddc1111110944444401755555555555555555555557182222220e2222220ddddddddddddddddc111111094444440175
5712282822022eee220dddddddddddddddd111c111049949940175555555555555555555555712282822022eee220dddddddddddddddd111c111049949940175
571288888202eeeee20dddddddddddddddd11ccc1104999994017555555555555555555555571288888202eeeee20dddddddddddddddd11ccc11049999940175
571288888202eeeee20dddddddddddddddd1ccccc104499944017555555555555555555555571288888202eeeee20dddddddddddddddd1ccccc1044999440175
571228882202eeeee20dddddddddddddddd11ccc1104999994017555555555555555555555571228882202eeeee20dddddddddddddddd11ccc11049999940175
5712228222022eee220dddddddddddddddd111c111049949940175555555555555555555555712228222022eee220dddddddddddddddd111c111049949940175
500000220000022200000dddddddddddddd111111104444444017555555555555555555555500000220000022200000dddddddddddddd1111111044444440175
507770000777000007770dddddddddddddd000000000000000017555555555555555555555507770000777000007770dddddddddddddd0000000000000000175
507000990070033300070dddddddddddddd82222220b333333017555555555555555555555507000990070033300070dddddddddddddd82222220b3333330175
5070aaaaa07033b333070dddddddddddddd22828220333b3330175555555555555555555555070aaaaa07033b333070dddddddddddddd22828220333b3330175
5000aaaaa0003bbb33000dddddddddddddd2888882033bbb330175555555555555555555555000aaaaa0003bbb33000dddddddddddddd2888882033bbb330175
57199aaa99033bbb330dddddddddddddddd2888882033bbb3301755555555555555555555557199aaa99033bbb330dddddddddddddddd2888882033bbb330175
50009aaa9000bbbbb3000dddddddddddddd228882203bbbbb301755555555555555555555550009aaa9000bbbbb3000dddddddddddddd228882203bbbbb30175
507099a99070bbbbb3070dddddddddddddd222822203bbbbb3017555555555555555555555507099a99070bbbbb3070dddddddddddddd222822203bbbbb30175
507000990070033300070dddddddddddddd222222203333333017555555555555555555555507000990070033300070dddddddddddddd2222222033333330175
507770000777000007770dddddddddddddd000000000000000017555555555555555555555507770000777000007770dddddddddddddd0000000000000000175
500000220000099900000dddddddddddddde2222220e222222017555555555555555555555500000220000099900000dddddddddddddde2222220e2222220175
57122eee2209aaaaa90dddddddddddddddd22eee22022eee2201755555555555555555555557122eee2209aaaaa90dddddddddddddddd22eee22022eee220175
5712eeeee209aaaaa90dddddddddddddddd2eeeee202eeeee20175555555555555555555555712eeeee209aaaaa90dddddddddddddddd2eeeee202eeeee20175
5712eeeee2099aaa990dddddddddddddddd2eeeee202eeeee20175555555555555555555555712eeeee2099aaa990dddddddddddddddd2eeeee202eeeee20175
5712eeeee2099aaa990dddddddddddddddd2eeeee202eeeee20175555555555555555555555712eeeee2099aaa990dddddddddddddddd2eeeee202eeeee20175
57122eee220999a9990dddddddddddddddd22eee22022eee2201755555555555555555555557122eee220999a9990dddddddddddddddd22eee22022eee220175
5712222222099999990dddddddddddddddd2222222022222220175555555555555555555555712222222099999990dddddddddddddddd2222222022222220175
5710000000000000000dddddddddddddddd0000000000000000175555555555555555555555710000000000000000dddddddddddddddd0000000000000000175
571a9999990a9999990ddddddddddddddddb3333330b333333017555555555555555555555571a9999990a9999990ddddddddddddddddb3333330b3333330175
5719aaaaa909aaaaa90dddddddddddddddd333b3330333b3330175555555555555555555555719aaaaa909aaaaa90dddddddddddddddd333b3330333b3330175
5719aaaaa909aaaaa90dddddddddddddddd33bbb33033bbb330175555555555555555555555719aaaaa909aaaaa90dddddddddddddddd33bbb33033bbb330175
57199aaa99099aaa990dddddddddddddddd33bbb33033bbb3301755555555555555555555557199aaa99099aaa990dddddddddddddddd33bbb33033bbb330175
57199aaa99099aaa990dddddddddddddddd3bbbbb303bbbbb301755555555555555555555557199aaa99099aaa990dddddddddddddddd3bbbbb303bbbbb30175
571999a9990999a9990dddddddddddddddd3bbbbb303bbbbb3017555555555555555555555571999a9990999a9990dddddddddddddddd3bbbbb303bbbbb30175
5719999999099999990dddddddddddddddd3333333033333330175555555555555555555555719999999099999990dddddddddddddddd3333333033333330175
5710000000000000000dddddddddddddddd0000000000000000175555555555555555555555710000000000000000dddddddddddddddd0000000000000000175
571b3333330e222222082222220b3333330c1111110b333333017555555555555555555555571b3333330e222222082222220b3333330c1111110b3333330175
571333b333022eee22022828220333b3330111c1110333b333017555555555555555555555571333b333022eee22022828220333b3330111c1110333b3330175
57133bbb3302eeeee202888882033bbb33011ccc11033bbb3301755555555555555555555557133bbb3302eeeee202888882033bbb33011ccc11033bbb330175
57133bbb3302eeeee202888882033bbb3301ccccc1033bbb3301755555555555555555555557133bbb3302eeeee202888882033bbb3301ccccc1033bbb330175
5713bbbbb302eeeee20228882203bbbbb3011ccc1103bbbbb30175555555555555555555555713bbbbb302eeeee20228882203bbbbb3011ccc1103bbbbb30175
5713bbbbb3022eee220222822203bbbbb30111c11103bbbbb30175555555555555555555555713bbbbb3022eee220222822203bbbbb30111c11103bbbbb30175
57133333330222222202222222033333330111111103333333017555555555555555555555571333333302222222022222220333333301111111033333330175
57100000000000000000000000000000000000000000000000017555555555555555555555571000000000000000000000000000000000000000000000000175
571c11111109444444082222220c1111110e22222209444444017555555555555555555555571c11111109444444082222220c1111110e222222094444440175
571111c11104994994022828220111c111022eee2204994994017555555555555555555555571111c11104994994022828220111c111022eee22049949940175
57111ccc110499999402888882011ccc1102eeeee20499999401755555555555555555555557111ccc110499999402888882011ccc1102eeeee2049999940175
5711ccccc1044999440288888201ccccc102eeeee2044999440175555555555555555555555711ccccc1044999440288888201ccccc102eeeee2044999440175
57111ccc110499999402288822011ccc1102eeeee20499999401755555555555555555555557111ccc110499999402288822011ccc1102eeeee2049999940175
571111c11104994994022282220111c111022eee2204994994017555555555555555555555571111c11104994994022282220111c111022eee22049949940175
57111111110444444402222222011111110222222204444444017555555555555555555555571111111104444444022222220111111102222222044444440175
57100000000000000000000000000000000000000000000000017555555555555555555555571000000000000000000000000000000000000000000000000175
571a9999990a999999094444440c1111110c1111110b333333017555555555555555555555571a9999990a999999094444440c1111110c1111110b3333330175
5719aaaaa909aaaaa9049949940111c1110111c1110333b3330175555555555555555555555719aaaaa909aaaaa9049949940111c1110111c1110333b3330175
5719aaaaa909aaaaa904999994011ccc11011ccc11033bbb330175555555555555555555555719aaaaa909aaaaa904999994011ccc11011ccc11033bbb330175
57199aaa99099aaa990449994401ccccc101ccccc1033bbb3301755555555555555555555557199aaa99099aaa990449994401ccccc101ccccc1033bbb330175
57199aaa99099aaa9904999994011ccc11011ccc1103bbbbb301755555555555555555555557199aaa99099aaa9904999994011ccc11011ccc1103bbbbb30175
571999a9990999a999049949940111c1110111c11103bbbbb3017555555555555555555555571999a9990999a999049949940111c1110111c11103bbbbb30175
57199999990999999904444444011111110111111103333333017555555555555555555555571999999909999999044444440111111101111111033333330175
57100000000000000000000000000000000000000000000000017555555555555555555555571000000000000000000000000000000000000000000000000175
57159595950525252505353535059595950545454505353535017555555555555555555555571595959505252525053535350595959505454545053535350175
57195a5a595258585253535353595a5a59545959545353535351755555555555555555555557195a5a595258585253535353595a5a5954595954535353535175
5715a5a5a5058585850535b53505a5a5a5059595950535b5350175555555555555555555555715a5a5a5058585850535b53505a5a5a5059595950535b5350175
57195a5a5952585852535b5b53595a5a5954595954535b5b5351755555555555555555555557195a5a5952585852535b5b53595a5a5954595954535b5b535175

__map__
777778787c7c324f6e5d3232324f6e5d324f5d32320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c4f6d6d7e6e5d4f096d224f6d7e6e5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c5f7d6d6d7f5e5f6f6f5e5f6f6f6f5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c325f6f6f5e324f6e6e6e5d4f6e5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0202020202025f6f6f6f5e5f6f5e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0118081121010108183111080131082100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c3121011808112118011801311101210800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0831110101113121211101312131013100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c2108182131110801083118011818212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c1801113108011131210108111108180100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0821311121211801180821180108112100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c1811212101111808213111180821311800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000600000775008750097500a7500b7500c7500d7500e7500f750107501175012750137501475015750167501775018750197501a7501b7501c7501d7501e7501f75020750217502275023750247502575026750
0002000007610096100c6100461018600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000302002000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000f3101c3101f3102132023330263402835000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001d03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002903129031290312903129031290312903129031290312902129021290112901329000290002900029000290002900029000000000000000000000000000000000000000000000000000000000000000
000700000262105631086410865107641056310462103611026010060500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00001804503300003000030017045000000000000000180450000000000000001704500000000000000000000000000000000000240450000000000000002304500000000000000000000000000000000000
000c00000c03000000000000000000000000000000000000100300000000000000001103000000000000000013030000000000000000000000000000000000001103000000000000000000000000000000000000
010c00001303503300003000030000000000000000000000000000000000000000000000000000000000000013035000000000000000000000000000000000001f03500000000000000000000000000000000000
000c0000070400000000000000000000000000000000000011040000000000000000100400000000000000000e040000000000000000000000000000000000000b0400000000000000000c040000000000000000
0106000011050000000000000000100500000000000000000e0500000000000000001005000000000000000011050000000000000000100500000000000000000e05000000000000000010050000000000000000
000600000c0530000000000000000c0530000000000000000c0530000000000000000c05300000000000000018053000001805300000180530000000000000001805300000000000000018053000000000000000
__music__
01 0b0a4344
00 0b0a4344
02 0c0d4344
03 0e0f4344


pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

bounceframecount = 10
coyotehangtime = 12
manualraiserepeatframes = 5
squashholdframes = 3
flashframes = 45
faceframes = 26
flashandfaceframes = 71
popoffset = 9
chainresetcount = 7
postclearholdframes = 3

bs_idle = 0
bs_matching = 1
bs_swapping = 2
bs_coyote = 3
bs_postclearhold = 4
bs_garbage = 5
bs_garbagematching = 6

blocktileidxs = {
  1, 17, 33, 49, 8, 24, 40
}

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
 	fallenonce=0,
 	garbagex=0,
 	garbagey=0,
 	garbagewidth=0,
 	garbageheight=0,
 }
end

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

 b.blocktypecount = 6


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
   if y < 10 then
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



function _cursdir(b, bidx)
 
 if not press(bidx, b.contidx)
   then return false end
  
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

 return false
end

function stateisswappable(s)
 if s == bs_idle
   or s == bs_postclearhold
   then
  return true
 end
 return false
end

function hasblock(bk, bkbelow)
 if not bk then
  return false
 end
 if bk.btype > 0 and
   (not bkbelow or
     bkbelow.btype > 0)
   then
  return true
 end
 return false
end

function canswap(bk, bkbelow)
  if bk.btype == 0 or (
     not bkbelow
     or bkbelow.btype > 0
     ) then
   return true
  end
  return false
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

function board_cursinput(b)
	
	if b.cursstate != cs_idle then
	 return
	end
 
 if newpress(5, b.contidx) then
  local bk1, bk2 =
    board_getcursblocks(b)
   
  local bk1below = nil
  local bk2below = nil
  if b.cursy < 12 then
  	bk1below, bk2below =
  	  board_getcursblocks(b, 1)
  	--[[
  	local belowrow =
  	  board_getrow(b,
  	    b.cursy + 2)
   bk1below =
     belowrow[b.cursx + 1]
   bk2below =
     belowrow[b.cursx + 2]
  --]]
  end
  
  if stateisswappable(bk1.state)
    and stateisswappable(
      bk2.state)
    and (hasblock(bk1, bk1below)
     or hasblock(bk2, bk2below))
    and (canswap(bk1, bk1below)
     and canswap(bk2, bk2below))
    then
   -- swap shit
   bk1.state = bs_swapping
   bk2.state = bs_swapping
   b.cursstate = cs_swapping
   b.curscount = 0
   
   return
  else
   -- todo mask and bump
  end
 
 
 
 end
 
 
 if b.cursy > 0 and
 	 (not (b.cursy == 1
 	   and b.raiseoffset > 3))
 	 and _cursdir(b, 2) then
  b.cursy -= 1
 end
 
 if b.cursy < 11 and
 	 _cursdir(b, 3) then
  b.cursy += 1
 end
 
 if b.cursx > 0 and
 	  _cursdir(b, 0) then
  b.cursx -= 1
 end
 
 if b.cursx < 4 and
   _cursdir(b, 1) then
  b.cursx += 1
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
  
  
  for i = 1, #b.matchrecs do
   b.matchrecs[i].y -= 1
  end
  --todo, adjust matches
 
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
  
  --todo, autoraise
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
   	
   	local bdown = nil
   	if y < 13 then
   	 bdown = board_getrow(
   		 b, y + 1)[x]
   	end
   	
   	local bup = nil
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

 local checkhorzrun =
   function(x1, y1)
  if horzrun.len < 3 then
   return
  end
  -- todo
  local matchseq = {}
  add(newmatchseqs, matchseq)
  local row = board_getrow(
    b, y1)
  local pad = flashandfaceframes
  local dur = pad +
      horzrun.len * popoffset
  
  
  local chainmax = 0
  
  -- todo, metal match count
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
   add(matchseq, mrec)
   
   chainmax = max(chainmax,
     runbk.chain + 1)
   
   newmatchminx = min(
     newmatchminx, rx)
     
   pad += popoffset
   rx += 1
  end
  
  if chainmax > 1 then
   for i = 1, #matchseq do
    matchseq[i].chain =
      chainmax
   end
  end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 end
 
 --todo function checkvertrun
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
  
  local hmatchseq = nil
  
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
    
    for i = 1, #hmatchseq do
     hmatchseq[i].dur = dur
    end  
    
    chainmax = max(chainmax,
      hmatchseq[1].chain)
   else
    chainmax = max(chainmax,
      runbk.chain + 1)
   end
     
   
   ry += 1
  end
 
  local matchseq = nil
  if hmatchseq then
   matchseq = hmatchseq
   for i = 1, #matchseq do
    matchseq[i].chain =
      chainmax
   end
  else
   matchseq = {}
   add(newmatchseqs, matchseq) 
  end
  
  local mrec = nil
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
   add(matchseq, mrec)
   
   newmatchminy = min(
     newmatchminy, ry)
   
   --todo: metal
   --todo: seqidx
   
   ::cont::
   
  	ry += 1
  	pad += popoffset
  end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 
 end
 
 local prevrow = nil
 local row = nil
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
						--stop()
						 
      bkbelow.btype = bk.btype
      bkbelow.fallframe =
        frame
      bkbelow.count = 0
      bkbelow.chain = 0
      
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
    else
     -- not falling
     if bk.count > 0 then
      bk.count -= 1
     end
    
     -- todo chain reset
     if bk.count ==
       chainresetcount then
      bk.chain = 0
     end
    end
    
    if (bounceframecount -
      bk.count) < 2 then
     
     checkhorzrun(x)
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
      --we don't match but
      --what's before us might
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
    
   
    -- todo, garbage
   end
   
   ::cont::
   
  end
  checkhorzrun(7, y)
  prevrow = row
 end
 
 
 if #newmatchseqs > 0 then
  --b.matchrecs
  
  --todo, check garbage
  for i = 1, #newmatchseqs do
   
   local ms = newmatchseqs[i]
   
   for j = 1, #ms do
    add(b.matchrecs, ms[j])
   end
   
  end
  --transfer to active match
 end
 
 local activematches = {}
 
 for i = 1, #b.matchrecs do
  local m =
    b.matchrecs[i]
  
  local keep = true
  if m.dur > 0 then
   local bk = board_getrow(b,
     m.y)[m.x]
   
   bk.count = bk.count + 1
   
   if bk.count >= m.dur then
    m.dur = 0
    bk.count =
      postclearholdframes
    if bk.state == bs_matching
      then
     bk.state =
       bs_postclearhold
     
     bk.btype = 0
     bk.chain = 0
     
     -- walk up and max chain
     for y = m.y - 1, 1, -1 do
      -- todo
     end
     
     
    --todo garbage match
    end
   elseif bk.count == bk.count2
     then
    m.puffcount = 0
    --sfxpop
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
  
  if ry == 13 then
   idx += 1
  elseif b.count > 0 then
   idx += bounceframes[b.count]
  elseif squashed then
  	-- todo column squash
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
 -- todo, matching
 --       garbage
 --       garbagematching 
 end
 
end


function board_draw(b)
 local x = b.x
 local y = b.y
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
 for i = 1, 6 do
  squashed[i] = (
    r1[i].btype > 0 or
      r2[i].btype > 0)
 end
 
 y -= b.raiseoffset
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
	
	palt(12, true)
	for i = 1, #b.matchrecs do
	 local m = b.matchrecs[i]
	 
	 if m.puffcount != 255 and 
	   m.puffcount < 18 then
	 
	  local sx = (m.x - 1) * 8 + x
	  local sy = (m.y - 1) * 8 + y
	  
	  local d = m.puffcount
	 	spr(48, sx - d, sy - d)
	 	spr(48, sx + d, sy - d)
	 	spr(48, sx - d, sy + d)
	 	spr(48, sx + d, sy + d)
	 	
	 	
	 	
	 end
	
	end
	palt(12, false)
	-- draw cursors

	local cx = x + b.cursx * 8
	local cy = y + b.cursy * 8
	
	  -- todo draw swapping blocks
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
	
	palt(13, true)
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
	
	palt(13, false)
	
end


function _init()
 frame = 2
 pframe = 1
 cstate = 0
 prevcstate = 0
 squashframe = 0
 squashcount = 0

 boards = {board_new(),
   board_new()}

 boards[1].x = 3
 boards[2].x = 77
 boards[2].contidx = 1
 
 boards[2].nextlinerandomseed =
   boards[1].nextlinerandomseed
 local s = rnd(31767)
 srand(s)
 board_fill(boards[1], 6)
 srand(s)
 board_fill(boards[2], 6)

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
 
 return false
end

function press(bidx, cidx)
  return _press(
    bidx, cidx, cstate)
end

function newpress(bidx, cidx)
 if not press(bidx, cidx) then
  return false
 end

	if _press(bidx, cidx,
	  prevcstate) then
	 return false
	end
	
	return true
end


function _update60()
	pframe = frame
	frame += 1
	
	prevcstate = cstate
	cstate = btn()
	
	squashcount =
	  (squashcount + 1) % 3
	
	if squashcount == 0 then
	 squashframe =
	   (squashframe + 1) % 6
	end
	
	for i = 1, #boards do
	 board_step(boards[i])
	end
end

function _draw()
 cls()
 rectfill(0, 0, 127, 127, 5)

 palt(0, false)
 
 for i = 1, #boards do
	 board_draw(boards[i])
	end
	
 palt(0, true)
end











__gfx__
0000000082222220525252508222222082828220888888200222222087777778e222222052525250e2222220e2eee220eeeeee2002222220e777777e00000000
000000002282822025858525222222202888882028888820222222227787877822eee22025e5e525222222202eeeee202eeeee202222222277eee77e00000000
00700700288888205858585022222220288888202288822022822822788888782eeeee205e5e5e50222222202eeeee202eeeee2022e22e227eeeee7e00000000
00077000288888202585852528828820228882202228222022822822788888782eeeee2025e5e5252eeeee202eeeee2022eee22022e22e227eeeee7e00000000
00077000228882205258525088888880222822202222222022222222778887782eeeee205e5e5e50eeeeeee022eee22022222220222222227eeeee7e00000000
007007002228222025252525288888202222222022222220228888227778777822eee22025e5e525eeeeeee0222222202222222022eeee2277eee77e00000000
000000002222222052525250228882202222222022222220222222227777777822222220525252502eeeee202222222022222220222222227777777e00000000
0000000000000000050505050000000000000000000000000222222088888888000000000505050500000000000000000000000002222220eeeeeeee00000000
ddddddddc111111051515150c1111110c11c1110c1ccc11001111110c777777ca999999059595950a9999990aaaaaa90aaaaaa9009999990a777777a00000000
dddddddd111c1110151515151111111011ccc1101ccccc1011111111777c777c9aaaaa9095a5a595999999909aaaaa9099aaa990999999997aaaaa7a00000000
dd00000d11ccc110515c5150111111101ccccc1011ccc11011c11c1177ccc77c9aaaaa905a5a5a509999999099aaa99099aaa99099a99a997aaaaa7a00000000
dd07770d1ccccc1015c5c5151111111011ccc110111c111011c11c117ccccc7c99aaa99095a5a5959999999099aaa990999a999099a99a9977aaa77a00000000
dd07000d11ccc110515c51501ccccc10111c1110111111101111111177ccc77c99aaa990595a5950aaaaaaa0999a9990999999909999999977aaa77a00000000
dd070ddd111c111015151515ccccccc0111111101111111011cccc11777c777c999a9990959595959aaaaa90999999909999999099aaaa99777a777a00000000
dd000ddd11111110515151501ccccc101111111011111110111111117777777c999999905959595099aaa9909999999099999990999999997777777a00000000
dddddddd000000000505050500000000000000000000000001111110cccccccc000000000505050500000000000000000000000009999990aaaaaaaa00000000
ddddddddb333333053535350b3333330b33b3330b3bbb33003333330b777777b6555555005050500655555506556555065565550055555506777777600000000
dddddddd333b3330353535353333333033bbb33033bbb33033333333777b777b5556555050505050555555505556555055565550555555557776777600000000
d00000dd33bbb330535b53503333333033bbb3303bbbbb3033b33b3377bbb77b5556555005060500555555505556555055555550556556557776777600000000
d07770dd33bbb33035b5b535333333303bbbbb303bbbbb3033b33b3377bbb77b5556555050505050556665505555555055565550556556557776777600000000
d00700dd3bbbbb305b5b5b503bbbbb303bbbbb3033333330333333337bbbbb7b5555555005050500556665505556555055555550555555557777777600000000
dd070ddd3bbbbb3035b5b535bbbbbbb0333333303333333033bbbb337bbbbb7b5556555050505050555555505555555055555550556666557776777600000000
dd000ddd3333333053535350bbbbbbb03333333033333330333333337777777b5555555005050500556665505555555055555550555555557777777600000000
dddddddd000000000505050500000000000000000000000003333330bbbbbbbb0000000000000000000000000000000000000000055555506666666600000000
cccccccc944444405454545094444440999499409999994004444440977777790000000000000000000000000000000000000000000000005555555555555555
cccccccc499499404595954544444440499999404499944044444444799799790555555505555555555555550000000055555555000000005000000557777775
ccc76ccc499999405959595044444440449994404999994044944944799999790500000005000000000000000000000000000000000000005050050557577575
cc7665cc449994404595954599949990499999404994994044944944779997790500000005000000000000000000000000000000000000005050050557577575
cc6655cc499999405959595099999990499499404444444044444444799999790500000005000000000000000000000000000000000000005000000557777775
ccc55ccc499499404595954599999990444444404444444044999944799799790500000005000000000000000000000000000000000000005055550557555575
cccccccc444444405454545099949990444444404444444044444444777777790555555505000000555555555555555500000000000000005000000557777775
cccccccc000000000505050500000000000000000000000004444440999999990000000005000000000000000000000000000000000000005555555555555555
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000012107000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000012131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000110131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000310717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000171701000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000120818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

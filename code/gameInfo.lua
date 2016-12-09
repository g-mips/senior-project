--[[
   GET_ALL_POSITIONS:
   NO PROBLEMS HERE!
--]]
function getAllPositions()
   marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
   marioY = memory.readbyte(0x03B8)+16
       
   screenX = memory.readbyte(0x03AD)
   screenY = memory.readbyte(0x03B8)

   return { ["mX"]= marioX, ["mY"]= marioY, ["sX"]= screenX, ["sY"]= screenY }
end

--[[
   GET_TILE:
   NO PROBLEMS HERE!
--]]
function getTile(dx, dy, pos)
   local x = pos["mX"] + dx + 8
   local y = pos["mY"] + dy - 16
   local page = math.floor(x/256)%2
   
   local subx = math.floor((x%256)/16)
   local suby = math.floor((y - 32)/16)
   local addr = 0x500 + page*13*16+suby*16+subx
   
   if suby >= 13 or suby < 0 then
      return 0
   end
               
   if memory.readbyte(addr) ~= 0 then
      return 1
   else
      return 0
   end
end

--[[
   GET_SPRITES:
   NO PROBLEMS HERE!
--]]
function getSprites()
   local sprites = {}

   -- Get the enemy positions
   for slot=0,4 do
      local enemy = memory.readbyte(0xF+slot)
      if enemy ~= 0 then
	 local x = memory.readbyte(0x6E + slot)*0x100 + memory.readbyte(0x87+slot)
	 local y = memory.readbyte(0xCF + slot)+24
	 sprites[#sprites+1] = {["x"]=x,["y"]=y}
      end
   end
               
   return sprites
end

--[[
   GET_INPUTS
   NO PROBLEMS HERE!
--]]
function getInputs()
   -- Get the positions and the sprites
   local pos     = getAllPositions()
   local sprites = getSprites()

   -- Begin collecting the inputs to the phenotype. These are the surrounding tiles of mario
   local inputs = {}
   for dy=-BOX_RADIUS*16, BOX_RADIUS*16, 16 do
      for dx=-BOX_RADIUS*16, BOX_RADIUS*16, 16 do
	 -- Zero means that there is nothing to worry about in the current position
	 inputs[#inputs+1] = 0

	 -- Get the tile of the given dx, dy, and mario's current positions
	 -- Then check if there is a tile there. A one is given to the input to signify that there is a tile there
	 tile = getTile(dx, dy, pos)
	 if tile == 1 and pos["mY"]+dy < 0x1B0 then
	    inputs[#inputs] = 1
	 end

	 -- A negative one is given to the input to indicate the presence of a sprite (an enemy)
	 for i=1, #sprites, 1 do
	    distx = math.abs(sprites[i]["x"] - (pos["mX"]+dx))
	    disty = math.abs(sprites[i]["y"] - (pos["mY"]+dy))
	    if distx <= 8 and disty <= 8 then
	       inputs[#inputs] = -1
	    end
	 end
      end
   end
   
   return inputs
end

function displayInformation()
   local x = 1
   gui.text(x,  30, "Enemy 1 Loaded: " .. mainmemory.readbyte(0x000F))
   gui.text(x,  50, "Enemy 2 Loaded: " .. mainmemory.readbyte(0x0010))
   gui.text(x,  70, "Enemy 3 Loaded: " .. mainmemory.readbyte(0x0011))
   gui.text(x,  90, "Enemy 4 Loaded: " .. mainmemory.readbyte(0x0012))
   gui.text(x, 110, "Mario X Pos 1 : " .. mainmemory.readbyte(0x0086))
   gui.text(x, 130, "Mario X Pos 2 : " .. mainmemory.readbyte(0x006D))
end

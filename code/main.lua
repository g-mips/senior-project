function displayInformation()
   x = 1
   gui.text(x, 30,"Enemy 1 Loaded: " .. mainmemory.readbyte(0x000F))
   gui.text(x, 50,"Enemy 2 Loaded: " .. mainmemory.readbyte(0x0010))
   gui.text(x, 70,"Enemy 3 Loaded: " .. mainmemory.readbyte(0x0011))
   gui.text(x, 90,"Enemy 4 Loaded: " .. mainmemory.readbyte(0x0012))
   gui.text(x,110,"Mario X Pos 1 : " .. mainmemory.readbyte(0x0086))
   gui.text(x,130,"Mario X Pos 2 : " .. mainmemory.readbyte(0x006D))
end

while true do
   displayInformation()
   emu.frameadvance()
end

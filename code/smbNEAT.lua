
console.write(gameinfo.getromname())
print()
console.write(gameinfo.getstatus())
print()
console.write(gameinfo.indatabase())
print()
console.write(gameinfo.getoptions())
print()
console.write(joypad.get())
screenwidth = client.screenwidth()
x = 1
while true do
   gui.text(x,30,"This is the message")
   gui.text(x,65,mainmemory.readbyte(0x000F))
   
   emu.frameadvance()
end

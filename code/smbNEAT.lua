
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
   gui.text(x,10,"This is the message")
   if x > tonumber(screenwidth) then
      x = 1
   elseif x == 10 then
      print(x)
   end
   emu.frameadvance()
end

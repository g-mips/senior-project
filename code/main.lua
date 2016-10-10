--[[ 
- Mutation

- Input Nodes (8):

   - 'A'
   - 'B'
   - 'Select'
   - 'Start'
   - 'Up'
   - 'Left'
   - 'Right'
   - 'Down'

- Generate the population (the genome??)

--]]
MAX_IN_NODES = 8

--[[
- Can change connection weights and network structures.
- Structural mutations occur in two ways:
   - Connection addition
   - Node addition
- Each mutation expands the size of the genome by adding gene(s).
--]]
function mutate(genome)

end

--[[
Should this only be called once?
- Genomes (Linear representations of network connectivity) [IN OTHER WORDS: The Neural Network]

   - Each genome includes a list of connection genes, each of which refers to two node genes being connected.
   - Node genes provide a list of inputs, hidden nodes, and outputs that can be connected.
   - Each connection gene specifies the in-node, the out-node, the weight of the connection, whether or not the
     connection gene is expressed (an enable bit), and an innovation number, which allows finding corresponding genes.

RETURN 
   LIST
   [
         CONNECT_GENE_1: 
         [
              IN - The In Node
              OUT - The Out Node
              Weight - The weight between the two nodes
              Enable Bit - If the connection is enabled or not
              Innovation Number - ID?
         ]
         ...
         CONNECT_GENE_N
   ]
              
--]]
function generateGenotype()
   local genotype = { }
   
   return genotype
end

function displayPhenotype(genotype)

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

function main()
   local genotype = generateGenotype()
   while true do
      --[[ Call display information every frame --]]
      displayInformation()

      --[[ Advance a frame --]]
      emu.frameadvance()
   end
end

main()

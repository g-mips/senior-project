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

Genotype/Genome (Neural Network) : List of connection nodes and node genes
Connection Nodes                 : Shows the input and output nodes, the weight of the connection, whether or not it it enabled, and the connections innovation id.
Node Genes                       : List of input, hidden, and output nodes that can be connected.

member : {
   "genotype" : {
       "cNodes" : {
           0 : {
                 "in": nodeIn,
                 "out": nodeOut,
                 "weight": math.random(0.1, 1),
                 "active": true,
                 "id": INNOVATION_ID
           },
           ...
       },
       "nodeGenes" : {
           0 : {
                 "type": geneType,
                 "ID": id
           },
           ...
       }
   },
   "phenotype" : {
   
   }
}

--]]
SAVE_STATE = "SMB_World1-1.State"
MAX_FITNESS = 0
BUTTONS = {
   "P1 A",
   "P1 B",
   "P1 Down",
   "P1 Left",
   "P1 Right",
   "P1 Select",
   "P1 Start",
   "P1 Up",
   --[[ I shouldn't care about these guys and possibly select --]]
   "Power",
   "Reset"
}
BOX_RADIUS = 6

NUM_INPUT_NODES  = ((BoxRadius*2+1)*(BoxRadius*2+1))+1
NUM_OUTPUT_NODES = #BUTTONS
MAX_NODES = 100000

INNOVATION_NUMBER = 0
POPULATION        = 200

MUTATION_CHANCE   = 0.25
WEIGHT_CHANCE     = 0.15
CONNECTION_CHANCE = 2.0
NODE_CHANCE       = 0.50
DISABLE_CHANCE    = 0.4
ENABLE_CHANCE     = 0.2

PerturbChance = 0.90
CrossoverChance = 0.75

BiasMutationChance = 0.40

function setController()

end

function writeGenotype(genotype)

end

function writeGeneration()

end

function newMember()
   local member = {
      "genotype": {
	 "cNodes": {},
	 "nodeGenes": {},
		  },
      "phenotype": {},
      "mutationChances": {
	 "weight": WEIGHT_CHANCE,
	 "node": NODE_CHANCE,
	 "connection": CONNECTION_CHANCE,
	 "active": 0,
	 "enable": ENABLE_CHANCE,
	 "disable": DISABLE_CHANCE
			 },
      "fitness": 0,
      "rank": 0,
   }

   return genotype
end
   
--[[
   NEW_NODE_GENE:
Parameters:
   id - The ID of the new node gene. This is ever increasing and is 
   geneType - 0: Input, 1: Hidden, 2: Output
--]]
function newNodeGene(id, geneType)
   local nodeGene = {
      "type": geneType,
      "ID": id
   }

   return nodeGene
end

--[[
   NEW CONNECTION NODE:

   NODE is a GENE
--]]
function newConnectionNode(member, nodeIn, nodeOut)
   -- TODO(Grant): Figure out how innovation number is handled (i.e. globally or scope of each member)
   INNOVATION_NUMBER += 1
   --member["genotype"]["innovationNumber"] += 1
   local connectionNode = {
      "in": nodeIn,
      "out": nodeOut,
      "weight": 0,
      "active": true,
      "id": INNOVATION_ID
   }
   
   return connectionNode
end

function getRandomNode(member, availableOutputs)
   local node
   local outputNodes
   
   if #availableOutputs != 0 then
      -- For choosing the output node
      node = math.random(1, #availableOutputs)
      outputNodes = availableOutputs
   else
      -- For choosing the input node 
      local foundNode

      repeat
	 foundNode = true

	 -- Create a list of all avaliable outputNodes
	 outputNodes = {}
	 for i=1, NUM_OUTPUT_NODES, 1 do
	    outputNodes[i] = i+MAX_NODES
	 end

	 -- Get a random input node
	 node = math.random(1, NUM_INPUT_NODES)

	 -- Mark nodes for removing
	 for i=1, #member["genotype"]["cNodes"], 1 do
	    if member["genotype"]["cNodes"]["in"] == node then
	       outputNodes[member["genotype"]["cNodes"]["out"]] = nil
	    end
	 end

	 -- Remove marked nodes
	 for i=#outputNodes, 1, -1 do
	    if outputNodes[i] == nil then
	       table.remove(outputNodes, i)
	    end
	 end

	 -- Check if there are no outputNodes left
	 if #outputNodes == 0 then
	    foundNode = false
	 end
      until (foundNode)
   end

   return node, outputNodes
end

--[[
   MUTATE:
   There
Parameters:
   member - This is the current member/genome that will be mutated
Return:
   member - The mutated member/genome
   Finished!
   TODO: TEST!
- Can change connection weights and network structures.
- Structural mutations occur in two ways:
   - Connection addition
   - Node addition
- Each mutation expands the size of the genome by adding gene(s).
--]]
function mutate(member)
   -- Change rate of mutation chances
   
   -- Add Connection: Single new connection gene with a random weight is added connecting two previously unconnected nodes
   if math.random() > member["mutationChances"]["connection"] then
      member = addConnectionMutation(member)
   end
   
   --[[ Add Node: An existing connection is split and the new node placed where the old connection used to be. Old: disabled. Two New: Added 
        New connection leading into the new node receives a weight of 1, and the new connection leading out receives the same weight as the
        old connection.
   --]]
   if math.random() > member["mutationChances"]["node"] then
      member = addNodeMutation(member)
   end

   if math.random() > member["mutationChances"]["weight"] then
      member = addWeightMutation(member)
   end
   
   -- TODO(Grant): Alter activation response
   if math.random() > member["mutationChances"]["active"] then

   end

   if math.random() > member["mutationChances"]["enable"] then
      member = addEnableDisableMutation(member, true)
   end

   if math.random() > member["mutationChances"]["disable"] then
      member = addEnableDisableMutation(member, false)
   end
   
   return member
end


--[[
   Finished!
   TODO: TEST!
--]]
function addConnectionMutation(member)
   -- Get an input and an output node
   local nodeIn, outputNodes  = getRandomNode(member, {})
   local nodeOut, outputNodes = getRandomNode(member, outputNodes)
   local connectionNode       = newConnectionNode(member, nodeIn, nodeOut)

   connectionNode["weight"] = math.random(-2, 2)
   
   -- Add the new connection node to the member
   table.insert(member["genotype"]["cNodes"], connectionNode)

   return member
end

--[[
   Finished!
   TODO: TEST!
--]]
function addNodeMutation(member)
   -- Get a random connection node
   local index       = math.random(1,#member["genotype"]["cNodes"])
   local input       = member["genotype"]["cNodes"][index]["in"]
   local output      = member["genotype"]["cNodes"][index]["out"]

   -- Create two new connections
   local connection1 = newConnectionNode(member, input, member["genotype"]["nodeGenes"][#member["genotype"]["nodeGenes"]]["id"])
   local connection2 = newConnectionNode(member, member["genotype"]["nodeGenes"][#member["genotype"]["nodeGenes"]]["id"], output)

   connection1["weight"] = 1
   connection2["weight"] = member["genotype"]["cNodes"][index]["weight"]

   -- TODO: How do I figure out the input type? Is it always hidden?
   table.insert(member["genotype"]["nodeGenes"], newNodeGene(#member["genotype"]["nodeGenes"]+1, 1))

   -- Insert the two connections into the connection nodes table
   table.insert(member["genotype"]["cNodes"], connection1)
   table.insert(member["genotype"]["cNodes"], connection2)

   -- Deactivate old connection
   member["genotype"]["cNodes"][index]["active"] = false

   return member
end

function addWeightMutation(member)
   local index = math.random(1,#member["genotype"]["cNodes"])

   if math.random() > 0.5 then
      member["genotype"]["cNodes"][index]["weight"] = math.random(-2, 2)
   else
      if math.random() > 0.5 then
	 member["genotype"]["cNodes"][index]["weight"] = member["genotype"]["cNodes"][index]["weight"] +
	    math.random(0, member["mutationChances"]["weight"])
      else
	 member["genotype"]["cNodes"][index]["weight"] = member["genotype"]["cNodes"][index]["weight"] -
	    math.random(0, member["mutationChances"]["weight"])
      end
   end

   return member
end

function addEnableDisableMutation(member, enable)
   local index = math.random(1,#member["genotype"]["cNodes"])
   
   if enable then
      member["genotype"]["cNodes"][index]["active"] = true
   else
      member["genotype"]["cNodes"][index]["active"] = false
   end
end

function crossover()
   --[[ Take "half" from one and take "half" from the other and combine them --]]

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

function calculateFitness()

end

function main()
   local genotype = generateGenotype()
   local frames = 0
   local fitness = 0
   local prev_fitness = 0
   local controller = joypad.get()
   print(controller) 

   --[[ Step 1 (Variation)
      Create a population (species) of N elements with random genetic material
      Heredity
      Variation
      Selection
   --]]
   createInitialPopulation()

   while true do
      --[[ Call display information every frame --]]
      displayInformation()

      --[[ Step 2 (Selection)
	 Calculate Fitness for N elements 
      --]]
      calculateFitness()
      buildPool()
      
      --[[ Step 3 (Selection/Heredity)
	 Population / Selection
	 3.1 Pick "two" parents
	 3.2 Make a new element
	 3.2.1 Crossover
	 3.2.2 Mutation
	 3.3 Add a child to the new population
      --]]
      pickParents()
      crossover()
      mutate()
      
      if (frames > 60 and prev_fitness == fitness) then
	 --[[frames = 0 --]]
	 savestate.load(SAVE_STATE)
	 fitness = fitness + 1
	 
--[[      elseif (prev_fitness ~= fitness)
      then
   frames = 0--]]
      end

      controller["P1 Right"] = "True"
      joypad.set(controller)
      if (frames == 0) then
	 print("START BUTTONS")
	 for i=1,10,1 do
	    print(i)
	    print(controller[BUTTONS[i]])
	 end
      end
      

      --[[ Replace old population with new population --]]
      
      --[[ Advance a frame --]]
      frames = frames + 1
      emu.frameadvance()
   end
end

savestate.load(SAVE_STATE)
main()

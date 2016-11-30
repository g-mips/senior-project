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

POPULATION        = 200

WEIGHT_CHANCE     = 0.25
CONNECTION_CHANCE = 2.0
NODE_CHANCE       = 0.50
DISABLE_CHANCE    = 0.4
ENABLE_CHANCE     = 0.2
STEP              = 0.1

PerturbChance = 0.90
CrossoverChance = 0.75

BiasMutationChance = 0.40

--[[
   {
       "in":  #,
       "out": #
   }
--]]
GLOBAL_INNOVATIONS = {}

--[[
   NEW_POOL:
   Creates a new pool with empty everything.
Parameters:
   None
Return:
   Returns the newly created pool
--]]
function newPool()
   local pool = {
      -- Table of species. Indexes are just numbers. Is #species safe.
      "species": {},
      "generation": 0,
      "currentSpecies": 1,
      "currentMember": 1,
      "currentFrame": 0,
      "maxFitness": 0
   }

   return pool
end

--[[
   NEW_SPECIES:
   Creates a new species with empty everything.
Parameters:
   None
Return:
   Returns the newly created species
--]]
function newSpecies()
   local species = {
      "topFitness": 0,
      -- Table of members. Indexes are just numbers. Is #members safe.
      "members": {},
      "averageFitness": 0
   }

   return species
end

--[[
   NEW_MEMBER:
   Creates a new member with empty everything, except the mutationChances.
Parameters:
   None
Return:
   Returns the newly created member
--]]
function newMember()
   local member = {
      "genotype": {
	 -- Table of connection nodes. Indexes represent the innovation numbers. Is NOT #cNodes safe
	 "cNodes": {},
	 -- How this works is that 1 - NUM_INPUT_NODES are input nodes.
	 -- (MAX_NODES + NUM_OUTPUT_NODES) - MAX_NODES are the output nodes.
	 -- The inbetween nodes are the hidden nodes
	 "numNodeGenes": 0,
	 "maxNodeGenes": 0,
	 "numCNodes": 0
		  },
      "phenotype": {},
      "mutationChances": {
	 "weight": WEIGHT_CHANCE,
	 "node": NODE_CHANCE,
	 "connection": CONNECTION_CHANCE,
	 -- TODO(Grant): Do I need this active mutationChance?
	 "active": 0,
	 "enable": ENABLE_CHANCE,
	 "disable": DISABLE_CHANCE
			 },
      "fitness": 0,
      "rank": 0,
   }

   return member
end
   
--[[
   NEW_CONNECTION_NODE:
   Creates a connection node with a node in of nodeIn and a node out of nodeOut.
   Defaults to a 0 innovation. Should be changed to a real number.
   Defaults to being active.
   Defaults to having a weight of 0.
Parameters:
   nodeIn - The node that the connection starts with.
   nodeOut - The node that the connection ends with.
Return:
   Returns the connectionNode created
--]]
function newConnectionNode(nodeIn, nodeOut)
   local connectionNode = {
      "in": nodeIn,
      "out": nodeOut,
      "weight": 0,
      "active": true,
      "innovation": 0
   }
   
   return connectionNode
end

--[[
   GET_RANDOM_NODE:
   Gets a random node
--]]
function getRandomNode(genotype, availableOutputs)
   local node
   local outputNodes = { "nodes": {}, "numNodes": 0 }

   if #availableOutputs != 0 then
      -- For choosing the output node
      node = availableOutputs["nodes"][math.random(#availableOutputs["nodes"]-availableOutputs["numNodes"],#availableOutputs["nodes"])]
   else
      -- For choosing the input node 
      local foundNode

      -- Keep going until a valid node is found
      repeat
	 foundNode = true

	 -- Generate the outputNodes
	 for i=NUM_INPUT_NODES+1,genotype["numNodeGenes"],1 do
	    outputNodes["nodes"][i] = NUM_INPUT_NODES+i
	    outputNodes["numNodes"] = outputNodes["numNodes"] + 1
	 end

	 -- Find a random node that is not an output node
	 repeat
	    node = math.random(genotype["numNodeGenes"])
	 until (node > NUM_INPUT_NODES + NUM_OUTPUT_NODES or node <= NUM_INPUT_NODES)

	 -- Remove nodes from outputNodes table
	 for i=1, genotype["numCNodes"], 1 do
	    if genotype["cNodes"][i]["in"] == node then
	       if outputNodes["nodes"][genotype["cNodes"][i]["out"]] ~= nil then
		  table.remove(outputNodes["nodes"], genotype["cNodes"][i]["out"])
		  outputNodes["numNodes"] = outputNodes["numNodes"] - 1
	       end
	    end
	 end

	 -- Check if there are no outputNodes left
	 if outputNodes["numNodes"] == 0 then
	    foundNode = false
	 end
      until (foundNode)
   end

   return node, outputNodes
end

--[[
   MUTATE:
Parameters:
   member - This is the current member/genome that will be mutated
Return:
   member - The mutated member/genome
   TODO: TEST!
--]]
function mutate(member)
   -- Change rate of mutation chances
   
   -- Add Connection: Single new connection gene with a random weight is added connecting two previously unconnected nodes
   if math.random() > member["mutationChances"]["connection"] then
      addConnectionMutation(member["genotype"])
   end
   
   --[[ Add Node: An existing connection is split and the new node placed where the old connection used to be. Old: disabled. Two New: Added 
        New connection leading into the new node receives a weight of 1, and the new connection leading out receives the same weight as the
        old connection.
   --]]
   if math.random() > member["mutationChances"]["node"] then
      addNodeMutation(member["genotype"])
   end

   if math.random() > member["mutationChances"]["weight"] then
      addWeightMutation(member["genotype"])
   end
   
   -- TODO(Grant): Alter activation response
   -- NOTE(Grant): I may not need this
   if math.random() > member["mutationChances"]["active"] then

   end

   if math.random() > member["mutationChances"]["enable"] then
      addEnableDisableMutation(member["genotype"], true)
   end

   if math.random() > member["mutationChances"]["disable"] then
      addEnableDisableMutation(member["genotype"], false)
   end
end

function checkInnovation(nodeIn, nodeOut)
   local globalInnovationIndex = 0

   -- Check to see if the innovation already exists
   for i=1, #GLOBAL_INNOVATIONS, 1 do
      if GLOBAL_INNOVATIONS[i]["in"] == nodeIn and GLOBAL_INNOVATIONS[i]["out"] == nodeOut then
	 globalInnovationIndex = i
	 break
      end
   end

   return globalInnovationIndex
end

--[[
   ADD_CONNECTION_MUTATION:
   
   Finished!
   TODO: TEST!

Parameters:
Return:

--]]
function addConnectionMutation(genotype)
   local nodeIn
   local outputNodes
   local nodeOut
   local globalInnovationIndex

   -- Get an input and an output node and use them to check if a connection between them already exists.   
   nodeIn, outputNodes   = getRandomNode(genotype, {})
   nodeOut, outputNodes  = getRandomNode(genotype, outputNodes)
   globalInnovationIndex = checkInnovation(nodeIn, nodeOut)

   -- If the innovation exists, then just change it's weight
   -- If it doesn't exist, create it
   if globalInnovationIndex > 0 then
      genotype["cNodes"][globalInnovationIndex]["weight"] = math.random() + math.random(-2, 2)
   else
      local connectionNode = newConnectionNode(nodeIn, nodeOut)

      -- Insert the new innovation to the global list (which increments the number of innovations count)
      table.insert(GLOBAL_INNOVATIONS, { "in": nodeIn, "out": nodeOut })

      -- Add the new innovation to the connection node and create a random weight
      connectionNode["innovation"] = #GLOBAL_INNOVATIONS
      connectionNode["weight"] = math.random() + math.random(-2, 2)
   
      -- Add the new connection node to the genotype and increase the connection node count
      genotype["cNodes"][connectionNode["innovation"]] = connectionNode
      genotype["numCNodes"] = genotype["numCNodes"] + 1
   end
end

--[[
   ADD_NODE_MUTATION:

   Finished!
   TODO: TEST!

Parameters:
Return:

--]]
function addNodeMutation(genotype)
   -- Get a random connection node
   local index  = math.random(genotype["numCNodes"])
   local input  = genotype["cNodes"][index]["in"]
   local output = genotype["cNodes"][index]["out"]

   -- Create a new node
   genotype["numNodeGenes"] = genotype["numNodeGenes"] + 1

   -- Check if connections already exist
   local globalInnovationIndex1 = checkInnovation(input, genotype["numNodeGenes"])
   local globalInnovationIndex2 = checkInnovation(genotype["numNodeGenes"], output)

   -- Create two new connections
   local connection1 = newConnectionNode(input, genotype["numNodeGenes"])
   local connection2 = newConnectionNode(genotype["numNodeGenes"], output)

   -- Check to see if these innovations already exist and if not create them
   -- TODO(Grant): Check to see if I need to update any innovations in the pool
   if globalInnovationIndex1 == 0 then
      table.insert(GLOBAL_INNOVATIONS, { "in": input, "out": genotype["numNodeGenes"] })      
      globalInnovationIndex1 = #GLOBAL_INNOVATIONS
   end

   if globalInnovationIndex2 == 0 then
      table.insert(GLOBAL_INNOVATIONS, { "in": genotype["numNodeGenes"], "out": input })
      globalInnovationIndex1 = #GLOBAL_INNOVATIONS      
   end

   -- Add the innovation to the connections
   connection1["innovation"] = genotype["cNodes"][globalInnovationIndex1]
   connection2["innovation"] = genotype["cNodes"][globalInnovationIndex2]

   -- Change the weights
   connection1["weight"] = 1
   connection2["weight"] = genotype["cNodes"][index]["weight"]

   -- Insert the two connections into the connection nodes table
   genotype["cNodes"][connection1["innovation"]] = connection1
   genotype["numCNodes"] = genotype["numCNodes"] + 1
   
   genotype["cNodes"][connection2["innovation"]] = connection2
   genotype["numCNodes"] = genotype["numCNodes"] + 1
   
   -- Deactivate old connection
   genotype["cNodes"][index]["active"] = false
end

--[[
   ADD_WEIGHT_MUTATION:
Parameters:
Return:
--]]
function addWeightMutation(genotype)
   local index = math.random(genotype["numCNodes"])

   if math.random() > 0.5 then
      genotype["cNodes"][index]["weight"] = math.random(-2, 2)
   else
      if math.random() > 0.5 then
	 genotype["cNodes"][index]["weight"] = genotype["cNodes"][index]["weight"] +
	    math.random(0, member["mutationChances"]["weightStep"])
      else
	 genotype["cNodes"][index]["weight"] = genotype["cNodes"][index]["weight"] -
	    math.random(0, member["mutationChances"]["weightStep"])
      end
   end

   return member
end

--[[
   ADD_ENABLE_DISABLE_MUTATION:
Parameters:
Return:
--]]
function addEnableDisableMutation(genotype, enable)
   local index = math.random(genotype["numCNodes"])
   
   if enable then
      genotype["cNodes"][index]["active"] = true
   else
      genotype["cNodes"][index]["active"] = false
   end
end

--[[
   CROSSOVER:
--]]
function crossover(memberA, memberB)
   local child = newMember()
   local sameFitness = false

   -- Make sure memberA is the better member, unless they are the same then it doesn't matter.
   if memberB["fitness"] > memberA["fitness"] then
      local temp = memberB
      memberB = memberA
      memberA = temp
   elseif memberA["fitness"] == memberB["fitness"] then
      sameFitness = true
   end

   -- Get all the connection nodes of memberB
   local memberBCNodes = {}
   for _,cNode in pairs(memberB["genotype"]["cNodes"]) do
      memberBCNodes[cNode["innovation"] = cNode
   end

   -- Add the nodes from the parents to the child
   local nonUniqueBCNodes = {}
   local nodesAdded = {}
   for _,cNodeA in pairs(memberA["genotype"]["cNode"]) do
      local cNodeB = memberBCNodes[cNodeA["innovation"]]

      -- If there is a connection node from memberB that also exists in memberA, then we need to add it to non unique list
      if cNodeB ~= nil then
	 nonUniqueBCNodes[cNodeB["innovation"]] = cNodeB
      end
      
      -- IF: Accepted cNodeB
      -- ELSE: Accepted cNodeA
      if cNodeB ~= nil and (sameFitness and math.random(2) == 1) then
	 child["genotype"]["cNodes"][cNodeB["innovation"]] = copyCNode(cNodeB)
	 child["genotype"]["numCNodes"] = child["genotype"]["numCNodes"] + 1
	 
	 if nodesAdded[cNodeB["in"]] ~= nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 end

	 if nodesAdded[cNodeB["out"]] ~= nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 end
      else
	 child["genotype"]["cNodes"][cNodeA["innovation"]] = copyCNode(cNodeA)
	 child["genotype"]["numCNodes"] = child["genotype"]["numCNodes"] + 1
	 
	 if nodesAdded[cNodeA["in"]] ~= nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 end

	 if nodesAdded[cNodeA["out"]] ~= nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 end
      end
   end

   -- Add the remaining disjoint and excess nodes from memberB
   for _,cNode in pairs(memberBCNodes) do
      if nonUniqueBCNodes[cNode["innovation"]] == nil then
	 child["genotype"]["cNodes"][cNode["innovation"]] = copyCNode(cNode)
      end
   end

   -- Copy over the mutation chances
   for mutation,chance in pairs(memberA["mutationChances"]) do
      child["mutationChances"][mutation] = chance
   end

   return child
end

function setController()

end

function writeGenotype(genotype)

end

function writeGeneration()

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

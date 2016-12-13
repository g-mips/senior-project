SAVE_STATE = "SMB1.1.state"
END_GAME = false
WRITE = false

BUTTONS = {
   "P1 A",
   "P1 B",
   "P1 Down",
   "P1 Left",
   "P1 Right",
   "P1 Up"
}
BOX_RADIUS = 6
FRAMES = 0
FURTHEST_X = 0
TIMEOUT = 20
CONTROLLER = joypad.get()

NUM_INPUT_NODES  = ((BOX_RADIUS*2+1)*(BOX_RADIUS*2+1))+1
NUM_OUTPUT_NODES = #BUTTONS

POPULATION        = 300

WEIGHT_CHANCE     = 0.25
CONNECTION_CHANCE = 2.0
NODE_CHANCE       = 0.50
DISABLE_CHANCE    = 0.4
ENABLE_CHANCE     = 0.2
STEP              = 0.1
CROSSOVER_CHANCE  = 0.75

SPECIES_UNIQUE_CHANCE   = 2.0
SPECIES_WEIGHTS_CHANCE  = 0.4
SPECIES_THRESHOLD       = 1.0
UNINTERESTING_THRESHOLD = 15

form = forms.newform(200, 260, "Fitness")
showNetwork = forms.checkbox(form, "Show Map", 5, 30)
showMutationRates = forms.checkbox(form, "Show M-Rates", 5, 52)
hideBanner = forms.checkbox(form, "Hide Banner", 5, 190)

--[[
   in
   out
--]]
GLOBAL_INNOVATIONS = {}

--[[

--]]
function setupSequence(genotype)
   local sequence = {}
   local inserted = {}
   
   for i=1, genotype["numNodeGenes"], 1 do
      for _,cNode in pairs(genotype["cNodes"]) do
	 if (cNode["in"] == i or cNode["out"] == i) and cNode["active"] then
	    if cNode["in"] == i and inserted[i] == nil then
	       table.insert(sequence, i)
	       inserted[i] = true
	    end

	    if cNode["out"] == i and inserted[i] == nil then
	       table.insert(sequence, i)
	       inserted[i] = true
	    end
	 end
      end
   end
   
   genotype["nodeSequence"] = sequence
   
   return genotype
end

--[[

--]]
function getConnectionValues(member, node)
   local incomingNodes = {}
   
   for _,cNode in pairs(member["genotype"]["cNodes"]) do
      if cNode["out"] == node then
	 table.insert(incomingNodes, { ["weight"]= cNode["weight"], ["value"]= member["phenotype"][cNode["out"]]["value"] })
      end
   end

   return incomingNodes
end

--[[

--]]
function sigmoid(x)
   return 2 / (1 + math.exp(-4.9 * x)) - 1
end

--[[

--]]
function generatePhenotype(member)
   local phenotype = {}
   local nodes = {}
   
   -- Set all the input nodes and output nodes
   for i=1, NUM_INPUT_NODES+NUM_OUTPUT_NODES, 1 do
      phenotype[i] = newNeuron()
   end

   -- Set the active hidden nodes
   for _,cNode in pairs(member["genotype"]["cNodes"]) do
      if cNode["active"] then
	 if phenotype[cNode["in"]] == nil then
	    phenotype[cNode["in"]] = newNeuron()
	 end

	 if phenotype[cNode["out"]] == nil then
	    phenotype[cNode["out"]] = newNeuron()
	 end

	 table.insert(phenotype[cNode["out"]]["incomingCNodes"], cNode)
      end
   end
   member["phenotype"] = phenotype

   -- May be able to get rid of this
   member["genotype"] = setupSequence(member["genotype"])
   
   return member
end

--[[

--]]
function evaluatePhenotype(member, inputs)
   -- This gets the bias input
   table.insert(inputs, 1)

   -- Set up all the input nodes
   for i=1, NUM_INPUT_NODES, 1 do
      member["phenotype"][i]["value"] = inputs[i]
   end

   -- Go through all the neurons of the phenotype (network) and set up the value for each neuron.
   for _,neuron in pairs(member["phenotype"]) do
      -- Why does this work?!?!?!
      local sum = 0
      for i=1, #neuron["incomingCNodes"] do
	 sum = sum + neuron["incomingCNodes"][i]["weight"] * member["phenotype"][neuron["incomingCNodes"][i]["in"]]["value"]
      end

      -- We only want to change the value of non-input nodes (or nodes that have incoming nodes)
      if #neuron["incomingCNodes"] > 0 then
	 neuron["value"] = sigmoid(sum)
      end
   end

   for i=1, NUM_OUTPUT_NODES, 1 do
      if member["phenotype"][i+NUM_INPUT_NODES]["value"] > 0 then
	 CONTROLLER[BUTTONS[i]] = true
      else
	 CONTROLLER[BUTTONS[i]] = false
      end
   end

   return member
end

--[[

--]]
function rankAllMembers(pool)
   local allMembers = {}

   for i=1, #pool["species"], 1 do
      for j=1, #pool["species"][i]["members"], 1 do
	 table.insert(allMembers, pool["species"][i]["members"][j])
      end
   end

   table.sort(allMembers, function (memberA, memberB)
		 return memberA["fitness"] < memberB["fitness"]
   end)

   for i=1, #allMembers, 1 do
      allMembers[i]["rank"] = i
   end

   return pool
end

--[[

--]]
function calculateAverageRank(species)
   local sum = 0
   
   for _,member in pairs(species["members"]) do
      sum = sum + member["rank"]
   end

   species["averageRank"] = sum / #species["members"]
   
   return species
end

--[[

--]]
function sumAverageRanks(pool)
   local sum = 0

   for _,species in pairs(pool["species"]) do
      sum = sum + species["averageRank"]
   end
   
   return sum
end

--[[

--]]
function removeUnworthy(pool, removeType, sum)
   local worthySpecies = {}

   -- Loop through all the species backwards
   for i=#pool["species"], 1, -1 do
      local species = pool["species"][i]

      -- UNINTERESTING SPECIES
      if removeType == 0 then
	 -- Sort members by fitness
	 table.sort(species["members"], function(memberA, memberB)
		       return (memberA["fitness"] > memberB["fitness"])
	 end)

	 -- Check to see if the best members is better than what was already recorded
	 if species["members"][1]["fitness"] > species["bestFitness"] then
	    species["bestFitness"] = species["members"][1]["fitness"]
	    species["uninteresting"] = 0
	 else
	    species["uninteresting"] = species["uninteresting"] + 1
	 end

	 -- If the species is uninteresting then remove it
	 if species["uninteresting"] >= UNINTERESTING_THRESHOLD and species["bestFitness"] < pool["bestFitness"] then
	    table.remove(pool["species"], i)
	 end
      -- WEAK SPECIES
      elseif removeType == 1 then
	 local breed = math.floor(species["averageRank"] / sum * POPULATION)
	 
	 if breed < 1 then
	    table.remove(pool["species"], i)
	 end
      -- REMOVE UNWORTHY MEMBERS OF SPECIES
      elseif removeType >= 2 then
	 local remaining = #species["members"]
	 table.sort(species["members"], function(memberA, memberB)
		       return (memberA["fitness"] > memberB["fitness"])
	 end)

	 if removeType == 2 then
	    remaining = math.ceil(#species["members"]/2)
	 elseif removeType == 3 then
	    remaining = 1
	 end

	 while #species["members"] > remaining do
	    table.remove(species["members"])
	 end
      end
   end

   return pool
end

--[[

--]]
function breed(species)
   local child = {}
   if math.random() < CROSSOVER_CHANCE then
      local memberA = species["members"][math.random(1, #species["members"])]
      local memberB = species["members"][math.random(1, #species["members"])]
      child = crossover(memberA, memberB)
   else
      local member = species["members"][math.random(1, #species["members"])]
      child = copyMember(member)
   end
       
   child = mutate(child)
       
   return child
end

--[[

--]]
function beginNextGeneration(pool)
   local uninteresting = 0
   local weak = 1
   local halfMembers = 2
   local allButOneMember = 3

   -- Begin straining out bad species and members
   -- Cut out the bottom half of each species based on fitness
   pool = removeUnworthy(pool, halfMembers, 0)

   -- Rank the members and then remove uninteresting species
   pool = rankAllMembers(pool)
   pool = removeUnworthy(pool, uninteresting, 0)

   -- Rerank the members and then calculate the average rank of each species
   pool = rankAllMembers(pool)
   for _,species in pairs(pool["species"]) do
      species = calculateAverageRank(species)
   end

   -- Remove "weak" species based on average ranks
   pool = removeUnworthy(pool, weak, sumAverageRanks(pool))

   -- Sum up the average ranks of the remaining species
   local sum = sumAverageRanks(pool)

   -- Breed new children
   local newMembers = {}
   for i=1, #pool["species"], 1 do
      local breedNum = math.floor(pool["species"][i]["averageRank"] / sum * POPULATION) - 1
      for j=1, breedNum, 1 do
	 table.insert(newMembers, breed(pool["species"][i]))
      end
   end

   -- Cut out all members but one of each species
   pool = removeUnworthy(pool, allButOneMember, 0)

   -- Breed more new children. Do it until the POPULATION amount
   while #newMembers + #pool["species"] < POPULATION do
      local species = pool["species"][math.random(1, #pool["species"])]
      table.insert(newMembers, breed(species))
   end

   -- Finally add the newMembers to their respecitve species
   for i=1, #newMembers, 1 do
      pool = addMemberToSpecies(pool, newMembers[i])
   end

   -- Go to the next generation
   pool["generation"] = pool["generation"] + 1

   if WRITE then
      writeFile("backup." .. pool["generation"] .. ".SMB1.1", pool)
   end
   
   return pool
end

function nextMember(pool)
   pool["currentMember"] = pool["currentMember"] + 1
   if pool["currentMember"] > #pool["species"][pool["currentSpecies"]]["members"] then
      pool["currentMember"] = 1
      pool["currentSpecies"] = pool["currentSpecies"] + 1
      
      if pool["currentSpecies"] > #pool["species"] then
	 pool = beginNextGeneration(pool)
	 pool["currentSpecies"] = 1
      end
   end
   
   return pool
end

function computeFitness(member)
   local fitness = FURTHEST_X - FRAMES / 2

   if FURTHEST_X > 3186 then
      fitness = fitness + 1000
      client.closerom()
      END_GAME = true
   end

   -- This should never happen
   if fitness == 0 then
      fitness = -1
   end
   
   return fitness
end

--[[

--]]
function countUnique(cNodesA, cNodesB)
   local numUniqueMembers = 0
   for _,cNode in pairs(cNodesA) do
      if cNodesB[cNode["innovation"]] == nil then
	 numUniqueMembers = numUniqueMembers + 1
      end
   end

   for _,cNode in pairs(cNodesB) do
      if cNodesA[cNode["innovation"]] == nil then
	 numUniqueMembers = numUniqueMembers + 1
      end      
   end

   return numUniqueMembers
end

--[[

--]]
function averageOfSummedDiffsOfWeights(cNodesA, cNodesB, numA, numB)
   local innovationsOfMemB = {}
   for _,cNode in pairs(cNodesB) do
      innovationsOfMemB[cNode["innovation"]] = cNode
   end
 
   local sum = 0
   local totalNumber = 0
   for _,cNode in pairs(cNodesA) do
      if innovationsOfMemB[cNode["innovation"]] ~= nil then
	 local cNode2 = innovationsOfMemB[cNode["innovation"]]
	 sum = sum + math.abs(cNode["weight"] - cNode2["weight"])
	 totalNumber = totalNumber + 1
      end
   end
       
   return sum / totalNumber
end

--[[

--]]
function isPartOfTheSame(memberA, memberB)
   local numMembers = math.max(memberA["genotype"]["numCNodes"], memberB["genotype"]["numCNodes"])
   local weightedUniquePercentage = SPECIES_UNIQUE_CHANCE * (countUnique(memberA["genotype"]["cNodes"], memberB["genotype"]["cNodes"]) / numMembers)
   local weightedWeightsPercentage = SPECIES_WEIGHTS_CHANCE * averageOfSummedDiffsOfWeights(memberA["genotype"]["cNodes"], memberB["genotype"]["cNodes"])
   
   return weightedUniquePercentage + weightedWeightsPercentage < SPECIES_THRESHOLD
end

function addMemberToSpecies(pool, member)
   local found = false

   for _,species in pairs(pool["species"]) do
      if isPartOfTheSame(member, species["members"][1]) then
	 table.insert(species["members"], member)
	 found = true
	 break
      end
   end

   -- If the species was not found, then create a new species
   if not found then
      local species = newSpecies()
      table.insert(species["members"], member)
      table.insert(pool["species"], species)
   end

   return pool
end

--[[
   SET_UP_INITIAL_C_NODES:
   DO NOT USE!
--]]
function setUpInitialCNodes(member)
   for i=1, NUM_INPUT_NODES, 1 do
      for j=1, NUM_OUTPUT_NODES, 1 do
	 local cNode = newConnectionNode(i, j+NUM_INPUT_NODES)
	 member["genotype"]["numCNodes"] = member["genotype"]["numCNodes"] + 1
	 cNode["weight"] = math.random() + math.random(-2, 2)
	 table.insert(GLOBAL_INNOVATIONS, { ["in"]= i, ["out"]= j+NUM_INPUT_NODES })
	 cNode["innovation"] = #GLOBAL_INNOVATIONS
	 member["genotype"]["cNodes"][#GLOBAL_INNOVATIONS] = cNode
      end
   end

   return member
end

function clearJoypad()
   for i=1, #BUTTONS, 1 do
      CONTROLLER[BUTTONS[i]] = false
   end
   joypad.set(CONTROLLER)
end

function evaluation(member)
   local inputs = getInputs()
	 
   evaluatePhenotype(member, inputs)

   if CONTROLLER["P1 Left"] and CONTROLLER["P1 Right"] then
      CONTROLLER["P1 Left"]  = false
      CONTROLLER["P1 Right"] = false
   end
   if CONTROLLER["P1 Up"] and CONTROLLER["P1 Down"] then
      CONTROLLER["P1 Up"]   = false
      CONTROLLER["P1 Down"] = false
   end
	
   joypad.set(CONTROLLER)
end

function beginRun(pool)
   savestate.load(SAVE_STATE)
   FURTHEST_X = 0
   FRAMES = 0
   TIMEOUT = 20
   clearJoypad()

   local species = pool["species"][pool["currentSpecies"]]
   local member = species["members"][pool["currentMember"]]
   member = generatePhenotype(member)
   evaluation(member)

   return pool
end

function playTop(pool)
   local maxfitness = 0
   local maxs, maxg
   for i,species in pairs(pool["species"]) do
      for j,member in pairs(species["members"]) do
	 if member["fitness"] > maxfitness then
	    maxfitness = member["fitness"]
	    maxs = i
	    maxg = j
	 end
      end
   end
	
   pool["currentSpecies"] = 34
   pool["currentMember"] = 16
   pool["bestFitness"] = maxfitness

   beginRun(pool)

   return pool
end

--[[
   CREATE_INITIAL_POPULATION:
--]]
function createInitialPopulation(loadFromFile, playBest)
   local pool

   if loadFromFile then
      local fileName = "backup.67.SMB1.1"
      pool = loadFile(fileName)

--      while pool["species"][pool["currentSpecies"]]["members"][pool["currentMember"]]["fitness"] ~= 0 do
--	 pool = nextMember(pool)
--      end
   else
      pool = newPool()

      for i=1, POPULATION, 1 do
	 local member = newMember()
	 member = mutate(member)
	 pool = addMemberToSpecies(pool, member)
      end
   end

   
   if playBest then
      pool = playTop(pool)
   else
      pool = beginRun(pool)
   end

   return pool
end

function main()
   --[[ Step 1 (Variation)
      Create a population (species) of N elements with random genetic material
      Heredity
      Variation
      Selection
   --]]
   local doLoad = true
   local playBest = true
   local pool = createInitialPopulation(doLoad, playBest)

   while true do
      local backgroundColor = 0xD0FFFFFF
      if not forms.ischecked(hideBanner) then
	 gui.drawBox(0, 0, 300, 32, backgroundColor, backgroundColor)
      end

      local species = pool["currentSpecies"]
      local member  = pool["currentMember"]

      if forms.ischecked(showNetwork) then
	 displayMember(pool["species"][species]["members"][member])
      end      
      
      -- Evaluate the phenotype (network) and get the outputs (controller) then set the controller to it
      if FRAMES % 5 == 0 then
	 evaluation(pool["species"][species]["members"][member])
      end
      joypad.set(CONTROLLER)
      
      -- Get Mario's position after evaluating the phenotype and check to see if there was an improvement.
      local pos = getAllPositions()
      if pos["mX"] > FURTHEST_X then
	 FURTHEST_X = pos["mX"]
	 TIMEOUT = 20
      end
      
      -- Lower the timeout and (using the bonusTime) check to see if we ran out of time for Mario to move
      TIMEOUT = TIMEOUT - 1
      local bonusTime = FRAMES / 4
      if TIMEOUT + bonusTime <= 0 then
	 pool["species"][species]["members"][member]["fitness"] = computeFitness(pool["species"][species]["members"][member])

	 if pool["species"][species]["members"][member]["fitness"] > pool["bestFitness"] then
	    pool["bestFitness"] = pool["species"][species]["members"][member]["fitness"]
	    if WRITE then
	       writeFile("backup." .. pool["generation"] .. ".SMB1.1", pool)
	    end
	    if END_GAME then
	       return
	    end
	 end

	 console.writeline("Gen " .. pool["generation"] .. " species " .. pool["currentSpecies"] .. " member " .. pool["currentMember"] ..
			      " fitness: " .. pool["species"][species]["members"][member]["fitness"])

	 if not doLoad then
	    pool["currentSpecies"] = 1
	    pool["currentMember"] = 1
	 
	    while pool["species"][pool["currentSpecies"]]["members"][pool["currentMember"]]["fitness"] ~= 0 do
	       pool = nextMember(pool)
	    end
	 else
	    pool = nextMember(pool)
	 end
	
	 beginRun(pool)
      end
      
      --[[ Call display information every frame --]]
      local measured = 0
      local total = 0
      for _,species in pairs(pool["species"]) do
	 for _,member in pairs(species["members"]) do
	    total = total + 1
	    if member["fitness"] ~= 0 then
	       measured = measured + 1
	    end
	 end
      end
      
      if not forms.ischecked(hideBanner) then
	 gui.drawText(0, 5, "Gen " .. pool["generation"] .. " species " .. pool["currentSpecies"] .. " member " .. pool["currentMember"] .. " (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
	 gui.drawText(0, 17, "Fitness: " .. math.floor(FURTHEST_X - (FRAMES) / 2 - (TIMEOUT + bonusTime)*2/3), 0xFF000000, 11)
	 gui.drawText(100, 17, "Max Fitness: " .. math.floor(pool["bestFitness"]), 0xFF000000, 11)
      end
      
      --[[ Advance a frame --]]
      FRAMES = FRAMES + 1
      emu.frameadvance()
   end
end

main()

--[[
   IMPORTANT: Only thing different is that I do not give myself multiple chances
   MUTATE:
Parameters:
   member - This is the current member/genome that will be mutated
Return:
   member - The mutated member/genome
   TODO: TEST!
--]]
function mutate(member)
   -- Change rate of mutation chances
   for mutation,chance in pairs(member["mutationChances"]) do
      if math.random(1,2) == 1 then
	 member["mutationChances"][mutation] = 0.95*chance
      else
	 member["mutationChances"][mutation] = 1.05263*chance
      end
   end
   
   -- Add Connection: Single new connection gene with a random weight is added connecting two previously unconnected nodes
   local chance = member["mutationChances"]["connection"]
   while chance > 0 do
      if math.random() < chance then
	 member["genotype"] = addConnectionMutation(member["genotype"], false)
      end
      chance = chance - 1
   end

   chance = member["mutationChances"]["connection"]
   while chance > 0 do
      if math.random() < chance then
	 member["genotype"] = addConnectionMutation(member["genotype"], true)
      end
      chance = chance - 1
   end
   
   --[[ Add Node: An existing connection is split and the new node placed where the old connection used to be. Old: disabled. Two New: Added 
        New connection leading into the new node receives a weight of 1, and the new connection leading out receives the same weight as the
        old connection.
   --]]
   chance = member["mutationChances"]["node"]
   while chance > 0 do
      if math.random() < chance then
	 member["genotype"] = addNodeMutation(member["genotype"])
      end
      chance = chance - 1
   end

   chance = member["mutationChances"]["weight"]
   while chance > 0 do
      if math.random() < chance then
	 member = addWeightMutation(member)
      end
      chance = chance - 1
   end
   
   chance = member["mutationChances"]["enable"]
   while chance > 0 do
      if math.random() < chance then
	 member["genotype"] = addEnableDisableMutation(member["genotype"], true)
      end
      chance = chance - 1
   end
   
   chance = member["mutationChances"]["disable"]
   while chance > 0 do
      if math.random() < chance then
	 member["genotype"] = addEnableDisableMutation(member["genotype"], false)
      end
      chance = chance - 1
   end
   
   return member
end

--[[
   IMPORTANT: POSSIBLE PROBLEMS HERE!
   The randomNode function is most likely behaving badly.
   I do not take into account forceBias
   ADD_CONNECTION_MUTATION:
   
   Finished!
   TODO: TEST!

Parameters:
Return:

--]]
function addConnectionMutation(genotype, isBias)
   local nodeIn
   local outputNodes
   local nodeOut
   local globalInnovationIndex

   -- Get an input and an output node and use them to check if a connection between them already exists.   
   nodeIn  = getRandomNode(genotype, 0)
   nodeOut = getRandomNode(genotype, 1)

   if nodeIn <= NUM_INPUT_NODES and nodeOut <= NUM_INPUT_NODES then
      return genotype
   end

   if nodeOut <= NUM_INPUT_NODES then
      local tempNode = nodeIn
      nodeIn = nodeOut
      nodeOut = tempNode
   end

   if isBias then
      nodeIn = NUM_INPUT_NODES
   end
   
   globalInnovationIndex = checkInnovation(nodeIn, nodeOut)

   -- If the innovation exists, then just change it's weight
   -- If it doesn't exist, create it
   if globalInnovationIndex > 0 then
      if genotype["cNodes"][globalInnovationIndex] == nil then
	 genotype["numCNodes"] = genotype["numCNodes"] + 1
      end
      genotype["cNodes"][globalInnovationIndex] = newConnectionNode(nodeIn, nodeOut)
      genotype["cNodes"][globalInnovationIndex]["weight"] = math.random() + math.random(-2, 2)
      genotype["cNodes"][globalInnovationIndex]["innovation"] = globalInnovationIndex
   else
      local connectionNode = newConnectionNode(nodeIn, nodeOut)

      -- Insert the new innovation to the global list (which increments the number of innovations count)
      table.insert(GLOBAL_INNOVATIONS, { ["in"]= nodeIn, ["out"]= nodeOut })

      -- Add the new innovation to the connection node and create a random weight
      connectionNode["innovation"] = #GLOBAL_INNOVATIONS
      connectionNode["weight"] = math.random() + math.random(-2, 2)
   
      -- Add the new connection node to the genotype and increase the connection node count
      genotype["cNodes"][connectionNode["innovation"]] = connectionNode
      genotype["numCNodes"] = genotype["numCNodes"] + 1
   end

   return genotype
end

--[[
   NO PROBLEMS HERE!
   ADD_NODE_MUTATION:

   Finished!
   TODO: TEST!

Parameters:
Return:

--]]
function addNodeMutation(genotype)
   if genotype["numCNodes"] == 0 then
      return
   end

   -- Get a random connection node
   local index  = getRandomConnection(genotype)
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
      table.insert(GLOBAL_INNOVATIONS, { ["in"]= input, ["out"]= genotype["numNodeGenes"] })      
      globalInnovationIndex1 = #GLOBAL_INNOVATIONS
   end

   if globalInnovationIndex2 == 0 then
      table.insert(GLOBAL_INNOVATIONS, { ["in"]= genotype["numNodeGenes"], ["out"]= input })
      globalInnovationIndex2 = #GLOBAL_INNOVATIONS
   end

   -- Add the innovation to the connections
   connection1["innovation"] = globalInnovationIndex1
   connection2["innovation"] = globalInnovationIndex2

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

   return genotype
end

--[[
   IMPORTANT: POSSIBLE PROBLEMS HERE!
   SOME DIFFERENCES ARE THAT THIS CHOOSES A RANDOM CONNECTION. IT DOES NOT GO THROUGH
   ALL CONNECTIONS. Also math is a bit different. Also the chances are different.
   ADD_WEIGHT_MUTATION:
Parameters:
Return:
--]]
function addWeightMutation(member)
   for _,cNode in pairs(member["genotype"]["cNodes"]) do
      if math.random() < 0.9 then
	 cNode["weight"] = cNode["weight"] - math.random(0, member["mutationChances"]["weightStep"])
      else
	 cNode["weight"] = math.random() + math.random(-2, 2)
      end
   end
   
   return member
end

--[[
   IMPORTANT: I do NOT check to see if already enabled or not!
   ADD_ENABLE_DISABLE_MUTATION:
Parameters:
Return:
--]]
function addEnableDisableMutation(genotype, enable)
   local cNodes = {}
   for _,cNode in pairs(genotype["cNodes"]) do
      if cNode["active"] == not enable then
	 table.insert(cNodes, cNode)
      end
   end

   if #cNodes == 0 then
      return genotype
   end

   local cNode = cNodes[math.random(1,#cNodes)]
   cNode["active"] = not cNode["active"]
   --[[local index = getRandomConnection(genotype)
   
   if enable then
      genotype["cNodes"][index]["active"] = true
   else
      genotype["cNodes"][index]["active"] = false
      end--]]

   return genotype
end

--[[
   IMPORTANT POSSIBLY NO PROBLEMS HERE!
   Does not get maxneuron in the same way it does in the other neat.
   Inserts a bit differently. Takes into account if the fitnesses are the same or not.
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
      memberBCNodes[cNode["innovation"]] = cNode
   end

   -- Add the nodes from the parents to the child
   local nonUniqueBCNodes = {}
   local nodesAdded = {}
   for _,cNodeA in pairs(memberA["genotype"]["cNodes"]) do
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
	 
	 if nodesAdded[cNodeB["in"]] == nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	    nodesAdded[cNodeB["in"]] = true
	 end

	 if nodesAdded[cNodeB["out"]] == nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	    nodesAdded[cNodeB["out"]] = true
	 end
      else
	 child["genotype"]["cNodes"][cNodeA["innovation"]] = copyCNode(cNodeA)
	 child["genotype"]["numCNodes"] = child["genotype"]["numCNodes"] + 1
	 
	 if nodesAdded[cNodeA["in"]] == nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	    nodesAdded[cNodeA["in"]] = true
	 end

	 if nodesAdded[cNodeA["out"]] == nil then
	    child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	    nodesAdded[cNodeA["out"]] = true
	 end
      end
   end
   
   -- Add the remaining disjoint and excess nodes from memberB
   for _,cNode in pairs(memberBCNodes) do
      if nonUniqueBCNodes[cNode["innovation"]] == nil then
	 child["genotype"]["cNodes"][cNode["innovation"]] = copyCNode(cNode)
      end

      if nodesAdded[cNode["in"]] == nil then
	 child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 nodesAdded[cNode["in"]] = true
      end

      if nodesAdded[cNode["out"]] == nil then
	 child["genotype"]["numNodeGenes"] = child["genotype"]["numNodeGenes"] + 1
	 nodesAdded[cNode["out"]] = true
      end      
   end

   -- Copy over the mutation chances
   for mutation,chance in pairs(memberA["mutationChances"]) do
      child["mutationChances"][mutation] = chance
   end

   return child
end

--[[
   IMPORTANT: Does not SEEM to have a counterpart!
   IMPORTANT: POSSIBLE COUNTERPART: cotainsLink
--]]
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

function getRandomConnection(genotype)
   local index = math.random(genotype["numCNodes"])
   local cNodeIndex = 0
   local i = 0
   for _,cNode in pairs(genotype["cNodes"]) do
      i = i + 1
      cNodeIndex = cNode["innovation"]

      if i == index then
	 break
      end
   end

   return cNodeIndex
end

--[[
   IMPORTANT: POSSIBLE PROBLEMS HERE! THINGS ARE DONE QUITE DIFFERENTLY HERE!
   GET_RANDOM_NODE:
   Gets a random node
--]]
function getRandomNode(genotype, nodeType)
   local node = 0
   local nodes = {}
   local numNodes = 0
   if nodeType == 0 then
      for i=1, NUM_INPUT_NODES, 1 do
	 nodes[i] = true
	 numNodes = numNodes + 1
      end
   end

   for i=1+NUM_INPUT_NODES, NUM_INPUT_NODES+NUM_OUTPUT_NODES, 1 do
      nodes[i] = true
      numNodes = numNodes + 1
   end

   for _,cNode in pairs(genotype["cNodes"]) do
      if cNode["in"] > NUM_INPUT_NODES+NUM_OUTPUT_NODES and nodes[cNode["in"]] == nil then
	 nodes[cNode["in"]] = true
	 numNodes = numNodes + 1
      end
      if cNode["out"] > NUM_INPUT_NODES+NUM_OUTPUT_NODES and nodes[cNode["out"]] == nil then
	 nodes[cNode["out"]] = true
	 numNodes = numNodes + 1
      end
   end

   local choosenNode = math.random(1, numNodes)

   for curNode,_ in pairs(nodes) do
      choosenNode = choosenNode - 1
      if choosenNode == 0 then
	 node = curNode
      end
   end
   
   return node
end
--[[function getRandomNode(genotype, availableOutputs)
   local node
   local outputNodes = { ["nodes"]= {}, ["numNodes"]= 0 }

   if availableOutputs["numNodes"] ~= 0 then
      -- For choosing the output node
      node = availableOutputs["nodes"][math.random(1, #availableOutputs["nodes"])]
   else
      -- For choosing the input node 
      local foundNode
      local tryNum = 0
      
      -- Keep going until a valid node is found
      repeat
	 foundNode = true

	 -- Generate the outputNodes NOTE: These are both output and hidden nodes
	 for i=1,genotype["numNodeGenes"]-NUM_INPUT_NODES,1 do
	    outputNodes["nodes"][i] = NUM_INPUT_NODES+i
	    outputNodes["numNodes"] = outputNodes["numNodes"] + 1
	 end

	 -- Find a random node that is not an output node
	 repeat
	    node = math.random(genotype["numNodeGenes"])
	 until (node > NUM_INPUT_NODES + NUM_OUTPUT_NODES or node <= NUM_INPUT_NODES)

	 -- Remove nodes from outputNodes table
	 for _,cNode in pairs(genotype["cNodes"]) do
	    --for i=1, genotype["numCNodes"], 1 do
	    if cNode["in"] == node then
	       for j=#outputNodes["nodes"], 1, -1 do
		  if outputNodes["nodes"][j] == cNode["out"] then
		     table.remove(outputNodes["nodes"], j)
		     outputNodes["numNodes"] = outputNodes["numNodes"] - 1
		  end
	       end
	    end
	 end

	 -- Check if there are no outputNodes left
	 if outputNodes["numNodes"] == 0 then
	    foundNode = false
	 end

	 tryNum = tryNum + 1
      until (foundNode or tryNum > 150)
   end

   return node, outputNodes
end
--]]

--[[
   TODO: Make it equal to outputs??
   {
       "in":  #,
       "out": #
   }
--]]
GLOBAL_INNOVATIONS = {}

--[[
   NO PROBLEM HERE!
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
      ["species"]= {},
      ["generation"]= 0,
      ["currentSpecies"]= 1,
      ["currentMember"]= 1,
      ["bestFitness"]= 0
      -- TODO: Do i need to keep track of innovation differently?
   }

   return pool
end

--[[
   NO PROBLEM HERE!
   NEW_SPECIES:
   Creates a new species with empty everything.
Parameters:
   None
Return:
   Returns the newly created species
--]]
function newSpecies()
   local species = {
      ["bestFitness"]= 0,
      -- Table of members. Indexes are just numbers. Is #members safe.
      ["members"]= {},
      ["averageRank"]= 0,
      ["uninteresting"]= 0
   }

   return species
end

--[[
   POSSSIBLY NO PROBLEM HERE!
   NEW_MEMBER:
   Creates a new member with empty everything, except the mutationChances.
Parameters:
   None
Return:
   Returns the newly created member
--]]
function newMember()
   local member = {
      ["genotype"]= {
	 -- Table of connection nodes. Indexes represent the innovation numbers. Is NOT #cNodes safe
	 ["cNodes"]= {},
	 -- How this works is that 1 - NUM_INPUT_NODES are input nodes.
	 -- (MAX_NODES + NUM_OUTPUT_NODES) - MAX_NODES are the output nodes.
	 -- The inbetween nodes are the hidden nodes
	 ["numNodeGenes"]= NUM_INPUT_NODES+NUM_OUTPUT_NODES,
	 ["numCNodes"]= 0,
	 ["nodeSequence"]= {}
	 -- TODO: Do i need to do a maxneuron?
		  },
      ["phenotype"]= {},
      ["mutationChances"]= {
	 ["weight"]= WEIGHT_CHANCE,
	 ["weightStep"]= STEP,
	 ["node"]= NODE_CHANCE,
	 ["connection"]= CONNECTION_CHANCE,
	 ["enable"]= ENABLE_CHANCE,
	 ["disable"]= DISABLE_CHANCE
			 },
      ["fitness"]= 0,
      ["adjustedFitness"]= 0,
      ["rank"]= 0
   }

   return member
end

--[[
   NO PROBLEMS HERE!
--]]
function copyMember(member)
   local newMember = newMember()

   --newMember["fitness"] = member["fitness"]
   --newMember["rank"] = member["rank"]
   newMember["genotype"]["numNodeGenes"] = member["genotype"]["numNodeGenes"]
   newMember["genotype"]["numCNodes"] = member["genotype"]["numCNodes"]
   
   for cNodeInnovation,cNode in pairs(member["genotype"]["cNodes"]) do
      newMember["genotype"]["cNodes"][cNodeInnovation] = copyCNode(cNode)
   end

   --[[for i=1, #member["genotype"]["nodeSequence"], 1 do
      table.insert(newMember["genotype"]["nodeSequence"], member["genotype"]["nodeSequence"][i])
      end--]]
   
   for mutationName,mutationChance in pairs(member["mutationChances"]) do
      newMember["mutationChances"][mutationName] = mutationChance
   end

   return newMember
end

--[[
   NO PROBLEMS HERE!
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
      ["in"]= nodeIn,
      ["out"]= nodeOut,
      ["weight"]= 0,
      ["active"]= true,
      ["innovation"]= 0
   }
   
   return connectionNode
end

--[[
   NO PROBLEMS HERE!
--]]
function copyCNode(cNode)
   local cNode2 = newConnectionNode(cNode["in"], cNode["out"])

   cNode2["active"] = cNode["active"]
   cNode2["innovation"] = cNode["innovation"]
   cNode2["weight"] = cNode["weight"]

   return cNode2
end

--[[
   NO PROBLEMS HERE!
--]]
function newNeuron()
   local neuron = {
      ["value"]= 0.0,
      ["incomingCNodes"]= {},
   }

   return neuron
end

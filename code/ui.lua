function displayMember(member)
   local phenotype = member["phenotype"]
   local cells = {}
   local i = 1
   local cell = {}

   for dy=-BOX_RADIUS,BOX_RADIUS do
      for dx=-BOX_RADIUS,BOX_RADIUS do
	 cell = {}
	 cell.x = 50+5*dx
	 cell.y = 70+5*dy
	 cell.value = phenotype[i]["value"]
	 cells[i] = cell
	 i = i + 1
      end
   end
   local biasCell = {}
   biasCell.x = 80
   biasCell.y = 110
   biasCell.value = phenotype[NUM_INPUT_NODES]["value"]
   cells[NUM_INPUT_NODES] = biasCell
	
   for o = 1,NUM_OUTPUT_NODES do
      cell = {}
      cell.x = 220
      cell.y = 30 + 8 * o
      cell.value = phenotype[NUM_INPUT_NODES + o]["value"]
      cells[NUM_INPUT_NODES+o] = cell
      local color
      if cell.value > 0 then
	 color = 0xFF0000FF
      else
	 color = 0xFF000000
      end
      gui.drawText(223, 24+8*o, BUTTONS[o], color, 9)
   end
   
   for n,neuron in pairs(phenotype) do
      cell = {}
      if n == NUM_INPUT_NODES or n > NUM_OUTPUT_NODES + NUM_INPUT_NODES then
	 cell.x = 140
	 cell.y = 40
	 cell.value = neuron["value"]
	 cells[n] = cell
      end
   end
   
   for n=1,4 do
      for _,cNode in pairs(member["genotype"]["cNodes"]) do
	 if cNode["active"] then
	    local c1 = cells[cNode["in"]]
	    local c2 = cells[cNode["out"]]
	    if cNode["in"] == NUM_INPUT_NODES or cNode["in"] > NUM_INPUT_NODES + NUM_OUTPUT_NODES then
	       c1.x = 0.75*c1.x + 0.25*c2.x
	       if c1.x >= c2.x then
		  c1.x = c1.x - 40
	       end
	       if c1.x < 90 then
		  c1.x = 90
	       end
	       
	       if c1.x > 220 then
		  c1.x = 220
	       end
	       c1.y = 0.75*c1.y + 0.25*c2.y
	       
	    end
	    if cNode["out"] == NUM_INPUT_NODES or cNode["out"] > NUM_INPUT_NODES + NUM_OUTPUT_NODES then
	       c2.x = 0.25*c1.x + 0.75*c2.x
	       if c1.x >= c2.x then
		  c2.x = c2.x + 40
	       end
	       if c2.x < 90 then
		  c2.x = 90
	       end
	       if c2.x > 220 then
		  c2.x = 220
	       end
	       c2.y = 0.25*c1.y + 0.75*c2.y
	    end
	 end
      end
   end
   
   gui.drawBox(50-BOX_RADIUS*5-3,70-BOX_RADIUS*5-3,50+BOX_RADIUS*5+2,70+BOX_RADIUS*5+2,0xFF000000, 0x80808080)
   for n,cell in pairs(cells) do
      if n > NUM_INPUT_NODES or cell.value ~= 0 then
	 local color = math.floor((cell.value+1)/2*256)
	 if color > 255 then color = 255 end
	 if color < 0 then color = 0 end
	 local opacity = 0xFF000000
	 if cell.value == 0 then
	    opacity = 0x50000000
	 end
	 color = opacity + color*0x10000 + color*0x100 + color
	 gui.drawBox(cell.x-2,cell.y-2,cell.x+2,cell.y+2,opacity,color)
      end
   end
   for _,cNode in pairs(member["genotype"]["cNodes"]) do
      if cNode["active"] then
	 local c1 = cells[cNode["in"]]
	 local c2 = cells[cNode["out"]]
	 local opacity = 0xA0000000
	 if c1.value == 0 then
	    opacity = 0x20000000
	 end
	 
	 local color = 0x80-math.floor(math.abs(sigmoid(cNode["weight"]))*0x80)
	 if cNode["weight"] > 0 then 
	    color = opacity + 0x8000 + 0x10000*color
	 else
	    color = opacity + 0x800000 + 0x100*color
	 end
	 gui.drawLine(c1.x+1, c1.y, c2.x-3, c2.y, color)
      end
   end
   
   gui.drawBox(49,71,51,78,0x00000000,0x80FF0000)
   
   if forms.ischecked(showMutationRates) then
      local pos = 100
      for mutation,rate in pairs(member["mutationChances"]) do
	 gui.drawText(100, pos, mutation .. ": " .. rate, 0xFF000000, 10)
	 pos = pos + 8
      end
   end
end

function writeFile(filename)
        local file = io.open(filename, "w")
	file:write(pool.generation .. "\n")
	file:write(pool.maxFitness .. "\n")
	file:write(#pool.species .. "\n")
        for n,species in pairs(pool.species) do
		file:write(species.topFitness .. "\n")
		file:write(species.staleness .. "\n")
		file:write(#species.members .. "\n")
		for m,member in pairs(species.members) do
			file:write(member.fitness .. "\n")
			file:write(member.maxneuron .. "\n")
			for mutation,rate in pairs(member["mutationChances"]) do
				file:write(mutation .. "\n")
				file:write(rate .. "\n")
			end
			file:write("done\n")
			
			file:write(#member["genotype"]["cNodes"] .. "\n")
			for l,cNode in pairs(member["genotype"]["cNodes"]) do
				file:write(cNode["in"] .. " ")
				file:write(cNode["out"] .. " ")
				file:write(cNode["weight"] .. " ")
				file:write(cNode.innovation .. " ")
				if(cNode["active"]) then
					file:write("1\n")
				else
					file:write("0\n")
				end
			end
		end
        end
        file:close()
end

function savePool()
	local filename = forms.gettext(saveLoadFile)
	writeFile(filename)
end

function loadFile(filename)
        local file = io.open(filename, "r")
	pool = newPool()
	pool.generation = file:read("*number")
	pool.maxFitness = file:read("*number")
	forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
        local numSpecies = file:read("*number")
        for s=1,numSpecies do
		local species = newSpecies()
		table.insert(pool.species, species)
		species.topFitness = file:read("*number")
		species.staleness = file:read("*number")
		local numMembers = file:read("*number")
		for g=1,numMembers do
			local member = newMember()
			table.insert(species.members, member)
			member.fitness = file:read("*number")
			member.maxneuron = file:read("*number")
			local line = file:read("*line")
			while line ~= "done" do
				member["mutationChances"][line] = file:read("*number")
				line = file:read("*line")
			end
			local numCNodes = file:read("*number")
			for n=1,numCNodes do
				local cNode = newCNode()
				table.insert(member["genotype"]["cNodes"], cNode)
				local enabled
				cNode["in"], cNode["out"], cNode["weight"], cNode.innovation, enabled = file:read("*number", "*number", "*number", "*number", "*number")
				if enabled == 0 then
					cNode["active"] = false
				else
					cNode["active"] = true
				end
				
			end
		end
	end
        file:close()
	
	while fitnessAlreadyMeasured() do
		nextMember()
	end
	initializeRun()
	pool.currentFrame = pool.currentFrame + 1
end

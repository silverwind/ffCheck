Flasks = {}

local noFood, noFlask, oneElixir, unitbuffs = {}, {}, {}, {}

local foods = {
	35272, -- Well Fed
	44106, -- "Well Fed" from Brewfest
	43730, -- Electrified
	43722, -- Enlightened
}

local flasks = {
	17626, -- 17626 Flask of the Titans
	17627, -- 17627 Flask of Distilled Wisdom 
	17628, -- 17628 Flask of Supreme Power 
	17629, -- 17629 Flask of Chromatic Resistance 
	28518, -- 28518 Flask of Fortification
	28519, -- 28519 Flask of Mighty Restoration 
	28520, -- 28520 Flask of Relentless Assault 
	28521, -- 28521 Flask of Blinding Light 
	28540, -- 28540 Flask of Pure Death 
	33053, -- 33053 Mr. Pinchy's Blessing
	42735, -- 42735 Flask of Chromatic Wonder 
	40567, -- 40567 Unstable Flask of the Bandit
	40568, -- 40568 Unstable Flask of the Elder
	40572, -- 40572 Unstable Flask of the Beast
	40573, -- 40573 Unstable Flask of the Physician
	40575, -- 40575 Unstable Flask of the Soldier
	40576, -- 40576 Unstable Flask of the Sorcerer
	41608, -- 41608 Relentless Assault of Shattrath
	41609, -- 41609 Fortification of Shattrath
	41610, -- 41610 Mighty Restoration of Shattrath
	41611, -- 41611 Sureme Power of Shattrath
	46837, -- 46837 Pure Death of Shattrath
	46839, -- 46839 Blinding Light of Shattrath
	-- Flask WotLK
	53752, -- 53752 Lesser Flask of Toughness
	53755, -- 53755 Flask of the Frost Wyrm
	53758, -- 53758 Flask of Stoneblood
	53760, -- 53760 Flask of Pure Mojo
	54212, -- 54212 Flask of Endless Rage
	62380, -- Lesser Flask of Resistance
}

local elixirGuardian = {  
	-- Classic Wow
	11348, -- 11348 Greater Armor 
	11396, -- 11396 Greater Intellect 
	24363, -- 24363 Mana Regeneration 
	-- Burning Crusade
	28502, -- 28502 Major Armor 
	28509, -- 28509 Greater Mana Regeneration 
	28514, -- 28514 Empowerment 
	39625, -- 39625 Elixir of Major Fortitude 
	39627, -- 39627 Elixir of Draenic Wisdom 
	39628, -- 39628 Elixir of Ironskin
	39637, -- 39637 Earthen Elixir  
	-- WotLK
	53747, -- 53747 Elixir of Spirit 
	60347, -- 60347 Elixir of Mighty Thoughts 
	53764, -- 53764 Elixir of Mighty Mageblood 
	53751, -- 53751 Elixir of Mighty Fortitude 
	60343, -- 60343 Elixir of Mighty Defense 
}

local elixirBattle = {
	-- Classic Wow
	11390, -- 11390 Arcane Elixir
	11406, -- 11406 Elixir of Demonslaying
	17538, -- 17538 Elixir of the Mongoose
	17539, -- 17539 Greater Arcane Elixir 
	-- Burning Crusade
	28490, -- 28490 Major Strength 
	28491, -- 28491 Healing Power 
	28493, -- 28493 Major Frost Power 
	28501, -- 28501 Major Firepower 
	28503, -- 28503 Major Shadow Power 
	33720, -- 33720 Onslaught Elixir 
	33721, -- 33721 Spellpower Elixir
	33726, -- 33726 Elixir of Mastery 
	38954, -- 38954 Fel Strength Elixir
	45373, -- 45373 Bloodberry 
	54452, -- 54452 Adept's Elixir 
	54494, -- 54494 Major Agility 
	-- WotLK
	53746, -- 53746 Wrath Elixir
	53749, -- 53749 Guru's Elixir
	53763, -- 53763 Elixir of Protection
	53748, -- 53748 Elixir of Mighty Strength
	28497, -- 53748 Elixir of Mighty Agility
	60346, -- 60346 Elixir of Lightning Speed
	60344, -- 60344 Elixir of Expertise
	60341, -- 60341 Elixir of Deadly Strikes
	60345, -- 60345 Elixir of Armor Piercing
	60340, -- 60340 Elixir of Accuracy
}

function Flasks:Check()
	if GetNumRaidMembers() == 0 then return end
	table.wipe(noFood) table.wipe(noFlask) table.wipe(oneElixir)
	local diff, i = GetInstanceDifficulty(), nil
	for i = 1,GetNumRaidMembers() do
		local _, _, subGroup, _, _, _, _, online, _, _, _ = GetRaidRosterInfo(i)
		if (((diff == 1) or (diff == 3)) and subGroup < 3) or (((diff == 2) or (diff == 4)) and subGroup < 6) and online then
			if self:CheckFood("raid"..i) == false then
				noFood[table.getn(noFood)+1] = UnitName("raid"..i)
			end
			local hasFlask = self:CheckFlask("raid"..i)                
			local hasBattle = self:CheckBattleElixir("raid"..i)        
			local hasGuardian = self:CheckGuardianElixir("raid"..i)
			
			if hasFlask == false and hasBattle == true and hasGuardian == false then
				oneElixir[table.getn(oneElixir)+1] = UnitName("raid"..i)
			elseif hasFlask == false and hasBattle == false and hasGuardian == true then
				oneElixir[table.getn(oneElixir)+1] = UnitName("raid"..i)
			elseif hasFlask == false and hasBattle == false and hasGuardian == false then
				noFlask[table.getn(noFlask)+1] = UnitName("raid"..i)
			end
		end
	end
	local string
	if table.getn(oneElixir) > 0 then
		table.sort(oneElixir)
		string = "Only One Elixir: "..table.concat(oneElixir,", ")
		if IsShiftKeyDown() then
			SendChatMessage(string,"Raid")
		else
			print(string)
		end
	end
	if table.getn(noFlask) > 0 then
		table.sort(noFlask)
		string = "No Flask: "..table.concat(noFlask,", ")
		if IsShiftKeyDown() then
			SendChatMessage(string,"Raid")
		else
			print(string)
		end
	end
	if table.getn(noFood) > 0 then
		table.sort(noFood)
		string = "No Food: "..table.concat(noFood,", ")
		if IsShiftKeyDown() then
			SendChatMessage(string,"Raid")
		else
			print(string)
		end
	end
	if table.getn(oneElixir) == 0 and table.getn(noFood) == 0 and table.getn(noFlask) == 0 then
		print"All Buffed!"
	end
end

function Flasks:CheckFood(unit)
	self:ScanBuffs(unit)
	for i, v in ipairs(foods) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
	return false
end

function Flasks:CheckFlask(unit)
	self:ScanBuffs(unit)
	for i, v in pairs(flasks) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
	return false
end

function Flasks:CheckBattleElixir(unit)
	self:ScanBuffs(unit)
	for i, v in pairs(elixirBattle) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
	return false
end

function Flasks:CheckGuardianElixir(unit)
	self:ScanBuffs(unit)
	for i, v in pairs(elixirGuardian) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
	return false
end

function Flasks:ScanBuffs(unit)
	table.wipe(unitbuffs)
	local index = 1
	while true do
		local name, _, _, _, _, _, _, _, _, _, _ = UnitAura(unit,index)
		if not name then return end
		unitbuffs[name] = true
		index = index + 1
	end
end
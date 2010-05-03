local noFood, noFlask, unitbuffs = {}, {}, {}

local foods = {
	35272, -- Well Fed
	44106, -- "Well Fed" from Brewfest
}

local flasks = {
	17626, -- Flask of the Titans
	17627, -- Flask of Distilled Wisdom
	17628, -- Flask of Supreme Power
	17629, -- Flask of Chromatic Resistance
	28518, -- Flask of Fortification
	28519, -- Flask of Mighty Restoration
	28520, -- Flask of Relentless Assault
	28521, -- Flask of Blinding Light
	28540, -- Flask of Pure Death
	53752, -- Lesser Flask of Toughness
	53755, -- Flask of the Frost Wyrm
	53758, -- Flask of Stoneblood
	53760, -- Flask of Pure Mojo
	54212, -- Flask of Endless Rage
	62380, -- Lesser Flask of Resistance
}

local function ScanBuffs(unit)
	table.wipe(unitbuffs)
	local index = 1
	while true do
		local name, _, _, _, _, _, _, _, _, _, _ = UnitAura(unit,index)
		if not name then return end
		unitbuffs[name] = true
		index = index + 1
	end
end

local function CheckFood(unit)
	ScanBuffs(unit)
	for i, v in ipairs(foods) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
end

local function CheckFlask(unit)
	ScanBuffs(unit)
	for i, v in pairs(flasks) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
end

SLASH_FLASKS1 = "/flasks"
SlashCmdList["FLASKS"] = function()
	if GetNumRaidMembers() == 0 then return end
	table.wipe(noFood) table.wipe(noFlask)
	local diff, i = GetInstanceDifficulty(), nil
	for i = 1,GetNumRaidMembers() do
		local _, _, subGroup, _, _, _, _, online, _, _, _ = GetRaidRosterInfo(i)
		if (((diff == 1) or (diff == 3)) and subGroup < 3) or (((diff == 2) or (diff == 4)) and subGroup < 6) and online then
			if not CheckFood("raid"..i) then
				noFood[#noFood+1] = UnitName("raid"..i)
			end
			if not CheckFlask("raid"..i) then
				noFlask[#noFlask+1] = UnitName("raid"..i)
			end
		end
	end
	local string
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
	if table.getn(noFood) == 0 and table.getn(noFlask) == 0 then
		print"All Buffed!"
	end
end
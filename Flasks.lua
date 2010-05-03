local noFood, noFlask, unitbuffs = {}, {}, {}

local foods = {
	35272, -- Well Fed
	44106, -- "Well Fed" from Brewfest
}

local flasks = {
	17627, -- Flask of Distilled Wisdom
	53752, -- Lesser Flask of Toughness
	53755, -- Flask of the Frost Wyrm
	53758, -- Flask of Stoneblood
	53760, -- Flask of Endless Rage
	54212, -- Flask of Pure Mojo
	62380, -- Lesser Flask of Resistance
}

local function ScanBuffs(unit)
	table.wipe(unitbuffs)
	local i = 1
	while true do
		local name  = UnitAura(unit,i)
		if not name then return end
		unitbuffs[name] = true
		i = i + 1
	end
end

local function CheckFood(unit)
	ScanBuffs(unit)
	for _, v in pairs(foods) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
end

local function CheckFlask(unit)
	ScanBuffs(unit)
	for _, v in pairs(flasks) do
		if unitbuffs[GetSpellInfo(v)] then
			return true
		end
	end
end

local function print(text)
	_G.print("|cff9999eeFlasks: |r"..text)
end

SLASH_FLASKS1 = "/flasks"
SlashCmdList["FLASKS"] = function()
	local num = GetNumRaidMembers()
	if num == 0 then print("Player not in raid, aborting.")	return end
	table.wipe(noFood) table.wipe(noFlask)
	local diff, i = GetInstanceDifficulty(), nil
	for i = 1,num do
		local _, _, subGroup, _, _, _, _, online, _, _, _ = GetRaidRosterInfo(i)
		if (((diff == 1) or (diff == 3)) and subGroup < 3) or (((diff == 2) or (diff == 4)) and subGroup < 6) and online then
			local name = UnitName("raid"..i)
			if not CheckFood("raid"..i) then
				noFood[#noFood+1] = name
			end
			if not CheckFlask("raid"..i) then
				noFlask[#noFlask+1] = name
			end
		end
	end
	local string
	if #noFlask > 0 then
		table.sort(noFlask)
		string = "No Flask: "..table.concat(noFlask,", ")
		if IsShiftKeyDown() then
			SendChatMessage(string,"Raid")
		else
			print(string)
		end
	end
	if #noFood > 0 then
		table.sort(noFood)
		string = "No Food: "..table.concat(noFood,", ")
		if IsShiftKeyDown() then
			SendChatMessage(string,"Raid")
		else
			print(string)
		end
	end
	if #noFood == 0 and #noFlask == 0 then
		print"All Buffed!"
	end
end
local addon = ...
local version = GetAddOnMetadata(addon, "version")
local ldb = LibStub:GetLibrary"LibDataBroker-1.1"
local noFood, noFlask, unitBuffs = {}, {}, {}
ffCheckDB = {}

-- Option Defaults
local NORMALCLICKBEHAVIOR = true
local AUTOREPORT = false

local L = {}
if GetLocale() == "deDE" then
	L.noFood = "Kein Essen: "
	L.noFlask = "Kein Fläschchen: "
	L.allBuffed = "Alles drin!"
	L.tip = "|cffeda55fKlick|r um lokal zu Berichten. |cffeda55fShift-Klick|r um an deine Gruppe zu Berichten. |cffeda55fRechts-Klick|r um die Optionen anzuzeigen."
	L.tip2 = "|cffeda55fKlick|r um an deine Gruppe zu Berichten. |cffeda55fShift-Klick|r um lokal zu Berichten. |cffeda55fRechts-Klick|r um die Optionen anzuzeigen."
	L.reportOnShift = "Shift-Klick berichtet"
	L.toRaid = "an deine Gruppe"
	L.toLocal = "lokal"
	L.reportHelpText = "Notiz: Diese Option vertauscht das Klick / Shift-Klick - Verhalten."
	L.reportOnReadyCheck = "Automatisch bei Bereitschafts-Check an die Gruppe berichten."
else
	L.noFood = "No Food: "
	L.noFlask = "No Flask: "
	L.allBuffed = "All Buffed!"
	L.tip = "|cffeda55fClick|r to report locally. |cffeda55fShift-Click|r to report to your party. |cffeda55fRight-Click|r to show the options."
	L.tip2 = "|cffeda55fClick|r to report to your party. |cffeda55fShift-Click|r to report locally. |cffeda55fRight-Click|r to show the options."
	L.reportOnShift = "Shift-Click reports"
	L.toRaid = "to your party"
	L.toLocal = "locally"
	L.reportHelpText = "Note: This option exchanges the Click / Shift-Click behavior."
	L.reportOnReadyCheck = "Automatically report to your party on Ready Check."
end

local foods = {
	35272, -- Well Fed
	44106, -- "Well Fed" from Brewfest
}

local flasks = {
	--17627, -- Flask of Distilled Wisdom
	--53755, -- Flask of the Frost Wyrm
	--53758, -- Flask of Stoneblood
	--53760, -- Flask of Endless Rage
	--54212, -- Flask of Pure Mojo
	62380, -- Lesser Flask of Resistance
	79469, -- Flask of Steelskin
	79470, -- Flask of the Draconic Mind
	79471, -- Flask of the Winds
	79472, -- Flask of Titanic Strength
	92679, -- Flask of Battle
	94160, -- Flask of Flowing Water
	79631, -- Prismatic Elixir (listed because there is no resistance flask in Cataclysm)
}

local function scan(unit)
	table.wipe(unitBuffs)
	local i = 1
	while true do
		local name = UnitAura(unit,i,"HELPFUL")
		if not name then return end
		unitBuffs[name] = true
		i = i + 1
	end
end

local function checkFood(unit)
	scan(unit)
	for _, id in pairs(foods) do
		if unitBuffs[GetSpellInfo(id)] then
			return true
		end
	end
end

local function checkFlask(unit)
	scan(unit)
	for _, id in pairs(flasks) do
		if unitBuffs[GetSpellInfo(id)] then
			return true
		end
	end
end

local function checkUnit(unit)
	local name = UnitName(unit)
	if not checkFood(unit) then
		noFood[#noFood+1] = name
	end
	if not checkFlask(unit) then
		noFlask[#noFlask+1] = name
	end
end

local function print(text)
	_G.print("|cffffbb11ffCheck: |r"..text)
end

local function getDiff() -- Workaround the "bug" of GetInstanceDifficulty returning 1 when outside the instance.
	if IsInInstance() then
		return GetInstanceDifficulty()
	else
		return select(1,GetRaidDifficulty())
	end
end

-- The Main function to run a check
local function run(autoreport)
	local num = GetNumRaidMembers()
	local diff = getDiff()
	local checkType = "raid"

	local reportToRaid = IsShiftKeyDown() or false
	if not NORMALCLICKBEHAVIOR then reportToRaid = not reportToRaid end
	if autoreport == true then reportToRaid = true end
	table.wipe(noFood)
	table.wipe(noFlask)
	if num == 0 then
		num = GetNumPartyMembers()
		if num > 0 and num <= 4 then
			checkType = "party"
		end
		checkUnit"player"
	end
	for i = 1,num do
		if checkType  == "raid" then
			local _, _, subGroup, _, _, _, _, online = GetRaidRosterInfo(i)
			if (((diff == 1) or (diff == 3)) and subGroup < 3) or (((diff == 2) or (diff == 4)) and subGroup < 6) and online then
				local unit = checkType..i
				checkUnit(unit)
			end
		else
			local unit = checkType..i
			if UnitIsConnected(unit) then
				checkUnit(unit)
			end
		end
	end
	local output
	if #noFlask > 0 then
		table.sort(noFlask)
		output = L.noFlask..table.concat(noFlask,", ")
		if reportToRaid then
			SendChatMessage(output,checkType)
		else
			print(output)
		end
	end
	if #noFood > 0 then
		table.sort(noFood)
		output = L.noFood..table.concat(noFood,", ")
		if reportToRaid then
			SendChatMessage(output,checkType)
		else
			print(output)
		end
	end
	if #noFood == 0 and #noFlask == 0 then
		if reportToRaid then
			SendChatMessage(addon..": "..L.allBuffed,checkType)
		else
			print(L.allBuffed)
		end
	end
end

-- Create the slash command
SLASH_FFCHECK1 = "/ffcheck"
SlashCmdList.FFCHECK = run

-- Create the LDB object
if ldb then
	local object = ldb:NewDataObject(addon, {
		type = "launcher",
		icon = "Interface\\Icons\\inv_potione_6",
		iconCoords = {.07, .93, .07, .93},
		OnClick = function(self,button) if button == "RightButton" then InterfaceOptionsFrame_OpenToCategory"ffCheck" else run(false) end end,
		text = addon,
	})
	function object.OnTooltipShow(tooltip)
		tooltip:AddLine(addon)
		local text = NORMALCLICKBEHAVIOR and L.tip or L.tip2
		tooltip:AddLine(text,0.2, 1, 0.2, 1)
	end
end

-- Event Handler
local f = CreateFrame"Frame"
f:RegisterEvent"ADDON_LOADED"
f:RegisterEvent"READY_CHECK"
f:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... == addon then
			if ffCheckDB.NormalReportBehavior == nil then ffCheckDB.NormalReportBehavior = NORMALCLICKBEHAVIOR end
			if ffCheckDB.AutoReport == nil then ffCheckDB.AutoReport = AUTOREPORT end
			NORMALCLICKBEHAVIOR = ffCheckDB.NormalReportBehavior
			AUTOREPORT = ffCheckDB.AutoReport
		end
	else
		if AUTOREPORT then
			run(true)
		end
	end
end)

-- Options
local opts = CreateFrame("Frame", "ffCheckOptions", InterfaceOptionsFramePanelContainer)
opts.name = addon
opts.okay = function()
	NORMALCLICKBEHAVIOR = ffCheckReportOnShiftRaid:GetChecked() or false
	AUTOREPORT = ffCheckReportOnReadyCheck:GetChecked() or false
	ffCheckDB.NormalReportBehavior = NORMALCLICKBEHAVIOR
	ffCheckDB.AutoReport = AUTOREPORT
end
opts:SetScript("OnShow", function()
	ffCheckReportOnShiftRaid:SetChecked(NORMALCLICKBEHAVIOR)
	ffCheckReportOnShiftLocal:SetChecked(not NORMALCLICKBEHAVIOR)
	ffCheckReportOnReadyCheck:SetChecked(AUTOREPORT)
end)
InterfaceOptions_AddCategory(opts)

local function processRadios(frame)
	local checked = frame:GetChecked() or false
	if frame.index == 1 then
		ffCheckReportOnShiftLocal:SetChecked(not checked)
	else
		ffCheckReportOnShiftRaid:SetChecked(not checked)
	end
end

local title = opts:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -15)
title:SetText(addon.." "..version)
local reportOnShiftText = opts:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
reportOnShiftText:SetPoint("TOPLEFT", 25, -50)
reportOnShiftText:SetText(L.reportOnShift)
local reportOnShiftRaid = CreateFrame("CheckButton", "ffCheckReportOnShiftRaid", opts)
reportOnShiftRaid.index = 1
reportOnShiftRaid:SetPoint("LEFT", reportOnShiftText, "RIGHT", 15, 0)
reportOnShiftRaid:SetSize(17, 17)
reportOnShiftRaid:SetNormalTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftRaid:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
reportOnShiftRaid:SetHighlightTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftRaid:GetHighlightTexture():SetTexCoord(0.5, 0.75, 0, 1)
reportOnShiftRaid:SetCheckedTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftRaid:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
reportOnShiftRaid:SetPushedTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftRaid:GetPushedTexture():SetTexCoord(0, 0.25, 0, 1)
reportOnShiftRaid:SetScript("OnClick", processRadios)
local reportOnShiftRaidText = reportOnShiftRaid:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
reportOnShiftRaidText:SetPoint("LEFT", reportOnShiftRaid, "RIGHT", 0, 1)
reportOnShiftRaidText:SetText(L.toRaid)
reportOnShiftRaid:SetHitRectInsets(0, -reportOnShiftRaidText:GetWidth(), 0, 0)
local reportOnShiftLocal = CreateFrame("CheckButton", "ffCheckReportOnShiftLocal", opts)
reportOnShiftLocal:SetPoint("LEFT", reportOnShiftRaidText, "RIGHT", 20, 0)
reportOnShiftLocal:SetSize(17, 17)
reportOnShiftLocal:SetNormalTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftLocal:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
reportOnShiftLocal:SetHighlightTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftLocal:GetHighlightTexture():SetTexCoord(0.5, 0.75, 0, 1)
reportOnShiftLocal:SetCheckedTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftLocal:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
reportOnShiftLocal:SetPushedTexture"Interface\\Buttons\\UI-RadioButton" reportOnShiftLocal:GetPushedTexture():SetTexCoord(0, 0.25, 0, 1)
reportOnShiftLocal:SetScript("OnClick", processRadios)
local reportOnShiftLocalText = reportOnShiftLocal:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
reportOnShiftLocalText:SetPoint("LEFT", reportOnShiftLocal, "RIGHT", 0, 1)
reportOnShiftLocalText:SetText(L.toLocal)
reportOnShiftLocal:SetHitRectInsets(0, -reportOnShiftLocalText:GetWidth(), 0, 0)
local reportHelpText = opts:CreateFontString("ffCheckOptionsReportHelpText", "ARTWORK", "GameFontHighlightSmall")
reportHelpText:SetPoint("TOPLEFT", 40, -70)
reportHelpText:SetText(L.reportHelpText)
local reportOnReadyCheck = CreateFrame("CheckButton", "ffCheckReportOnReadyCheck", opts)
reportOnReadyCheck:SetWidth(26)
reportOnReadyCheck:SetHeight(26)
reportOnReadyCheck:SetPoint("TOPLEFT", 20, -100)
reportOnReadyCheck:SetNormalTexture"Interface\\Buttons\\UI-CheckBox-Up"
reportOnReadyCheck:SetPushedTexture"Interface\\Buttons\\UI-CheckBox-Down"
reportOnReadyCheck:SetHighlightTexture"Interface\\Buttons\\UI-CheckBox-Highlight"
reportOnReadyCheck:SetCheckedTexture"Interface\\Buttons\\UI-CheckBox-Check"
local reportOnReadyCheckText = reportOnReadyCheck:CreateFontString("ffCheckOptionsReportOnReadyCheckTitle", "ARTWORK", "GameFontHighlight")
reportOnReadyCheckText:SetPoint("LEFT", reportOnReadyCheck, "RIGHT", 0, 1)
reportOnReadyCheckText:SetText(L.reportOnReadyCheck)
reportOnReadyCheck:SetHitRectInsets(0, -reportOnReadyCheckText:GetWidth(), 0, 0)
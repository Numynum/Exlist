local key = "azerite"
local prio = 30
local Exlist = Exlist
local L = Exlist.L
local C_AzeriteItem,C_AzeriteEmpoweredItem = C_AzeriteItem,C_AzeriteEmpoweredItem
local Item = Item
local format = string.format
local tinsert = tinsert
local next, ipairs, pairs = next, ipairs, pairs
local WrapTextInColorCode = WrapTextInColorCode
local colors = Exlist.Colors
--local strings = Exlist.Strings

local function GetAvailableTraits(powerLevel)
	local t = {}
	for _,slot in next, { 1, 3, 5 } do
		-- 1=head,3=shoulders,5=chest
		local item = Item:CreateFromEquipmentSlot(slot)
		if not item:IsItemEmpty() then
			local itemLoc = item:GetItemLocation()
			if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) and C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(itemLoc) then
				-- check if azerite armor has available traits
				local tiers = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
				t[slot] = 0
				for _,tierInfo in ipairs(tiers) do
					if tierInfo.unlockLevel <= powerLevel then
						-- is tier available to player
						local empty = true
						for _,powerId in ipairs(tierInfo.azeritePowerIDs) do
							-- check if player has selected any of tier's traits
							if C_AzeriteEmpoweredItem.IsPowerSelected(itemLoc,powerId) then
								empty = false
								break
							end
						end
						t[slot] = empty and t[slot] + 1 or t[slot]
					end
				end
			end
		end
	end
	return t
end

local function GetAzeriteInfo()
  if not C_AzeriteItem.HasActiveAzeriteItem() then return end
  local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()
  local xp,maxXp = C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation)
  local powerLevel = C_AzeriteItem.GetPowerLevel(itemLocation)
  local t = {
    xp = xp,
    maxXp = maxXp,
    powerLevel = powerLevel,
    traitsAvailable = GetAvailableTraits(powerLevel),
  }
  return t
end

local function Updater(event)
  Exlist.UpdateChar(key,GetAzeriteInfo())
end

local slotNames = {
	[1] = L["Head"],
	[3] = L["Shoulders"],
	[5] = L["Chest"],
}

local function Linegenerator(tooltip,data,character)
  if not data then return end
  local info = {
    character = character,
    priority = prio,
    moduleName = key,
    titleName = L["Azerite Power"],
    data = format("|c%s%s:|r %i",colors.faded,L["Level"],data.powerLevel),
    OnEnter = Exlist.CreateSideTooltip(),
    OnEnterData = {
      title = WrapTextInColorCode(L["Azerite Power"], colors.sideTooltipTitle),
      body = {
        { L["Progress"], format("%.1f%% (%i/%i)",(data.xp/data.maxXp)*100,data.xp,data.maxXp)},
        { L["Level"],data.powerLevel },
      }
    },
    OnLeave = Exlist.DisposeSideTooltip(),
  }
  local shorten = Exlist.ConfigDB.settings.shortenInfo
  local total = 0
  for slot,availableTraits in pairs(data.traitsAvailable) do
  	tinsert(info.OnEnterData.body,{format("%s: %s",slotNames[slot],WrapTextInColorCode(format("%i |4 %s: %s; %s",availableTraits,L["trait"],L["traits"],L["available"]), colors.available))})
  	total = total + availableTraits
  end
  if total > 0 then 
  	info.data = info.data .. WrapTextInColorCode(format(" %i %s",total,shorten and L["avail"] or L["available"]), colors.available)
  end
  Exlist.AddData(info)
end

--[[
local function GlobalLineGenerator(tooltip,data)

end
]]

--[[
local function Modernize(data)
  -- data is table of module table from character
  -- always return table or don't use at all
end
]]

--[[
local function init()
  -- code that will run before any other function
end
]]

--[[
local function ResetHandler(resetType)
  -- code that will be run at reset for this module
  -- instead of just wiping all data that is keyed 
  -- by this module key
end
]]

local data = {
  name = L['Azerite'],
  key = key,
  linegenerator = Linegenerator,
  priority = prio,
  updater = Updater,
  event = {"PLAYER_ENTERING_WORLD","AZERITE_ITEM_EXPERIENCE_CHANGED","AZERITE_ITEM_POWER_LEVEL_CHANGED"},
  weeklyReset = false,
  dailyReset = false,
  description = L["<TMP> Tracks Azerite Item's current level and progress"],
  -- globallgenerator = GlobalLineGenerator,
  -- modernize = Modernize,
  -- init = init,  
  -- override = true,
  -- specialResetHandle = ResetHandler

}

Exlist.RegisterModule(data)

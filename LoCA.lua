local addonName, addon = ...
addon.addonTitle = GetAddOnMetadata(addonName, "Title")

addon.defaultSettings = {
  profile = {
    setting = true,
    debuffs = {
      scale = 1,
      debuffsTable = {
        { spellId = 122, category = "Snared", weight = 1, active = true },     --[[ Frost Nova --]]
        { spellId = 12494, category = "Snared", weight = 1, active = true },   --[[ Frostbite --]]
        { spellId = 19675, category = "Snared", weight = 1, active = true },   --[[ Feral Charge --]]
        { spellId = 23694, category = "Snared", weight = 1, active = true },   --[[ Improved Hamstring --]]
        { spellId = 44047, category = "Snared", weight = 1, active = true },   --[[ Chastise --]]
        { spellId = 339, category = "Snared", weight = 1, active = true },     --[[ Entangling Roots --]]

        { spellId = 18469, category = "Silenced", weight = 2, active = true }, --[[ Imp Counterspell --]]
        { spellId = 15487, category = "Silenced", weight = 2, active = true }, --[[ Silence --]]
        { spellId = 34490, category = "Silenced", weight = 2, active = true }, --[[ Silencing Shot --]]
        { spellId = 1330, category = "Silenced", weight = 2, active = true },  --[[ Garrote --]]
        { spellId = 19647, category = "Silenced", weight = 2, active = true }, --[[ Spell Lock --]]
        { spellId = 676, category = "Disarmed", weight = 2, active = true },   --[[ Disarm --]]

        { spellId = 8643, category = "Stunned", weight = 3, active = true },   --[[ Kidney Shot --]]
        { spellId = 1833, category = "Stunned", weight = 3, active = true },   --[[ Cheap Shot --]]
        { spellId = 8983, category = "Stunned", weight = 3, active = true },   --[[ Bash --]]
        { spellId = 20615, category = "Stunned", weight = 3, active = true },  --[[ Intercept --]]
        { spellId = 7922, category = "Stunned", weight = 3, active = true },   --[[ Charge --]]
        { spellId = 9005, category = "Stunned", weight = 3, active = true },   --[[ Pounce --]]
        { spellId = 39077, category = "Stunned", weight = 3, active = true },  --[[ Hammer of Justice --]]
        { spellId = 19577, category = "Stunned", weight = 3, active = true },  --[[ Intimidation --]]
        { spellId = 15269, category = "Stunned", weight = 3, active = true },  --[[ Blackout --]]

        { spellId = 22570, category = "Incapacitated", weight = 4, active = true }, --[[ Maim --]]
        { spellId = 20066, category = "Incapacitated", weight = 4, active = true }, --[[ Repentence --]]
        { spellId = 38764, category = "Sapped", weight = 4, active = true },        --[[ Gouge --]]
        { spellId = 19503, category = "Disoriented", weight = 4, active = true },   --[[ Scatter Shot --]]
        { spellId = 2094, category = "Disoriented", weight = 4, active = true },    --[[ Blind --]]
        { spellId = 12825, category = "Polymorphed", weight = 4, active = true },   --[[ Polymorph --]]
        { spellId = 6213, category = "Feared", weight = 4, active = true },         --[[ Fear --]]
        { spellId = 8122, category = "Feared", weight = 4, active = true },         --[[ Psychic Scream --]]
        { spellId = 5246, category = "Feared", weight = 4, active = true },         --[[ Intimidating Shout --]]
        { spellId = 5484, category = "Feared", weight = 4, active = true },         --[[ Howl of Terror --]]
        { spellId = 27223, category = "Feared", weight = 4, active = true },        --[[ Death Coil --]]
        { spellId = 33786, category = "Cycloned", weight = 4, active = true },      --[[ Cyclone --]]
        { spellId = 11297, category = "Sapped", weight = 4, active = true },        --[[ Sap --]]
        { spellId = 14309, category = "Frozen", weight = 4, active = true },        --[[ Freezing Trap --]]
        { spellId = 11196, category = "Bandaged", weight = 4, active = true },        --[[ Freezing Trap --]]
        { spellId = 41425, category = "Hypo", weight = 4, active = true },        --[[ Freezing Trap --]]
      }
    }
  }
}

addon.options = {
  name = addon.addonTitle,
  handler = addon,
  type = 'group',
  args = {
    title = {
      order = 1,
      type = 'description',
      fontSize = 'large',
      name = addon.addonTitle .. " " .. GetAddOnMetadata(addonName, "Version")
    },
    break1 = {
      order = 2,
      type = "header",
      name = ""
    }
  },
}

addon.debuffs = {}

function addon:OnInitialize()

  addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", addon.defaultSettings, true)
  addon.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)

  debuffs:OnInitialize(addon.db.profile["debuffs"])

  addon.options.args["debuffs"] = debuffs.options

  LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, addon.options)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle)

  print("Initialized " .. addon.addonTitle)
end

function addon:OnEvent(event, ...)
  if event == "ADDON_LOADED" and ... == addonName then
    addon:OnInitialize()
  elseif event == "UNIT_AURA" then
    addon:OnAuraEvent(...)
  elseif event == "LOSS_OF_CONTROL_ADDED" then
    -- TODO: Consider using this event
  end
end

function addon:OnAuraEvent(unitId)
  -- we are only interested in our debuffs
  if unitId ~= "player" then
    return
  end

  debuffs:OnDebuffsChanged()
end

addon.eventHandler = CreateFrame("Frame")
addon.eventHandler:SetScript("OnEvent", addon.OnEvent)
addon.eventHandler:RegisterEvent("ADDON_LOADED")
addon.eventHandler:RegisterEvent("UNIT_AURA")
addon.eventHandler:RegisterEvent("LOSS_OF_CONTROL_ADDED")

function addon:CreateDebuffs()
  debuffs = {
  }

  return debuffs
end
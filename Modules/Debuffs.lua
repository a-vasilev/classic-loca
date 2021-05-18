local addonName, addon = ...
local locaDebuffs = addon.CreateDebuffs()

local container
local isLocked = true

-- weights - 1 - MOVEMENT, 2 - SILENCE/DISARM, 3 - FULL
local debuffsTable = {
  { spellId = 11196, category = "Bandage", weight = 2 },
  { spellId = 41425, category = "Frozen", weight = 3 },
}

locaDebuffs.options = {
  type = "group",
  name = "Debuffs",
  args = {
    lock = {
      order = 1,
      name = function() if isLocked then return "Unlock" else return "Lock" end end,
      type = "execute",
      desc = "Unlock/Lock the alerts for movement",
      func = function()
        if isLocked then
          locaDebuffs:Unlock()
        else
          locaDebuffs:Lock()
        end
      end,
      width = 0.5
    },
    break1 = {
      order = 2,
      type = "header",
      name = ""
    },
    scale = {
      order = 3,
      name = "Scale",
      type = "range",
      min = 0.1,
      max = 3,
      step = 0.1,
      bigStep = 0.1,
      get = function(info) return locaDebuffs:GetScale(info) end,
      set = function(info, val) locaDebuffs:SetScale(info, val) end
    },
    alpha = {
      order = 4,
      name = "Alpha",
      type = "range",
      min = 0.1,
      max = 1,
      step = 0.1,
      bigStep = 0.1,
      get = function(info) return locaDebuffs:GetAlpha(info) end,
      set = function(info, val) locaDebuffs:SetAlpha(info, val) end
    },
  }
}

local icons = {}
local iconFrame

function locaDebuffs:OnDebuffsChanged()
  local candidatesForActivation = {}
  local candidateDurations = {}
  
  for i = 1, 20 do
    local name, _, icon, debuffType, duration, expirationTime, _, _, _, spellId = UnitDebuff("player", i)
    if not name then break end

    local durationLeft = expirationTime - GetTime()

    local debuffIcon = icons[name]

    -- check if the debuff is being monitored for alerts
    if debuffIcon then
      table.insert(candidatesForActivation, debuffIcon)
      table.insert(candidateDurations, durationLeft)
    end
  end

  local maxDuration = -1
  local targetIndex = 0
  local maxWeight = 1

  for idx, candidateDuration in ipairs(candidateDurations) do
    local candidateWeight = candidatesForActivation[idx].weight

    if candidateWeight > maxWeight then
      maxDuration = candidateDuration
      targetIndex = idx
      maxWeight = candidateWeight
    elseif candidateWeight == maxWeight then
      if candidateDuration > maxDuration then
        maxDuration = candidateDuration
        targetIndex = idx
        maxWeight = candidateWeight
      end
    end
  end

  locaDebuffs:ActivateNewDebuff(candidatesForActivation[targetIndex], candidateDurations[targetIndex])

end

function locaDebuffs:OnLossOfControlEvent(locData, eventIndex)
  local locType = locData.locType;
  local spellID = locData.spellID;
  local text = locData.displayText;
  local iconTexture = locData.iconTexture;
  local startTime = locData.startTime;
  local timeRemaining = locData.timeRemaining;
  local duration = locData.duration;
  local lockoutSchool = locData.lockoutSchool;
  local priority = locData.priority;
  local displayType = locData.displayType;

  if ( text and displayType ~= 0 ) then
    if ( locType == "SCHOOL_INTERRUPT" ) then
      if(lockoutSchool and lockoutSchool ~= 0) then
        text = string.format("%s Locked", GetSchoolString(lockoutSchool));
      end
    end
    
    -- make a fake debuff configuration object
    local debuffConfiguration = {
      spellId = spellID,
      name = text,
      icon = iconTexture,
      weight = priority,
      category = text
    }

    if not iconFrame.active or debuffConfiguration.weight > iconFrame.weight then
      locaDebuffs:ActivateNewDebuff(debuffConfiguration, timeRemaining)
    elseif iconFrame.active and debuffConfiguration.weight == iconFrame.weight and timeRemaining > iconFrame.timeLeft then
      locaDebuffs:ActivateNewDebuff(debuffConfiguration, timeRemaining)
    end
  end
end

function locaDebuffs:OnLossOfControlUpdate(locData)
  if locData and locData.displayType ~= 0 then
    if iconFrame.active and locData.spellID ~= iconFrame.spellId then
      locaDebuffs:DeactivateDebuff()
    end
    locaDebuffs:OnLossOfControlEvent(locData)
  else
    locaDebuffs:DeactivateDebuff()
  end
end

function locaDebuffs:LoadPosition()
  if locaDebuffs.db.position then
    container:SetPoint(locaDebuffs.db.position.point, UIParent, locaDebuffs.db.position.relativePoint, locaDebuffs.db.position.xOfs, locaDebuffs.db.position.yOfs)
  else
    container:SetPoint("CENTER", UIParent, "CENTER")
  end
end

function locaDebuffs:SavePosition()
  local point, _, relativePoint, xOfs, yOfs = container:GetPoint()

  if not locaDebuffs.db.position then 
    locaDebuffs.db.position = {}
  end

  locaDebuffs.db.position.point = point
  locaDebuffs.db.position.relativePoint = relativePoint
  locaDebuffs.db.position.xOfs = xOfs
  locaDebuffs.db.position.yOfs = yOfs
end

function locaDebuffs:CreateContainerFrame()
  container = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
  container:SetMovable(false)
  container:SetWidth(160)
  container:SetBackdrop({
    --bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  --container:SetBackdropColor(0, 0, 0, 0)
  container:SetBackdropBorderColor(0.4, 1, 0.4, 0)
  container:SetHeight(50)
  container:SetClampedToScreen(true) 
  container:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self:StartMoving() end end)
  container:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() locaDebuffs:SavePosition() end end)
  container:EnableMouse(false)
  container:Show()
  container:SetPoint("CENTER", UIParent, "CENTER")
end

function locaDebuffs:UpdateContainer()
  container:SetScale(locaDebuffs.db.scale)
  container:SetAlpha(locaDebuffs.db.alpha)
end

function locaDebuffs:OnInitialize(db)

  locaDebuffs.db = db

  locaDebuffs:CreateContainerFrame()

  for _, debuff in ipairs(locaDebuffs.db.debuffsTable) do
    local name, _, spellicon = GetSpellInfo(debuff.spellId)
    debuff.name = name
    debuff.icon = spellicon

    icons[name] = debuff
  end

  iconFrame = locaDebuffs:CreateIcon()

  locaDebuffs:OnUpdateSettings()
end

function locaDebuffs:CreateIcon(debuff)
  local btn = CreateFrame("Frame", nil, container)
  btn:SetWidth(40)
  btn:SetHeight(40)
  btn:SetFrameStrata("LOW")
  btn:SetPoint("LEFT", container, "LEFT", 8, 0)

  local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  cd.noomnicc = true
  cd.noCooldownCount = true
  cd:SetAllPoints(true)
  cd:SetFrameStrata("HIGH")
  cd:SetUseCircularEdge(true)
  cd:SetSwipeColor(0.17, 0, 0, 0.8)
  cd:SetEdgeTexture("Interface\\Cooldown\\edge-LoC.blp")
  cd:SetHideCountdownNumbers(true)
  --cd:Hide()

  local texture = btn:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints(true)

  local backgroundTexture = btn:CreateTexture(nil, "BACKGROUND")
  backgroundTexture:SetTexture("Interface\\Cooldown\\LoC-ShadowBG")
  backgroundTexture:SetPoint("BOTTOM", container, "BOTTOM", 0, 0)
  backgroundTexture:SetWidth(160)
  backgroundTexture:SetHeight(50)
  backgroundTexture:SetVertexColor(1, 1, 1, 0.6)

  local redLineTop = btn:CreateTexture(nil, "BACKGROUND")
  redLineTop:SetTexture("Interface\\Cooldown\\Loc-RedLine")
  redLineTop:SetWidth(160)
  redLineTop:SetHeight(27)
  redLineTop:SetPoint("BOTTOM", container, "TOP", 0, 0)

  local redLineBottom = btn:CreateTexture(nil, "BACKGROUND")
  redLineBottom:SetTexture("Interface\\Cooldown\\Loc-RedLine")
  redLineBottom:SetWidth(160)
  redLineBottom:SetHeight(20)
  redLineBottom:SetTexCoord(0, 1, 1, 0)
  redLineBottom:SetPoint("TOP", container, "BOTTOM", 0, 0)

  local debuffTitle = btn:CreateFontString(nil, "ARTWORK")
  debuffTitle:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
  debuffTitle:SetTextColor(1, 1, 0, 1)
  debuffTitle:SetPoint("LEFT", btn, "RIGHT", 6, 8)

  local text = btn:CreateFontString(nil, "ARTWORK")
  text:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
  text:SetTextColor(1, 1, 1, 1)
  text:SetPoint("LEFT", btn, "RIGHT", 6, -10)

  btn.text = text
  btn.textureIcon = texture
  btn.cd = cd
  btn.redLineBottom = redLineBottom
  btn.redLineTop = redLineTop
  btn.debuffTitle = debuffTitle

  btn.spellId = 0
  btn.name = ""
  btn.weight = 0
  btn.duration = 0

  btn.activate = function(debuff, timeLeft)
    if btn.active then return end
    
    btn.spellId = debuff.spellId
    btn.name = debuff.name
    btn.weight = debuff.weight

    btn.textureIcon:SetTexture(debuff.icon)
    btn.debuffTitle:SetText(debuff.category)
    
    container:SetBackdropColor(0, 0, 0, 0.4)
    btn:Show()
    btn.start = GetTime()
    btn.duration = timeLeft
    btn.cd:Show()
    btn.cd:SetCooldown(GetTime(), timeLeft)
    btn.settimeleft(timeLeft)
    btn:SetScript("OnUpdate", function(self) locaDebuffs:OnUpdateTimer(self) end)
    btn.active = true
  end

  -- called to hide stop the frame
  btn.deactivate = function()
    if not btn.active then return end
    container:SetBackdropColor(0, 0, 0, 0)
    btn:Hide()
    btn.text:SetText("")
    btn.cd:Hide()
    btn:SetScript("OnUpdate", nil)
    btn.active = false
  end

  btn.settimeleft = function(timeleft)
    btn.timeLeft = timeleft

    if timeleft < 10 then
      if timeleft <= 0.5 then
        btn.text:SetText("")
      else
        btn.text:SetFormattedText("%.1f", timeleft)
      end
    else
      btn.text:SetFormattedText("%.1f", timeleft)
    end

    -- set smaller font if the time left is too big, so it can fit in the icon
    if timeleft > 60 then
      btn.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    else
      btn.text:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    end
  end

  btn:Hide()

  btn:SetPoint("CENTER", container, "CENTER", 0, 0)

  return btn
end

function locaDebuffs:ActivateNewDebuff(newDebuff, durationLeft)
  if not newDebuff then
    locaDebuffs:DeactivateDebuff()
    return
  end

  if iconFrame.active then
    if iconFrame.spellId == newDebuff.spellId then
      -- TODO: do we need to update the time left?
      return
    end
    locaDebuffs:DeactivateDebuff()
  end

  iconFrame.activate(newDebuff, durationLeft)
end

function locaDebuffs:DeactivateDebuff()
  if iconFrame.active then
    iconFrame.deactivate()
  end
end

function locaDebuffs:OnUpdateTimer(self)
  local cooldown = self.start + self.duration - GetTime()
  if cooldown <= 0 then
    locaDebuffs:DeactivateDebuff()
  else
    self.settimeleft(cooldown)
  end
end

function locaDebuffs:Unlock()
  isLocked = false
  container:SetBackdropBorderColor(0.4, 1, 0.4, 0.7)
  container:SetMovable(true)
  container:EnableMouse(true)
end

function locaDebuffs:Lock()
  isLocked = true
  container:SetBackdropBorderColor(0.4, 1, 0.4, 0)
  container:EnableMouse(false)
  container:SetMovable(false)
end

function locaDebuffs:GetScale(info)
  return locaDebuffs.db.scale
end

function locaDebuffs:SetScale(info, val)
  locaDebuffs.db.scale = val
  locaDebuffs:UpdateContainer()
end

function locaDebuffs:GetAlpha(info)
  return locaDebuffs.db.alpha
end

function locaDebuffs:SetAlpha(info, val)
  locaDebuffs.db.alpha = val
  locaDebuffs:UpdateContainer()
end

function locaDebuffs:OnUpdateSettings()
  locaDebuffs:DeactivateDebuff()

  locaDebuffs:LoadPosition()

  locaDebuffs:UpdateContainer()
end
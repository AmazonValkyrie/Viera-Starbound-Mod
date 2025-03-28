require "/scripts/viera/vUtil.lua"

function build(directory, config, parameters, level, seed)
  local db = false
  local slot = ""
  local displayTier = ""  
  local displayStyle = ""  
  local displayCategory = ""
  local tier = getTier(config)
  local lvl = parameters.level or level or config.level or 1
  local color = getColor(parameters, config)
  local displaySlot = config.femaleFrames or config.maleFrames
  local style = config.style or ""
  local species = config.species or "viera"
  local mannequin = string.format("/interface/mannequin/%s_mannequin.png",species)
  local mImage  = mannequin..":base"
  local idle, normal = ":idle.1", ":normal"
  local mhImage, mfImage, mlImage, mbImage = "", "", ""
  local fImage, cImage, bImage = "", "", ""
  local subTitle, dLabel, hltLabel, nrgLabel, pwrLabel, prtLabel = "", "", "", "", "", ""
  
  if string.sub(config.category,1,5) == "chest" then
	displayCategory = vUtil.properCase(string.sub(config.category,1,5)).." "..vUtil.properCase(string.sub(config.category,6))
    fImage = directory..displaySlot.frontSleeve..idle..color
    cImage = directory..displaySlot.body..idle..color
    bImage = directory..displaySlot.backSleeve..idle..color
    mfImage = mannequin..":armf"
    mbImage = mannequin..":armb"
	slot = "chest"
  elseif string.sub(config.category,1,4) == "head" then
	displayCategory = vUtil.properCase(string.sub(config.category,1,4)).." "..vUtil.properCase(string.sub(config.category,5))
    fImage = directory..displaySlot..normal..color
    mhImage = mannequin..":head"
	slot = "head"
  elseif string.sub(config.category,1,3) == "leg" then
	displayCategory = vUtil.properCase(string.sub(config.category,1,3)).." "..vUtil.properCase(string.sub(config.category,4))
    cImage = directory..displaySlot..idle..color
    mlImage = mannequin..":legs"
	slot = "legs"
  elseif string.sub(config.category,1,4) == "back" then
	displayCategory = vUtil.properCase(string.sub(config.category,1,4)).." "..vUtil.properCase(string.sub(config.category,5))
    bImage = directory..displaySlot..idle..color
	slot = "back"
  end
  
  if tier == "1" then
    displayTier = "[Tier I] "  
  elseif tier == "2" then
    displayTier = "[Tier II] "  
  elseif tier == "3" then
    displayTier = "[Tier III] "  
  elseif tier == "4" then
    displayTier = "[Tier IV] "  
  elseif tier == "5" then
    displayTier = "[Tier V] "  
  elseif tier == "6" then
    displayTier = "[Tier VI] "  
  end
  subTitle = string.format("^yellow;%s%s^reset;", displayTier, displayCategory)
  
  local leveledStatusEffects = {}
  local statSpread = config.statSpread or "cosmetic"
  local spreadStyle = "Cosmetic"
  if statSpread ~= "cosmetic" then
    local lseConfig = root.assetJson("/items/armors/viera_leveledStatusEffects.config")
    local statGrowth = config.statGrowth or "standard"
	local statConfig = lseConfig[statSpread]
    local statusEffects = {"powerMultiplier","protection","maxEnergy","maxHealth"}
    for s = 1,#statusEffects do
      local stat = statusEffects[s]
      local statusEffect = {}
      statusEffect.stat = stat
	  statusEffect.levelFunction = statGrowth..statConfig[stat].levelFunction
	  if statusEffects[s] == "powerMultiplier" then
	    statusEffect.baseMultiplier = statConfig[stat][slot]
		pwrLabel = string.format("^cyan; +%s%s^reset;",(100*(statConfig[stat][slot]-1.0))*lvl,"%")
	  else
	    statusEffect.amount = statConfig[stat][slot]
		if statusEffects[s] == "protection" then
		  prtLabel = string.format("^cyan; +%s^reset;",(10*statConfig[stat][slot])*lvl)		
		elseif statusEffects[s] == "maxEnergy" then
		  nrgLabel = string.format("^cyan; +%s^reset;",(statConfig[stat][slot]*lvl))		
		elseif statusEffects[s] == "maxHealth" then
		  hltLabel = string.format("^cyan; +%s^reset;",(statConfig[stat][slot]*lvl))		
		end
	  end
	  vUtil.addItem(leveledStatusEffects,statusEffect)
    end
    config.leveledStatusEffects = leveledStatusEffects
	spreadStyle = statConfig.label
  end
  
  if style == "" then style = vUtil.properCase(species).." - "..spreadStyle end
  displayStyle = "^yellow;["..style.."]^reset;\n"  
  dLabel = string.format("%s%s", displayStyle, config.description)
  
  config.tooltipFields = config.tooltipFields or {}  
  config.tooltipFields.subTitle = subTitle -- Subtitle
  config.tooltipFields.dLabel   = dLabel ---- Description  
  config.tooltipFields.hltLabel = hltLabel -- Health Label
  config.tooltipFields.nrgLabel = nrgLabel -- Energy Label
  config.tooltipFields.pwrLabel = pwrLabel -- Power Multiplier Label
  config.tooltipFields.prtLabel = prtLabel -- Protection Label  
  config.tooltipFields.fImage   = fImage ---- Front Image
  config.tooltipFields.cImage   = cImage ---- Center Image
  config.tooltipFields.bImage   = bImage ---- Back Image
  config.tooltipFields.mImage   = mImage ---- Mannequin Body Image 
  config.tooltipFields.mhImage  = mhImage --- Mannequin Head Image
  config.tooltipFields.mfImage  = mfImage --- Mannequin Front Arm Image
  config.tooltipFields.mlImage  = mlImage --- Mannequin Legs Image
  config.tooltipFields.mbImage  = mbImage --- Mannequin Back Arm Image
  if db then sendDebug(config) end
  return config, parameters
end

function getColor(parameters, config)
  local c = ""
  local colors = config.colorOptions
  if colors then
    local i = (parameters.colorIndex or config.colorIndex or 0) + 1
    i = i % #colors
    if colors[i] then
      for fromColor, toColor in pairs(colors[i]) do
        c = c.."?replace="..fromColor.."="..toColor
      end
    end
  end
  return c
end

function getTier(config)
  if config.itemTags then
    for i,tag in pairs(config.itemTags) do
	  if string.sub(tag,1,4) == "tier" then
	    return string.sub(tag,5,5)
	  end	  
	end
  end
  return "0"
end

function sendDebug(config)
  local i = 0
  local f = {}
  local v = {}
  for field,value in pairs(config) do
    i=i+1
    f[i] = field
    v[i] = value
  end
  vUtil.showLog("Displaying Armor", f, v)
end
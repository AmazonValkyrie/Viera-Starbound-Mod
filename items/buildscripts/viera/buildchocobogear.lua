function build(directory, config, parameters, level, seed)
  
  local pathMod = ""
  local displayTier = ""  
  local displayStyle = ""  
  local displayCategoy = ""
  local category = string.sub(config.category,8)
  local fullTier = getTier(config)
  local fullStats = getStats(config, fullTier)
  local tier = string.sub(fullTier,1,2)
  local style = string.sub(fullTier,4)
  local imagePath = string.format("/items/active/viera/chocobogear/%s/%s/%s", config.category, config.unlock, category)
  local png = ".png:idle.1"  
  
  parameters.health     = parameters.health or fullStats.health or nil
  parameters.protection = parameters.protection or fullStats.protection or nil
  parameters.jumpLimit  = parameters.jumpLimit or fullStats.jumpLimit or nil
  parameters.moveSpeed  = parameters.moveSpeed or fullStats.moveSpeed or nil
  parameters.waterSpeed = parameters.waterSpeed or fullStats.waterSpeed or nil
  
  if config.category == "chocobosaddle" then
	displayCategoy = "Chocobo Saddle"
  elseif config.category == "chocobobarding" then
	displayCategoy = "Chocobo Barding"
	pathMod = "_silent"
  end
  
  if tier == "01" then
    displayTier = "[Tier I] "  
  elseif tier == "02" then
    displayTier = "[Tier II] "  
  elseif tier == "03" then
    displayTier = "[Tier III] "  
  elseif tier == "04" then
    displayTier = "[Tier IV] "  
  elseif tier == "05" then
    displayTier = "[Tier V] "  
  elseif tier == "06" then
    displayTier = "[Tier VI] "  
  elseif tier ~= "00" then
    displayTier = "["..case(tier).."] "
  end
  
  if style ~= "naked" then
    displayStyle = "^yellow;["..case(style).."]^reset; "  
  end
  
  config.tooltipFields = config.tooltipFields or {}  
  config.tooltipFields.subTitle = string.format("^yellow;%s%s^reset;", displayTier, displayCategoy)
  config.tooltipFields.dLabel = string.format("%s%s", displayStyle, config.description)
  config.tooltipFields.fImage = string.format("%sf%s%s", imagePath, pathMod, png)
  config.tooltipFields.cImage = string.format("%s%s%s",  imagePath, pathMod, png)
  config.tooltipFields.bImage = string.format("%sb%s%s", imagePath, pathMod, png)
  config.tooltipFields.mImage = "/interface/viera_chocobomannequin.png"
  return config, parameters
end

function getTier(config)
  local data = root.assetJson(string.format("/items/active/viera/chocobogear/viera_chocobogear.config:%sTiers",string.sub(config.category,8)))
  return data[config.unlock]
end

function getStats(config, tier)
  local data = root.assetJson(string.format("/items/active/viera/chocobogear/viera_chocobogear.config:%sStats",string.sub(config.category,8)))
  return data[tier]
end

function case(s)
  return (s:gsub("^%l", string.upper))
end

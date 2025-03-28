require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"

function init()
  storage = nil  
  self.setSelf = false 
  self.storageData = nil
  self.needsUpdate = false 
  self.initializing = true
  self.gatheringData = false
  self.slotCount = config.getParameter("slotCount")
  self.storageID = pane.sourceEntity()
  
  self.chocobo = {}
  self.thisUID = {}
  self.lastUID = {} 
  for i = 1, self.slotCount do
    local stall = "stall_"..i
    self.chocobo[stall] = nil
    self.thisUID[stall] = nil
    self.lastUID[stall] = nil	
  end
  self.position = world.entityPosition(self.storageID)
end

function update(dt)
  storageData("get")
end

function storageData(m)
  local method = m.."StorageData"
  
  if self.storageID then
    if m == "set" then	
	  local data = {}
	  data.chocobo = self.chocobo
	  data.thisUID = self.thisUID
	  data.lastUID = self.lastUID
      world.sendEntityMessage(self.storageID, method, data, false)
    elseif self.storageData == nil then
	  self.gatheringData = true
      self.storageData = world.sendEntityMessage(self.storageID, method)
	end			
	if self.storageData ~= nil and self.storageData:succeeded() then
      if self.storageData:finished()then
	    if  m == "get" then
	      storage = {}
	      storage = self.storageData:result()
          self.setSelf = true 
	    end
	    self.gatheringData = false
        self.storageData = nil
	  end
    end
  end	
  
  if self.setSelf then
    setSelf(storage)
    self.setSelf = false 
  end   
end

function setSelf(storage)  
  if storage ~= nil then 
    for i = 1,self.slotCount do
      local stall = "stall_"..i
      self.chocobo[stall] = storage.chocobo[stall]
      self.thisUID[stall] = storage.thisUID[stall]
      self.lastUID[stall] = storage.lastUID[stall]
    end
	self.position = storage.position
  end
  
  for i = 1,self.slotCount do
    local stall = "stall_"..i
    widget.setItemSlotItem(stall, self.chocobo[stall])
	checkForUpdate(stall)
  end
end
 
function swapItem(widgetName)
  local i = tonumber(string.sub(widgetName, 7))
  local stall = "stall_"..i
  local oldItem = self.chocobo[stall]
  local newItem = player.swapSlotItem()  
  if newItem == nil or (root.itemHasTag(newItem.name, "chocobocall") and newItem.parameters.state == "filled") then
    player.setSwapSlotItem(oldItem)	
    widget.setItemSlotItem(widgetName, newItem)
    self.chocobo[stall] = newItem
    self.lastUID[stall] = self.thisUID[stall]
	if newItem ~= nil then
	  self.thisUID[stall] = newItem.parameters.UID
	else	  
	  self.thisUID[stall] = nil
	end
  
    checkForUpdate(stall)
    storageData("set")
  end
end

function ejectItem(widgetName)
  local i = tonumber(string.sub(widgetName, 7))
  local stall = "stall_"..i
  local oldItem = self.chocobo[stall]
  self.lastUID[stall] = self.thisUID[stall]
  self.thisUID[stall] = nil
  self.chocobo[stall] = nil
  widget.setItemSlotItem(widgetName, nil)
  eject(oldItem)
  
  checkForUpdate(stall)
  storageData("set")
end

function checkForUpdate(stall)
  if self.thisUID[stall] ~= self.lastUID[stall] or self.initializing then
    updateDisplay(stall)
  end  
end

function updateDisplay(stall)
  local i = tonumber(string.sub(stall, 7))
  local health = 0
  local name = string.format("--")
  local breed = string.format("--")	 
  local healthBar = string.format("healthBar_%s",i) 
  local nameLabel = string.format("nameLabel_%s",i)
  local breedLabel = string.format("breedLabel_%s",i)
  if self.chocobo[stall] ~= nil then
    self.chocobo[stall] = cleanupGear("saddle",self.chocobo[stall].parameters.equippedSaddle,self.chocobo[stall])
    self.chocobo[stall] = cleanupGear("barding",self.chocobo[stall].parameters.equippedBarding,self.chocobo[stall])
    name = string.format("%s",self.chocobo[stall].parameters.chocoboName)
    breed = string.format("%s",self.chocobo[stall].parameters.chocoboBreed)
    health = chocoboHealth(self.chocobo[stall],"percentage")
  end
  widget.setText(nameLabel,name)
  widget.setText(breedLabel,breed)
  widget.setProgress(healthBar,health)
end

function chocoboHealth(chocobo,style)
  local maxHealth = chocobo.parameters.maxHealth or 23
  local currentHealth = chocobo.parameters.currentHealth or 1.0
  if style == "factor" then
    return maxHealth+((currentHealth/maxHealth)/10)
  elseif style == "percentage" then
    return currentHealth/maxHealth
  end
  return currentHealth
end

function cleanupGear(style,equipped,chocobo)
  local keep = nil
  local good = vUtil.cleanup({equipped},root.assetJson("/items/active/viera/chocobogear/viera_chocobogear.config:"..style.."Names"))
  for _,this in pairs(good) do
    if this ~= "naked" or keep == nil then
	  keep = this	  
	end
  end
  if keep == "naked" then
    if style == "saddle" then
      chocobo.parameters.equippedSaddle = "naked"
      chocobo.parameters.equippedSaddleJumpLimit = 0
      chocobo.parameters.equippedSaddleMoveSpeed = 0
      chocobo.parameters.equippedSaddleWaterSpeed = 0
	elseif style  == "barding" then
      chocobo.parameters.equippedBarding = "naked"
      chocobo.parameters.equippedBardingHealth = 0
      chocobo.parameters.equippedBardingProtection = 0
	end
  end
  return chocobo
end

function eject(item)
  if item ~= nil then
    world.spawnItem(item.name, self.position, item.count, item.parameters)
  end
end

function uninit()
  storageData("set")
end

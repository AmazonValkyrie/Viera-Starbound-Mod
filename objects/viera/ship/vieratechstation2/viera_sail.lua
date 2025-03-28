require "/scripts/viera/vPortraitTalk.lua"

function init()
  --Instantly spawn the pet when first created
  storage.spawnTimer = storage.spawnTimer and 0.5 or 0
  storage.petParams = storage.petParams or {}
  self.monsterType = config.getParameter("shipPetType", "petchocobo")
  self.spawnOffset = config.getParameter("spawnOffset", {2, 1})
  
  vPortraitTalk.init()
  
  message.setHandler("activateShip", function()
	vPortraitTalk.setTrackers("activateShip")
    animator.playSound("shipUpgrade")
  end)  
  
  message.setHandler("get.portraitTalkComplete", function()
    return storage.portraitTalkComplete
  end)
end

function update(dt)
  spawnPet(dt)
  vPortraitTalk.run(dt)
end

function repeatableActions(dt)
end

function oneTimeActions(dt)
  if portraitTalk.conversation == "activateShip" then
    object.setOfferedQuests(config.getParameter("portraitTalk.conversation.offeredQuests"))
  end
end

function onInteraction()
  return sayNext() -- for compatibility with other mods that replace the interact function
end

function sayNext()
  if not storage.portraitTalkComplete then
    if storage.portraitTalking and portraitTalk.conversation ~= "wait" then
      storage.portraitTalking = vPortraitTalk.next()
    end  
  else
    return config.getParameter("interactAction")
  end
end

function spawnPet(dt)
  if self.petId and not world.entityExists(self.petId) then
    self.petId = nil
  end
  if storage.spawnTimer < 0 and self.petId == nil then
    storage.petParams.level = 1
    self.petId = world.spawnMonster(self.monsterType, object.toAbsolutePosition(self.spawnOffset), storage.petParams)
    world.callScriptedEntity(self.petId, "setAnchor", entity.id())
    storage.spawnTimer = 0.5
  else
    storage.spawnTimer = storage.spawnTimer - dt
  end
end

function setPet(entityId, params)
  if self.petId == nil or self.petId == entityId then
    self.petId = entityId
    storage.petParams = params
  else
    return false
  end
end

function hasPet()
  return self.petId ~= nil
end
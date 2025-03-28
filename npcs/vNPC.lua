require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/quest/participant.lua"
require "/scripts/relationships.lua"
require "/scripts/actions/dialog.lua"
require "/scripts/actions/movement.lua"
require "/scripts/drops.lua"
require "/scripts/statusText.lua"
require "/scripts/tenant.lua"
require "/scripts/companions/recruitable.lua"
require "/scripts/viera/vUtil.lua"
require "/scripts/viera/vPortraitTalk.lua"

-- Engine callback - called on initialization of entity
function init()
  -- STORAGE
  restorePreservedStorage()
  storage.spawnerID = storage.spawnerID or config.getParameter("spawnerID") or nil
  storage.turnInQuests = storage.turnInQuests or config.getParameter("turnInQuests") or {}
  storage.offeredQuests = storage.offeredQuests or config.getParameter("offeredQuests") or {}
  storage.portraitTalkComplete = storage.portraitTalkComplete or false
  
  -- SELF VALUES
  self.debug = false
  self.forceDie = false
  self.shouldDie = true
  self.pathing = {}
  self.notifications = {}
  self.identity = npc.humanoidIdentity()
  
  -- NPC SETTINGS
  npc.setInteractive(true)
  npc.setDamageOnTouch(true)
  npc.setDisplayNametag(true)	
  npc.setTurnInQuests(storage.turnInQuests)
  npc.setOfferedQuests(storage.offeredQuests)
  npc.setAggressive(config.getParameter("aggressive", false))
  self.uniqueId = config.getParameter("uniqueId")
  updateUniqueId(false)     
  
  -- POSITION
  self.stuckCheckTimer = 0.1
  self.stuckCheckTime = config.getParameter("stuckCheckTime", 3.0)
  if storage.spawnPosition == nil then
    local position = mcontroller.position()
    local groundPosition = findGroundPosition(position, -20, 3)
    storage.spawnPosition = groundPosition or position
  end
  mcontroller.setAutoClearControls(false)
  if (config.getParameter("facingDirection")) then
    mcontroller.controlFace(config.getParameter("facingDirection"))
  end
  
  -- QUESTS
  local questOutbox = Outbox.new("questOutbox", ContactList.new("questContacts"))
  self.quest = QuestParticipant.new("quest", questOutbox)
  self.quest.onOfferedQuestStarted = offeredQuestStarted
  self.quest.onOfferedQuestFinished = offeredQuestFinished
  
  -- BEHAVIORS
  script.setUpdateDelta(10)
  self.behaviorConfig = config.getParameter("behaviorConfig", {})
  if personality().behaviorConfig then
    self.behaviorConfig = applyDefaults(personality().behaviorConfig, self.behaviorConfig)
  end
  if config.getParameter("behavior") then
    self.behavior = behavior.behavior(config.getParameter("behavior"), self.behaviorConfig, _ENV)
    self.board = self.behavior:blackboard()
    self.board:setPosition("spawn", storage.spawnPosition)
  end
  
  -- EQUIPPEMENT
  self.sheathedPrimary = npc.getItemSlot("sheathedprimary")
  self.primary = npc.getItemSlot("primary")
  self.sheathedAlt = npc.getItemSlot("sheathedalt")
  self.alt = npc.getItemSlot("alt")
  self.delayedSetItemSlot = {}
  self.previousHeadSlot = npc.getItemSlot("head")
  self.previousCosmeticHeadSlot = npc.getItemSlot("headCosmetic")
  if self.previousHeadSlot or self.previousCosmeticHeadSlot then
    self.wearingHat = true
  else
    self.wearingHat = false
  end
  -- EXTRA INITS
  recruitable.init()
  vPortraitTalk.init()    
  if type(extraInit) == "function" then
    extraInit()
  end

  -- MESSAGE HANDLING
  message.setHandler("notify", function (_, _, notification)
    return notify(notification)
  end)

  message.setHandler("suicide", function ()
    status.setResource("health", 0)
  end)
  
  message.setHandler("set.portraitTalkConversation", function(_,_,conversation)
     vPortraitTalk.setTrackers(conversation)
  end)  
  
  message.setHandler("get.portraitTalkStatus", function()
    local data = {}
	data.talkComplete = storage.portraitTalkComplete or nil
	data.conversation = portraitTalk.conversation    or nil
	data.talking      = storage.portraitTalking      or nil
    return data
  end)
    
  message.setHandler("get.portraitTalkComplete", function()
    return storage.portraitTalkComplete
  end)
end

-- RESTORE DYNAMIC NPC DATA FOR COLONY/CREW SYSTEMS
function restorePreservedStorage()
  for k, v in pairs(config.getParameter("initialStorage", {})) do
    if storage[k] == nil then
      storage[k] = v
    end
  end
  for slot, item in pairs(storage.itemSlots or {}) do
    npc.setItemSlot(slot, item)
  end
end

-- SETUP DYNAMIC NPC STORAGE FOR COLONY/CREW SYSTEMS
function preservedStorage()
  return {
    itemSlots = storage.itemSlots,
    relationships = storage.relationships,
    criminal = storage.criminal,
    stolen = storage.stolen,
    extraMerchantItems = storage.extraMerchantItems
  }
end

function updateUniqueId(overwrite)
  if (self.uniqueId and not entity.uniqueId()) or overwrite then
    npc.setUniqueId(self.uniqueId)
  end
end

-- PRIMARY UPDATE FUNCTION
function update(dt)
  -- SELF VALUES
  self.tradingEnabled = false
  self.setFacingDirection = false
  self.primaryFire = false
  self.altFire = false
  self.controlAggressive = false
  self.lounge = false
  self.playing = false
  self.moving = false
  self.interacted = false
  self.damaged = false
  self.stunned = false
  self.notifications = {}
  
  -- STUCK CHECK
  self.stuckCheckTimer = math.max(0, self.stuckCheckTimer - dt)
  if self.stuckCheckTimer == 0 then
    checkStuck()
    self.stuckCheckTimer = self.stuckCheckTime
  end
  
  -- EXTRA UPDATES
  updateUniqueId(false)
  self.quest:update()
  recruitable.update(dt)
  if type(extraUpdate) == "function" then
    extraUpdate(dt)
  end    
  
  -- LOAD DELAYED EQUIPMENT
  for _,slot in pairs(self.delayedSetItemSlot) do
    setNpcItemSlot(slot.slotName, slot.item)
  end
  self.delayedSetItemSlot = {}
  
  -- STUN NPC
  mcontroller.clearControls()
  if status.resourcePositive("stunned") then
    self.stunned = true
    if self.primary and root.itemHasTag(self.primary.name, "ranged") then
      npc.endPrimaryFire()
    end
    return
  end
  
  -- RUN PORTRAIT TALK  
  vPortraitTalk.run(dt)
  
  -- RUN BEHAVIORS
  self.board:setEntity("self", entity.id())
  self.board:setPosition("self", mcontroller.position())
  self.board:setNumber("facingDirection", mcontroller.facingDirection())
  if self.behavior and not storage.portraitTalking then
    self.behavior:run(dt)
  end
  BGroup:updateGroups()

  -- PRIMARY FIRE
  if self.primaryFire then
    npc.beginPrimaryFire()
  else
    npc.endPrimaryFire()
  end
  
  -- ALT FIRE
  if self.altFire then
    npc.beginAltFire()
  else
    npc.endAltFire()
  end
  
  -- SET AGGRESSION
  if self.controlAggressive then
    npc.setAggressive(true)
  else
    npc.setAggressive(config.getParameter("aggressive", false))
  end
  
  -- RESET LOUNGING
  if not self.lounge and npc.isLounging() then
    npc.resetLounging()
  end
  
  -- PLAY
  if not self.playing and self.playTarget then
    if world.entityExists(self.playTarget) then
      world.callScriptedEntity(self.playTarget, "npcToy.notifyNpcPlayEnd", entity.id())
    end
    self.playTarget = nil
  end
  
  -- DIE
  if storage.spawnerID and not world.entityExists(storage.spawnerID) then
    self.forceDie = true
  end  
  self.die = (self.shouldDie and not status.resourcePositive("health")) or self.forceDie
end

-- Engine callback - called on interact
function interact(args)
  --vUtil.showLog("INTERACT",{"args"},{args})
  if not storage.portraitTalkComplete then 
    --vUtil.showLog("TALKING",{"storage.portraitTalkComplete"},{storage.portraitTalkComplete})
    if portraitTalk.conversation ~= "wait" then
      storage.portraitTalking = vPortraitTalk.next()
    end
  else  
    --vUtil.showLog("INTERACTING",{"storage.portraitTalkComplete"},{storage.portraitTalkComplete})
    setInteracted(args)
	
    local recruitAction = recruitable.interact(args.sourceId)
    if recruitAction then
      return recruitAction
    end

    if self.tradingConfig ~= nil and self.tradingEnabled then
      return { "OpenMerchantInterface", self.tradingConfig }
    end

    if type(handleInteract) == "function" then
      return handleInteract(args)
    else
      local interactAction = config.getParameter("interactAction")
      if interactAction then
        local data = config.getParameter("interactData", {})
        if type(data) == "string" then
          data = root.assetJson(data)
        end
        return { interactAction, data }
      end
    end
  end
end

function setInteracted(args)
  self.interacted = true
  self.quest:fireEvent("interaction", args.sourceId)
  self.board:setEntity("interactionSource", args.sourceId)
end

-- Engine callback - called on taking damage
function damage(args)
  self.damaged = true
  self.board:setEntity("damageSource", args.sourceId)
end

function shouldDie()
  return self.die
end

function die()
  self.quest:die()
  recruitable.die()
  tenant.backup()
  spawnDrops()
end

function uninit()
  self.quest:uninit()
  BGroup:uninit()
end

function offeredQuestStarted(questArc)
  if entity.damageTeam().type ~= "assistant" then
    storage.preQuestDamageTeam = entity.damageTeam()
    npc.setDamageTeam({
        type = "assistant",
        team = 1 -- Friendly NPCs always on team 1
      })
  end
end

function offeredQuestFinished(questArc, complete)
  if storage.preQuestDamageTeam then
    npc.setDamageTeam(storage.preQuestDamageTeam)
    storage.preQuestDamageTeam = nil
  end
end

-- Personality and reactions
function personality()
  if not storage.personality then
    storage.personality = generatePersonality()
  end
  return storage.personality
end

function setPersonality(personality)
  storage.personality = personality
end

function personalityType()
  return personality().personality
end

function generatePersonality()
  return util.weightedRandom(config.getParameter("personalities"), npc.seed())
end

function participateInNewQuests()
  local enabled = config.getParameter("questGenerator.enableParticipation")
  return enabled and not self.quest:isQuestGiver()
end

function getHeldItems()
  local result = {}
  -- table.insert has no effect on the table when given a nil
  table.insert(result, self.primary)
  table.insert(result, self.sheathedPrimary)
  table.insert(result, self.alt)
  table.insert(result, self.sheathedAlt)
  return result
end

function setNpcItemSlot(slotName, item)
  npc.setItemSlot(slotName, item)
  storage.itemSlots = storage.itemSlots or {}
  
  storage.itemSlots[string.lower(slotName)] = item
  --vUtil.showLog("STORING...", {"storage.itemSlots"}, {storage.itemSlots})

  self.primary = npc.getItemSlot("primary")
  self.alt = npc.getItemSlot("alt")
  self.sheathedPrimary = npc.getItemSlot("sheathedprimary")
  self.sheathedAlt = npc.getItemSlot("sheathedalt")
end

function setItemSlotDelayed(slotName, item)
  table.insert(self.delayedSetItemSlot, {
      slotName = slotName,
      item = item
    })
end

function checkStuck()
  if mcontroller.isCollisionStuck() and not npc.isLounging() then
    -- sloppy catch-all correction for various cases of getting stuck in things
    -- due to bad spawn position, failure to exit loungeable (on ships), etc.
    local poly = mcontroller.collisionPoly()
    local pos = mcontroller.position()
    for maxDist = 2, 4 do
      local resolvePos = world.resolvePolyCollision(poly, pos, maxDist)
      if resolvePos then
        mcontroller.setPosition(resolvePos)
        break
      end
    end
  end
end

function checkForSwaps(checkHeadSlot)
  local swaps = {}
  local pinningEars = false
  --vUtil.showLog("CHECKING...", {"checkHeadSlot"}, {checkHeadSlot})
  if checkHeadSlot then
    --vUtil.showLog("CHECKING...", {"checkHeadSlot.name"}, {checkHeadSlot.name})
    if checkHeadSlot.name then
      --vUtil.showLog("CHECKING...", {"showears"}, {root.itemHasTag(checkHeadSlot.name, "showears")})
	  if not root.itemHasTag(checkHeadSlot.name, "showears") then
        pinningEars = true
        --vUtil.showLog("CHECKING...", {"pinningEars"}, {pinningEars})
      end	    
	end
  end
  local fields = {"type","was","style","swaps"}
  local values = {}
  local path = ""
  local val = ""
  if self.identity.species == "moogle" then
	path = self.identity.hairType
	val = "hairType"
  elseif self.identity.species == "viera" then
    path = self.identity.facialMaskType
	val = "facialMaskType"
  end
  --vUtil.showLog("CHECKING...", { "species", "path" }, { self.identity.species, path })
  if pinningEars then
	  if self.uniqueId then
	    if string.sub(path,8,9) == "up" then	
          local style = string.sub(path,11)		
		  swaps[val] = "unique/down/"..style
          --vUtil.showLog("PINNING...", fields, {string.sub(path,1,6), string.sub(path,8,9), string.sub(path,11), swaps[val]})
		  forceRespawn(swaps)
		end
	  elseif string.sub(path,1,2) == "up" then	  
        local style = string.sub(path,4)		
		swaps[val] = "down/"..style 
        --vUtil.showLog("PINNING...", fields, {"basic", string.sub(path,1,2), string.sub(path,4), swaps[val]})
		forceRespawn(swaps)
	  end	
  else
	  if self.uniqueId then
	    if string.sub(path,8,11) == "down" then	
          local style = string.sub(path,13)		
		  swaps[val] = "unique/up/"..style
          --vUtil.showLog("LIFTING...", fields, {string.sub(path,1,6), string.sub(path,8,11), string.sub(path,13), swaps[val]})
		  forceRespawn(swaps)
		end
	  elseif string.sub(path,1,4) == "down" then	  
        local style = string.sub(path,6)		
		swaps[val] = "up/"..style   
        --vUtil.showLog("LIFTING...", fields, {"basic", string.sub(path,1,4), string.sub(path,6), swaps[val]})
		forceRespawn(swaps)
	  end
  end
end

function forceRespawn(swaps)
  --vUtil.showLog("FORCE RESPAWN", {"swaps"}, {swaps})
  npc.resetLounging()
  
  local identity = npc.humanoidIdentity()
  for field,value in pairs(swaps) do
    identity[field] = value
  end
  local npcParameters = {
	identity = identity,
    scriptConfig = {
      personality = personality(),
      initialStorage = preservedStorage()
    }
  }
  if storage.spawnerID and world.entityExists(storage.spawnerID) then
    --vUtil.showLog("THROUGH SPAWNER", {"storage.spawnerID"}, {storage.spawnerID})	  
    world.sendEntityMessage(storage.spawnerID, "set.npc", entity.position(), npc.species(), npc.npcType(), npc.level(), npc.seed(), npcParameters)
  else
    --vUtil.showLog("BASIC", {}, {})	  
	world.spawnNpc(entity.position(), npc.species(), npc.npcType(), npc.level(), npc.seed(), npcParameters)
  end
  self.forceDie = true
end

function testEars()
  if self.wearingHat then
    local checkPrevious = npc.getItemSlot("head")
	if checkPrevious then
      setNpcItemSlot("head", "")
      local checkCurrent = npc.getItemSlot("head")
      --vUtil.showLog("DOFFING HAT", {"previous", "current"}, {checkPrevious, checkCurrent})
	  self.wearingHat = false
	end
  else
    local checkPrevious = npc.getItemSlot("head")
	if not checkPrevious then
      setNpcItemSlot("head", self.speciesTestHat)
      local checkCurrent = npc.getItemSlot("head")
      --vUtil.showLog("DONNNING HAT", {"previous", "current"}, {checkPrevious, checkCurrent})
	  self.wearingHat = true
	end 
  end
end
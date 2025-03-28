require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
  self.npcUID = config.getParameter("npcUID")
  self.followUp = config.getParameter("followUp")
  self.descriptions = config.getParameter("descriptions")
  self.compassUpdate = config.getParameter("compassUpdate")
  self.getWakeupStatus = nil
  self.questCompleted = false
  
  self.state = FSM:new()
  self.state:set(wakePlayer)
    
  setPortraits()
end



function questStart()
end

function questInteract(entityId)
end

function update(dt)
  self.state:update(dt)
  checkStatus()
end

function wakePlayer()
  quest.setCompassDirection(nil)
  quest.setObjectiveList({{self.descriptions.wakePlayer, false}})
  world.sendEntityMessage(self.npcUID, "set.portraitTalkConversation", "wakePlayer")
  world.sendEntityMessage(self.npcUID, "set.wakeupStatus", false)

  util.wait(1.0, function()
    local teleporters = world.entityQuery(mcontroller.position(), 100, {includedTypes = {"object"}})
    teleporters = util.filter(teleporters, function(entityId)
      if string.find(world.entityName(entityId), "teleporterTier0") then
        return true
      end
    end)
    if #teleporters > 0 then
      player.lounge(teleporters[1])
      return true
    end
  end)
    
  while true do
    local goal = util.uniqueEntityTracker(self.npcUID, self.compassUpdate)
    questutil.pointCompassAt(goal())
    coroutine.yield()
  end
end

function checkStatus()
  local titles = { "self.npcUID", "self.getWakeupStatus", "self.questCompleted" }
  local entries =  { self.npcUID, self.getWakeupStatus, self.questCompleted } 
  --vUtil.showLog( "SENDING MESSAGE", titles, entries )
  if self.getWakeupStatus == nil then
    self.getWakeupStatus = world.sendEntityMessage(self.npcUID, "get.wakeupStatus")
  elseif self.getWakeupStatus:finished() then
    --vUtil.showLog( "SEONHA FINISHED", {  }, {  } )
    if self.getWakeupStatus:succeeded() then
      --vUtil.showLog( "SEONHA SUCCEEDED", {  }, {  } )
	  local result = self.getWakeupStatus:result()
      if result.status then
 	    self.questCompleted = result.status
        --vUtil.showLog( "SEONHA RESULT", { "self.questCompleted" }, { self.questCompleted } )
      elseif not result.talking then 
	    world.sendEntityMessage(self.npcUID, "set.portraitTalkConversation", "wakePlayer")
	  end
    end
	if not self.questCompleted then
	  self.getWakeupStatus = nil
	else
      world.sendEntityMessage("techstation", "set.canInteract")
	  player.startQuest(self.followUp)
      quest.complete()
	end
  end
end
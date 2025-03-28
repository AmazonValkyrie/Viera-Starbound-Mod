require "/scripts/util.lua"
require "/scripts/viera/vUtil.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
  storage.questComplete = storage.questComplete or false
  
  self.followUp = config.getParameter("followUp")
  self.shipUpgrade = config.getParameter("shipUpgrade")
  self.descriptions = config.getParameter("descriptions")
  self.compassUpdate = config.getParameter("compassUpdate")
  self.techstationUid = config.getParameter("techstationUid")
  self.checkCompletion = nil
  self.doneSpeaking = false
  
  self.state = FSM:new()
  self.state:set(wakeSail)

  setPortraits()
end

function questStart()
end

function questInteract(entityId)
  if storage.questComplete and world.entityUniqueId(entityId) == self.techstationUid then
    player.upgradeShip(self.shipUpgrade)
    return true
  end
end

function update(dt)
  self.state:update(dt)    
  if not storage.questComplete then
    progressQuest()
  end
end

function wakeSail()
  quest.setCompassDirection(nil)
  quest.setObjectiveList({{self.descriptions.wakeSail, false}})
  
  world.sendEntityMessage(self.techstationUid, "announceErrors")
  while true do
    local goal = util.uniqueEntityTracker(self.techstationUid, self.compassUpdate)
    questutil.pointCompassAt(goal())
    local shipUpgrades = player.shipUpgrades()
    if shipUpgrades.shipLevel > 0 then
      world.sendEntityMessage(self.techstationUid, "activateShip")
      quest.complete()
      player.startQuest(self.followUp)
    end
    coroutine.yield()
  end
end

function progressQuest()
  if self.checkCompletion == nil then
    self.checkCompletion = world.sendEntityMessage(self.techstationUid, "get.portraitTalkComplete", "announceErrors")
  elseif self.checkCompletion:finished() then
    --vUtil.showLog( "WOOD FINISHED", {  }, {  } )
    if self.checkCompletion:succeeded() then
      --vUtil.showLog( "WOOD SUCCEEDED", {  }, {  } )
      if self.checkCompletion:result() then
        --vUtil.showLog( "WOOD RESULT", { "self.checkCompletion:result()" }, { self.checkCompletion:result() } )
	    self.doneSpeaking = self.checkCompletion:result()
		self.checkCompletion = "complete"		
	    if self.doneSpeaking then 
		  storage.questComplete = true
		end
      end
	end
	if not self.doneSpeaking then
	  self.checkCompletion = nil
	end
  end
end

function questComplete()
end

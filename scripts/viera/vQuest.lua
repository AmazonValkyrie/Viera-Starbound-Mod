vQuest = {}

-- STANDARD QUEST FUNCTIONS

function init()
  storage.changingStage = storage.changingStage or false
  storage.questComplete = storage.questComplete or false  
  storage.continuingStage = storage.continuingStage or false
  storage.state = storage.state or 1
  
  self.repeatable = config.getParameter("repeatable", false)
  self.spoken = false
  
  stages = config.getParameter("stages", {})
  states = defineStates()

  setPortraits()
  self.state = FSM:new()
  self.state:set(states[storage.state])
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function questStart()
end

function update(dt)
  self.state:update(dt)  
end

function questComplete()
  self.complete = FSM:new()
  self.complete:set(vQuest.mainComplete)
end


-- SPECIFIC QUEST FUNCTIONS -- 

function vQuest.mainStart()
  --vQuest.stateInfo("mainSTART()")
  self.spoken = false
  local stage = stages[storage.state]
  --vUtil.fieldValues(stage,"STAGE DATA")
  if storage.continuingStage then  
	local speaker = stage.speakers.interim 
    if stage.radioMessages and stage.radioMessages.interim then
	  vQuest.playRadioMessages(stage.radioMessages.interim)
    end
	if stage.portraitTalks and stage.portraitTalks.interim then
      world.sendEntityMessage(speaker.uid, "set.portraitTalkConversation", stage.portraitTalks.interim)
      vQuest.checkPortraitTalk(speaker)
	end
  else
	local speaker = stage.speakers.initial
    if stage.radioMessages and stage.radioMessages.initial then
	  vQuest.playRadioMessages(stage.radioMessages.initial)
    end 
	if stage.portraitTalks and stage.portraitTalks.initial then
      world.sendEntityMessage(speaker.uid, "set.portraitTalkConversation", stage.portraitTalks.initial)
      vQuest.checkPortraitTalk(speaker)
	end
	storage.changingStage = false
    storage.continuingStage = true
    quest.setIndicators({})
    quest.setObjectiveList({})
    quest.setCanTurnIn(false)
    quest.setCompassDirection(nil)
  end
end

function vQuest.mainFinish(a,b)
  --vQuest.stateInfo("mainFINISH()")
  local stage = stages[storage.state]
  storage.state = b
  quest.setIndicators({})
  if not self.spoken then
	--vUtil.showLog( "State Finished - Triggering Messages...",{},{})
    if stage.radioMessages and stage.radioMessages.cleared then
      vQuest.playRadioMessages(stage.radioMessages.cleared)
    end
    if stage.portraitTalks and stage.portraitTalks.cleared then
      local speaker = stage.speakers.cleared
	  --vUtil.showLog( "State Finished - Initial/Interim Speech...",{},{})
      vQuest.checkPortraitTalk(speaker)
	  --vUtil.showLog( "State Finished - Initial/Interim Speech [DONE]",{},{})	  
      util.wait(10.0)
      world.sendEntityMessage(speaker.uid, "set.portraitTalkConversation", stage.portraitTalks.cleared)
	  --vUtil.showLog( "State Finished - Cleared Speech...",{},{})
      vQuest.checkPortraitTalk(speaker)
	  --vUtil.showLog( "State Finished - Cleared Speech [DONE]",{},{})
      util.wait(7.0)
    end
	self.spoken = true
  end
  if a ~= b then   
	storage.changingStage = true
    storage.continuingStage = false
    --vUtil.showLog( "CHANGING STAGE", { "storage.changingStage", "storage.continuingStage" }, { storage.changingStage, storage.continuingStage } )	
  else
	if stage.autoComplete ~= true then
      quest.setCanTurnIn(true)
	else
	  entityId = player.id()
	  questComplete()
	end
  end
end

function vQuest.mainComplete()
  storage.questComplete = true
  --vQuest.stateInfo("mainCOMPLETE()")
  local stage = stages[storage.state]
  if stage.deliverPreviousItems then
    for i = 1, #stage.deliverPreviousItems do
      vQuest.consumeQuestItems(stages[stage.deliverPreviousItems[i]].items)
    end
  end
  --vUtil.showLog( "CHECKING REPEATABLE...", { "self.repeatable" }, { self.repeatable } )
  questutil.questCompleteActions()
  if self.repeatable then
    --vUtil.showLog( "FAILED! (FOR REPEAT)",{},{})
    quest.fail()
  else
    --vUtil.showLog( "COMPLETE!",{},{})
  end
end


-- OBJECTIVE FUNCTIONS --

function vQuest.gather(a,b)
  vQuest.mainStart()
  local stage = stages[storage.state]
  local currentState = storage.state
  
  --vUtil.showLog( "GATHERING", { "stage", "a", "b" }, { stage, a, b } )	
  while not storage.changingStage and not storage.questComplete and not vQuest.needPreviousGathered(stage) do
    local have = 0
    local need = 0
    local objectiveComplete = true
    local descriptions = {}
    if #stage.items == 1 then
	  local objective  = stage.items[1]
	  local playerCount = vQuest.playerQuestItemCount(objective)
	  local defaultDescription = "^green;Gather^reset; "..playerCount.."/"..objective[3].." ^orange;"..objective[2].."^reset;."
      local description = stage.descriptions[i] ~= nil and stage.descriptions[i] or defaultDescription
      if description ~= nil then 
	    descriptions[1] = { description, false }
	  end	
      --vUtil.showLog( "SINGLE ITEM", { "defaultDescription", "description" }, { defaultDescription, description } )
	
	  have = have+player.hasCountOfItem(objective[1])
	  need = need+objective[3]
	  if not player.hasItem({name = objective[1], count = objective[3]}) then
	    objectiveComplete = false
	  end  
	else
      local d = 2
	  local defaultDescription = "^green;Gather^reset; the following items: "
	  local description = stage.descriptions[1] ~= nil and stage.descriptions[1] or defaultDescription
	  descriptions[1] = { description, false }
	  for i,objective in pairs(stage.items) do		
	    local playerCount = vQuest.playerQuestItemCount(objective)
	    defaultDescription = playerCount.."/"..objective[3].." ^orange;"..objective[2].."^reset;."
        description = stage.descriptions[i+1] ~= nil and stage.descriptions[i+1] or defaultDescription
        if description ~= nil then 
	      descriptions[d] = { description, false }
	      d = d+1
	    end
		local title = "LIST ITEM: "..i
        --vUtil.showLog( title, { "defaultDescription", "description" }, { defaultDescription, description } )
		
	    have = have+math.min(player.hasCountOfItem(objective[1]),objective[3])
	    need = need+objective[3]
	    if not player.hasItem({name = objective[1], count = objective[3]}) then
	      objectiveComplete = false
	    end
	  end
	end
    --vUtil.showLog( "DESCRIPTIONS", { "descriptions" }, { descriptions } )
    quest.setObjectiveList(descriptions)
    quest.setProgress(have/need)
    if objectiveComplete then
      vQuest.mainFinish(a,b)
    end
    coroutine.yield()
  end
  --vUtil.showLog( "ENDING STATE", { "name", "next state" }, { stage.state, stages[storage.state].state } )
end

function vQuest.locate(a,b)
  vQuest.mainStart()
  local stage = stages[storage.state]
  local currentState = storage.state
  
  local uid = stage.speakers.target.uid
  local target =  stage.name ~= nil and ("^orange;"..stage.name.."^reset;") or "your ^orange;target^reset;"
  local defaultDescription = "^green;Locate^reset; "..target.."."
  local description = stage.descriptions[1] ~= nil and stage.descriptions[1] or defaultDescription
  
  --vUtil.showLog( "LOCATING", { "stage", "a", "b" }, { stage, a, b } )
  while not storage.changingStage and not storage.questComplete and not vQuest.needPreviousGathered(stage) do
	quest.setCanTurnIn(false)
    quest.setObjectiveList({{description, false}})
    quest.setParameter(uid, {type = "entity", uniqueId = uid})
    quest.setCompassDirection(nil)
    quest.setIndicators({uid})
	local findRange = stage.findRange or 12
	local compassUpdate = stage.compassUpdate or 0.5
    local tracker = util.uniqueEntityTracker(uid, compassUpdate)
    local located = tracker()
    if located then
      questutil.pointCompassAt(located)	  
      if world.magnitude(located, mcontroller.position()) < findRange then
		vQuest.mainFinish(a,b)
	  end
    end
    coroutine.yield()
  end
  --vUtil.showLog( "ENDING STATE", { "name", "next state" }, { stage.state, stages[storage.state].state } )
end


-- HELPER FUNCTIONS --

function vQuest.checkPortraitTalk(speaker,inCoroutine)
  local uid = speaker.uid or nil
  local name = speaker.name or "Someone"
  
  if uid == nil then return end
  if inCoroutine ~= false then inCoroutine = true end  
  
  local onFirstLoop = true
  local speechCheck = nil
  local speaking = true
  local doneSpeaking = false
  local conversation = "checking"
  local tracker = util.uniqueEntityTracker(uid, 0.5)
  local tempDescritpion = "^cyan;"..name.."^reset; has something to ^green;talk^reset; about!"
  
  --vUtil.showLog("STARTING LOOP",{"uid","speechCheck","speaking","doneSpeaking","conversation"},{uid,speechCheck,speaking,doneSpeaking,conversation})
  while speaking and not doneSpeaking do
    local located = tracker()
    if not located then
      speaking = false
	  doneSpeaking = true
    else 
      if onFirstLoop then 
        quest.setCanTurnIn(false)
        quest.setObjectiveList({{tempDescritpion, false}})
        quest.setParameter(uid, {type = "entity", uniqueId = uid})
        quest.setIndicators({uid})
	    onFirstLoop = false
	  end
      questutil.pointCompassAt(located)	  
      --vUtil.showLog("LOOP "..w,{"uid","speechCheck","speaking","doneSpeaking","conversation"},{uid,speechCheck,speaking,doneSpeaking,conversation})
      if speechCheck == nil then	
	    --vUtil.showLog("SENDING MESSAGE",{"uid","speechCheck","speaking","doneSpeaking","conversation"},{uid,speechCheck,speaking,doneSpeaking,conversation})
        speechCheck = world.sendEntityMessage(uid, "get.portraitTalkStatus")
	  else
	    --vUtil.showLog("MESSAGE SENT",{"uid","speechCheck","speaking","doneSpeaking","conversation"},{uid,speechCheck,speaking,doneSpeaking,conversation})
        local finished = speechCheck:finished() or nil
	    if finished ~= nil then
	      --vUtil.showLog("MESSAGE FINISHED",{"uid","finished","speaking","doneSpeaking","conversation"},{uid,finished,speaking,doneSpeaking,conversation})
          local succeeded = speechCheck:succeeded() or nil
		  if succeeded ~= nil  then
	        --vUtil.showLog("MESSAGE SUCCEEDED",{"uid","succeeded","speaking","doneSpeaking","conversation"},{uid,succeeded,speaking,doneSpeaking,conversation})
		    local result = speechCheck:result() or nil
		    if result ~= nil then
			  speaking     = result.talking
			  doneSpeaking = result.talkComplete
			  conversation = result.conversation
			  if conversation == "wait" then 
			    speaking = false
			    doneSpeaking = true
			  end
	          --vUtil.showLog("MESSAGE RESULT",{"result","speaking","doneSpeaking","conversation"},{result,speaking,doneSpeaking,conversation})
		    end
		  end
	      speechCheck = nil
	    end
      end
	end
	if inCoroutine then
      coroutine.yield()
	end
  end
end

function vQuest.playRadioMessages(messages)
  for i=1,#messages do
    player.radioMessage(messages[i])
  end
end

function vQuest.playerQuestItemCount(objective)
  local countColor = "^white;"
  if player.hasItem({name = objective[1], count = objective[3]}) then
	countColor = "^green;"		
  else
	countColor = "^red;"
  end
  return countColor..player.hasCountOfItem(objective[1]).."^reset;"
end

function vQuest.confirmQuestItemCount(items)
  local have = 0
  local need = 0
  for i,objective in pairs(items) do		
	have = have+player.hasCountOfItem(objective[1])
	need = need+objective[3]
    if not player.hasItem({name = objective[1], count = objective[3]}) then
	  --vUtil.showLog( "MISSING ITEM", { "name", "have", "need" }, { objective[1], player.hasCountOfItem(objective[1]), objective[3] } )
	  return false
	end
  end
  return true
end

function vQuest.needPreviousGathered(stage)
  if stage.needPreviousItems then
    local previousState = storage.state-1
    if not vQuest.confirmQuestItemCount(stages[previousState].items) then
	  --vUtil.showLog( "NEED PREVIOUS OBJECTIVE", { "this state", "previous state" }, { storage.state, previousState } )
      storage.continuingStage = false
	  storage.state = previousState
	  return true
	end
  end
  return false
end

function vQuest.consumeQuestItems(items)
  for i,objective in pairs(items) do		
	player.consumeItem({name = objective[1], count = objective[3]})
  end
end

function vQuest.stateInfo(title)
  vUtil.showLog(title,
    { "EntityID", "Name",  "Changing Stage", "Quest Complete", "Missing Needed Items" }, 
	{ entityId, stages[storage.state].state, storage.changingStage, storage.questComplete, vQuest.needPreviousGathered(stages[storage.state]) }
  )
end










require "/scripts/viera/vUtil.lua"

function extraInit()  
  storage.wakeupStatus = storage.wakeupStatus or false
  self.lastSpeech = nil
  self.thisSpeech = nil  
  
  message.setHandler("set.wakeupStatus", function(_,_,status)
    storage.wakeupStatus = status
  end)
  
  message.setHandler("get.wakeupStatus", function()
    return {talking = storage.portraitTalking, status = storage.wakeupStatus}
  end)
end

function extraUpdate(dt)
  if not storage.wakeupStatus then
    self.lastSpeech = thisSpeech
    self.thisSpeech = portraitTalk.conversation
    if (self.thisSpeech == "wakePlayer" or self.lastSpeech == "wakePlayer") and not storage.portraitTalking then
      storage.wakeupStatus = true
    end
  end  
end

function repeatableActions(dt)
end

function oneTimeActions(dt)
end

function handleInteract(args)
end
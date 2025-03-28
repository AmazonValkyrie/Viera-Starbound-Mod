require "/scripts/viera/vPortraitTalk.lua"

function init()  
  vPortraitTalk.init()
  storage.canInteract = storage.canInteract or false
  storage.dialogTimer = storage.dialogTimer or 1
  self.dialogTimer = storage.dialogTimer
  
  message.setHandler("set.canInteract", function()
    storage.canInteract = true
  end)
  
  message.setHandler("announceErrors", function()
    vPortraitTalk.setTrackers("announceErrors")
  end)
  
  message.setHandler("activateShip", function()
    animator.playSound("shipUpgrade")
  end)
  
  message.setHandler("get.portraitTalkComplete", function()
    return storage.portraitTalkComplete
  end)
  
end

function update(dt)
  vPortraitTalk.run(dt)
end

function repeatableActions(dt)
end

function oneTimeActions(dt)
end

function onInteraction()
  sayNext() -- for compatibility with other mods that replace the interact function
end

function sayNext()
  if storage.canInteract then
    if not storage.portraitTalkComplete then
      if storage.portraitTalking and portraitTalk.conversation ~= "wait" then
        storage.portraitTalking = vPortraitTalk.next()
      end  
    else
      return {config.getParameter("interactAction"), config.getParameter("interactData")}
    end
  end
end

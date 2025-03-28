function init()
  storage.portraitTalking = storage.portraitTalking or true
  message.setHandler("wakePlayer", function()
    self.dialog = config.getParameter("dialog.wakePlayer")
    self.dialogTimer = 0.0
    self.dialogInterval = 3.0
    self.drawMoreIndicator = true
    object.setOfferedQuests({})
  end)

  message.setHandler("activateShip", function()
    animator.playSound("shipUpgrade")
    self.dialog = config.getParameter("dialog.activateShip")
    self.dialogTimer = 0.0
    self.dialogInterval = 1.0
    self.drawMoreIndicator = true
    object.setOfferedQuests({})
  end)
end

function onInteraction()
  if storage.portraitTalking then
    sayNext()
    return nil
  else
    return config.getParameter("interactAction")
  end
end

function sayNext()
  if self.dialog and #self.dialog > 0 then
    if #self.dialog > 0 then
      local options = {
        drawMoreIndicator = self.drawMoreIndicator
      }
      self.dialogTimer = self.dialogInterval
      if #self.dialog == 1 then
        options.drawMoreIndicator = false
        self.dialogTimer = 0.0
      end

      object.sayPortrait(self.dialog[1][1], self.dialog[1][2], nil, options)
      table.remove(self.dialog, 1)

      return true
    end
  else
	if self.dialog then
	  storage.portraitTalking = false
	  self.dialog = nil
	  return false
	end
  end
  return true
end

function update(dt)
  storage.portraitTalking = storage.portraitTalking or true
  if self.dialogTimer then
    self.dialogTimer = math.max(self.dialogTimer - dt, 0.0)
    if self.dialogTimer == 0 and not sayNext() then
      self.dialogTimer = nil
      object.setOfferedQuests(config.getParameter("offeredQuests"))
    end
  end
  
  if self.dialogTimer == nil then
  end
end

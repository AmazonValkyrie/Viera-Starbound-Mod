
vPortraitTalk = {}

-- PORTRAIT TALK FUNCTIONS
function vPortraitTalk.init()
  portraitTalk = config.getParameter("portraitTalk", {})
  portraitTalk.speakerID = entity.id()
  vPortraitTalk.setTrackers("wait")
end

function vPortraitTalk.setTrackers(conversation, mode)
  portraitTalk.next = 1
  portraitTalk.conversation = conversation
  if mode ~= nil then
    portraitTalk.mode = mode
  end
  if conversation == "wait" then
    storage.portraitTalking = false
    storage.portraitTalkComplete = true  
  else
    storage.portraitTalking = true
    storage.portraitTalkComplete = false
    portraitTalk.count = #portraitTalk.conversations[conversation].text
    portraitTalk.timer = portraitTalk.conversations[conversation].startDelay
  end
end

function vPortraitTalk.run(dt)
  if not storage.portraitTalkComplete then 
    local players = world.playerQuery(world.entityPosition(portraitTalk.speakerID), 10)
    if players[1] then
      portraitTalk.timer = math.max(0, portraitTalk.timer - dt)
      if portraitTalk.timer == 0 then
        if storage.portraitTalking then
          storage.portraitTalking = vPortraitTalk.next()
        else
          if type(oneTimeActions) == "function" then
            oneTimeActions(dt)
	      end
          vPortraitTalk.setTrackers("wait")
	    end
      end
	end
  else
    if type(repeatableActions) == "function" then
      repeatableActions(dt)
	end
  end
end

function vPortraitTalk.next()
  local tags = vPortraitTalk.getTags()
  local options = { drawMoreIndicator = true }
  local currentTalk = portraitTalk.conversations[portraitTalk.conversation]
  if portraitTalk.next <= #currentTalk.text then
	local cd = currentTalk.cooldowns[portraitTalk.next]
	local text = currentTalk.text[portraitTalk.next]
	local image = portraitTalk.portraits[currentTalk.image[portraitTalk.next]]
    portraitTalk.timer = cd
    if portraitTalk.next == portraitTalk.count then
      options.drawMoreIndicator = false
    end  
	if portraitTalk.mode == "npc" then
      npc.sayPortrait(text, image, tags, options)
	elseif portraitTalk.mode == "object" then
      object.sayPortrait(text, image, tags, options)
	elseif portraitTalk.mode == "monster" then
      monster.sayPortrait(text, image, tags)
	elseif portraitTalk.mode == "remotenpc" then
	  world.callScriptedEntity(portraitTalk.speakerID, "npc.sayPortrait", {text, image, tags, options})
	elseif portraitTalk.mode == "remoteobject" then
	  world.callScriptedEntity(portraitTalk.speakerID, "object.sayPortrait", {text, image, tags, options})
	elseif portraitTalk.mode == "remotemonster" then
	  world.callScriptedEntity(portraitTalk.speakerID, "monster.sayPortrait", {text, image, tags})
	end
    portraitTalk.next = portraitTalk.next+1
    if portraitTalk.next <= #currentTalk.text then
	  return true
	end
  end
  return false
end

function vPortraitTalk.getTags()
  local tags = {}
  tags.player = vPortraitTalk.getPlayerName()
  return tags
end

function vPortraitTalk.getPlayerName()
  local players = world.playerQuery(world.entityPosition(portraitTalk.speakerID), 10)
  if players then
    local player = players[1]
    if player then
	  return world.entityName(player)
	end
  end	
  return "friend"
end

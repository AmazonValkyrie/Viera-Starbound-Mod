require "/scripts/vec2.lua"
require "/scripts/viera/vUtil.lua"

function init()
  storage.npcID = storage.npcID or nil
  storage.npcParam = storage.npcParam or {}
  storage.npcParam.identity = storage.npcParam.identity or {}
  storage.npcParam.scriptConfig = storage.npcParam.scriptConfig or {}
  storage.npcParam.scriptConfig.spawnerID = entity.id() or nil
  storage.npcSeed = storage.npcSeed or config.getParameter("npcSeed", nil)
  storage.npcOffset = storage.npcOffset or config.getParameter("npcSpawnOffset", {2, 4})
  
  npc = {}
  npc.spawnPoint = vec2.add(object.position(), storage.npcOffset)
  npc.uid        = config.getParameter("npcUID", nil)
  npc.species    = config.getParameter("npcSpecies", "moogle")
  npc.type       = config.getParameter("npcType", "villager")
  npc.level      = config.getParameter("npcLevel", 1)
  npc.parameters = storage.npcParam
  npc.seed       = storage.npcSeed
  npc.cooldown   = math.random()+0.5
  npc.timer      = npc.cooldown
  
  chat = {}
  chat.expressions = config.getParameter("chatExpressions", {})
  chat.radius      = config.getParameter("chatRadius", 1)
  chat.cooldown    = config.getParameter("chatCooldown", 30)
  chat.timer       = 0
  
  tags = {}
  tags.player = "friend"
    
  searching = nil 
  
  message.setHandler("set.npc", function(_,_,pos,species,typ,level,seed,param)
    npc.spawnPoint = pos
    npc.species    = species
    npc.type       = typ
    npc.level      = level
    npc.seed       = seed
    npc.parameters = param
	npc.parameters.scriptConfig.spawnerID = entity.id()     
    --sendLog("CHANGING NPC")
  end)
  
  --sendLog("SPAWNER INITIALIZING")
end

function update(dt)
  npc.timer = math.max(0, npc.timer - dt)
  if npc.timer == 0 then 
    if storage.npcID == nil then    
      if not searching then
        searching = world.findUniqueEntity(npc.uid)  
	  else
        if searching:finished() then
	      if searching:succeeded() then
		    local atLocation = searching:result()
	        if atLocation then
		      local ID = world.npcQuery(atLocation)[1]
			  if world.entityExists(ID) and world.entityUniqueId(ID) == npc.uid then
			    storage.npcID = ID
			  end
		    end
	      else
            spawnNPC()
		  end
	      searching = nil
	    end
      end
    elseif not world.entityExists(storage.npcID) or world.entityUniqueId(storage.npcID) ~= npc.uid then
      storage.npcID = nil
	  --sendLog("NEED NPC")
	end
  end
  
  chat.timer = math.max(0, chat.timer - dt)
  if chat.timer == 0 then  
    if storage.npcID ~= nil then
	  local atLocation = world.entityPosition(storage.npcID)
	  if atLocation then 
        local players = world.playerQuery(atLocation, chat.radius)
        if #players > 0 and #chat.expressions > 0 then   
          say(chat.expressions[math.random(1, #chat.expressions)], players)
	    end
	  end
	end
  end
end

function spawnNPC()
  --sendLog("SPAWNING NPC")
  storage.npcID = world.spawnNpc(npc.spawnPoint, npc.species, npc.type, npc.level, npc.seed, npc.parameters)
  storage.npcSeed = world.callScriptedEntity(storage.npcID, "npc.seed")
  npc.timer = npc.cooldown
  --sendLog("NPC SPAWNED")
end

function say(expression, players)
  local confidant = players[math.random(1, #players)]
  tags.player = world.entityName(confidant)
  world.callScriptedEntity(storage.npcID, "npc.say", expression, tags)
  chat.timer = chat.cooldown
end

function sendLog(title)
  vUtil.showLog(
    title, 
    {"spawnerID",       "npcID",   "spawnPoint",   "parameters",   "uid",   "species",   "type",   "level",   "seed"}, 
    {entity.id(), storage.npcID, npc.spawnPoint, npc.parameters, npc.uid, npc.species, npc.type, npc.level, npc.seed}
  )
end
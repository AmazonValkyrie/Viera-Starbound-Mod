require "/scripts/vec2.lua"
require "/scripts/viera/vUtil.lua"

function init()
  storage.npcID     = storage.npcID or nil
  storage.npcSeed   = storage.npcSeed or nil
  storage.npcOffset = storage.npcOffset or config.getParameter("npcSpawnOffset", {2, 4})
  storage.logLabels = {"standID", "npcID", "npcSeed"}
    
  npc = {}
  npc.spawnPoint = vec2.add(object.position(), storage.npcOffset)
  npc.species    = config.getParameter("npcSpecies", "moogle")
  npc.type       = config.getParameter("npcType", "chocoboknight")
  npc.level      = config.getParameter("npcLevel", 1)
  npc.cooldown   = 0.5
  npc.timer      = 0
  
  chat = {}
  chat.expressions = config.getParameter("chatExpressions", {})
  chat.radius      = config.getParameter("chatRadius", 1)
  chat.cooldown    = config.getParameter("chatCooldown", 30)
  chat.timer       = 0
    
  --sendLog("CHOCOBO STAND INITIALIZING")
end

function update(dt)
  if storage.npcID and not world.entityExists(storage.npcID) then
    storage.npcID = nil
	--sendLog("NEED NPC")
  end
  
  npc.timer = math.max(0, npc.timer - dt)
  if npc.timer == 0 then 
    if storage.npcID == nil then    
      spawnNPC()
	end  
  end
  
  chat.timer = math.max(0, chat.timer - dt)
  if chat.timer == 0 then  
    if storage.npcID ~= nil then
      local players = world.entityQuery(object.position(), chat.radius, {includedTypes = {"player"}, boundMode = "CollisionArea"})
      if #players > 0 and #chat.expressions > 0 then   
        say(chat.expressions[math.random(1, #chat.expressions)])
	  end
	end
  end
end

function spawnNPC()
  --sendLog("SPAWNING NPC")
  storage.npcID = world.spawnNpc(npc.spawnPoint, npc.species, npc.type, npc.level, storage.npcSeed)
  storage.npcSeed = world.callScriptedEntity(storage.npcID, "npc.seed")
  world.callScriptedEntity(storage.npcID, "npc.setPersistent", false)
  npc.timer = npc.cooldown
  --sendLog("NPC SPAWNED")
end

function say(expression)
  world.callScriptedEntity(storage.npcID, "npc.say", expression)
  chat.timer = chat.cooldown
end

function sendLog(title)
  vUtil.showLog(title, storage.logLabels, {entity.id(), storage.npcID, storage.npcSeed})
end
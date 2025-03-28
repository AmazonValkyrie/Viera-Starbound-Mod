require "/scripts/vec2.lua"

vUtil = {}

--GENERAL FUNCTIONS
function vUtil.showLog(title,fields,values)  
  sb.logInfo("\\\\\\\\\\\\", title)
  sb.logInfo("%s ", title)
  for i = 1, math.max(#fields,#values) do
    local field = " >>> "..i
	local value = ""
    if i <= #fields then
	  field = fields[i]
    end	
    if i <= #values then
	  value = values[i]
    end	
    sb.logInfo(" ||> %s: %s", field, value)
  end
  sb.logInfo("//////")
  sb.logInfo("")
end

function vUtil.showDebug(fields,values,position,offset)  
  if offset == nil then offset = 0 end
  local z = (offset*0.5)+3
  local yPos = (#fields*0.5)+z
  local xPos = 2
  local xLimit = 24
  local i = 0
  local debar = "|------------------------------------------------------------------------------------------------|"
  world.debugText(debar, vec2.add(position,{xPos,yPos}),"yellow")
  for f,field in pairs(fields) do
    i=i+0.5
    local text = string.format("%s:  %s", field,values[f])
    world.debugText("|", vec2.add(position,{xPos,yPos-i}),       "yellow")
    world.debugText(text,vec2.add(position,{xPos+0.5,yPos-i}),     "white")
    world.debugText("|", vec2.add(position,{xPos+0.05+xLimit,yPos-i}),"yellow")
  end
  i=i+0.5
  world.debugText(debar, vec2.add(position,{xPos,yPos-i}),"yellow")
  return (i*2)+offset+2
end

function vUtil.fieldValues(data, title)
  local i = 0
  local fields = {}
  local values = {}
  for f,v in pairs(data) do
    i = i+1
    fields[i] = f
	values[i] = v
  end
  if title ~= nil then
    vUtil.showLog(title, fields, values)
  end
  return { fields = fields, values = values }
end 

function vUtil.cleanup(unlocked,unlockable)
  local cleanedUnlocks = {}
  if unlocked == nil then unlocked = {} end
  --vUtil.fieldValues(unlocked,"--- UNLOCKED ---")
  --vUtil.fieldValues(unlockable,"-- UNLOCKABLE --")
  if not vUtil.contains(unlocked,"naked") then vUtil.addItem(unlocked, "naked") end
  for _,value in pairs(unlocked) do
	if vUtil.contains(unlockable,value) then
	  vUtil.addItem(cleanedUnlocks, string.format("%s",value))
	end
  end
  --vUtil.fieldValues(cleanedUnlocks,"--- CLEANED ----")
  return cleanedUnlocks
end

function vUtil.contains(array,testField,testValue)
  if array ~= nil then
    for field,value in pairs(array) do
      if testField ~= nil then 	 
	    if field == testField then 
	      if testValue ~= nil then		
	        if value == testValue then 
	          return true
	        end
		  else
	        return true
		  end
		end
	  else
	    if testValue ~= nil then		
	      if value == testValue then 
	        return true
	      end
		end	  
	  end
	end
  end
  return false
end

function vUtil.compareArrays(a,b)
  --vUtil.showLog("START COMPARE",{},{})
  if a == nil or b == nil then
    if a == nil and b == nil then
      --vUtil.showLog("-> BOTH EMPTY",{"a","b","result"},{a,b,true})
	  return true
	else
      --vUtil.showLog("-> ONE EMPTY",{"a","b","result"},{a,b,false})
	  return false
	end
  else
    if #a ~= #b then 
      --vUtil.showLog("-> DIFFERENT LENGTH",{"#a","#b","result"},{#a,#b,false})
	  return false
	else
      for f,v in pairs(a) do
	    if v ~= b[f] then 
          --vUtil.showLog("-> MISSING VALUE",{"a-v","b-v","result"},{v,b[f],false})
	      return false
	    end
	  end	
	end
  end
  --vUtil.showLog("GOOD!",{},{})
  return true
end

function vUtil.copyArray(a)
  --vUtil.showLog("START COPY",{"a"},{a})
  if a == nil then return a end
  local b = {}
  for f,v in pairs(a) do
    --vUtil.showLog("-> COPYING ["..f.."] - "..v,{"a","b"},{a,b})
    b[f]=v
    --vUtil.showLog("-> COPIED ["..f.."] - "..v,{"a","b"},{a,b})
  end	
  --vUtil.showLog("-> COPIED!",{"a","b"},{a,b})
  return b
end

function vUtil.addItem(array,newItem)
  local present = false
  if array ~= nil then
    for i,item in pairs(array) do
	  if item == newItem then  
	     present = true
		 break
	  end
	end
	if not present then
      table.insert(array, newItem)  
	end	
  else
    array = { newItem }
  end
  return array
end

function vUtil.orderNumberedPairs(array)
  local newArray = {}
  for i,value in pairs(array) do
    newArray[tonumber(i)] = value 
  end
  return newArray
end

function vUtil.properCase(s)
  s = string.lower(s)
  return (s:gsub("^%l", string.upper))
end

function vUtil.rainbowString(t)
  local r = {"#D80000","#FF6A00","#FFD800","#D8FF00","#6AFF00","#00D800","#00D8D8","#0000D8","#6A00FF","#D800FF"}
  local n = ""
  local l = string.len(t) or 0
  local s = math.max(0,(math.floor(#r/2)-l))
  local c = 0
  for i=1,l do
    c = c+1
	if s*(c-1) > #r then c = 1 end
    local z = s*(i-1)
    n = n.."^"..r[i+z]..";"..string.sub(t,i,i).."^reset;"
	--vUtil.showLog("RAINBOW!", {"text","rainbowArray","length","skip amount","letter count","color count","this skip amount","return text"}, {t,r,l,s,i,c,z,n})
  end
  return n
end

function vUtil.shiftHue(dt,sec)
  if sec == nil then sec = 2 end
  if self.colorShift[1] == nil then
    self.colorShift = vUtil.copyArray(self.oldColor)
  end
  local s = {}
  local m = 1
  for i,n in pairs(self.newColor) do
    local o = self.oldColor[i]
	if n > o then
	  s[i] = n-o
    else
	  s[i] = o-n
	end
	if s[i] > m then m = s[i] end
  end
  
  local x = m*(dt/sec)
  for i,n in pairs(s) do
	local nn = self.newColor[i]
	local no = self.oldColor[i]
	local nc = self.colorShift[i]
    if nn <= no then
      nx = math.max(nn,(nc+math.min(-0.1,-x)))
	else
      nx = math.min(nn,(nc+math.max(0.1,x)))
	end
    self.hueColor[i] = math.min(255,math.max(0,math.floor(nx)))
    self.colorShift[i] = nx
  end  
  return self.hueColor
end
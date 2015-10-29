--=======================================Defining the container table
--All functions in this library are elements of the table PMLib so as to not polute the namespace while providing users access to every function.
--"new" initializes the creation of a plugin message
--"write" functions handle making the "string" that gets send as the message.
--"read" functions handle manipulating the string recieved from a plugin message and getting you the information you want.
--This is never nessecary (if you send as long, any value will work), but it is nice.
--PMLib.FindLen is an INCREDIBLY useful function. It finds the length of the next section of the message. Do note that every read function does this already (or knows the length ahead of time), so FindLen is mostly for your own use if you choose to parse manually.

local PMLib = {}

function PMLib.FindLen(a_str)
  return string.byte(a_str,1) * 256 + string.byte(a_str,2), a_str:sub(3)
end

--=======================================Begin the creation of a Plugin Message
--Plugin messages are send like this:
--cPlayer:GetClientHandle():SendPluginMessage(channel,message)
--PMLib:new(channel) creates a tablethat allows for chainable message construction. This means that, instead of
--..SendPluginMessage("BungeeCord",PMLib.writeUTF("Hi!") .. PMLib.writeInt(270))
--We can do
--..SendPluginMessage(PMLib:new("BungeeCord"):writeUTF("Hi!"):writeInt(270):GetOut())
--In addition, at any time, you can pause your writing and read the table that gets outputted. Ex:
--local obj = PMLib:new("BungeeCord"):writeUTF("Hi!)
--local storedmessage = obj.Msg
function PMLib:new(a_Channel) -- Thanks to NilSpace for this
  local obj = {}
  setmetatable(obj, PMLib)
  self.__index = self
  
  obj.Channel = a_Channel
  obj.Msg = ""
   
  return obj
end

--=======================================Define the message
--These functions are chainable to each other and PMLib:new(channel)
--They can also be used on the table returned by PMLib:new(channel) and any other write function.
--Do note that these DO NOT work unless you use PMLib:new first to create the table that they manipulate.
function PMLib:writeUTF(a_str) --Thanks to NilSpace for this too
  assert(type(a_str) == "string", "Not a string!")
  local len = a_str:len()
  self.Msg = self.Msg .. string.char((len-127)/256,len % 256) .. a_str
  return self
end

function PMLib:writeByte(n) --Integer composed of 1 byte
  assert(not (n > 127),n .. " is too large")
  assert(not (n < -128),n .. " is too small")
  n = (n < 0) and (256 + n) or n
  self.Msg = self.Msg .. string.char(n%256)
  return self
end

function PMLib:writeShort(n) --Integer composed of 2 bytes
  assert(not (n > 32767),n .. " is too large")
  assert(not (n < -32768),n .. " is too small")
  n = (n < 0) and (65536 + n) or n
  self.Msg = self.Msg .. string.char((math.modf(n/256))%256,n%256)
  return self
end

function PMLib:writeInt(n) --Integer composed of 4 bytes
  assert(not (n > 2147483647),n .. " is too large")
  assert(not (n < -2147483648),n .. " is too small")
  -- adjust for 2's complement
  n = (n < 0) and (4294967296 + n) or n
  self.Msg = self.Msg .. string.char((math.modf(n/16777216))%256, (math.modf(n/65536))%256, (math.modf(n/256))%256, n%256)
  return self
end

function PMLib:writeLong(n) --Integer composed of 8 bytes
  assert(not (n > 9223372036854775807),n .. " is too large")
  assert(not (n < -9223372036854775808),n .. " is too small")
  n = (n < 0) and (1 + n) or n
  self.Msg = self.Msg .. string.char((math.modf(n/72057594037927936))%256,(math.modf(n/281474976710656))%256,(math.modf(n/1099511627776))%256,(math.modf(n/4294967296))%256,(math.modf(n/16777216))%256,(math.modf(n/65536))%256,(math.modf(n/256))%256,n%256)
  return self
end

function PMLib:writeBool(a_state) --True or False
  assert(type(a_state) == "boolean","Input is not a boolean!")
  if a_state then self.Msg = self.Msg .. string.char(0,1,1) else self.Msg = self.Msg .. string.char(0,1,0) end
  return self
end

--=======================================Return final values
--Once you have finished writing your message, throw
--:GetOut()
--onto the end of your chain, or your defined table.
--This function returns the channel (as defined in PMLib:new) and the message you created, meaning you can just plop it in a "SendPluginMessage" function and be done with it.
function PMLib:GetOut()
    return self.Channel, self.Msg
end

--=======================================Prepare to parse
--When you recieve a plugin message, the "message" section is an array of bytes that Cuberite represents as a string
--That string isn't super useful. PMLib:startparse prepares the string for manipulation by the "read" functions.
--PMLib:startparse(message) returns a table. The table can be to a variable and the variable manipulated by the "read" functions.
function PMLib:startparse(a_mess)
  local obj = {}
  setmetatable(obj, PMLib)
  self.__index = self
  
  obj.Msg = a_mess
  obj.arr = {}
  
  return obj
end

--=======================================Parse Message
--Each of these functions will read the byte string and output a specific type of value to a new element in an array.
--This array is stored in the parent object (a temporary object if you go from startparse to GetIn without defining an object
--or the object that you defined to be equal to startparse + and reads you did)
--Don't worry, you don't have to remember where you stored the array, you have have it extracted at the end.
--Be careful to use this in the exact order they have to be used. It is nearly impossible to do error checking with this
--As such, none has been implemented! The pressure is on you to make sure it's correct.
--If you just want to used BungeeCord plugin messages, I suggest you used the BPMLib that can also be found in this directory.
--It has automatic handling of most BungeeCord subchannels, both inbound and outbound, and utilizes this library, making it fully compatible!
function PMLib:readUTF()
  local len = tonumber(string.byte(self.Msg,1)) * 256 + tonumber(string.byte(self.Msg,2))
  self.arr[#self.arr + 1] = self.Msg:sub(3,len+2)
  self.Msg = self.Msg:sub(len+3)
  return self
end

function PMLib:readByte()
  local n = tonumber(self.Msg:byte(1))
  n = (n > 127) and (n - 256) or n
  self.arr[#self.arr + 1] = n
  self.Msg = self.Msg:sub(4)
  return self
end

function PMLib:readShort()
  local n = tonumber(self.Msg:byte(1))*256+tonumber(self.Msg:byte(2))
  n = (n > 32767) and (n - 65536) or n
  self.arr[#self.arr + 1] = n
  self.Msg = self.Msg:sub(5)
  return self
end

function PMLib:readInt()
  local n = tonumber(self.Msg:byte(1))*16777216 + tonumber(self.Msg:byte(2))*65536 + tonumber(self.Msg:byte(3))*256 + tonumber(self.Msg:byte(4))
  n = (n > 2147483647) and (n - 4294967296) or n
  self.arr[#self.arr + 1] = n
  self.Msg = self.Msg:sub(7)
  return self
end

function PMLib:readLong()
  local n = tonumber(self.Msg:byte(1))*72057594037927936 + tonumber(self.Msg:byte(2))*281474976710656 + tonumber(self.Msg:byte(3))*1099511627776 + tonumber(self.Msg:byte(4))*4294967296 + tonumber(self.Msg:byte(5))*16777216 + tonumber(self.Msg:byte(6))*65536 + tonumber(self.Msg:byte(9))*256 + tonumber(self.Msg:byte(10))
  n = (n > 9223372036854775807) and (n - 18446744073709551616) or n, self.Msg:sub(11)
  self.arr[#self.arr + 1] = n
  self.Msg = self.Msg:sub(11)
  return self
end

function PMLib:readBool()
  assert(self.Msg:byte() == 0 and self.Msg:byte(2) == 1,"Not a boolean value!")
  assert(self.Msg:byte(3) == 0 or self.Msg:byte(3) == 1,"Not a boolean value!")
  self.arr[#self.arr + 1] = self.Msg:byte(3) == 0 and false or true
  self.Msg = self.Msg:sub(4)
  return self
end

--=======================================Return final values
--Like I said above, you have have the array automatically extracted.
--Just slap a :GetIn() onto the end of your chain and it will return an array of the values you parsed!
function PMLib:GetIn()
    return self.arr
end
  


--=======================================Experimental functions
--While they work, I do not promise accuracy.
--They seem to be accurate to 2 decimal places, however I have not done extensive testing.
--An alternative is to use math.modf to separate out the fraction and the integer, multiple the fraction by 10 enough times to make it a decimal, then send the two numbers as two numbers, and undo at the other end.
--A better solution to this may come with a future change to the Cuberite API, or someone who's better at coding than I am.
--And yes, these use the ZLib. If you'd rather not include ZLib and don't plan on using read/write float/double, I suggest you comment these functions.
--Simply remove one of the dashes in the line below and VOILA! Commented out.
---[[
function PMLib:writeFloat(a_num)  --32 bit IEEE 754-1985 floating point
  
end

function PMLib:readFloat()
  local bytestring = self.Msg:sub(1,4)
  self.Msg = self.Msg:sub(5)
  local num = ZLib.readFloat
  self.arr[#self.arr + 1] = num
  return self
end

function PMLib:writeDouble(a_num) --64 bit IEEE 754-1985 floating point
  self.Msg = self.Msg .. ZLib.double2ByteString(a_num)
end


function PMLib:readDouble()
  local bytestring = self.Msg:sub(1,8)
  self.Msg = self.Msg:sub(9)
  self.arr[#self.arr + 1] = ZLib.byteString2Double(bytestring)
  return self
end
--]]
--=======================================End of experimental functions

--=======================================No seriously. **** this with a wooden spoon. Floats were hard enough, this is torture.
--[[ Unused because **** this...
function PMLib:readUTF16()
  
end

function PMLib:writeUTF16(a_char)
  
end

--]]

return PMLib

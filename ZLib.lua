--[[
The MIT License (MIT)

Copyright (c) 2015 Jakub (Kubuxu) Sztandera

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--
--The above license applies only to a handful of functions found below. They have been identified by comments.
--Modifications have been made to the original code. Original can be found here: https://gist.github.com/Kubuxu/e5e04c028d8aaeab4be8


--=======================================The parent table
--Every function in this file is an element of this table so as to avoid polluting the namespace while providing access to every function
local ZLib = {}

--=======================================Split String Function
--This function is pretty simple: it will split a string into an array.
--ZLib.stringSplit(string,separator) is how you use it.
--If separator is undefined (function used like ZLib.stringSplit(string), or is defined as false or nil, then the string will be split at every character.
--If separator is defined, a new array element will be made every time the separator is found.
--Example:
--local stringy = "This, Is, A, List"
--ZLib.stringSplit(stringy,", ")
-->{1 = "This", 2 = "Is", 3 = "A", 4 = "List"}
--local stringy2 = "ABCD"
--ZLib.stringSplit(stringy2)
-->{1= "A", 2 = "B", 3 = "C", 4 = "D"}
function ZLib.stringSplit(a_str,a_sep)
  local arr = {}
  if a_sep then
    local iter = 1
    for i in string.gmatch(a_str,a_sep) do
      arr[iter] = i
      iter = iter + 1
    end
  else
    for i = 1, a_str:len() do
      arr[i] = a_sep:sub(i,i)
    end
  end
  return arr
end

--=======================================Honestly there are very few place others will need this.
--If they do, the name is probably enough to tip them off.
--It's long because I don't plan on using it often, and would rather not forget what it does.
function ZLib.byteString2ByteArray(bytestring)
  local arr = {}
  for i = 1, bytestring:len() do
    arr[i] = bytestring:byte(i)
  end
  return arr
end

--=======================================Honestly there are very few place others will need this.
--If they do, the name is probably enough to tip them off.
--It's long because I don't plan on using it often, and would rather not forget what it does.
function ZLib.byteArray2ByteString(bytearray)
  local arr = {}
  local str = ""
  for i = 1, #bytearray do
    arr[i] = string.char(bytearray[i])
    str = str .. string.char(bytearray[i])
  end
  return table.concat(arr,""), str
end

--=======================================Take a byte string and convert to a float
--Niche use cases. If you need it, you'll understand by the name.
--This doesn't do any error checking, so proceed with caution.
function ZLib.byteString2Float(bytestring)
  local sign, bits2_8
  if bytestring:byte(1) >= 128 then
    sign, bits2_8 = -1, (bytestring:byte(1) - 128)*2
  else
    sign, bits2_8 = 1,bytestring:byte(1)*2
  end
  local pre_exponent, bits10_16
  if bytestring:byte(2) >= 128 then
    pre_exponent, bits10_16 = bits2_8 + 1, (bytestring:byte(2) - 128)*65536
  else
    pre_exponent, bits10_16 = bits2_8,bytestring:byte(2)*65536
  end
  if pre_exponent == 0 then
    return sign*0
  end
  local pre_fraction = bits10_16 + bytestring:byte(3)*256 + bytestring:byte(4)
  local exponent = pre_exponent - 127
  local fraction = pre_fraction/8388608 + 1
  return sign*fraction*(2^exponent)
end

--=======================================================Begin section liscenced by Jakub (Kubuxu) Sztandera

--=======================================Take a float and convert to a byte string
--Niche use cases. If you need it, you'll understand by the name.
--This doesn't do any error checking, so proceed with caution.
function ZLib.float2ByteString(a_num)
  if a_num == 0 then
    return "\0\0\0\0"
  end
  local anum = math.abs(a_num)
  
  local mantissa, exponent = math.frexp(anum)
  exponent = exponent - 1
  mantissa = mantissa * 2 - 1
  local sign = ((a_num ~= anum) and 128) or 0
  exponent = exponent + 127
  
  local bytes = string.char(sign + math.floor(exponent / 2))
  mantissa = mantissa * 128
  local currentmantissa = math.floor(mantissa)
  mantissa = mantissa - currentmantissa
  bytes = bytes .. string.char((exponent % 2) * 128 + currentmantissa)
  
  mantissa = mantissa * 256
  currentmantissa = math.floor(mantissa)
  mantissa = mantissa - currentmantissa
  bytes = bytes .. string.char(currentmantissa)
  
  mantissa = mantissa * 256
  currentmantissa = math.floor(mantissa)
  mantissa = mantissa - currentmantissa
  bytes = bytes .. string.char(currentmantissa)
  return bytes
end

--=======================================Take a byte string and convert to a double
--Niche use cases. If you need it, you'll understand by the name.
--This doesn't do any error checking, so proceed with caution.
function ZLib.byteString2Double(bytestring) 
  local bytes = ZLib.byteString2ByteArray(bytestring)
  local sign = 1
  local mantissa = bytes[2] % 2^4
  for i = 3, 8 do
    mantissa = mantissa * 256 + bytes[i]
  end
  if bytes[1] > 127 then sign = -1 end
  local exponent = (bytes[1] % 128) * 2^4 + math.floor(bytes[2] / 2^4)
  
  if exponent == 0 then
    return 0
  end
  mantissa = (math.ldexp(mantissa, -52) + 1) * sign
  return math.ldexp(mantissa, exponent - 1023)
end

--=======================================Take a double and convert to a byte string
--Niche use cases. If you need it, you'll understand by the name.
--This doesn't do any error checking, so proceed with caution.
function ZLib.double2ByteString(num)
  local bytes = {0,0,0,0, 0,0,0,0}
  if num == 0 then
    return bytes
  end
  local anum = math.abs(num)
  
  local mantissa, exponent = math.frexp(anum)
  exponent = exponent - 1
  mantissa = mantissa * 2 - 1
  local sign = num ~= anum and 128 or 0
  exponent = exponent + 1023
  
  bytes[1] = sign + math.floor(exponent / 2^4)
  mantissa = mantissa * 2^4
  local currentmantissa = math.floor(mantissa)
  mantissa = mantissa - currentmantissa
  bytes[2] = (exponent % 2^4) * 2^4 + currentmantissa
  for i= 3, 8 do
    mantissa = mantissa * 2^8
    currentmantissa = math.floor(mantissa)
    mantissa = mantissa - currentmantissa
    bytes[i] = currentmantissa
  end
  return ZLib.byteArray2ByteString(bytes)
end
--=======================================================End section liscenced by Jakub (Kubuxu) Sztandera



return ZLib

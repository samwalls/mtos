--          RECURSIVE ADDRESS PROTOCOL API
local rap = {}
rap.__index = rap

function rap.create(subnets)
  local r = {}
  setmetatable(r, rap)
  r.subnets = subnets
  return r
end

--turn single alphabet digit into number
--alpha must be between "a" and "z" inclusive
function rap.value(alpha)
  local a = string.byte("a")
  local z = string.byte("z")
  local n = string.byte(alpha) - a
  return (n < 0 or n > 25) and nil or n
end

--turn number between 0 and 25 into its equivalent alphabet character
function rap.alpha(n)
  return (n >= 0 and n <= 25) and string.char(string.byte("a") + n) or nil
end

--convert base10 to base26 alphabet string
function rap.base26(n, length)
  --shortcut this solution
  if n == 0 then return rap.leadingzeroes("a", length) end

  --otherwise get the coefficients of each digit
  local num = n
  local digits = {}
  i = 1
  while num ~= 0 do
    rem = num % 26
    num = math.floor(num / 26)
    digits[i] = rem
    i = i + 1
  end

  --construct the string based on the digits
  local output = ""
  for i = 1, #digits do
    output = rap.alpha(digits[i])..output
  end

  --if the output sequence has less digits than the format length, prepend zeroes
  if length and length > 1 and #output < length then
    output = rap.leadingzeroes(output, length)
  end
  return output
end

--helper for base26 string formatting
function rap.leadingzeroes(r, n)
  local r = r or "a"
  local n = n or 0
  for i = 1, n - #r do
    r = "a"..r
  end
  return r
end

--convert base26 alphabet string to base10
function rap.base10(alpha)
  local n = nil
  local i = #alpha - 1
  for c in alpha:gmatch(".") do
    n = (not n and 0 or n) + rap.value(c) * math.pow(26, i)
    i = i - 1
  end
  return n
end

--constructors
--store as an array of numbers between 0 and 765

--create based on array of numbers, return nil if arr is not valid as subnet array
function rap.fromarray(arr)
  local r = {}
  assert(#arr > 0, "array is not a valid RAP subnet array")
  for k,item in pairs(arr) do
    assert(type(item) == "number" and item >= rap.MIN and item <= rap.MAX, "array is not a valid RAP subnet array")
  end
  return rap.create(arr)
end

function rap.fromstring(str)
  assert(str, "argument to fromstring is nil!")
  assert(type(str) == "string", "expected argument to fromstring to be string")
  local r = {}
  local _, subcount = string.gsub(str, ":", "")
  subcount = subcount + 1
  local subnets = {}
  local groups = {}

  local i = 1
  for net in str:gmatch("([^:]+)") do
    groups[i] = net
    i = i + 1
  end
  assert(subcount == #groups or #groups > 0, "string "..str.." is not a valid RAP address")

  --then check and convert each subnet string
  --this is horrible, but needs to be done as lua has a crap regex implementation
  local i = 1
  local offset = 0
  while i <= #groups do
    --get an array of alphabet characters (if they exist)
    local alphas = {}
    local alpha = 1
    for item in groups[i]:gmatch("([a-z][a-z])") do
      alphas[alpha] = item
      alpha = alpha + 1
    end

    local n = tonumber(groups[i])
    --check for one or more groups of two b26 digits
    if #alphas > 0 and #alphas * 2 == #groups[i] then
      for j = 1, #alphas do
        subnets[offset + i + j - 1] = rap.base10(alphas[j])
      end
      offset = #alphas > 1 and offset + #alphas - 1 or offset
    elseif n and n >= rap.MIN and n <= rap.MAX then
      subnets[offset + i] = n
    else
      error("string "..str.." is not a valid RAP address\n subnet "..groups[i].." is either not a number between "..rap.MIN.." and "..rap.MAX.." inclusive, or one or more two digit alphabet strings (e.g. '"..rap.base26(rap.MIN, 2).."' or '"..rap.base26(rap.MAX).."')")
    end

    i = i + 1
  end
  return rap.create(subnets)
end

--member functions
--tostring
function rap:tostring()
  local out = rap.base26(self.subnets[1], 2)
  for i = 2, #self.subnets do
    out = out..":"..rap.base26(self.subnets[i], 2)
  end
  return out
end

--add the subnets of the address to the head (right) of self
function rap:append(address)
  local subs = self.subnets
  if address and address.subnets then
    local thislen = #subs
    for i = 1, #address.subnets do
      subs[i + thislen] = address.subnets[i]
    end
  end
  return rap.create(subs)
end

--add the subnets of address to the tail (left) of self
function rap:prepend(address)
  local subs = self.subnets
  if address and address.subnets then
    --move the self address along in index
    local otherlen = #address.subnets
    for i = #self.subnets, 1, -1 do
      subs[i + otherlen] = subs[i]
    end
    for i = 1, #address.subnets do
      subs[i] = address.subnets[i]
    end
  end
  return rap.create(subs)
end

--take n subnets from the head (right) of the address, return a new rap of them
function rap:head(n)
  local n = (n and n > 1) and n or 1
  local r = rap.create({})
  local j = 1
  if self.subnets then
    for i = #self.subnets - n + 1, #self.subnets do
      r.subnets[j] = self.subnets[i]
      j = j + 1
    end
  end
  return r
end

--take n subnets from the tail (left) of the address, return a new rap of them
function rap:tail(n)
  local n = (n and n > 1) and n or 1
  local r = rap.create({})
  if self.subnets then
    for i = 1, n do
      r.subnets[i] = self.subnets[i]
    end
  end
  return r
end

-- remove n segments from the i-th subnet, towards the head (rightwards)
function rap:remove(i, n)
  local i = (i and i >= 1) and i or 1
  local n = (n and n >= 1) and n or 1
  -- take the head from the right of the hole
  local head_size = #self.subnets - (i + n) + 1
  local tail_size = i - 1
  --print("head size: "..head_size.." | tail size: "..tail_size)
  local right = (head_size < 1 and rap.create({})) or self:head(head_size)
  -- ...and the tail from the left of the hole
  local left = (tail_size < 1 and rap.create({})) or self:tail(tail_size)
  --print("left: "..left:tostring().." | right: "..right:tostring())
  return left:append(right)
end

rap.SEGMENT_LENGTH = 2
rap.MIN = 0 -- minimum valid RAP segment address
-- create a string representing the maximum rap segment address
local s = ""
for i = 1, rap.SEGMENT_LENGTH do
  s = s.."z"
end
rap.MAX = rap.base10(s) -- maximum valid RAP segment address

return rap

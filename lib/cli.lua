                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           local cli = {}
local builder = {}
cli.builder = builder

-- Canonical Usage
--[[
local c = cli.create({
  builder:create("o"):longopt("output"):numargs(1):requireargs(true):description("Specify the output file location + name"):build(),
  builder:create("h"):longopt("help"):description("display the help screen for this command"):build()
})
local o = nil
c.parse(...)
if c.has("o") then
  o = c.get
]]

--constructors
function cli.create(o)
  local c = {}
  setmetatable(c, cli)
  return o and c.opt(o) or c
end

function builder.create()
  local b = {}
  setmetatable(b, cli.builder)
  return b
end

--BUILDER MEMBER FUNCTIONS
function builder:opt(o)
  if o and type(o) == "string" then
    self.short = o
  else
    error("expected string argument for short option name")
  end
  return self
end

function builder:longopt(o)
  if o and type(o) == "string" then
    self.long = o
  else
    error("expected string argument for long option name")
  end
  return self
end

function builder:description(d)
  if d and type(d) == "string" then
    self.description = d
  else
    error("expected string argument for option description")
  end
  return self
end

function builder:numargs(n)
  if n and type(n) == "number" and n >= 0 then
    self.numargs = n
  else
    error("expected numeric argument >= 0 for number of arguments")
  end
  return self
end

function builder:requireargs(r)
  self.requireargs = r and true or false
end

function builder:build()
  --TODO build a parser from the spec
end

--CLI PRIVATE FUNCTIONS
function parse(option, argset)
  --TODO run the option's parser over the argset, return the modified argset if succesful nil otherwise
end

--CLI MEMBER FUNCTIONS
function cli:parse(s)
  --TODO parse arguments, using the output of one parser to the next if succesful
  --parse based on self.options
end

function cli:has(o)
  return self.args[o] and true or false
end

return cli

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           local cli = {}
local options = {}
local builder = {}
cli.option = options
cli.builder = builder

--constructors
function cli.create()
  local c = {}
  setmetatable(c, cli)
  return c
end

function builder.create()
  local b = {}
  setmetatable(b, cli.builder)
  return b
end

function options.create()
  local o = {}
  setmetatable(o, options)
  return o
end

--OPTIONS MEMBER FUNCTIONS
function options:add(o)

end

--BUILDER MEMBER FUNCTIONS
function builder:opt(o)
  return self
end

function builder:longopt(o)
  return self
end

function builder:description(d)
  return self
end

function builder:numargs(n)
  return self
end

function builder:requireArgs(r)
  return self
end

function builder:build()
end

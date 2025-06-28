-- formatter/syntax.lua

local M = {}

-- Known section levels
local levels = {
  part = 1,
  chapter = 2,
  title = 2,
  section = 3,
  subject = 3,
  subsection = 4,
  subsubject = 4,
}

-- Lookup helper
local function lvl(name) return levels[name] end
local function trim(s) return s:match("^%s*(.-)%s*$") end

-- Split into lines (preserving blank lines)
local function split_lines(s)
  local t = {}
  for line in s:gmatch("([^\r\n]*)\r?\n?") do table.insert(t, line) end
  return t
end

-- Join lines
local function join_lines(t)
  return table.concat(t, "\n")
end

-- convert sections
local function convert_sections(content)
    local command = {
      "chapter",
      "section",
      "subsection"
    }
    for i = 1, #command do
      content = content:gsub("\\"..command[i].."%*", "\\"..command[i])
    end
    for i = 1, #command do
      content = content:gsub("\\"..command[i].."%s*%b{}", function(match)
        local inner = match:match("\\"..command[i].."%s*{(.*)}")
        if inner then
            return "\\start"..command[i].."[title={" .. inner .. "}]"
        end
        return match
      end)
    end
    
    return content
end

-- convert theorems
local function convert_theorems(content)
    local command = {
      "theorem",
      "lemma",
      "proposition",
      "definition",
      "exercise",
      "problem",
      "corollary",
      "example"
    }
    for i = 1, #command do
      content = content:gsub("\\begin{"..command[i].."}%s*%b[]", function(match)
        local inner = match:match("\\begin{"..command[i].."}%s*%[(.*)%]")
        if inner then
            return "\\start"..command[i].."[title={" .. inner .. "}]"
        end
        return match
      end)
    end
    for i = 1, #command do
      content = content:gsub("\\end{"..command[i].."}", "\\stop"..command[i])
    end
    
    return content
end


-- Safely split mid-line commands and trailing arguments
local function presplit(content)
  content = content
      :gsub("([^\r\n])\\(start%w+)", "%1\n\\%2")
      :gsub("([^\r\n])\\(stop%w+)", "%1\n\\%2")

  local out = {}
  for _, line in ipairs(split_lines(content)) do
    local trimmed   = trim(line)
    local lead      = line:match("^(%s*)") or ""

    local cmd, rest = trimmed:match("^(\\start%w+)%s+(.+)$")
    if not cmd then
      cmd, rest = trimmed:match("^(\\stop%w+)%s+(.+)$")
    end

    if cmd then
      table.insert(out, lead .. cmd)
      if rest and rest:match("%S") then
        table.insert(out, lead .. rest)
      end
    else
      table.insert(out, line)
    end
  end

  return join_lines(out)
end


-- Main formatter
function M.apply(content)
  content     = convert_sections(content)
  content     = convert_theorems(content)
  content     = presplit(content)
  local lines = split_lines(content)
  local out   = {}
  local stack = {}

  for _, line in ipairs(lines) do
    local t = trim(line)

    -- Match \startfoo or \stopfoo, with optional args like [], {}, or space
    local sname = t:match("^\\start([%a]+)%s*[%[{]?")
    local pname = t:match("^\\stop([%a]+)%s*[%[{]?")

    if sname and lvl(sname) then
      local L = lvl(sname)
      while #stack > 0 and lvl(stack[#stack]) >= L do
        table.insert(out, "\\stop" .. table.remove(stack))
      end
      table.insert(out, line)
      table.insert(stack, sname)
    elseif pname and lvl(pname) then
      local found = false
      for i = #stack, 1, -1 do
        if stack[i] == pname then
          found = true
          break
        end
      end
      if found then
        local L = lvl(pname)
        while #stack > 0 and lvl(stack[#stack]) > L do
          table.insert(out, "\\stop" .. table.remove(stack))
        end
        table.insert(out, line)
        if stack[#stack] == pname then
          table.remove(stack)
        end
      else
        -- Unmatched stop: drop
      end
    else
      -- Not a section start/stop
      table.insert(out, line)
    end
  end

  -- Close remaining
  while #stack > 0 do
    table.insert(out, "\\stop" .. table.remove(stack))
  end

  -- Insert a blank line between \stop<section> and next \start<section>
  local final_out = {}
  for i = 1, #out do
    table.insert(final_out, out[i])
    local this_line = out[i]:match("^\\stop([%a]+)")
    local next_line = out[i+1] and out[i+1]:match("^\\start([%a]+)") or nil
    if this_line and next_line and lvl(this_line) and lvl(next_line) then
      -- Insert blank line between these lines
      table.insert(final_out, "")
    end
  end

  return join_lines(final_out)
end

return M

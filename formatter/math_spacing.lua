-- formatter/math_spacing.lua

local M = {}

-- Apply spacing rules to a single math body string, without touching newlines
local function space_body(s)
  -- 1) Add spaces around * - + = < >
  s = s:gsub(" *([%*/%-%+%=<>]) *", " %1 ")

  -- 2) Add space after ! ? , : ;
  s = s:gsub("([!%?%,:;]) *", "%1 ")

  -- 3) Add space before macros that start with a letter (e.g. \alpha), but skip \\ etc.
  s = s:gsub(" *(\\%a)", " %1")

  -- 4) Remove spaces before ! ? , : ; } ^ _
  s = s:gsub(" +([!%?%,:;}%^_])", "%1")

  -- 5) Remove spaces after { ^ _
  s = s:gsub("([{%^_]) +", "%1")

  -- 6) Collapse multiple spaces into one (not newlines)
  s = s:gsub(" {2,}", " ")

  return s
end

-- Trim leading/trailing spaces for inline math only
local function space_inline_body(s)
  return space_body(s):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Process inline math: \m{...}
local function process_inline(content)
  return content:gsub("\\m%s*%b{}", function(full)
    local body = full:match("\\m%s*{(.*)}")
    if not body then return full end
    return "\\m{" .. space_inline_body(body) .. "}"
  end)
end

-- Process display math: \startformula...\stopformula
-- Do not trim leading/trailing spaces or lines
local function process_display(content)
  return content:gsub("(\\startformula)(.-)(\\stopformula)", function(open, body, close)
    return open .. space_body(body) .. close
  end)
end

function M.apply(content)
  content = process_inline(content)
  content = process_display(content)
  return content
end

return M

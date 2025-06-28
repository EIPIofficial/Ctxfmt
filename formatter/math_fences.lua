-- formatter/math_fences.lua

local M = {}

local fence_defs = {
  ["\\{"] = { close = "\\}", macro = "\\set" },
  ["||"]  = { close = "||",  macro = "\\norm" },
  ["|"]   = { close = "|",   macro = "\\abs" },
  ["("]   = { close = ")",   macro = "\\parenthesis", alt = "\\tuple" },
  ["["]   = { close = "]",   macro = "\\bracket" },
}

local openers = {}
for op in pairs(fence_defs) do
  table.insert(openers, op)
end
table.sort(openers, function(a, b) return #a > #b end)

local function starts_with(str, pos, prefix)
  return str:sub(pos, pos + #prefix - 1) == prefix
end

local function transform_fences(s)
  local sqrt_placeholders = {}
  -- Preserve optional arguments in \sqrt[] by replacing them with placeholders
  s = s:gsub("(\\sqrt%b[])", function(opt)
    local key = "__SQRTOPT" .. tostring(#sqrt_placeholders + 1) .. "__"
    sqrt_placeholders[key] = opt
    return key
  end)

  local stack = {}
  local output = {}
  local i = 1
  local len = #s

  local function parse()
    local buf = {}
    while i <= len do
      local top = stack[#stack]
      if top then
        local def = fence_defs[top]
        local c = def.close

        -- Remove any leading \right before closer
        while starts_with(s, i, "\\right") do
          i = i + 6
        end

        if starts_with(s, i, c) then
          i = i + #c
          local inner = table.concat(buf)
          table.remove(stack)
          local macro = def.macro
          if top == "(" and inner:find(",") then
            macro = def.alt
          end
          return macro .. "{" .. inner .. "}"
        end
      end

      local matched = false
      for _, op in ipairs(openers) do
        local pos = i
        if starts_with(s, pos, "\\left") then
          pos = pos + 5
        end

        if not (stack[#stack] == "\\{" and (op == "|" or op == "||")) then
          if starts_with(s, pos, op) then
            i = pos + #op
            table.insert(stack, op)
            local inner = parse()
            table.insert(buf, inner)
            matched = true
            break
          end
        end
      end

      if not matched then
        table.insert(buf, s:sub(i, i))
        i = i + 1
      end
    end
    return table.concat(buf)
  end

  while i <= len do
    local found = false
    for _, op in ipairs(openers) do
      local pos = i
      if starts_with(s, pos, "\\left") then
        pos = pos + 5
      end

      if starts_with(s, pos, op) then
        i = pos + #op
        table.insert(stack, op)
        table.insert(output, parse())
        found = true
        break
      end
    end
    if not found then
      table.insert(output, s:sub(i, i))
      i = i + 1
    end
  end

  local result = table.concat(output)

  -- Restore preserved \sqrt[...] placeholders
  for k, v in pairs(sqrt_placeholders) do
    result = result:gsub(k, v)
  end

  return result
end

local function process_inline_math(content)
  return content:gsub("\\m%s*%b{}", function(full)
    local body = full:match("\\m%s*{(.*)}")
    if not body then return full end
    return "\\m{" .. transform_fences(body) .. "}"
  end)
end

local function process_display_math(content)
  return content:gsub("(\\startformula)(.-)(\\stopformula)", function(open, body, close)
    return open .. transform_fences(body) .. close
  end)
end

local function convert_math_env(content)
    -- 匹配 \[ ... \] 并转换为 \startformula...\stopformula
    -- 处理可能存在的空格和换行
    return content:gsub("\\%[%s*(.-)\\%s*%]", function(math_content)
        -- 移除内容首尾的空白字符
        local trimmed = math_content:match("^%s*(.-)%s*$")
        -- 构建新的公式环境，确保换行
        return "\\startformula\n"..trimmed.."\n\\stopformula"
    end)
end


function M.apply(content)
  content = process_inline_math(content)
  content = process_display_math(content)
  content = convert_math_env(content)
  return content
end

return M

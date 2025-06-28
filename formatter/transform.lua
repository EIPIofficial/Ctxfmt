local M = {}

local function trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

local function find_item_end(lines, start_idx)
  local depth = 0
  for i = start_idx + 1, #lines do
    local line = trim(lines[i])
    if line:match("^\\startitemize") then
      depth = depth + 1
    elseif line:match("^\\stopitemize") then
      if depth > 0 then
        depth = depth - 1
      else
        return i - 1
      end
    elseif line:match("^\\item") and depth == 0 then
      return i - 1
    elseif line:match("^\\stop") and depth == 0 then
      return i - 1
    end
  end
  return #lines
end

function M.apply(content)
  local lines = {}
  for line in content:gmatch("([^\r\n]*)\r?\n?") do
    table.insert(lines, line)
  end

  local out = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    local trimmed = trim(line)

    if trimmed:match("^%$%$") then
      local formula_lines = {}
      local first_line = trimmed:gsub("^%$%$", "", 1)
      if #first_line > 0 then
        table.insert(formula_lines, first_line)
      end
      i = i + 1
      while i <= #lines and not lines[i]:match("%$%$$") do
        table.insert(formula_lines, lines[i])
        i = i + 1
      end
      if i <= #lines then
        local last_line = lines[i]:gsub("%$%$$", "")
        if #last_line > 0 then
          table.insert(formula_lines, last_line)
        end
      end
      table.insert(out, "\\startformula")
      for _, fl in ipairs(formula_lines) do
        table.insert(out, fl)
      end
      table.insert(out, "\\stopformula")
      i = i + 1
    elseif line:match("%$") then
      local newline = line:gsub("%$(.-)%$", function(m)
        return "\\m{" .. m .. "}"
      end)
      table.insert(out, newline)
      i = i + 1
    elseif trimmed:match("^\\item") then
      local item_end = find_item_end(lines, i)
      local item_lines = {}

      local first_line = lines[i]
      local after_item = first_line:gsub("^%s*\\item%s*", "")
      table.insert(item_lines, "\\startitem")
      if after_item ~= "" then
        table.insert(item_lines, after_item)
      end

      local content_lines = {}
      for j = i + 1, item_end do
        table.insert(content_lines, lines[j])
      end
      local nested_content = M.apply(table.concat(content_lines, "\n"))
      for nested_line in nested_content:gmatch("([^\r\n]*)\r?\n?") do
        if nested_line ~= "" then
          table.insert(item_lines, nested_line)
        else
          table.insert(item_lines, "")
        end
      end

      table.insert(item_lines, "\\stopitem")

      for _, l in ipairs(item_lines) do
        table.insert(out, l)
      end
      i = item_end + 1
    else
      table.insert(out, line)
      i = i + 1
    end
  end

  return table.concat(out, "\n")
end

return M

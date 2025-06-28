-- formatter/indent.lua

local M = {}

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local function collapse_spaces(s)
  -- Replace multiple spaces with single space, but keep leading spaces (indentation)
  local leading = s:match("^(%s*)") or ""
  local rest = s:sub(#leading + 1)
  rest = rest:gsub(" +", " ")
  return leading .. rest
end

function M.apply(content)
  -- 1) Insert newline before any mid-line \start... or \stop...
  content = content
      :gsub("([^\r\n])\\(start[%a]+)", "%1\n\\%2")
      :gsub("([^\r\n])\\(stop[%a]+)", "%1\n\\%2")

  local out_lines = {}
  local indent = 0
  local prev_line_empty = false

  -- To help remove empty lines after \start and before \stop, we keep track of last command
  local last_command = nil -- "start", "stop", or nil

  -- Helper to check if a line is \start or \stop command line
  local function is_start(line)
    return line:match("^\\start")
  end
  local function is_stop(line)
    return line:match("^\\stop")
  end

  for line in content:gmatch("([^\r\n]*)\r?\n?") do
    -- Trim line (for processing, but keep original indentation for output)
    local trimmed = trim(line)

    -- Collapse multiple spaces inside line (except leading indentation)
    local processed_line = collapse_spaces(line)

    -- Detect empty line (only whitespace)
    local empty_line = trimmed == ""

    -- Skip second+ consecutive empty lines
    if empty_line and prev_line_empty then
      -- skip this line
    else
      -- Remove empty line immediately after \start command
      if empty_line and last_command == "start" then
        -- skip this empty line
        -- Remove empty line immediately before \stop command
      elseif empty_line then
        -- Check next line ahead — tricky without lookahead, so defer this fix after building lines
        -- We'll remove empty lines before \stop in a second pass
        table.insert(out_lines, "")
        prev_line_empty = true
        last_command = nil
      else
        -- Non-empty line processing:

        -- De-indent if line is \stop... command (before output)
        if is_stop(trimmed) then
          indent = indent - 1
          if indent < 0 then indent = 0 end
        end

        -- Split line if contains \start or \stop with trailing text (e.g. "\stopsubsection Hello")
        local cmd, rest = trimmed:match("^(\\(start|stop)%w+)%s*(.+)$")
        if cmd then
          -- Print command line
          table.insert(out_lines, string.rep("  ", indent) .. cmd)
          -- Print trailing rest on its own line, indented same level
          if rest and rest ~= "" then
            table.insert(out_lines, string.rep("  ", indent) .. collapse_spaces(rest))
          end
          last_command = cmd:match("^\\(start)") and "start" or "stop"
        else
          -- Normal content line
          table.insert(out_lines, string.rep("  ", indent) .. processed_line:match("^%s*(.-)%s*$"))
          last_command = nil
        end

        -- Increase indent if line is \start... command (after output)
        if is_start(trimmed) then
          indent = indent + 1
          last_command = "start"
        end

        prev_line_empty = false
      end
    end
  end

  -- SECOND PASS to remove empty lines before \stop commands
  local cleaned_lines = {}
  for i = 1, #out_lines do
    local line = out_lines[i]
    local next_line = out_lines[i + 1]

    -- Check if current line is empty and next line is \stop...
    if line == "" and next_line and next_line:match("^%s*\\stop") then
      -- Skip this empty line
    else
      table.insert(cleaned_lines, line)
    end
  end

  return table.concat(cleaned_lines, "\n") .. "\n"
end

return M

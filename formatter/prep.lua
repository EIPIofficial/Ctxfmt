-- formatter/prep.lua

local M = {}

-- delete useless part1
local function remove1(content)
  content = content:gsub("\\end{document}", "")
  local start_pos = content:find("\\maketitle")
    
  if not start_pos then
      return content 
  end
    
  local line_end = content:find("[\r\n]", start_pos)
  if not line_end then
      line_end = #content
  else
      line_end = line_end - 1
  end
    
  return content:sub(line_end + 1)
end

-- delete useless part2
local function remove2(content)
  content = content:gsub("\\end{document}", "")
  local start_pos = content:find("\\date{}")
    
  if not start_pos then
      return content 
  end
    
  local line_end = content:find("[\r\n]", start_pos)
  if not line_end then
      line_end = #content
  else
      line_end = line_end - 1
  end
    
  return content:sub(line_end + 1)
end

--delete \left and \right
local function delete_lr(content)
  content = content:gsub("\\left", "")
  content = content:gsub("\\right", "")

  return content
end

-- change align* into align
local function change_align(content)
  content = content:gsub("align%*", "align")

  return content
end

-- add text
local function add_title_wrapper(content)
  if not content:match("^\\starttext") then
      content = "\\starttext\n" .. content
  end
    
  if not content:match("\\stoptext%s*$") then
      if not content:match("\n%s*$") then
          content = content .. "\n"
      end
      content = content .. "\\stoptext\n"
  end
    
  return content
end

-- Main formatter
function M.apply(content)
  -- content     = process_new_commands(content)
  content     = remove1(content)
  content     = remove2(content)
  content     = delete_lr(content)
  content     = add_title_wrapper(content)
  content     = change_align(content)
  
  return content
end

return M

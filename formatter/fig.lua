local M = {}

local function comment_figures(content)
    local result = {}
    local in_figure = false
    
    for line in content:gmatch("([^\n]*)\n?") do
        if line:match("\\startfigure") then
            in_figure = true
        end
        
        if in_figure then
            table.insert(result, "% " .. line) 
        else
            table.insert(result, line)        
        end
        
        if line:match("\\stopfigure") then
            in_figure = false
        end
    end
    
    return table.concat(result, "\n")
end

function M.apply(content)
  content     = comment_figures(content)
  
  return content
end

return M
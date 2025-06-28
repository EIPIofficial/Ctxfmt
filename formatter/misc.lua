-- formatter/misc.lua

local M = {}

function M.apply(content)
  -- 1. Replace \operatorname with \mfunction
  content = content:gsub("\\operatorname", "\\mfunction")

  -- 2. Replace \begin{env} with \startenv
  content = content:gsub("\\begin%s*{%s*([%a%d_%-]+)%s*}", function(name)
    return "\\start" .. name
  end)

  -- 3. Replace \end{env} with \stopenv
  content = content:gsub("\\end%s*{%s*([%a%d_%-]+)%s*}", function(name)
    return "\\stop" .. name
  end)
  
  -- 4. Replace \emph with \mathit
  content = content:gsub("\\emph", "\\mathit")

  -- 5. Replace \textbf with \mathbf
  content = content:gsub("\\textbf", "\\mathbf")

  -- 6. Repace \startitemize with \startenumerate
  content = content:gsub("\\startitemize", "\\startenumerate")
  content = content:gsub("\\stopitemize", "\\stopenumerate")

  -- 7. Replace \smallsetminus with \setminus
  content = content:gsub("\\smallsetminus", "\\setminus")

  -- 8. Replace \ldots with \dots
  content = content:gsub("\\ldots", "\\dots")
  content = content:gsub("\\cdots", "\\dots")

  -- 9. Replace \tuple with \parenthesis
  content = content:gsub("\\tuple", "\\parenthesis")

  -- 10. delete \big
  content = content:gsub("\\big", "")
  content = content:gsub("\\bigl", "")
  content = content:gsub("\\bigr", "")

  -- 11. delete \tag{}
  content = content:gsub("\\tag%b{}", "")

  -- 12. Replace \widebar with \overline
  content = content:gsub("\\overline", "\\widebar")
  
  -- 13. The problem of align
  local function convert_align(content)
    local result = {}
    local in_align = false
    
    for line in content:gmatch("([^\n]*)\n?") do
        if line:match("\\startalign") then
            in_align = true
            table.insert(result, line)
        elseif line:match("\\stopalign") then
            in_align = false
            table.insert(result, line)
        elseif in_align then
            local converted = line:gsub("&", "\\NC ")
            converted = converted:gsub("\\\\", "\\NR")
            if converted:match("%S") then
                converted = "\\NC" .. converted
            end
            table.insert(result, converted)
        else
            table.insert(result, line)
        end
    end
    
    return table.concat(result, "\n")
  end

  content = convert_align(content)
  content = content:gsub("(\\startalign)", "\\startformula\n%1")
  content = content:gsub("(\\stopalign)", "%1\n\\stopformula")

  return content
end

return M

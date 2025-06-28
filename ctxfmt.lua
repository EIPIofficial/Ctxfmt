-- ctxfmt.lua

local formatter = require("formatter")

-- Get filenames from command-line arguments, or use defaults
local input_file = arg[1] or "input.tex"
local output_file = arg[2] or "output.tex"

local function read_file(filename)
  local file = io.open(filename, "r")
  if not file then
    io.stderr:write("Error: Cannot open input file: " .. filename .. "\n")
    os.exit(1)
  end
  local content = file:read("*all")
  file:close()
  return content
end

local function write_file(filename, content)
  local file = io.open(filename, "w")
  if not file then
    io.stderr:write("Error: Cannot write to output file: " .. filename .. "\n")
    os.exit(1)
  end
  file:write(content)
  file:close()
end

local input = read_file(input_file)
local output = formatter.format(input)
write_file(output_file, output)

print(string.format("Formatted %s → %s", input_file, output_file))

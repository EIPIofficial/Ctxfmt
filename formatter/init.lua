-- formatter/init.lua

local prep = require("formatter.prep")
local indent = require("formatter.indent")
local syntax = require("formatter.syntax")
local transform = require("formatter.transform")
local math_fences = require("formatter.math_fences")
local math_spacing = require("formatter.math_spacing")
local misc = require("formatter.misc")
local fig = require("formatter.fig")

local M = {}

function M.format(content)
  content = prep.apply(content)
  content = indent.apply(content)
  content = syntax.apply(content)
  content = transform.apply(content)
  content = math_fences.apply(content)
  content = math_spacing.apply(content)
  content = misc.apply(content)
  content = indent.apply(content)
  content = fig.apply(content)
  return content
end

return M

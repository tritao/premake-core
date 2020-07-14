---
-- compile-commands/tests/test_compile_commands.lua
-- Automated test suite for compilation commands database.
-- Copyright (c) 2020 Premake project
---


local suite = test.declare("test_compile_commands")
local p = premake
local compile_commands = p.modules.compile_commands

local wks, prj, cfg

function suite.setup()
	p.action.set("compile-commands")
	wks = test.createWorkspace()
end

local function prepare()
	wks = p.oven.bakeWorkspace(wks)
	prj = test.getproject(wks, 1)

	compile_commands.generateWorkspace(wks)
end

function suite.databaseCppFiles()
	files { "a.cpp" }
	prepare()

	test.capture [[
	dasdasds
]]
end



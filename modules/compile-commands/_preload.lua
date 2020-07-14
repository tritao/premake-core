--
-- Name:        compile-commands/_preload.lua
-- Purpose:     Define the compile_commands.json API's.
-- Copyright:   (c) 2020 Premake project
--

	local p = premake
	local api = p.api

--
-- Register new compile commands APIs.
--

	p.api.register {
		name = "compilecommandsincludes",
		scope = "config",
		kind = "string",
		default = "absolute",
		allowed = {
			"absolute",
			"relative",
		}
	}

--
-- Register the compile commands exporters.
--

	newaction {
		trigger = 'compile-commands',
		description = 'Export compiler commands in JSON Compilation Database Format',

		-- The capabilities of this action
		valid_languages = { "C", "C++" },

		execute = function()
			local m = p.modules.compile_commands
			m.generate()
		end
	}

--
-- Decide when the full module should be loaded.
--

	return function(cfg)
		return _ACTION == 'compile-commands'
	end

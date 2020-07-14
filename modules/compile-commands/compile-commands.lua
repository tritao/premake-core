--
-- Name:        compile-commands/compile-commands.lua
-- Purpose:     Generates the compile_commands.json files.
-- Copyright:   (c) 2020 Premake project
--

local p = premake

p.modules.compile_commands = {}
local m = p.modules.compile_commands

local workspace = p.workspace
local project = p.project

function m.getCommonFlags(cfg, toolset)
	local flags = toolset.getcppflags(cfg)
	local iscfile = path.iscfile(cfg.name)
	local getflags = iif(iscfile, toolset.getcflags, toolset.getcxxflags)
	flags = table.join(flags, getflags(cfg))
	flags = table.join(flags, toolset.getdefines(cfg.defines))
	flags = table.join(flags, toolset.getundefines(cfg.undefines))
	local isabsolute = true
	flags = table.join(flags, toolset.getincludedirs(cfg, cfg.includedirs, cfg.sysincludedirs, isabsolute))
	return table.join(flags, cfg.buildoptions)
end

function m.getDependenciesPath(prj, cfg, node)
	return path.join(cfg.objdir, path.appendExtension(node.objname, '.d'))
end

function m.getFileFlags(prj, cfg, node, toolset)
	local objpath = path.join(cfg.objdir, path.appendExtension(node.objname, 
		"." .. toolset.getObjectFileExtension()))
	local ismsvc = toolset == p.tools.msc
	if ismsvc then
		return table.join(m.getCommonFlags(cfg, toolset), {
			'/Fo"' .. objpath .. '"', 
			'/c', node.abspath
		})
	else
		return table.join(m.getCommonFlags(cfg, toolset), {
			'-o', objpath,
			'-MF', m.getDependenciesPath(prj, cfg, node),
			'-c', node.abspath
		})
	end
end

function m.generateCompileCommand(prj, cfg, node)
	local toolset = p.tools[cfg.toolset or 'gcc']
	local iscfile = path.iscfile(cfg.name)
	local tool = iscfile and toolset.gettoolname(cfg, "cc") or toolset.gettoolname(cfg, "cxx")
	return {
		directory = prj.location,
		file = node.abspath,
		command = tool .. ' ' .. table.concat(m.getFileFlags(prj, cfg, node, toolset), ' ')
	}
end

function m.getProjectCommands(prj, cfg)
	local tr = project.getsourcetree(prj)
	local cmds = {}
	p.tree.traverse(tr, {
		onleaf = function(node, depth)
			if not path.iscppfile(node.abspath) then
				return
			end
			table.insert(cmds, m.generateCompileCommand(prj, cfg, node))
		end
	})
	return cmds
end

function m.prepareCmds(wks)
	local cfgCmds = {}
	for prj in workspace.eachproject(wks) do
		for cfg in project.eachconfig(prj) do
			local cfgKey = cfg.shortname
			if not cfgCmds[cfgKey] then
				cfgCmds[cfgKey] = {}
			end
			cfgCmds[cfgKey] = table.join(cfgCmds[cfgKey], m.getProjectCommands(prj, cfg))
		end
	end
end

function m.generateWorkspace(wks, cmds)
	p.w('[')
	for i = 1, #cmds do
		local item = cmds[i]
		local command = string.format([[
		{
			"directory": "%s",
			"file": "%s",
			"command": "%s"
		}]],
		item.directory,
		item.file,
		item.command:gsub('\\', '\\\\'):gsub('"', '\\"'))
		if i > 1 then
			p.w(',')
		end
		p.w(command)
	end
	p.w(']')
end

function m.generate()
	for wks in p.global.eachWorkspace() do
		local cfgCmds = m.prepareCmds(wks)
		for cfgKey,cmds in pairs(cfgCmds) do
			local outfile = string.format('compile_commands/%s.json', cfgKey)
			p.generate(wks, outfile, m.generateWorkspace)
		end
	end
end

return m

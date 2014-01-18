local bc = CompileFile("bc.lua")()

local function CheckFunction(func, outFile, isChild)
    for n, k in bc.IterateChildren(func) do
		if type(k) == "proto" then -- Function defined within current function
			CheckFunction(k, outFile, true)
		end
    end

	if isChild then -- Don't check for GSET within main body of files, but just children of those files
		for pc, bcInfo in bc.IterateBytecode(func) do
			if bcInfo['op'] == "GSET" then
				local d = bit.rshift(bcInfo['ins'], 16)
				local k = jit.util.funck(func, -d - 1)
				local info = jit.util.funcinfo(func, pc)

				local out = string.format(
					"%s %s %s:%d\n", 
					k, 
					string.rep(" ", 28 - string.len(k)), 
					string.sub(info.source, 2), 
					info.currentline
				)

				if outFile then
					outFile:Write(out)
				else
					Msg(out)
				end
			end
		end
	end
end

local function CheckDir(dir, outFile)
	local files, dirs = file.Find(dir .. "/*", "GAME")

	for k, v in pairs(dirs or {}) do
		CheckDir(dir .. "/" .. v, outFile)
	end

	for k, v in pairs(files or {}) do
		if string.find(v, ".lua", nil, true) then -- It's 2AM
			local func = CompileString(file.Read(dir .. "/" .. v, "GAME"), dir .. "/" .. v) -- Using CompileFile is hard when iterating "GAME", so we just read it instead

			if func then
				CheckFunction(func, outFile)
			end
		end
	end
end

concommand.Add("lua_variable_global_find", function(ply, _, args)
	local dir = args[1]

	if not dir then
		print("[ERROR] bad argument #1 to 'lua_variable_global_find', (directory expected)")
		return
	end

	if not file.Exists(dir, "GAME") then
		print("[ERROR] bad argument #1 to 'lua_variable_global_find', (directory not found)")
		return
	end

	local outFile = nil

	if args[2] then
		outFile = file.Open(args[2] .. ".txt", "w", "DATA")

		if not outFile then
			print("[ERROR] bad argument #2 to 'lua_find_globalset', (could not open file for write)")
			return
		end
	end

	CheckDir(dir, outFile)

	if outFile then
		outFile:Close()
		print("Results output to: " .. args[2] .. ".txt")
	end
end)
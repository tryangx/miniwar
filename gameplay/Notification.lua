--[[
	Use to call function in global manager,
	instead of call it in Class Function Definition
	
	e.g
		function clz:Do()
			g_task:AddTask() -- it's forbidden
		end
]]
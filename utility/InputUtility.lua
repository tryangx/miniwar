function InputUtility_ReceiveInput()
	return io.read()
end


function InputUtility_Pause( ... )
	if ... then
		print( ... )
	else
		print( "Press any key to continue" )
	end
	InputUtility_ReceiveInput()
end

function InputUtility_Wait( content, key )
	local input = nil
	if not key then
		key = content
	else
		print( content )
	end
	print( "@please input key=" .. key )
	while input ~= key do
		input = InputUtility_ReceiveInput()
	end	
end
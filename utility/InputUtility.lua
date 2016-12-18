function InputUtility_ReceiveInput()
	return io.read()
end


function InputUtility_Pause( content )
	--if content then print( content ) end
	if content then
		print( content )
	else
		print( "Press any key to continue" )
	end
	InputUtility_ReceiveInput()
end

function InputUtility_Wait( key )
	local input = nil
	print( "@please input key=" .. key )
	while input ~= key do
		input = InputUtility_ReceiveInput()
	end	
end
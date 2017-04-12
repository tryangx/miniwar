DialogIDS =
{
	HINT_PLAYER_SUBMIT_PROPOSAL     = 100,
	HINT_LEADER_TO_CHOICE_PROPOSAL  = 101,
	HINT_PLAYER_TO_MAKE_PROPOSAL    = 102,
	NOTICE_CHOICE_PROPOPSAL_BEGIN   = 103,
	NOTICE_CHOICE_PROPOPSAL_END     = 104,
}

local DialogueContents = 
{
	[100] = { "Sir $name$, Please submit a proposal!" },
	[101] = { "My Lord $name$, Please make a choice!" },
	[102] = { "My Lord $name$, Please submit a proposal!" },
	[103] = { "Lord $name$ is ready to choice proposal!" },
	[104] = { "Finally, $name$ was choiced!" },
}

function Dialogue_Show( id, params )
	local dialogue = DialogueContents[id]
	if not dialogue then return end

	for k, word in ipairs( dialogue ) do
		local realWord = string.rep( word, 1 )
		if params then
			realWord = string.gsub( realWord, "%$(%w+)%$", params )
		end
		print( realWord )
	end	
end
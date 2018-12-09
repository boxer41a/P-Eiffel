note
	description: "[
		Constants used in the {FLIPPER} game.
		]"
	author:		"Jimmy J. Johnson"

class
	GAME_CONSTANTS

feature -- Access

	black: INTEGER = 1
	white: INTEGER = 2

feature {NONE} -- Implementation

	attribute_type: INTEGER
			-- Anchor for types
		once
		end

end

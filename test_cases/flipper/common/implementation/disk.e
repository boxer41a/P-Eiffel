note
	description: "[
		A game piece for the Othello game black on one
		side, white on the other.
		]"
	author:		"Jimmy J. Johnson"

class
	DISK

inherit

	GAME_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make (a_owner: like owner)
			-- Create a disk owned by `a_owner'
		require
			owner_exists: a_owner /= Void
		do
			owner := a_owner
			previous_owner := a_owner
		end

feature -- Access

	owner: PLAYER
			-- The owner of this disk

feature -- Element change

	set_owner (a_player: like owner)
			-- Change the `owner'
		do
			previous_owner := owner
			owner := a_player
		end

	revert_owner
			-- Change the owner back to what it was before
			-- the last call to `set_owner'.
		do
			owner := previous_owner
		end

feature -- Query

	is_opposing_disk (other: like Current): BOOLEAN
			-- Is `other' a disk owned by some other owner?
		do
			Result := not (owner = other.owner)
		end

feature {NONE} -- Implementation

	previous_owner: PLAYER
			-- The player who owned this disk before the last
			-- call to `set_owner'.

end

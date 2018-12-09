note
	description: "[
		Command used to place a disk in the {FLIPPER} game.
		]"
	author: "Jimmy J. Johnson"

class
	MOVE_COMMAND

inherit

	JJ_COMMAND
		redefine
			text,
			execute,
			undo,
			is_executable
		end

create
	make

feature {NONE} -- Initialization

	make (a_player: PLAYER; a_row, a_column: INTEGER)
			-- Initialize a command that can flip the disk at `a_to_location',
			-- giving control of that square to the active player of `a_game'.
		require
			is_valid_location: a_player.game.is_valid_index (a_row, a_column)
			is_valid_move: a_player.is_valid_move (a_row, a_column)
		do
			default_create
			create flipped_disks.make
			player := a_player
			row := a_row
			column := a_column
		end

feature -- Access

	text: STRING
			-- Description of the command
		do
			Result := player.name + " - place disk at "
			Result := Result +  "(" + row.out + ", " + column.out + ")"
		end

	player: PLAYER
			-- The player executing this command.

	row: INTEGER
			-- The y coordinate of the cell in a FLIPPER game to
			-- which this move referes.

	column: INTEGER
			-- The x coordinate of the cell in a FLIPPER game to
			-- which this move referes.

	flipped_disks: LINKED_LIST [DISK]
			-- The disks that were flipped by executing the command
			-- along with its previous color.

feature -- Basic operations

	execute
			-- Perform the action, which places a disk at `location'
			-- and advances to the next player.
		local
			d_list: LINKED_LIST [DISK]
		do
			Precursor {JJ_COMMAND}
			if player.has_move then
				d_list := player.outflanked (row, column)
				from d_list.start
				until d_list.after
				loop
					flipped_disks.extend (d_list.item)
					d_list.forth
				end
			end
			player.place_disk (row, column)
			player.game.advance_to_next_player
		end

	undo
			-- Reverse the effects of executing the command	
		local
			d: DISK
		do
			Precursor {JJ_COMMAND}
			from flipped_disks.start
			until flipped_disks.exhausted
			loop
				d := flipped_disks.item
				d.revert_owner
				flipped_disks.forth
			end
			flipped_disks.wipe_out
			player.game.put (Void, row, column)
			player.game.return_to_previous_player
			check
				this_player: player.game.active_player = player
					-- Because undoing make it this player's turn again.
			end
		end

feature -- Status report

	is_executable: BOOLEAN
			-- Can the command be executed?
		do
			Result := Precursor
			if Result then
				Result := player.is_valid_move (row, column)
				if not Result then
					explanation.extend ("Not a valid move")
				end
			end
		end

invariant

	player_exists: player /= Void

end

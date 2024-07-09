note
	description: "[
		One of the players in the {FLIPPER} game.
		]"
	author:		"Jimmy J. Johnson"

class
	PLAYER

inherit

	GAME_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make (a_game: FLIPPER)
			-- Create a player with `a_id' in `a_game'
		require
			game_exists: a_game /= Void
		do
			game := a_game
		end

feature -- Access

	game: FLIPPER
			-- The game to which this player belongs

	name: STRING
			-- The name of this player
		do
			if attached name_imp as n then
				Result := n
			else
				Result := "Player_" + game.index_of_player (Current).out
			end
		end

	outflanked (a_row, a_column: INTEGER): LINKED_LIST [DISK]
			-- All the disks that will be flipped if Current places
			-- a disk at this location
		do
				-- check north-west, north, north-east, east, etc.
			Result := outflanked_in_direction (a_row, a_column, -1, -1)
			Result.merge_right (outflanked_in_direction (a_row, a_column, -1, 0))
			Result.merge_right (outflanked_in_direction (a_row, a_column, -1, 1))
			Result.merge_right (outflanked_in_direction (a_row, a_column, 0, 1))
			Result.merge_right (outflanked_in_direction (a_row, a_column, 1, 1))
			Result.merge_right (outflanked_in_direction (a_row, a_column, 1, 0))
			Result.merge_right (outflanked_in_direction (a_row, a_column, 1, -1))
			Result.merge_right (outflanked_in_direction (a_row, a_column, 0, -1))
		end

feature -- Element change

	set_name (a_name: STRING)
			-- Change the `name'
		do
			name_imp := a_name
		end

feature -- Status report

	has_move: BOOLEAN
			-- Does Current have a move?
		local
			r, c: INTEGER
		do
			from r := 1
			until r > game.height or Result
			loop
				from c := 1
				until c > game.width or Result
				loop
					Result := is_valid_move (r, c)
					c := c + 1
				end
				r := r + 1
			end
		end

feature -- Basic operations

	place_disk (a_row, a_column: INTEGER)
			-- Current places a game piece at that position.
		require
			valid_move: is_valid_move (a_row, a_column)
		local
			d: DISK
			d_list: LINKED_LIST [DISK]
		do
			d_list := outflanked (a_row, a_column)
			check
				outflanked_at_least_one: d_list.count >= 1
					-- because of invariant
			end
			create d.make (Current)
			game.put (d, a_row, a_column)
			from d_list.start
			until d_list.exhausted
			loop
				d_list.item.set_owner (Current)
				d_list.forth
			end
		end

feature -- Query

	is_valid_move (a_row, a_column: INTEGER): BOOLEAN
			-- Can Current move to that position?
		do
			Result := not game.is_occupied (a_row, a_column) and
				outflanks_opponents (a_row, a_column)
		end

	outflanks_opponents (a_row, a_column: INTEGER): BOOLEAN
			-- If Current moves to this position will it flip any of
			-- the opponents' disks?
		require
			valid_index: game.is_valid_index (a_row, a_column)
		do
			Result := outflanked_in_direction (a_row, a_column, -1, -1).count >= 1 or
						outflanked_in_direction (a_row, a_column, -1, 0).count >= 1 or
						outflanked_in_direction (a_row, a_column, -1, 1).count >= 1 or
						outflanked_in_direction (a_row, a_column, 0, 1).count >= 1 or
						outflanked_in_direction (a_row, a_column, 1, 1).count >= 1 or
						outflanked_in_direction (a_row, a_column, 1, 0).count >= 1 or
						outflanked_in_direction (a_row, a_column, 1, -1).count >= 1 or
						outflanked_in_direction (a_row, a_column, 0,-1).count >= 1
		end

feature {NONE} -- Implementation

	outflanked_in_direction (a_row, a_column, a_row_delta,
							a_column_delta: INTEGER): LINKED_LIST [DISK]
			-- The disks that Current will outflank in the direction indicated
			-- by (`a_row_delta', `a_column_delta') if Current were to move
			-- to position (`a_row', `a_column').
		require
			deltas_big_enough: a_row_delta >= -1 and a_column_delta >= -1
			deltas_small_enough: a_row_delta <= 1 and a_column_delta <= 1
		local
			r, c: INTEGER
			pot: LINKED_LIST [DISK]
			done: BOOLEAN
		do
			create Result.make
			create pot.make
			r := a_row + a_row_delta
			c := a_column + a_column_delta
			if (game.is_valid_index (a_row, a_column) and
					game.is_valid_index (r, c)) and then
					(attached {DISK} game.item (r, c) as d and then
				d.owner /= Current) then
						-- Potentially add this disk and others reached by moving
						-- in the delta direction until reaching Current's color.
				pot.extend (d)
				from
					r := r + a_row_delta
					c := c + a_column_delta
				until done
				loop
					if game.is_valid_index (r, c) and then attached {DISK} game.item (r, c) as next_d then
						if next_d.owner = Current then
							done := True
							Result := pot
						else
							pot.extend (next_d)
						end
						r := r + a_row_delta
						c := c + a_column_delta
					else
						done := True
					end
				end
			end
		end

	name_imp: detachable STRING
			-- Void until `set_name' is called

invariant

	game_exists: game /= Void

end

note
	description: "[
		Representation of the game othello as an 8 x 8 board
		]"
	author:		"Jimmy Johnson"

class
	FLIPPER

inherit

	ARRAY2 [detachable DISK]
		export
			{ANY}
				array_put
		redefine
			default_create
		end

	PERSISTABLE
		undefine
			copy,
			is_equal
		redefine
			default_create
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create a game with two players
		local
			p: PLAYER
			d: DISK
		do
			create players.make (2)
			make_filled (Void, Default_size, Default_size)
			Precursor {PERSISTABLE}
				-- create the first player and place his initial markers
			create p.make (Current)
			p.set_name ("Black")
			players.extend (p)
			create d.make (p)
			put (d, 4, 5)
			create d.make (p)
			put (d, 5, 4)
				-- create the second player and place his initial markers
			create p.make (Current)
			p.set_name ("White")
			players.extend (p)
			create d.make (p)
			put (d, 4, 4)
			create d.make (p)
			put (d, 5, 5)
		end

feature -- Access

	player_count: INTEGER
			-- The number of players
		do
			Result := players.count
		end

	i_th_player (index: INTEGER): PLAYER
			-- The player at `index' position
		require
			valid_index: index >= 1 and index <= player_count
		do
			Result := players.i_th (index)
		end

	index_of_player (a_player: PLAYER): INTEGER
			-- The index of `a_player' in `players'.
		require
			has_player: players.has (a_player)
		do
			Result := players.index_of (a_player, 1)
		end

	players: ARRAYED_CIRCULAR [PLAYER]
			-- List of players in this game

	active_player: PLAYER
			-- The player whose turn it is
		do
			Result := players.item
		end

	active_player_index: INTEGER
			-- The index of the active player
		do
			Result := players.index
		end

	winner: PLAYER
			-- The winner of the game
		require
			game_over: is_over
		do
			Result := players.i_th (winner_index)
		end

	winner_index: INTEGER
			-- The index of the player that won the game
		require
			game_is_over: is_over
		local
			s, old_s: INTEGER
		do
			from players.start
			until players.exhausted
			loop
				s := score (players.item)
				if s > old_s then
					Result := players.index
					old_s := s
				end
				players.forth
			end
		end

	score (a_player: PLAYER): INTEGER
			-- Number of tiles occupied by `a_player'
		local
			i: INTEGER
		do
			from i := 1
			until i > count
			loop
				if attached {DISK} entry (i) as d and then d.owner = a_player then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	Default_size: INTEGER = 8
			-- The size [square] to make the game

	Minimum_players: INTEGER = 2
			-- The minimum number of players allowed

	Maximum_players: INTEGER = 4
			-- The maximum number of players allowed

	id: INTEGER
			-- Added to identify this object with the database row.

feature -- Element change

	set_id (a_id: INTEGER)
			-- Set `id'.  Added to allow database access.
		do
			id := a_id
		end

feature -- Basic operations

	advance_to_next_player
			-- Advance to the next player
		do
			players.forth
		end

	return_to_previous_player
			-- Go back to the player that moved last.
		do
			players.back
		end

	remove_player (a_index: INTEGER)
			-- Remove the indexed player
		require
			removal_allowed: players.count > Minimum_players
			valid_index: a_index >= 1 and a_index <= players.count
		do
			players.go_i_th (a_index)
			players.remove
		end

	add_player (a_player: PLAYER)
		require
			not_full: players.count < Maximum_players
		do
			players.extend (a_player)
		end

feature -- Status report

	is_over: BOOLEAN
			-- Is the game finished?
			-- True if the board is full or no player has a move
		do
			Result := not has_remaining_moves
		end

	has_remaining_moves: BOOLEAN
			-- Does the game still have possible moves?
		local
			i: INTEGER
		do
			from i := 1
			until i > players.count or Result
			loop
				Result := players [i].has_move
				i := i + 1
			end
		end

feature -- Query

	is_valid_index (a_row, a_column: INTEGER): BOOLEAN
			-- Is the position valid?
		do
			Result := a_row >= 1 and a_row <= width and
						a_column >= 1 and a_column <= height
		end

	is_occupied (a_row, a_column: INTEGER): BOOLEAN
			-- Is this position already claimed by a player?
		require
			is_valid_index: is_valid_index (a_row, a_column)
		do
			Result := item (a_row, a_column) /= Void
		end

invariant

	square_board: width = height
	active_player_exists: active_player /= Void

end

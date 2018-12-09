note
	description: "[
		Root class for all the views in {FLIPPER}.
		]"
	author:		"Jimmy J. Johnson"

class
	FLIPPER_VIEW

inherit

	JJ_MODEL_WORLD_VIEW
		redefine
			create_interface_objects,
			add_actions,
			target_imp,
			set_target,
			draw
		end

create
	default_create

feature {NONE} -- Initialization

	create_interface_objects
			-- Create objects to be used by `Current' in `initialize'
			-- Implemented by descendants to create attached objects
			-- in order to adhere to void-safety due to the implementation bridge pattern.
		do
			create disks.make_filled (create {DISK_SQUARE}, 0, 0)
			create score_text
			create background
			Precursor {JJ_MODEL_WORLD_VIEW}
		end

	add_actions
			-- Add agents to events
		do
			Precursor {JJ_MODEL_WORLD_VIEW}
			resize_actions.force_extend (agent on_resize)
		end

feature -- Element change

	set_target (a_target: like target)
			-- Change the value of `target' and add it to the `target_set' (the set
			-- of objects contained in this view.  The old target is removed from
			-- the set.
			-- When the target [a game] is changed the widgets are rebuilt.  Builds
			-- a square and a disk for each spot on the board; they get refreshed
			-- when they change colors.
		local
			r, c: INTEGER
			ds: DISK_SQUARE
		do
			Precursor {JJ_MODEL_WORLD_VIEW} (a_target)
			world.wipe_out
			world.extend (background)
			create ds
			create disks.make_filled (ds, target.width, target.height)
			from r := 1
			until r > target.width
			loop
				from c := 1
				until c > target.height
				loop
					create ds
					world.extend (ds)
					disks.put (ds, r, c)
					ds.pointer_button_release_actions.force_extend (agent on_tile_clicked (r, c))
					c := c + 1
				end
				r := r + 1
			end
			world.extend (score_text)
			update_tiles
			report_status
		end

feature -- Basic operations

	draw
			-- Build the view
		do
			world.full_redraw
			Precursor {JJ_MODEL_WORLD_VIEW}
		end

	update_tiles
			-- Size and color the tiles and disks
		local
			r, c: INTEGER
			ds: DISK_SQUARE
		do
			check attached player_to_color_map.item (target.active_player_index) as pc then
				background.set_background_color (pc)
			end
			from r := 1
			until r > target.width
			loop
				from c := 1
				until c > target.height
				loop
					ds := disks.item (r, c)
					if attached {DISK} target.item (r, c) as d then
						check attached player_to_color_map.item (target.players.index_of (d.owner, 1)) as pc then
							ds.set_disk_color (pc)
							ds.set_tile_color (tile_color)
						end
					elseif target.active_player.is_valid_move (r, c) then
						ds.set_disk_color (tile_color)
						ds.set_tile_color (tile_color)
					else
						ds.set_tile_color (grey_tile_color)
						ds.set_disk_color (grey_tile_color)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	report_status
			-- Send a message to the parent tool
		local
			p: PLAYER
			i: INTEGER
			s: STRING
		do
			check attached {FLIPPER_TOOL} parent_tool as t then
				s := ""
				from i := 1
				until i > target.player_count
				loop
					p := target.i_th_player (i)
					s := s + p.name + ": " + target.score (p).out + "    "
					i := i + 1
				end
				if target.is_over then
					s := "WINNER: " + target.winner.name + "    " + s
					check attached player_to_color_map.item (target.active_player_index) as pc then
						background.set_background_color (pc)
					end
				elseif not target.active_player.has_move then
					s := target.active_player.name + " has no moves!!!"
				else
					s := s + "   active: " + target.active_player.name
				end
				t.set_status_string (s)
			end
		end

	on_resize
			-- React to a change in the windows size
		local
			r, c: INTEGER
			ds: DISK_SQUARE
			x,y: INTEGER
			hs, vs: INTEGER
			h_marg, v_marg: INTEGER
		do
			h_marg := width // 10
			v_marg := height // 10
			if not is_view_empty then
				hs := (width - 2 * h_marg) // target.width
				vs := (height - 2 * v_marg) // target.height
				background.set_point_a_position (hs - h_marg, vs - v_marg)
				background.set_width (width)
				background.set_height (height)
				from
					r := 1
					y := v_marg
				until r > target.width
				loop
					x := hs
					from c := 1
					until c > target.height
					loop
						ds := disks.item (r, c)
						ds.set_x_y (x, y)
						ds.set_size (hs, vs)
						x := x + hs
						c := c + 1
					end
					y := y + vs
					r := r + 1
				end
			end
		end

	on_tile_clicked (a_row, a_column: INTEGER)
			-- React to a click on a tile
		local
			com: MOVE_COMMAND
		do
			if target.active_player.has_move then
				if target.active_player.is_valid_move (a_row, a_column) then
						-- Create and execute the command
					create com.make (target.active_player, a_row, a_column)
					command_manager.add_command (com)
				else
					do_nothing
				end
			else
				target.advance_to_next_player
			end
			update_tiles
			report_status
		end

feature {NONE} -- Implementation

	colors: EV_STOCK_COLORS
			-- To get some EV_COLORs
		once
			create Result
		end

	player_to_color_map: HASH_TABLE [EV_COLOR, INTEGER]
			-- Maps a particular color to a player
		once
			create Result.make (20)
			Result.extend (colors.Black, 1)
			Result.extend (colors.White, 2)
			Result.extend (colors.Green, 3)
			Result.extend (colors.Yellow, 4)
		end

	tile_color: EV_COLOR
			-- The default color for each tile
		once
			Result := colors.green
		end

	grey_tile_color: EV_COLOR
			-- Color for tiles which cannot be selected
		once
			Result := colors.dark_green
		end

feature {NONE} -- Implementation

	score_text: EV_MODEL_TEXT
			-- Reports the score

	background: EV_MODEL_RECTANGLE
			-- Just to color the background, so we know whose turn it is

	disks: ARRAY2 [DISK_SQUARE]
			-- All the cells (squares and circles) on the board

	target_imp: detachable FLIPPER
			-- The game displayed in Current

	Default_width: INTEGER = 400
			-- The default width of the board

	Default_height: INTEGER = 400
			-- the default width of the board

end

note
	description: "[
		Main window for graphical FLIPPER game.
		This version uses MySQL database to store games.
		]"
	author: "Jimmy J. Johnson"

class
	FLIPPER_MAIN_WINDOW

inherit

	JJ_MAIN_WINDOW
		redefine
			create_interface_objects,
			initialize,
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
			-- in order to adhere to void-safety due to the implementation
			-- bridge pattern.
		do
			Precursor {JJ_MAIN_WINDOW}
			create flipper_tool
			create db_chg.make
			create db_sel.make
			create db_res.make
			create db_tup.make
		end

	initialize
			-- Set up the window
		do
			Precursor {JJ_MAIN_WINDOW}
			split_manager.enable_mode_changes
			split_manager.set_vertical
			split_manager.extend (flipper_tool)
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
			set_target (create {like target_imp})
			set_size (800, 800)
		end

	add_actions
			-- Assign actions to the buttons
		do
			Precursor {JJ_MAIN_WINDOW}
			open_button.select_actions.extend (agent on_load)
			save_button.select_actions.extend (agent on_store)
		end

feature -- Element change

	set_target (a_target: like target)
			-- Change the target
		do
			Precursor {JJ_MAIN_WINDOW} (a_target)
			flipper_tool.set_target (target)
		end

feature -- Basic operations

	draw
			-- Refresh Current and its buttons, title bar, etc.
		do
			Precursor {JJ_MAIN_WINDOW}
			paint_buttons
		end

feature {NONE} -- Implementation

	paint_buttons
			-- Add/remove appropriate buttons from the bar, enable/disable them,
			-- and set their colors
		do
			open_button.enable_sensitive
			save_button.enable_sensitive
		end

	flipper_tool: FLIPPER_TOOL
			-- Drawing will be done here.

	target_imp: detachable FLIPPER
			-- The game being played

feature {NONE} -- Implementation (actions)

	on_load
			-- Load a previously saved game from the database.
		local
			d: LOAD_DIALOG
			g_index: INTEGER
			ev_dialog: EV_MESSAGE_DIALOG
		do
			check attached {FLIPPER_APPLICATION} ev_application as app then
				create ev_dialog
				ev_dialog.set_pixmap (create {EV_PIXMAP}.make_with_pixel_buffer (Icon_save_color_buffer))
				ev_dialog.set_buttons_and_actions (<<" OK ">>, <<agent ev_dialog.destroy>>)
					-- Check for connection.
				if app.db_control.is_connected then
					create d
					d.fill_game_list (loaded_game_index_tuples)
					d.show_modal_to_window (Current)
					if not d.is_cancelled then
						g_index := d.selected_game_index
						set_target (loaded_game (g_index))
					end
						-- Display a message.
					ev_dialog.set_text ("Game was loaded")
				else
					ev_dialog.set_text ("Unable to load the game:  not connected to database.")
				end
				ev_dialog.show_modal_to_window (Current)
			end
		end

	on_store
			-- Store the game to the database
		local
			ev_dialog: EV_MESSAGE_DIALOG
			q: STRING_8
			i: INTEGER
		do
			check attached {FLIPPER_APPLICATION} ev_application as app then
				create ev_dialog
				ev_dialog.set_pixmap (create {EV_PIXMAP}.make_with_pixel_buffer (Icon_save_color_buffer))
				ev_dialog.set_buttons_and_actions (<<" OK ">>, <<agent ev_dialog.destroy>>)
					-- Check for connection.
				if app.db_control.is_connected then
					if not is_game_stored then
							-- Insert the game into the database.
						q := "INSERT INTO game (width, height) VALUES "
						q.append ("(" + target.width.out + ", " + target.height.out + ");")
						db_chg.modify (q)
							-- Get that game's id from the database.
						q := "SELECT LAST_INSERT_ID()"
						db_sel.query (q)
						db_sel.load_result
						db_res := db_sel.cursor
						check attached db_res as r then
							db_tup.copy (r)
							check attached {INTEGER_REF} db_tup.item (1) as v then
								target.set_id (v)
							end
						end
						db_sel.terminate
					end
						-- Write the current time to the database for the game.
					q := "UPDATE game "
					q := q + "SET game_time = NOW() "
					q := q + " WHERE game_id = " + target.id.out + ";"
					db_chg.modify (q)
						-- Write the `current_player' to the database
					q := "UPDATE game SET current_player_id = "
					q := q + target.index_of_player (target.active_player).out
					q := q + " AND game_id = " + target.id.out + ";"
					db_chg.modify (q)
						-- Modify or insert the disks to the database.
					from i := 1
					until i > target.count
					loop
						if attached target.at (i) as d then
							if is_disk_stored (i) then
								modify_disk (d, i)
							else
								insert_disk (d, i)
							end
						end
						i := i + 1
					end
						-- Display a message.
					ev_dialog.set_text ("Game was saved")
				else
					ev_dialog.set_text ("Unable to store the game:  not connected to database.")
				end
				ev_dialog.show_modal_to_window (Current)
			end
		end

feature {NONE} -- Implementation (helps with database access)

	is_game_stored: BOOLEAN
			-- Has the current game (i.e. `target') been written to the database?
		local
			q: STRING
		do
			q := "SELECT EXISTS (SELECT * FROM game WHERE game_id = " + target.id.out + ");"
			db_sel.query (q)
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				Result := attached {INTEGER_REF} db_tup.item (1) as b and then not (b.item = 0)
			end
			db_sel.terminate
		end

	is_disk_stored (a_index: INTEGER): BOOLEAN
			-- Has the {DISK} indexed by `a_index' been written to the database?
		local
			q: STRING
		do
				-- Determine if disks have been inserted into the database.
			q := "SELECT EXISTS (SELECT * FROM disk WHERE game_id = " + target.id.out
			q := q + " AND disk_id = " + a_index.out + ");"
			db_sel.set_query (q)
			db_sel.execute_query
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				Result := attached {INTEGER_REF} db_tup.item (1) as b and then
					not (b.item = 0)
			end
			db_sel.terminate
		end

	loaded_game_index_tuples: LINKED_LIST [TUPLE [i: INTEGER_REF; dt: DATE_TIME]]
			-- A list of indexes into the games stored in the database,
			-- pared with the time that game was saved.
			-- Note:  I used {DATE_TIME} here instead of my {YMDHMS_TIME},
			-- because EiffelStore returns this type when a date is found
			-- in the database.  There was no need to convert the date.
		local
			q: STRING
			arr_list: ARRAYED_LIST [DB_RESULT]	-- to retrieve list of rows
		do
			create Result.make
			create arr_list.make (100)
				-- Get the data from the database.
			q := "SELECT game_id, game_time FROM game;"
			db_sel.query (q)
			db_sel.set_container (arr_list)
			db_sel.load_result
			from arr_list.start
			until arr_list.after
			loop
				db_res := arr_list.item
				check attached db_res as r then
					db_tup.copy (r)
					check attached {INTEGER_REF} db_tup.item (1) as v and then
							attached {DATE_TIME} db_tup.item (2) as dt then
						Result.extend ([v, dt])
					end
				end
				arr_list.forth
			end
			db_sel.terminate
		end

	loaded_game (a_game_index: INTEGER): FLIPPER
			-- Retrieve the game indexed by `a_index' from the database.
		local
			q: STRING
			p_index: INTEGER
			con: ARRAYED_LIST [DB_RESULT]
			d: DISK
			p: PLAYER
		do
			Result := target
			target.discard_items
				-- Load the index of the current player from the database.
			q := "SELECT current_player_id FROM game WHERE game_id = " + a_game_index.out + ";"
			db_sel.query (q)
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				check attached {INTEGER_REF} db_tup.item (1) as i then
					p_index := i
				end
			end
			db_sel.terminate
				-- Load the disks
			q := "SELECT disk_id, owner_id FROM disk WHERE game_id = " + a_game_index.out + ";"
			create con.make (100)
			db_sel.set_container (con)
			db_sel.query (q)
			db_sel.load_result
			from con.start
			until con.after
			loop
				db_res := con.item
				check attached db_res as r then
					db_tup.copy (r)
					check attached {INTEGER_REF} db_tup.item (1) as d_id and
							attached {INTEGER_REF} db_tup.item (2) as o_id then
						p := target.i_th_player (o_id)
						create d.make (p)
						Result.array_put (d, d_id)
					end
				end
				con.forth
			end
		end

	insert_disk (a_disk: DISK; a_index: INTEGER)
			-- Insert (the first time) the `a_disk', indexing it
			-- by `a_index' in the database.
		local
			p: PLAYER
			p_ndx: INTEGER
			q: STRING_8
		do
			p := a_disk.owner
			p_ndx := target.index_of_player (p)
			q := "INSERT INTO disk (disk_id, game_id, owner_id) VALUES ("
			q.append (a_index.out + ", " + target.id.out + ", " + p_ndx.out + ");")
			db_chg.modify (q)
		end

	modify_disk (a_disk: DISK; a_index: INTEGER)
			-- Modify the of the disk index by `a_index' in the database
			-- with the values in `a_disk'.
		local
			p: PLAYER
			p_ndx: INTEGER
			q: STRING_8
		do
			p := a_disk.owner
			p_ndx := target.index_of_player (p)
			q := "UPDATE  disk SET owner_id = " + p_ndx.out
			q := q + " WHERE disk_id = " + a_index.out
			q := q + " AND game_id = " + target.id.out + ";"
			db_chg.modify (q)
		end

	db_chg: DB_CHANGE
			-- Allows modifications to database (i.e. add row).

	db_sel: DB_SELECTION
			-- For getting values from the database.

	db_res: detachable DB_RESULT
			-- Along with DB_TUPLE, used to interpret results of a DB_SELECTION.

	db_tup: DB_TUPLE
			-- Along with DB_RESULT, used to interpret result of a DB_SELECTION.

end

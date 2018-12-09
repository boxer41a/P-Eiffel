note
	description: "[
		Main window for FLIPPER where objects are persisted
		using P-EIffel.
		]"
	author: "Jimmy J. Johnson"

class
	FLIPPER_MAIN_WINDOW

inherit

	PERSISTENCE_FACILITIES
		undefine
			default_create,
			copy
		end

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
		end

	initialize
			-- Set up the window
		local
			c: NETWORK_CREDENTIALS
--			r: MEMORY_REPOSITORY
			r: ZMQ_REPOSITORY
--			r: NETWORK_REPOSITORY
		do
				-- Set up the repository
			create c
			create r.make (c)
			if not is_repository_set then
				Persistence_manager.set_repository (r)
				r.accept_notifications
			end
			Persistence_manager.set_persist_automatic
			Precursor {JJ_MAIN_WINDOW}
			split_manager.enable_mode_changes
			split_manager.set_vertical
			split_manager.extend (flipper_tool)
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
			jj_tool_bar_box.extend (create {EV_HORIZONTAL_SEPARATOR})
				-- Create target and setup window.
			set_target (create {like target_imp})
			set_size (800, 800)
		end

	add_actions
			-- Assign actions to the buttons
		do
			Precursor {JJ_MAIN_WINDOW}
			open_button.select_actions.extend (agent on_load)
			check attached {JJ_APPLICATION} (create {EV_ENVIRONMENT}).application as app and
				 	attached {ZMQ_REPOSITORY} Persistence_manager.repository as r then
				app.add_idle_action (agent on_changed)
			end
		end

feature -- Element change

	set_target (a_target: like target)
			-- Change the target
		do
			Precursor {JJ_MAIN_WINDOW} (a_target)
			set_title ("FLIPPER   " + target.persistence_id.out + "   " + Persistence_manager.session_id.out)
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
			-- Load a previously saved game.
		local
			dt: INTEGER
			pt: PERSISTENT_TYPE
			d: LOAD_DIALOG
			p: JJ_PROXY
		do
			pt := Persistence_manager.persistent_type (target)
--			dt := Internal.dynamic_type_from_string ("FLIPPER")
--			pt := Persistence_manager.persistent_type_from_dynamic_type (dt)
			create d
			d.fill_game_list (Persistence_manager.loaded_by_type (pt))
			d.show_modal_to_window (Current)
			if not d.is_cancelled then
				io.put_string ("Load button selected %N")
				p := d.selected_item
				check attached {FLIPPER} p.object as g then
					set_target (g)
				end
			end
		end

	on_changed
			-- Procedure called on idle to check for changed objects
			-- and redraw the game if necessary.
		local
			tab: HASH_TABLE [BOOLEAN, PID]
		do
--			io.put_string (generating_type + ".on_changed %N")
 			check attached {ZMQ_REPOSITORY} Persistence_manager.repository as r then
				tab := r.get_changed_objects
				if tab.count > 0 then
					io.put_string ("     ")
					from tab.start
					until tab.after
					loop
						io.put_string (tab.key_for_iteration.out + ", ")
						tab.forth
					end
					io.put_string ("%N")
				end
			end
		end

end

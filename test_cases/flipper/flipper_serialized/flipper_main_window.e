note
	description: "[
		Main window for FLIPPER
		]"
	author:		"Jimmy J. Johnson"

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
			create filename.make_empty
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
			new_target_button.select_actions.extend (agent on_new_game)
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

feature {NONE} -- Implementation (actions)

	on_new_game
			-- Create a new game.
		local
			t: like target_imp
		do
			create t
			set_target (t)
				-- Make the filename empty, because it is used
				-- in the `on_store' and `on_load' features.
			filename.wipe_out
		end

	on_store
			-- Store the game to the Repository
		local
			t: YMDHMS_TIME
			d: EV_MESSAGE_DIALOG
			f: RAW_FILE
			s: STRING_8
		do
			create t.set_now_fine
			if filename.is_empty then
				s := t.as_string
					-- Remove the dot to allign with file names on windows
				s.replace_substring_all (".", "-")
				filename := "FLIPPER_" + s + ".flp"
			end
			create f.make_open_write (filename)
			f.independent_store (target)
				-- Display a message.
			create d.make_with_text ("Game was saved")
			d.set_pixmap (create {EV_PIXMAP}.make_with_pixel_buffer (Icon_save_color_buffer))
			d.set_buttons_and_actions (<<" OK ">>, <<agent d.destroy>>)
			d.show_modal_to_window (Current)
		end

	on_load
			-- Load a previously saved game.
		local
			d: EV_FILE_OPEN_DIALOG
			f: RAW_FILE
		do
			create d
			d.filters.extend (["FLIPPER_*.flp", "FLIPPER games (*.flp)"])
			d.show_modal_to_window (Current)
				-- There seems to be a bug in EV_FILE_DIALOG, which I reported
				-- on 23 Jun 16) where `file_name' and `file_title' are not
				-- empty when the dialog is cancelled, which is contrary to
				-- the comments in the features.
--			if not d.file_name.is_empty then
			if not (d.file_name.is_empty or d.file_title ~ "commands") then
				filename := d.file_name
				create f.make_open_read (filename)
				if attached {FLIPPER} f.retrieved as g then
					set_target (g)
				end
			end
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

	filename: STRING_8
			-- The name of the game if any that was loaded or saved.

end

note
	description: "[
		Root class for tools used in the Flipper game.
		]"
	author:		"Jimmy J. Johnson"

class
	FLIPPER_TOOL

inherit

	TOOL
		redefine
			create_interface_objects,
			initialize,
			add_actions,
			target_imp,
			set_target
		end

feature {NONE} -- Initialization

	create_interface_objects
			-- Create objects to be used by `Current' in `initialize'
			-- Implemented by descendants to create attached objects
			-- in order to adhere to void-safety due to the implementation
			-- bridge pattern.
		do
			Precursor {TOOL}
			create view
			create automate_player_button
			automate_player_button.set_pixmap (create {EV_PIXMAP}.make_with_pixel_buffer (Icon_supplier_color_buffer))
			automate_player_button.set_tooltip ("Automate the current player")
		end

	initialize
			-- Build the interface for this window
		do
			Precursor {TOOL}
			build_tool_bar
			split_manager.enable_mode_changes
			split_manager.set_horizontal
			split_manager.extend (view)
		end

	build_tool_bar
			-- Add buttons to `tool_bar' (from TOOL).
		do
			tool_bar.extend (automate_player_button)
		end

	add_actions
			-- Add functionality to the buttons
		do
			Precursor {TOOL}
			automate_player_button.pointer_button_press_actions.force_extend (agent on_automate)
		end

feature -- Element change

	set_target (a_target: like target)
			-- Change the value of `target' and add it to the `target_set' (the set
			-- of objects contained in this view.  The old target is removed from
			-- the set.
			-- This feature can be used as a pattern if a descendant wants to give
			-- special treatment to a single target.
		do
			Precursor {TOOL} (a_target)
			view.set_target (a_target)
			view.on_resize
		end

feature {FLIPPER_VIEW}

	set_status_string (a_message: STRING)
			-- React to a change in the game caused by the `view'
		do
			user_text.set_text (a_message)
		end

feature {NONE} -- Implementation (actions)

	on_automate
			-- React to button press to make current player AI controlled
		do
			io.put_string ("FLIPPER_TOOL.on_automate %N")
		end

feature {NONE} -- Implementation

	view: FLIPPER_VIEW
			-- Displays the board

	target_imp: detachable FLIPPER
			-- The game being played

	automate_player_button: EV_TOOL_BAR_BUTTON
			-- Button to change the current player to an computer player

end

note
	description: "[
		Dialog box for selected a previous game
		]"
	author: "Jimmy J. Johnson"

class
	LOAD_DIALOG

inherit

	EV_DIALOG
		redefine
			initialize,
			create_interface_objects
		end

feature {NONE} -- Initialization


	create_interface_objects
			-- <Precursor>
		do
			create game_list
			create load_button.make_with_text ("Load")
			create cancel_button.make_with_text ("Cancel")
			selected_button := cancel_button
			Precursor
		end

	initialize
			-- <Precursor>
		local
			vb: EV_VERTICAL_BOX
			bb: EV_HORIZONTAL_BOX
		do
			Precursor
			create vb
			create bb
				-- Set the top container
			vb.set_padding (14)
			vb.set_border_width (10)
			vb.extend (game_list)
				-- Set up the button box
			bb.set_padding (14)
			bb.set_border_width (10)
			bb.extend (load_button)
			bb.extend (cancel_button)
			bb.disable_item_expand (load_button)
			bb.disable_item_expand (cancel_button)
			vb.extend (bb)
			vb.disable_item_expand (bb)
			extend (vb)
				-- Add actions
			load_button.select_actions.extend (agent on_button_press (load_button))
			cancel_button.select_actions.extend (agent on_button_press (cancel_button))
				-- Initialize the dialog's size
			set_minimum_size (300, 200)
		end

feature -- Access

	game: FLIPPER
			-- The retrieved game
		require
			game_was_loaded: not is_cancelled
		do
			check attached game_imp as g then
				Result := g
			end
		end

	selected_item: JJ_PROXY
			-- The item last selected in the dialog
		require
			not_cancelled: not is_cancelled
		do
			check attached {EV_LIST_ITEM} game_list.selected_item as gl and then
					attached {JJ_PROXY} gl.data as p then
				Result := p
			end
		end

feature -- Element change

	fill_game_list (a_list: LINKED_LIST [JJ_PROXY])
			-- Put the persisted games, identified in `a_list' into Current.
		local
			list_i: EV_LIST_ITEM
		do
			from a_list.start
			until a_list.exhausted
			loop
				create list_i.make_with_text (a_list.item.out)
				list_i.set_data (a_list.item)
				game_list.extend (list_i)
				a_list.forth
			end
		end

feature -- Status report

	is_cancelled: BOOLEAN
			-- Was the `cancel_button' pressed?
		do
			Result := selected_button = cancel_button
		end

feature {NONE} -- Implementation

	on_button_press (a_button: EV_BUTTON)
			-- A button with text `a_button_text' has been pressed.
		local
			fac: PERSISTENCE_FACILITIES
		do
			if a_button = load_button and
					attached game_list.selected_item as list_i then
				selected_button := load_button
			else
				selected_button := cancel_button
			end
				-- Get rid of the dialog
			if not is_destroyed then
				destroy
			end
		end

	selected_button: EV_BUTTON
			-- Label of last clicked button.

	game_imp: detachable FLIPPER
			-- The game that was possibly loaded

	game_list: EV_LIST
			-- Displays the list of games

	load_button: EV_BUTTON
			-- Button to execute the load operation

	cancel_button: EV_BUTTON
			-- To close the dialog without doing anything

end

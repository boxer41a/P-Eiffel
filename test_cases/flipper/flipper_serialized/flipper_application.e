note
	description: "[
		Root class to test FLIPPER where the games are persisted
		using Eiffel serialization.  See {FLIPPER_MAIN_WINDOW}.
		]"
	author:		"Jimmy J. Johnson"

class
	FLIPPER_APPLICATION

inherit

	JJ_APPLICATION
		redefine
			create_interface_objects,
			window_anchor
		end

create
	make_and_launch

feature {NONE} -- Initialization

	create_interface_objects
			-- Create objects to be used by `Current' in initialize to adhere
			-- to void-safety due to the implementation bridge pattern.
		do
			create target
		end

feature -- Access

	target: FLIPPER
			-- The game currently in play.

feature {NONE} -- Implementation (anchors)

	window_anchor: FLIPPER_MAIN_WINDOW
			-- Anchor for the type of `first_window'
			-- Not to be called; just used to anchor types.
			-- Declared as a feature to avoid adding an attribute.
		require else
			not_callable: False
		do
			check
				do_not_call: False then
					-- Because give no info; simply used as anchor.
			end
		end

end

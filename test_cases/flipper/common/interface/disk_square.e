note
	description: "[
		A widget [world] consisting of a circle incribed in a square, representing
		a square on an Othello board containing a disk.
		]"
	author:		"Jimmy J. Johnson"

class
	DISK_SQUARE

inherit

	EV_MODEL_WORLD
		rename
			item as figure
		redefine
			default_create,
			new_filled_list
				-- Let's try redefining with an empty body; this feature
				-- may be inapplicable anyway.
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create a square
		do
			Precursor {EV_MODEL_WORLD}
			create square.make_with_positions (0, 0, 10, 10)
			create circle.make_with_positions (1, 1, 9, 9)
			world.extend (square)
			world.extend (circle)
		end

feature -- Access

	square: EV_MODEL_RECTANGLE
			-- The area of a game board

	circle: EV_MODEL_ELLIPSE
			-- The disk residing in the game square

feature -- Element change

	set_size (a_width, a_height: INTEGER)
			-- Change the width and height of the figures
		local
			sx, sy: DOUBLE
		do
			sx := a_width / square.width
			sy := a_height / square.height
			scale_x (sx)
			scale_y (sy)
		end

	set_disk_color (a_color: EV_COLOR)
			-- Change the color of the disk
		do
			circle.set_background_color (a_color)
			circle.set_foreground_color (a_color)
		end

	set_tile_color (a_color: EV_COLOR)
			-- Change the color of the tile
		do
			square.set_background_color (a_color)
		end

feature {NONE} -- Inapplicable

	new_filled_list (n: INTEGER): like Current
			-- Redefined to get past void-safety issues
		do
			check
				do_not_call: False then
					-- Because this was redefined to appease void-safety, nothing else.
			end
		end

end

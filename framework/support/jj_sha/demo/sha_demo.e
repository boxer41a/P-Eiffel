note
	description : "[
		Class which calls test functions to demonstrate and test
		the SHA-xxx classes.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SHA_DEMO

inherit
	ARGUMENTS

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			i: INTEGER
			t: SHA_TESTS
		do
			create t
				-- Clear the console
			from i := 1
			until i > 30
			loop
				io.new_line
				i := i + 1
			end
			print ("Begin SHA_DEMO %N")
			io.new_line

			t.test_sha_1

			io.new_line
			print ("End SHA_DEMO %N")
		end

end

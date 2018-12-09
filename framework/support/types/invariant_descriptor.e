note
	description: "[
		Describes an invariant on a persistent resource
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	INVARIANT_DESCRIPTOR

inherit

	CONSTRUCT_DESCRIPTOR
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make (a_name: like name)
			-- Create an instance
		do
			Precursor {CONSTRUCT_DESCRIPTOR} (a_name)
		end

end

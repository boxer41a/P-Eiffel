note
	description: "[
		A reference to a REPOSITORY (i.e. a reference to a PID_FACTORY).
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	REPOSITORY_REF

inherit

	ANY
		redefine
			default_create
		end


feature {NONE} -- Initialization

	default_create
			-- Initialize Current as a {LOCAL_REPOSITORY} called "datafile.dat"
		local
--			c: CREDENTIALS
		do
--			create c.make ("default_repository_ref.dat")
--			create {LOCAL_REPOSITORY} item.make (c)
		end

feature -- Access

	item: detachable REPOSITORY
			-- The factory referenced by Current

feature -- Element change

	set_item (a_repository: like item)
			-- Change the `item'
		do
			item := a_repository
		end

end

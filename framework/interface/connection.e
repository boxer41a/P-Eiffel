note
	description: "[
		Represents a connection to a client.  Feature `is_waiting' indicates
		that feature `execute' (from POLL_COMMAND) was executed and therefore
		a message is waiting on the IO_MEDIUM with which Current was associated
		in its creation routine `make'.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	CONNECTION

inherit

	POLL_COMMAND
		redefine
			make
		end

	PERSISTENCE_FACILITIES		-- for access to `session_id'

create
	make

feature {NONE} -- Initialization

	make (s: IO_MEDIUM)
		do
			Precursor (s)
			create client_id
		end

feature

	is_waiting: BOOLEAN
			-- Does Current have a message to deliver?

	client_id: like session_id
			-- To identify which client sent the message and to whom
			-- Current should reply

	execute (arg: ANY)
		do
			is_waiting := True
		end

	initialize
		do
			is_waiting := False
		end

	set_client_id (a_id: like client_id)
		do
			client_id := a_id
		end

end

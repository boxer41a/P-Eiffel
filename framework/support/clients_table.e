note
	description: "[
		A table holding information about each client to which
		a server needs to communicate.  This is really just a
		simple structure that consolidates client information
		into a single object in a HASH_TABLE.
		]"
	author: "Jimmy J. Johnson"

class
	CLIENTS_TABLE

inherit

	HASH_TABLE [TUPLE [is_push: BOOLEAN; pids: HASH_TABLE [BOOLEAN, PID]], UUID]
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make (a_size: INTEGER)
			-- Set up Current.
		do
			Precursor (a_size)
		end

feature -- Basic operations

	force_client (a_client: UUID)
			-- Create an entry for `a_client'.
		do
			force ([false, create {like pid_interests}.make (100)], a_client)
		ensure
			has_client: has (a_client)
		end

feature -- Element change

	enable_pushing (a_client: UUID)
			-- Set `is_pushing' to true.
		require
			has_client: has (a_client)
		do
			check attached item (a_client) as tup then
				tup.put (true, 2)
			end
		end

	disable_pushing (a_client: UUID)
			-- Set `is_pushing' to false.
		require
			has_client: has (a_client)
		do
			check attached item (a_client) as tup then
				tup.put (false, 2)
			end
		end

feature -- Query

	is_pushing (a_client: UUID): BOOLEAN
			-- Should server push messages to `a_client'?
		require
			has_client: has (a_client)
		do
			check attached item (a_client) as tup then
				Result := tup.is_push
			end
		end

	pid_interests (a_client: UUID): HASH_TABLE [BOOLEAN, PID]
			-- A list of {PID} for which the client wants notified if
			-- changed.  Implemented as HASH_TABLE for O(1) access.
		require
			has_client: has (a_client)
		do
			check attached item (a_client) as tup then
				Result := tup.pids
			end
		end

feature {NONE} -- Implementation


end

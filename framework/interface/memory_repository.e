note
	description: "[
		Interface to an underlying datastore, where that datastore is
		in session memory and never saved to permenant medium.
		This is used for development and testing of a persistent system.
		The data is simply stored in a {TABULATION}.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	MEMORY_REPOSITORY

inherit

	REPOSITORY
		redefine
			make,
			data,
			store
		end

create
	make

feature {NONE} -- Initialization

	make (a_credentials: CREDENTIALS)
			-- Create a repository to which a connection can be
			-- established using `a_credentials'.
		do
--			create last_pid		-- appease Void-safety
			create data_imp
			create id_bucket
			Precursor {REPOSITORY} (a_credentials)
		end

feature -- Access

	next_pid: PID
			-- The next available PID.  Sets `last_pid' to that value and
			-- changes Current's state so that the next call to this feature
			-- returns a new value.
		do
			create Result.make_from_value (id_bucket.next_oid.as_natural_64)
			set_last_pid (Result)
		end

	is_pid_available: BOOLEAN
			-- Is Current able to provide a new object identifier if
			-- asked for one by `next_oid'?
		do
			Result := not id_bucket.is_empty
		end

	recover_id (a_pid: PID)
			-- Someone is giving `a_pid' back to Current to use again.
		do
			id_bucket.recover_oid (a_pid.object_identifier)
			set_last_pid (a_pid)
		end

	data: TABULATION
			-- A representation of all the objects stored on Current.
			-- This can be used to view the repository for testing.
		do
			Result := data_imp.deep_twin
		end

	stored_descriptor (a_persistent_type: PERSISTENT_TYPE): TYPE_DESCRIPTOR
			-- Given `a_persistent_type', get the descriptor as recorded in
			-- the underlying datastore.
		do
			Result := data_imp.descriptor (a_persistent_type)
		end

	stored_type (a_pid: PID): PERSISTENT_TYPE
			-- The actual type of the object identified by `a_pid' as recorded
			-- in underlying store.  If `a_pid' is an identifier for a field,
			-- this gives the type of the referenced object.
		local
			i: INTEGER_32
			id: PID
		do
			if a_pid.is_attribute then
				i := a_pid.attribute_identifier
				id :=a_pid.as_object_identifier
				check data_imp.is_logged (id) then
					Result := data_imp.logged_type (id)
				end
			else
				Result := data_imp.logged_type (a_pid)
			end
		end

	stored_time (a_pid: PID): YMDHMS_TIME
			-- The time that the object identified by `a_pid' was recorded
			-- into the underlying datastore.
		do
			Result := data_imp.logged_time (a_pid)
		end

	known_types: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			-- A table containing all the types known to Current.
		do
			Result := data.descriptor_table
		end

	identifiers_for_type (a_type: PERSISTENT_TYPE): LINKED_LIST [PID]
			-- A list of identifiers of all the objects in Current that
			-- or of the same type as `a_type'.
		do
			Result := data_imp.identifiers_for_type (a_type)
		end

--	declared_type (a_pid: PID): PERSISTENT_TYPE
--			-- The declared type of the attribute identified by `a_pid' as seen
--			-- seen by the underlying store (the actual object type could be
--			-- any conforming type).
--		local
--			pt: PERSISTENT_TYPE
--			td: TYPE_DESCRIPTOR
--		do
--				-- Get the type from the descriptor of the enclosing object
--			pt := stored_type (a_pid)
--			td := stored_descriptor (pt)
--			Result := td.i_th_field (Parser.attribute_identifier (a_pid)).type
--		end

--	typed_proxies (a_type: PERSISTENT_TYPE): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies whose represented objects are of a
--			-- type that conforms to `a_type'
--		local
--			tup: like {TABULATION}.index.item		-- TUPLE [PERSISTENT_TYPE, YMDHMS_TIME]
--			pid: PID
--			p: JJ_PROXY
--		do
--			create result.make
--			from encoding.index.start
--			until encoding.index.after
--			loop
--				tup := encoding.index.item_for_iteration
--				pid := encoding.index.key_for_iteration
--				if tup.type ~ a_type then
--					create p.make (pid)
--					Result.extend (p)
--				end
--				encoding.index.forth
--			end
--		end

--	typed_proxies_with_attributes (a_type: PERSISTENT_TYPE;
--					a_attribute_list: ARRAYED_LIST [STRING_8]): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies containing the values of the listed attributes of the
--			-- represented objects as well as a handle to the persisted object.
--			-- This provides a way to load only a portion of an object, such as a
--			-- name, for display in a readable format without having to read in the
--			-- entire object.
--		local
--			tup: like {TABULATION}.index.item		-- TUPLE [PERSISTENT_TYPE, YMDHMS_TIME]
--			pid: PID
--			p: JJ_PROXY
--		do
--			create result.make
--			from encoding.index.start
--			until encoding.index.after
--			loop
--				tup := encoding.index.item_for_iteration
--				pid := encoding.index.key_for_iteration
--				if tup.type ~ a_type then
--					create p.make_with_attribute_names (pid, a_attribute_list)
--					Result.extend (p)
--				end
--				encoding.index.forth
--			end
--		end

feature -- Status setting

	connect
			-- Make Current able to communicate with the underlying physical store
		do
--			implementation.open_read_write
		end

	disconnect
			-- Make Current unable to communicate with the underlying physical store
		do
--			implementation.close
		end

feature -- Status report

	is_connected: BOOLEAN
			-- Is Current able to communicate with the underlying physical store?
		do
			Result := true
		end

feature -- Basic operations

	store (a_tabulation: TABULATION)
			-- Store `a_encoding'.
			-- So, this should only be called when `a_object' is in a valid
			-- state; other objects may be changing and in an invalid state,
			-- so we should not touch that part of the encoding yet.
		do
			data_imp.merge (a_tabulation)
--			print (generating_type + ".store:  data after merge: %N")
--			data_imp.show
				-- Save the changes
		end

	loaded (a_pid: PID): TABULATION
			-- Retrieve the encoding of the object referenced by `a_pid'
		local
			i, cnt: INTEGER_32
			id: PID
			pt: PERSISTENT_TYPE
			t: YMDHMS_TIME
			at: PERSISTENT_TYPE
			v: ANY
			queue: LINKED_QUEUE [PID]
			queued: HASH_TABLE [BOOLEAN, PID]	-- for O(1) lookup
			visited: HASH_TABLE [BOOLEAN, PID]
		do
			create queue.make
			create queued.make (Table_size)
			create visited.make (Table_size)
			create Result
				-- Set up the intitial value in the `queue' (i.e. the root).
			if a_pid.is_attribute then
				i := a_pid.attribute_identifier
				id := a_pid.as_object_identifier
				pt := data_imp.logged_type (id)
				t := data_imp.logged_time (id)
				at := data_imp.expected_type (i, id)
				v := data_imp.attribute_value (i, id)
					-- Add descriptor for the parent object
				Result.add_descriptor (data_imp.type_descriptor (id), pt)
				Result.log_object ([pt, t], id)
				Result.set_attribute_value (i, id, v)
				if data_imp.is_reference (i, id) then
					check attached {PID} v as n and then not n.is_void then
						queue.extend (n)
						queued.extend (true, n)
					end
				end
			elseif not a_pid.is_attribute and not a_pid.is_void then
					-- `a_pid' represents a reference to an object
				queue.extend (a_pid)
				queued.extend (true, a_pid)
			else
				do_nothing
			end
				-- Process the `queue'; breadth-first
			from
			until queue.is_empty
			loop
				id := queue.item
				visited.extend (true, id)
					-- Load the object and determine the number of fields it has.
				pt := data_imp.logged_type (id)
				t := data_imp.logged_time (id)
				if not Result.has_descriptor (pt) then
					Result.add_descriptor (data_imp.descriptor (pt), pt)
				end
				if not Result.is_logged (id) then
					Result.log_object ([pt, t], id)
				end
					-- Handle SPECIAL containing references differently.
				if data_imp.descriptor (pt).is_special_reference then
					cnt := data_imp.count_capacity (id).cap
					Result.set_count_capacity (data_imp.count_capacity (id), id)
				else
					cnt := data_imp.descriptor (pt).field_count
				end
				from i := 1
				until i > cnt
				loop
					if data_imp.has_attribute (i, id) then
						v := data_imp.attribute_value (i, id)
						Result.set_attribute_value (i, id, v)
						if data_imp.is_reference (i, id) then
								-- it must be a PID
							check attached {PID} v as pid then
								if not pid.is_void and not visited.has (pid) and not queued.has (pid) then
									queue.extend (pid)
									queued.extend (true, pid)
								end
							end
						end
					end
					i := i + 1
				end
				queue.remove
				queued.remove (id)
			end  -- until queue.is_empty ... loop
		end

	store_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Ensure Current knows about the type described by `a_descriptor'
		do
			data_imp.add_descriptor (a_descriptor, a_descriptor.type)
		end

	update_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Update the corresponding {TYPE_DESCRIPTOR} in Current with the
			-- values in the `ancestor_types' and `descendant_types' table of
			-- `a_descriptor'.
			-- An ancestor and descendent might be added to a {TYPE_DESCRIPTOR}
			-- whenever a new descriptor is created.  (See `initialize_types'
			-- from {TYPE_DESCRIPTOR}.)  Other values should never change.
		local
			td: TYPE_DESCRIPTOR
		do
			td := stored_descriptor (a_descriptor.type)
			td.ancestor_types.copy (a_descriptor.ancestor_types)
			td.descendant_types.copy (a_descriptor.descendant_types)
		end

	shut_down
		do
		end

	commit
		do
		end

	wipe_out
			-- Remove all data from the underlying store
			-- Used for testing
		do
			id_bucket.reset
			data_imp.wipe_out
			commit
		end

	show
			-- Display the data (for testing)
		local
			i: INTEGER
		do
			io.put_string ("vvvv " + generating_type)
			from i := 1
			until i > 3
			loop
				io.put_string (" vvvvvvvv " + generating_type)
				i := i + 1
			end
			io.put_string ("%N")
			io.put_string (data_imp.out)
			io.put_string ("^^^^ " + generating_type)
			from i := 1
			until i > 3
			loop
				io.put_string (" ^^^^^^^^ " + generating_type)
				i := i + 1
			end
			io.put_string ("%N")
		end

feature -- Query

	is_valid_credentials (a_credentials: like credentials): BOOLEAN
			-- Is `a_credentials' valid for connection to Current's
			-- underlying data store?
		do
			print (generating_type + ".is_valid_credentials:  Fix me! %N")
			Result := true
		end

	is_invariant_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_persistent_type' represent an invariant_type?
		do
			Result := false
			io.put_string ("REPOSITORY.is_invariant_type:  Fix me! %N")
		end

	is_stored (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been stored onto Current?
			-- This does not do a deep check to determine if the entire object
			-- structure reachable from `a_pid' is stored, so ...?
		do
			if a_pid.is_attribute then
				Result := data_imp.has_attribute (a_pid.attribute_identifier, a_pid.as_object_identifier)
			else
				Result := data_imp.is_logged (a_pid)
			end
		end

	is_stored_root (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been store onto Current
			-- and stored as a persistent root object?
		do
			Result := data_imp.has_root (a_pid)
		end

	is_known_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current know about the type described by `a_persistent_type'?
			-- See {TYPE_MAPPING}.stringify for description of the expected
			-- for `a_persistent_type' format.
		do
			Result := data_imp.has_descriptor (a_persistent_type)
		end

	is_attribute_type_declared (a_pid: PID): BOOLEAN
			-- Does Current contain a `stored_descriptor' for the object id
			-- refered to in `a_pid'?  If it does then there should be a
			-- declaration in that {TYPE_DESCRIPTOR} the that field.
		do
			print (generating_type + ".is_attribute_type_declared:  fix me!")
--			create pid.as_attribute_reference (a_pid, 0)
--			Result := data.object_table.has (pid)
		end

feature -- Implementation

	data_imp: TABULATION
			-- The in-memory data used by Current.

	id_bucket: ID_BUCKET
			-- Factory that supplies PID's for use on Current

end

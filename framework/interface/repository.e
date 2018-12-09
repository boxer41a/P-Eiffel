note
	description: "[
		Interface for accessing the underlying persistent store.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	REPOSITORY

inherit

	PERSISTENCE_FACILITIES

feature {NONE} -- Initialization

	make (a_credentials: CREDENTIALS)
			-- Create a repository to which a connection can be
			-- established using `a_credentials'.
		require
			is_valid_credentials: is_valid_credentials (a_credentials)
		do
			credentials := a_credentials
			create last_pid
		end

feature --{PERSISTENCE_MANAGER, PERSISTABLE, PSERVER, ZMQ_SERVER} -- Access

	next_pid: PID
			-- The next available PID.  Sets `last_pid' to that value and
			-- changes Current's state so that the next call to this feature
			-- returns a new value.
		deferred
		ensure
			pid_recorded: last_pid = Result
		end

	last_pid: PID
			-- Records the value returned by last call to `next_pid'

	is_pid_available: BOOLEAN
			-- Is Current able to provide a new object identifier if
			-- asked for one by `next_oid'?
		deferred
		end

	recover_id (a_pid: PID)
			-- Someone is giving `a_pid' back to Current to use again.
		deferred
		end

feature -- Access

	credentials: CREDENTIALS
			-- Information used to connect to the underlying data store.

	data: TABULATION
			-- The objects stored on Current
		deferred
		end

--	all_data: TABULATION
--			-- A representation of all the objects stored on Current.
--			-- This can be used to view the repository for testing.
--		deferred
--		end

	stored_descriptor (a_persistent_type: PERSISTENT_TYPE): TYPE_DESCRIPTOR
			-- Given `a_persistent_type', get the descriptor as recorded in
			-- the {REPOSITORY}.
		require
			is_known_type: is_known_type (a_persistent_type)
		deferred
		end

	stored_type (a_pid: PID): PERSISTENT_TYPE
			-- The actual type of the object identified by `a_pid' as recorded
			-- in underlying store.  If `a_pid' is an identifier for a field,
			-- this gives the type of the referenced object.
		require
			is_stored: is_stored (a_pid)
		deferred
		end

	stored_time (a_pid: PID): YMDHMS_TIME
			-- The time that the object identified by `a_pid' was recorded
			-- into the underlying datastore.
		require
			is_stored: is_stored (a_pid)
		deferred
		end

	known_types: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			-- A table containing all the object types known to Current.
		deferred
		end

--	declared_type (a_pid: PID): PERSISTENT_TYPE
--			-- The declared type of the attribute identified by `a_pid' as
--			-- seen by the underlying store (the actual object type could be
--			-- any conforming type).
--		require
--			is_attribute: Parser.is_attribute_id (a_pid)
--			is_object_type_known: is_attribute_type_declared (a_pid)
--		deferred
--		ensure
--			type_of_object_cannot_be_void: not (Result ~ Persistent_void_type)
--		end

--	typed_proxies (a_type: PERSISTENT_TYPE): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies whose represented objects are of a
--			-- type that conforms to `a_type'
--		deferred
--		end

--	typed_proxies_with_attributes (a_type: PERSISTENT_TYPE;
--					a_attribute_list: ARRAYED_LIST [STRING_8]): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies containing the values of the listed attributes of the
--			-- represented objects as well as a handled to the persisted object.
--			-- This provides a way to load only a portion of an object, such as a
--			-- name, for display in a readable format without having to read in the
--			-- entire object.
--		deferred
--		end

--	persisted_attribute (a_pid: PID): detachable ANY
--			-- The object, if any, referenced by `a_pid' where `a_pid' refers to
--			-- an attribute of some persisted object;
--			-- That attribute might be Void
--		require
--			is_persistent: is_persistent (a_pid)
--			is_attribute_id: a_pid.is_attribute_id
--		deferred
--		end

feature -- Basic operations

	store (a_encoding: TABULATION)
			-- Store the encoding of an object and save
			-- a reference to `a_encoding' in `last_encoding'.
		require
			encoding_exists: a_encoding /= Void
		deferred
		end

	loaded (a_pid: PID): TABULATION
			-- Retrieve the encoding of the object referenced by `a_pid'
		require
			is_stored: is_stored (a_pid)
		deferred
		end

	store_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Ensure Current knows about the type described by `a_descriptor'
		require
			not_known_type: not is_known_type (a_descriptor.type)
		deferred
		ensure
			is_known_type: is_known_type (a_descriptor.type)
		end

	update_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Update the corresponding {TYPE_DESCRIPTOR} in Current with the
			-- values in the `ancestor_types' and `descendant_types' table of
			-- `a_descriptor'.
			-- An ancestor and descendent might be added to a {TYPE_DESCRIPTOR}
			-- whenever a new descriptor is created.  (See `initialize_types'
			-- from {TYPE_DESCRIPTOR}.)  Other values should never change.
		require
			is_known_type: is_known_type (a_descriptor.type)
			same_names: stored_descriptor (a_descriptor.type).name ~ a_descriptor.name
				-- other_fields_same: ?
		deferred
		ensure
			was_updated: stored_descriptor (a_descriptor.type) ~ a_descriptor
		end

	identifiers_for_type (a_type: PERSISTENT_TYPE): LINKED_LIST [PID]
			-- A list of identifiers of all the objects in Current that
			-- or of the same type as `a_type'.
		require
			is_known_type: is_known_type (a_type)
		deferred
		end

	shut_down
			-- Ask the server to shut down; used for testing
		deferred
		end

	wipe_out
			-- Erase all data from the underlying store
			-- For testing
		deferred
		end

	show
			-- For testing
		deferred
		end

	commit
			-- Make changes to Current's state persistent
		require
			is_connected: is_connected
		deferred
		end

feature -- Query

	is_valid_credentials (a_credentials: like credentials): BOOLEAN
			-- Is `a_credentials' valid for connection to Current's
			-- underlying data store?
		deferred
		end

	is_stored (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been stored onto Current?
		require
			pid_exists: not a_pid.is_void
		deferred
		end

	is_stored_root (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been store onto Current
			-- and stored as a persistent root object?
		deferred
		end

	is_known_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current contain a `stored_descriptor' for `a_persistent_type'?
		deferred
		end

	is_attribute_type_declared (a_pid: PID): BOOLEAN
			-- Does Current contain a `stored_descriptor' for the object id
			-- refered to in `a_pid'?  If it does then there should be a
			-- declaration in that {TYPE_DESCRIPTOR} for that field.
		require
			represents_a_field: a_pid.is_attribute
		deferred
		end

	is_invariant_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_persistent_type' represent an invariant_type?
		deferred
		end

	value_conforms (a_value: ANY; a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_value' conform to `a_type'
		local
			a: ANY
			dt: INTEGER
		do
			dt := Mapped_types.item_by_persistent_type (a_type).dt
			a := (create {INTERNAL}).new_instance_of (dt)
			Result := a_value.conforms_to (a)
		end

	is_valid_uri (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_string' a valid URI?
		do
			Result := true
			io.put_string ("REPOSITORY.is_valid_uri:  Fix me! %N")
		end

	is_valid_creation_string (a_string: STRING): BOOLEAN
			-- Is `a_string' in the correct format for use in `make'?
			-- It should consist of a scheme name (i.e. ftp, http, etc.) followed
			-- by a colon; then two slashes followed by the hostname, colon, and
			-- port number.
			--    foo://host_name:port_number
			-- example:
			--     file://localhost:2222
		do
			io.put_string ("REPOSITORY.is_valid_creation_string:  fix me! %N")
			Result := true
		end

feature -- Status report

	is_connected: BOOLEAN
			-- Is Current able to communicate with the underlying physical store?
		deferred
		end

feature -- Status setting

	connect
			-- Ensure Current can communicate with the underlying
			-- physical store.
		deferred
		ensure
			is_connected: is_connected
		end

	disconnect
			-- Make Current unable to communicate with the underlying
			-- physical store
		deferred
		ensure
--			is_disconnected: not is_connected
		end

feature {NONE} -- Implementation

	set_last_pid (a_pid: PID)
			-- Set `last_pid' to `a_pid'
		do
			last_pid := a_pid
		end

invariant

--	name_exists: uri /= Void

end

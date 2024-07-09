note
	description: "[
		Interface to a repository that is reachable across a network
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	NETWORK_REPOSITORY

inherit

	REPOSITORY
		redefine
			make,
			credentials,
			store,
			recover_id
		end

	SOCKET_RESOURCES

	SED_STORABLE_FACILITIES
		rename
			store as sed_store
		end

create
	make

feature {NONE} -- Initialization

	make (a_credentials: like credentials)
			-- Create a repository to which a connection can be
			-- established using `a_credentials'.
		do
			create last_pid		-- appease Void-safety
--			client_make (a_credentials.port, a_credentials.hostname)
			Precursor (a_credentials)
--			client_make (a_credentials.port, a_credentials.hostname)
--				-- `in_out' is the NETWORK_STREAM_SOCKET from NETWORK_CLIENT.
--			max_to_poll := in_out.descriptor + 1
---				-- Create the command used to connect.
--			create connection.make (in_out)
--				-- Create the MEDIUM_POLLER, which will monitor events.
--			create poller.make_read_only
--				-- Make the poller look for CONNECTION commands.
--			poller.put_read_command (connection)
--			connect
		end

feature {NONE} -- Access

	next_oid: PID
			-- The next number in sequence.  Sets `last_oid' to that value and
			-- changes Current's state so that the next call to this feature
			-- returns a new value.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_id_message, Void)
			mes := ask_server (mes)
			check attached {PID} mes.data as r then
				Result := r
			end
		end

	is_oid_available: BOOLEAN
			-- Is Current able to provide a new object identifier if
			-- asked for one by `next_oid'?
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.is_oid_available_message, Void)
			mes := ask_server (mes)
			check attached {BOOLEAN} mes.data as r then
				Result := r
			end
		end

	data: TABULATION
			-- A representation of all the objects stored on Current.
			-- This can be used to view the repository for testing.
			-- A deep copy of the `cache'.`tabulation'.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_all_data_message, Void)
			mes := ask_server (mes)
			check attached {TABULATION} mes.data as r then
				Result := r
			end
		end

	recover_id (a_id: PID)
			-- Someone is giving `a_id' back to Current to use again.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.recover_oid_message, a_id)
			mes := ask_server (mes)
			check mes.message_type = {PMESSAGE}.recover_pid_acknowledge_message then
			end
		end

feature {NONE}

	ask_server (a_message: PMESSAGE): PMESSAGE
			-- Send `a_message' (i.e. a request) to the server and
			-- wait for the response
		local
			soc: detachable NETWORK_STREAM_SOCKET
			med: SED_MEDIUM_READER_WRITER
		do
			io.put_string (generating_type + ".ask_server:  about to send: %N")
			io.put_string (a_message.out + "%N")
			create soc.make_client_by_port (credentials.port, credentials.hostname)
			soc.connect
			create med.make (soc)
			med.set_for_writing
--			independent_store (a_message, med, true)
			sed_store (a_message, med)
				-- Must create a new MEDIUM or it does not work.
			create med.make_for_reading (soc)
			check attached {PMESSAGE} retrieved (med, true) as m then
				Result := m
				io.put_string (generating_type + ".ask_server:  response is %N")
				io.put_string (m.out)
			end
			soc.cleanup
		rescue
--			if attached soc as s and then attached med as m then
--					-- shut down server
--				create mes.make ({PMESSAGE}.shut_down_message, Void)
--				sed_store (mes, m)
--				s.cleanup
--			end
		end

	last_oid: PID
			-- The value that was returned by the previous call to `next_oid'
			-- or a {PID} whose `oid' is zero if `next' has not been called
			-- or if `recover' was called.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_last_id_message, Void)
			mes := ask_server (mes)
			check attached {PID} mes.data as r then
				Result := r
			end
		end

feature -- Access

	credentials: NETWORK_CREDENTIALS
			-- Information used to connect to the underlying data store.

--	hostname: STRING
--			-- The name of the host as in "localhost" or "191.177.1.100"

--	port: INTEGER
--			-- The port on which Current will communicate with the datastore

	shut_down
			-- Ask the server to shut down; used for testing
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.shut_down_message, void)
			mes := ask_server (mes)
			print ("NETWORK_SERVER.shut_down_server:  " + mes.out + "%N")
		end

	stored_descriptor (a_persistent_type: PERSISTENT_TYPE): TYPE_DESCRIPTOR
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_descriptor_message, a_persistent_type)
			mes := ask_server (mes)
			check attached {TYPE_DESCRIPTOR} mes.data as d then
				Result := d
			end
		end

	stored_type (a_pid: PID): PERSISTENT_TYPE
			-- The type of the object identified by `a_pid' as seen
			-- by the underlying store; if `a_pid' is an identifier for
			-- a field of a complex object, it is the type declared in
			-- the class (the actual object type could be any conforming
			-- type)
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_id_message, a_pid)
			mes := ask_server (mes)
			check attached {PERSISTENT_TYPE} mes.data as pt then
				Result := pt
			end
		end

	stored_time (a_pid: PID): YMDHMS_TIME
			-- The time that the object identified by `a_pid' was recorded
			-- into the underlying datastore.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_stored_time_message, a_pid)
			mes := ask_server (mes)
			check attached {YMDHMS_TIME} mes.data as pt then
				Result := pt
			end
		end

	known_types: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			-- A table containing all the object types known to Current.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_known_types_message, void)
			mes := ask_server (mes)
			check attached {HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]} mes.data as kt then
				Result := kt
			end
		end

--	declared_type (a_pid: PID): PERSISTENT_TYPE
--			-- The declared type of the attribute identified by `a_pid' as seen
--			-- seen by the underlying store (the actual object type could be
--			-- any conforming type).
--		local
--			mes: PMESSAGE
--		do
--			create mes.make ({PMESSAGE}.get_declared_type_message, a_pid)
--			mes := ask_server (mes)
--			check attached {PERSISTENT_TYPE} mes.data as pt then
--				Result := pt
--			end
--		end

--	typed_proxies (a_type: PERSISTENT_TYPE): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies whose represented objects are of a
--			-- type that conforms to `a_type'
--		do
--			create Result.make
--		end

--	typed_proxies_with_attributes (a_type: PERSISTENT_TYPE;
--					a_attribute_list: ARRAYED_LIST [STRING_8]): LINKED_LIST [JJ_PROXY]
--			-- A list of proxies containing the values of the listed attributes of the
--			-- represented objects as well as a handled to the persisted object.
--			-- This provides a way to load only a portion of an object, such as a
--			-- name, for display in a readable format without having to read in the
--			-- entire object.
--		do
--			create Result.make
--		end

feature -- Basic operations

	store (a_encoding: TABULATION)
			-- Store the encoding of an object
		local
			mes: PMESSAGE
			int: INTERNAL
		do
			create int
io.put_string (" *************** " + generating_type + ".store:  encoding size = ")
io.put_string (int.deep_physical_size_64 (a_encoding).out + "%N")
			create mes.make ({PMESSAGE}.persist_message, a_encoding)
io.put_string (" *************** " + generating_type + ".store:  message size = ")
io.put_string (int.deep_physical_size_64 (mes).out + "%N")
			mes := ask_server (mes)
			check mes.message_type = {PMESSAGE}.persist_acknowledge_message then
			end
		end

	loaded (a_pid: PID): TABULATION
			-- Retrieve the encoding of the object referenced by `a_pid'
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_object_message, a_pid)
			mes := ask_server (mes)
			check attached {TABULATION} mes.data as e then
				Result := e
			end
		end

	store_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Ensure Current knows about the type described by `a_descriptor'
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.store_descriptor_message, a_descriptor)
			mes := ask_server (mes)
			check mes.message_type = {PMESSAGE}.store_descriptor_acknowledge_message then
			end
		end

	update_descriptor (a_descriptor: TYPE_DESCRIPTOR)
			-- Update the corresponding {TYPE_DESCRIPTOR} in Current with the
			-- values in the `ancestor_types' and `descendant_types' table of
			-- `a_descriptor'.
			-- An ancestor and descendent might be added to a {TYPE_DESCRIPTOR}
			-- whenever a new descriptor is created.  (See `initialize_types'
			-- from {TYPE_DESCRIPTOR}.)  Other values should never change.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.update_descriptor_message, a_descriptor)
			mes := ask_server (mes)
			check mes.message_type = {PMESSAGE}.update_descriptor_acknowledge_message then
			end
		end

	identifiers_for_type (a_type: PERSISTENT_TYPE): LINKED_LIST [PID]
			-- Load a persistent identifies to all objects in Current that
			-- are the same type as `a_type'.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.get_identifiers_for_type_message, a_type)
			mes := ask_server (mes)
			check attached {LINKED_LIST [PID]} mes.data as e then
				Result := e
			end
		end

	wipe_out
			-- Erase all data from the underlying store
			-- For testing
		do
		end

	show
			-- For testing
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.show_repository_message, Void)
			mes := ask_server (mes)
		end

	commit
			-- Make changes to Current's state persistent
		do
		end

feature -- Query

	is_valid_credentials (a_credentials: like credentials): BOOLEAN
			-- Is `a_credentials' valid for connection to Current's
			-- underlying data store?
		do
			print (generating_type + ".is_valid_credentials:  Fix me! %N")
			Result := true
		end

	is_stored (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been stored onto Current?
		do
			print (generating_type + ".is_stored:  Fix me! %N")
		end

	is_stored_root (a_pid: PID): BOOLEAN
			-- Has an object identified by `a_pid' been store onto Current
			-- and stored as a persistent root object?
		do
			print (generating_type + ".is_stored_root:  Fix me! %N")
		end

	is_known_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current know about the type described by `a_persistent_type'?
			-- See {TYPE_MAPPING}.stringify for description of the expected
			-- for `a_persistent_type' format.
		do
			print (generating_type + ".is_known_type:  Fix me! %N")
		end

	is_attribute_type_declared (a_pid: PID): BOOLEAN
			-- Does Current contain a `stored_descriptor' for the object id
			-- refered to in `a_pid'?  If it does then there should be a
			-- declaration in that {TYPE_DESCRIPTOR} for that field.
		do
			print (generating_type + ".is_attribute_type_declared:  Fix me! %N")
		end

	is_invariant_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_persistent_type' represent an invariant_type?
		do
		end

feature -- Status report

	is_connected: BOOLEAN
			-- Is Current able to communicate with the underlying physical store?
		do
		end

feature -- Status setting

	connect
			-- Make Current able to communicate with the underlying physical store.
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.request_connection_message, Void)
			mes := ask_server (mes)
		end

	disconnect
			-- Make Current unable to communicate with the underlying physical store
		do
		end

feature {NONE} -- Implementation

--	socket: NETWORK_STREAM_SOCKET
--			-- The socket over which Current will send messages to the server

--	medium: SED_MEDIUM_READER_WRITER
--			-- The medium associated with the `socket'

end

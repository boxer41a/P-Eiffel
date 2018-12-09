note
	description: "[
		A {REPOSITORY} reachable across a network using the
		ZeroMQ Eiffel wrapper for the Zero-MQ library.
		Requires the wrapper library in the ecf and Zero-MQ
		must be installed on the platform.
		]"
	author: "Jimmy J. Johnson"

class
	ZMQ_REPOSITORY

inherit

	REPOSITORY
		redefine
			make,
			credentials,
			store,
			recover_id
		end

create
	make

feature {NONE} -- Initialization

	make (a_credentials: like credentials)
			-- Create a repository to which a connection can be
			-- established using `a_credentials'.
		do
			create last_pid		-- appease Void-safety
			Precursor (a_credentials)
			create context.make
			create poller.make (1)
			create changed_objects_imp.make (100)
			establish_sockets
		end

feature -- Constants

	Message_count: INTEGER = 3
			-- The number of messages to send; then quit.

	requester_address: STRING = "tcp://localhost:5555"
			-- The address on which the `requester' sends messages
			-- to a server and then listens for a response.

	listener_address: STRING = "tcp://localhost: 5556"
			-- The address on which the `listener' listens for
			-- general broadcast messages.

	subscriber_address: STRING = "tcp://localhost:5557"
			-- The address on which the `subscriber' listens for
			-- broadcast messages.

feature {NONE} -- Access

	next_pid: PID
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
			last_pid := Result
		end

	is_pid_available: BOOLEAN
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

	establish_sockets
			-- Set up the `requestor' and `subscriber' sockets.
			-- This feature gets the correct descendent type of {ZMQ_SOCKET}
			-- from the `context' using queries (e.g. `get_req_socket' and
			-- `get_sub_socket') from {ZMQ_CONTEXT}.
		do
				-- Get a socket that sends a request and expects a reply.
			requester := context.new_req_socket
				-- Servers `bind'; clients `connect'.
			requester.connect (requester_address)
				-- Get a socket that listens for change notifications.
			listener := context.new_sub_socket ("")
				-- Get a socket that listens for broadcast messages.
			subscriber := context.new_sub_socket ("")
			subscriber.bind (subscriber_address)
				-- Seems we must also `connect' for asyncronous protocols.
			listener.connect (listener_address)
			subscriber.connect (subscriber_address)
				-- Register actions with the polling socket
			poller.register (listener, agent get_notifications)
--			poller.register (subscriber, agent show_chat_message)
		end

	close_sockets
			-- Close any open sockets.
			-- (Is this really needed?)
		do
			requester.close
			subscriber.close
		end

	ask_server (a_message: PMESSAGE): PMESSAGE
			-- Send `a_message' (i.e. a request) to the server and
			-- wait for the response
		local
			zmq_m: ZMQ_MESSAGE
		do
			io.put_string (generating_type + ".ask_server: %N")
			io.put_string ("   sending message " + a_message.out + "%N")
				-- Serialize `a_message'.
			zmq_m := a_message.as_message
			requester.send_message (zmq_m)
				-- Wait for a response.
			requester.receive_message (zmq_m)
			create Result.from_message (zmq_m)
			io.put_string ("   received answer " + Result.out + "%N")
			io.put_string (generating_type + ".ask_server:  finished. %N")
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
			create mes.make ({PMESSAGE}.get_stored_type_message, a_pid)
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

	get_changed_objects: HASH_TABLE [BOOLEAN, PID]
			-- Table containing the identifiers of objects for which
			-- Current was notified of a change since the last call.
		do
			create Result.make (100)
			from
			until not poller.is_signaled (1)
			loop
				poller.execute
					-- This will call the action `get_notifications'
			end
			Result.merge (changed_objects_imp)
			changed_objects_imp.wipe_out
		end

	get_notifications
			-- Called by `poller' in the loop in `changed_objects'.
			-- This feature receives one message on the `listener' socket.
			-- The message should contain a list of {PID}s indicating
			-- which objects have been changed since the last call.
			-- This list is merged with the `changed_objects_table'.
			-- The `changed_objects_table' is emptied at the end of
			-- feature `changed_objects'.
		local
			zmq_m: ZMQ_MESSAGE
			p_mes: PMESSAGE
		do
			io.put_string (generating_type + ".get_notifications: %N")
			create zmq_m
			subscriber.receive_message (zmq_m)
			create p_mes.from_message (zmq_m)
io.put_string ("   received notification " + p_mes.out + "%N")
			check attached {HASH_TABLE [BOOLEAN, PID]} p_mes.data as t then
				changed_objects_imp.merge (t)
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
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.is_stored_message, a_pid)
			mes := ask_server (mes)
			check attached {BOOLEAN_REF} mes.data as b then
				Result := b
			end
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
		local
			mes: PMESSAGE
		do
			create mes.make ({PMESSAGE}.is_known_type_message, a_persistent_type)
			mes := ask_server (mes)
			check attached {BOOLEAN_REF} mes.data as b then
				Result := b
			end
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

	is_accepting_notifications: BOOLEAN
			-- Should Current receive a notification from the server whenever
			-- and object is changed by some other client?

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

	accept_notifications
			-- Inform the server that Current wishes to be notified on
			-- the `subscriber' whenever an object changes.
		local
			mes: PMESSAGE
		do
			is_accepting_notifications := true
			create mes.make ({PMESSAGE}.request_notifications_message, void)
			mes := ask_server (mes)
		end

	reject_notifications
			-- Inform the server that Current wishes to NOT be notified
			-- of object changes.
		local
			mes: PMESSAGE
		do
			is_accepting_notifications := false
			create mes.make ({PMESSAGE}.reject_notifications_message, void)
			mes := ask_server (mes)
		end

feature {NONE} -- Implementation

	context: ZMQ_CONTEXT
			-- Allows us to get one or more sockets, each various networking
			-- topologites or protocols, for communicating over a network.
			-- The underlying 0MQ object is "container for all sockets in a
			-- single process, and acts as the transport for inproc sockets,
			-- which are the fastest way to connect threads in one process."

	requester: ZMQ_SOCKET
			-- A socket on which to send a message and wait for a reply.

	listener: ZMQ_SOCKET
			-- A socket on which to listen for broadcasts from a server.

	subscriber: ZMQ_SOCKET
			-- A socket on which to listen for pushed messages from a server.
			-- This socket receives notifications containing lists of {PID}'s
			-- of objects that have been changed.  This socket is only checked
			-- if Current chooses to `subscribe_to_changed_notifications'

	poller: JJ_POLLER
			-- Used to listen on for object-changed messages, and perform
			-- the action associated with that socket.

	changed_objects_imp: HASH_TABLE [BOOLEAN, PID]
			-- Accumulator for `changed_objects'.

end

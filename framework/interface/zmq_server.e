note
	description: "[
		A server that communicates with a persistent system
		using the ZeroMQ Eiffel wrapper.
		]"
	author: "Jimmy J. Johnson"

class
	ZMQ_SERVER

inherit

	PERSISTENCE_FACILITIES
			-- because need it to show the `repository'; and all the
			-- once features from it are in the system anyway.

create
	make

feature {NONE} -- Initialization

	make
		local
			cred: CREDENTIALS
			r: MEMORY_REPOSITORY
		do
			print ("%N%N%N%N%N%N%N%N%N")
			create cred.make ("zmq_server.dat")
--			create repository.make (cred)
			create r.make (cred)
			Persistence_manager.set_repository (r)
			create context.make
			create poller.make (10)
			create clients.make (100)
--			show_version
			establish_sockets
			begin_polling
			close_sockets
		end

feature -- Constants

	Message_count: INTEGER = 10
			-- The number of messages to which to respond before exiting.
			-- (What happens to a client that wants to send a message, and
			-- the server is down?  Seems the sent message is dropped and
			-- the client waits indefinately.  Fix this.)

	responder_address: STRING = "tcp://*:5555"
			-- The address on which the `responder' listens for and
			-- answers clients.

	broadcaster_address: STRING = "tcp://*:5556"
			-- The address on which the `broadcaster' sends messages.

	notifier_address: STRING = "tcp://*:5557"
			-- The address on which the `notifiers' push notification
			-- messages to clients that subscribe.

feature -- Basic operations

	establish_sockets
			-- Set up the `requestor' and `subscriber' sockets.
			-- This feature gets the correct descendent type of {ZMQ_SOCKET}
			-- from the `context' using queries (e.g. `get_req_socket' and
			-- `get_sub_socket') from {ZMQ_CONTEXT}.
		do
			responder := context.new_rep_socket
				-- Servers `bind'; clients `connect'.
			responder.bind (responder_address)
			broadcaster := context.new_pub_socket
			broadcaster.bind (broadcaster_address)
				-- Set up the poller
			poller.register (responder, agent get_message)
		end

	close_sockets
			-- Close any open sockets.
			-- (Is this really needed?)
		do
			responder.close
			broadcaster.close
		end

	begin_polling
			-- Using a {JJ_POLLER} loop forever, listening for incoming
			-- messages on the `responder' socket.
		local
			i: INTEGER
		do
			io.put_string (generating_type + ".poll_for_chats: ")
			from i := 1
			until false	--i > message_count	-- or go forever?
			loop
				poller.execute
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	get_message
			-- React to a message on the `responder' socket by
			-- deserializing the message, passing it on to the
			-- `handle_message' feature if it was in the correct
			-- format, sending a response to the client, and if
			-- necessary, informing other clients of a change.
			-- Called by `poller' when there is a message on the
			-- `responder' socket.
		local
			zmq_m: ZMQ_MESSAGE
			quest, ans: PMESSAGE
			soc: ZMQ_SOCKET
		do
			io.put_string (generating_type + ".get_message: %N")
			create zmq_m
			responder.receive_message (zmq_m)
			create quest.from_message (zmq_m)
io.put_string ("   received message " + quest.out + "%N")
			if not clients.has (quest.sender) then
--				soc := context.new_pub_socket
--				soc.bind (Notifier_address)
--				soc.connect (Notifier_address)
				clients.force_client (quest.sender)
io.put_string ("   socket added to `clients';  client count = " + clients.count.out + "%N")
			end
			ans := handle_message (quest)
			answer_client (ans, ans.sender)
			io.put_string (generating_type + ".get_message:  ended %N")
			io.put_string ("--------------------------------------- %N%N%N")
		end

	answer_client (a_message: PMESSAGE; a_client: like {PMESSAGE}.sender)
			-- Send a reply to the client.
		local
			zmq_m: ZMQ_MESSAGE
		do
			io.put_string (generating_type + ".answer_client: %N")
			io.put_string ("  Sending message " + a_message.out + "%N")
			zmq_m := a_message.as_message
			responder.send_message (zmq_m)
		end

	handle_message (a_message: PMESSAGE): PMESSAGE
			-- Process `a_message' by querying the `repository' and
			-- and generate an answer message.
		require
			knows_about_client: clients.has (a_message.sender)
		local
			pid: PID
			b_ref: BOOLEAN_REF
		do
			inspect a_message.message_type
			when {PMESSAGE}.get_id_message then
				pid := repository.next_pid
				create Result.make (a_message.message_type, pid)
			when {PMESSAGE}.get_descriptor_message then
				check attached {PERSISTENT_TYPE} a_message.data as pt then
					create Result.make (a_message.message_type, repository.stored_descriptor (pt))
				end
--			when {PMESSAGE}.get_declared_type_message then
--				check attached {PID} a_message.data as id then
--					create Result.make (a_message.message_type, repository.declared_type (id))
--				end
			when {PMESSAGE}.get_known_types_message then
				create Result.make (a_message.message_type, repository.known_types)
			when {PMESSAGE}.get_stored_type_message then
				check attached {PID} a_message.data as id then
					create Result.make (a_message.message_type, repository.stored_type (id))
				end
			when {PMESSAGE}.get_identifiers_for_type_message then
					check attached {PERSISTENT_TYPE} a_message.data as d then
						create Result.make (a_message.get_identifiers_for_type_message, repository.identifiers_for_type (d))
					end
			when {PMESSAGE}.get_stored_time_message then
				check attached {PID} a_message.data as id then
					create Result.make (a_message.message_type, repository.stored_time (id))
				end
			when {PMESSAGE}.get_object_message then
				check attached {PID} a_message.data as id then
					check attached {TABULATION} repository.loaded (id) as t then
						io.put_string (generating_type + ".handle_message ")
						io.put_string (t.out + "%N")
						create Result.make (a_message.message_type, t)
					end
--					create Result.make (a_message.message_type, repository.loaded (id))
				end
			when {PMESSAGE}.get_last_id_message then
				create Result.make (a_message.message_type, repository.last_pid)
--			when {PMESSAGE}.get_all_data_message then
--				create Result.make (a_message.message_type, repository.all_data)
	----- persist related --------
			when {PMESSAGE}.persist_message then
				check attached {TABULATION} a_message.data as t then
					repository.store (t)
					create Result.make ({PMESSAGE}.persist_acknowledge_message, Void)
					notify_clients (t, a_message.sender)
				end
			when {PMESSAGE}.request_notifications_message then
				clients.enable_pushing (a_message.sender)
				create Result.make ({PMESSAGE}.yes_no_answer_message, true)
			when {PMESSAGE}.reject_notifications_message then
				clients.disable_pushing (a_message.sender)
				create Result.make ({PMESSAGE}.yes_no_answer_message, false)
	----------------------
			when {PMESSAGE}.show_repository_message then
				repository.show
				create Result.make ({PMESSAGE}.yes_no_answer_message, Void)
			when {PMESSAGE}.recover_oid_message then
				check attached {PID} a_message.data as id then
					repository.recover_id (id)
					create Result.make ({PMESSAGE}.recover_pid_acknowledge_message, Void)
				end
			when {PMESSAGE}.is_oid_available_message then
				create Result.make (a_message.message_type, repository.is_pid_available)
			when {PMESSAGE}.request_connection_message then
				create Result.make ({PMESSAGE}.server_acknowledge_connection_message, void)
			when {PMESSAGE}.shut_down_message then
				shut_down := true
				create Result.make ({PMESSAGE}.server_is_down_message, void)
			when {PMESSAGE}.is_known_type_message then
				check attached {PERSISTENT_TYPE} a_message.data as t then
					create b_ref
					b_ref.set_item (repository.is_known_type (t))
					create Result.make ({PMESSAGE}.yes_no_answer_message, b_ref)
				end
			when {PMESSAGE}.is_stored_message then
				check attached {PID} a_message.data as d then
					create b_ref
					b_ref.set_item (repository.is_stored (d))
					create Result.make ({PMESSAGE}.yes_no_answer_message, b_ref)
				end
			else
				create Result.make ({PMESSAGE}.server_unable_message, Void)
			end
		end

	notify_clients (a_tabulation: TABULATION; a_sender: UUID)
			-- Send a list of changed objects (i.e. their {PID}) to all
			-- the `clients' except `a_sender' that have requested to be
			-- notified.
		local
			uuid: UUID
			tup: TUPLE [is_push: BOOLEAN; pids: HASH_TABLE [BOOLEAN, PID]]
			p_mes: PMESSAGE
			zmq_m: ZMQ_MESSAGE
			tab: HASH_TABLE [BOOLEAN, PID]
		do
io.put_string (generating_type + ".notify_clients:  %N")
			create p_mes.make ({PMESSAGE}.pid_list_message, void)
			tab := a_tabulation.referenced_objects
			from clients.start
			until clients.after
			loop
				uuid := clients.key_for_iteration
				tup := clients.item_for_iteration
				if not (uuid ~ a_sender) then
						-- Determine which {PID}'s to send.
						-- FIX ME!!!  For now just send the hold thing.
					from tab.start
					until tab.after
					loop
						if not tup.pids.has (tab.key_for_iteration) then
							tup.pids.extend (true, tab.key_for_iteration)
						end
						tab.forth
					end
					if tup.is_push then
						p_mes.set_data (tup.pids)
						zmq_m := p_mes.as_message
--						tup.sock.bind (Notifier_address)
--						tup.sock.send_message (zmq_m)
						tup.pids.wipe_out
					end
				end
				clients.forth
			end
		end

feature {NONE} -- Implementation

	shut_down: BOOLEAN
			-- Should the server be stopped?
			-- Set in `handle_request' upon receiving a shut-down request from a client
			-- Used for testing & developement

feature {NONE} -- Implementation (persistence related)

--	repository: MEMORY_REPOSITORY
			-- Used to store data on a file system locally.
-- Commented out, because need to use `repository' from {PERSISTENCE_FACILITIES}.

	data_filename: STRING = "server_file.dat"
			-- Name of the file in which to store persistent information

	context: ZMQ_CONTEXT
			-- Allows us to get one or more sockets, each various networking
			-- topologites or protocols, for communicating over a network.
			-- The underlying 0MQ object is "container for all sockets in a
			-- single process, and acts as the transport for inproc sockets,
			-- which are the fastest way to connect threads in one process."

	responder: ZMQ_SOCKET
			-- A socket on which to listen for client request messages and
			-- on which to reaply to those messages.

	broadcaster: ZMQ_SOCKET
			-- A socket on which to broadcast messages to all clients
			-- listening to this socket.

	poller: JJ_POLLER
			-- Used to listen on zero or more sockets for incoming messages,
			-- and perform any actions associated with that socket.

	clients: CLIENTS_TABLE
			-- Keeps track of connected clients for heart-beating, etc.
			-- Set to true if client wishes to receive notifications when
			-- some other client changes an object.

end

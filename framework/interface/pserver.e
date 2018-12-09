note
	description : "[
		Server for a persistent system.
		This keeps track of the clients that have connected and polls for
		messages from those clients.  Feature `execute' from {NETWORK_SERVER}
		is a never-ending loop that calls `receive', `process_message', 
		`respond', and `close'.  These features are redefined or effected
		in this class in order to respond to requests from a system that
		uses the persistence cluster.
		
		Feature `execute' is called in `start_server'.
		
		A {PSERVER} talks to its own {LOCAL_REPOSITORY}, but is not, itself
		a {REPOSIToRY}.
		]"
	author: "Jimmy J. Johnson"
	date        : "$Date$"
	revision    : "$Revision$"

class
	PSERVER

inherit

--	NETWORK_SERVER
--		rename
--			make as server_make
--		redefine
--			receive, received, close
--		end

--	STORABLE

	SOCKET_RESOURCES

	SED_STORABLE_FACILITIES

--	PERSISTENCE_FACILITIES

create
	make

feature {NONE} -- Initialization

	make (argv: ARRAY [STRING])
			-- Run application
		local
			cred: CREDENTIALS
			n: STRING_8	-- hostname
			p: INTEGER	-- port
			mes: PMESSAGE
--			cons: detachable like connections
			soc1: NETWORK_STREAM_SOCKET
			i: INTEGER
		do
			print ("%N%N%N%N%N%N%N%N%N")
			create cred.make ("pserver.dat")
			create repository.make (cred)
				-- Read the command-line arguments
			if argv.count < 3 then
				io.put_string ("Usage:  hostname  portnumber %N")
			end
			if argv.count = 2 then
				n := argv.item (1)
				p := 2222
			elseif argv.count = 3 then
				n := argv.item (1)
				p := argv.item (2).to_integer
			else
				n := "localhost"
				p := 2221
			end
			io.put_string (" hostname = '" + n + "' %N")
			io.put_string (" port = " + p.out + "%N")
				-- Begin listening on a socket
			create soc1.make_server_by_port (p)
			soc1.listen (5)
				-- Process three messages then stop
			from i := 1
			until i > 6
			loop
				process (soc1)
				i := i + 1
			end
		rescue
			io.error.put_string ("IN RESCUE %N")
--			if attached cons as c then
--				create mes.make ({PMESSAGE}.server_is_down_message, Void)
--				from cons.start
--				until cons.after
--				loop
--					mes.independent_store (cons.item.active_medium)
--					cons.forth
--				end
--			end
		end

feature -- Basic operations

	process (a_socket: NETWORK_STREAM_SOCKET)
			-- Recieve a message and answer it.
		local
			med: SED_MEDIUM_READER_WRITER
			ans: PMESSAGE
				-- temp for testing
			fac: SED_STORABLE_FACILITIES
			f: RAW_FILE
			sed: SED_MEDIUM_READER_WRITER
			mes: PMESSAGE
			t: TABULATION
		do
			a_socket.accept
			if attached {NETWORK_STREAM_SOCKET} a_socket.accepted as s then
				create med.make (s)
				med.set_for_reading
				if attached {PMESSAGE} retrieved (med, true) as m then
					io.put_string (generating_type + ".process: Server message: %N")
					io.put_string (m.out + "%N")
					ans := handle_request (m)
					med.set_for_writing
					independent_store (ans, med, true)
				else
					io.put_string (generating_type + ".process:  Failed to retrieve message.")
					io.new_line
				end
				s.close
			end
		end

	handle_request (a_message: PMESSAGE): PMESSAGE
			-- Process `a_message' by querying the `repository' and
			-- and generate an answer message
		local
			pid: PID
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
			when {PMESSAGE}.get_stored_time_message then
				check attached {PID} a_message.data as id then
					create Result.make (a_message.message_type, repository.stored_time (id))
				end
			when {PMESSAGE}.get_object_message then
				check attached {PID} a_message.data as id then
					create Result.make (a_message.message_type, repository.loaded (id))
				end
			when {PMESSAGE}.get_last_id_message then
				create Result.make (a_message.message_type, repository.last_pid)
--			when {PMESSAGE}.get_all_data_message then
--				create Result.make (a_message.message_type, repository.all_data)
			when {PMESSAGE}.persist_message then
				check attached {TABULATION} a_message.data as t then
					repository.store (t)
					create Result.make ({PMESSAGE}.persist_acknowledge_message, Void)
				end
			when {PMESSAGE}.show_repository_message then
				repository.show
				Result := a_message
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
			else
				create Result.make ({PMESSAGE}.server_unable_message, Void)
			end
		end

feature {NONE} -- Implementation

	shut_down: BOOLEAN
			-- Should the server be stopped?
			-- Set in `handle_request' upon receiving a shut-down request from a client
			-- Used for testing & developement

--	connections: LINKED_LIST [CONNECTION]
			-- List of clients (really commands associated with a medium)
			-- that are connected to Current.

--	max_to_poll: INTEGER_32
			-- The "descriptor" of the last connection passed to `execute'
			-- from class MEDIUM_POLLER.

--	received: detachable PMESSAGE
			-- The last message, if any, recieved.

--	answer: PMESSAGE
			-- The answer this server sends back to the client.

feature {NONE} -- Implementation (persistence related)

	repository: MEMORY_REPOSITORY
			-- Used to store data on a file system locally.

	data_filename: STRING = "server_file.dat"
			-- Name of the file in which to store persistent information


end

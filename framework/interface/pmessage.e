note
	description: "[
		Passed between client and server for use in persistence cluster

	]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PMESSAGE

inherit

	ANY
		redefine
			out
		end

create
	make,
	from_message

feature {NONE} -- Initialization

	make (a_type: INTEGER; a_data: detachable ANY)
			-- Create a message in which `a_type' tells the reciever the
			-- intention of the message and `a_data' is the information
			-- passed between the client and server
		do
			message_type := a_type
			data := a_data
			sender := (create {PERSISTENCE_FACILITIES}).session_id
			message_number := message_number_imp.item + 1
			message_number_imp.set_item (message_number)
		end

	from_message (a_message: like as_message)
			-- Set up Current based on values in `a_message'.
		require
			is_valid_message: is_message_valid (a_message)
		local
			mp: MANAGED_POINTER
			rw: SED_MEMORY_READER_WRITER
			fac: SED_STORABLE_FACILITIES
			s: STRING_8
			obj: detachable ANY
		do
--			io.put_string (generating_type + ".from_message: %N")
				-- Deserialize the message.
			create mp.make_from_pointer (a_message.data, a_message.size.as_integer_32)
			create rw.make_with_buffer (mp)
			create fac
			rw.set_for_reading
			obj := fac.retrieved (rw, true)
			if attached fac.retrieved_errors as es then
				across es as e loop
					io.put_string (e.item.message.as_string_8 + "%N")
				end
			end
			check attached {PMESSAGE} obj as m then
				message_type := m.message_type
				data := m.data
				sender := m.sender
				message_number := m.message_number
			end
		end

feature -- Access

-- rename class as DATA_WRAPPER or something?

	message_number: INTEGER
			-- Used for debugging.

	message_number_imp: INTEGER_REF
			-- A counter for debugging.
		once
			create Result
		end

	sender: like {PERSISTENCE_FACILITIES}.session_id
			-- The client sending the message

	message_type: INTEGER
			-- Set to one of the constants below

	data: detachable ANY
			-- The information passed in the message

	as_message: ZMQ_MESSAGE
			-- Current wrapped in a {ZMQ_MESSAGE}.
		local
			s: STRING_8
		do
--			io.put_string (generating_type + ".as_message: %N")
				-- Get `stringified' version, which includes the `checksum'.
			create Result.with_string (stringified)
--				-- For testing, see if can deserialize the message
--			create mp.make_from_pointer (zmq_m.data, zmq_m.size.as_integer_32)
--			create rw.make_with_buffer (mp)
--			rw.set_for_reading
--			check attached {PMESSAGE} fac.retrieved (rw, true) as m then
--				io.put_string ("   For testing, the message is: " + m.out + "%N")
--				if attached m.data as d then
--					io.put_string ("   data.generating_type = " + d.generating_type + "%N")
--				end
--			end
		end

feature -- Element change

	set_type (a_type: INTEGER)
			-- Change the `message_type'.
		do
			message_type := a_type
		end

	set_data (a_data: detachable any)
			-- Change the `data'.
		do
			data := a_data
		end

feature -- Querry

	is_message_valid (a_message: like as_message): BOOLEAN
			-- Does `a_message' (in transmittable form) represent a {PMESSAGE}?
		local
			mp: MANAGED_POINTER
			rw: SED_MEMORY_READER_WRITER
			fac: SED_STORABLE_FACILITIES
			s: STRING_8
			obj: detachable ANY
		do
--			io.put_string (generating_type + ".is_valid_message: %N")
				-- Deserialize the message.
			create mp.make_from_pointer (a_message.data, a_message.size.as_integer_32)
			create rw.make_with_buffer (mp)
			create fac
			rw.set_for_reading
			obj := fac.retrieved (rw, true)
			Result := not attached fac.retrieved_errors and then
						attached {PMESSAGE} obj
		end

feature -- Status setting

--	intialize
--			-- Change status to `is_waiting'
--		do
--			is_waiting := true
--		end

--	execute
--			-- Change status to not `is_waiting'
--		do
--			is_waiting := false
--		end

feature -- Constants (for messages)

	get_id_message: INTEGER = 1
			-- Used to request a new object id from a {REPOSITORY}

	get_descriptor_message: INTEGER = 21
			-- To request the {CLASS_DESCRIPTOR} given a {PID}

	get_declared_type_message: INTEGER = 3
			-- To request the declared type given a {PID}
			-- This is the type as declared in a class

	get_stored_type_message: INTEGER = 4
			-- To request the actual type given a {PID}
			-- This is the type of the object attached to the entity

	get_known_types_message: INTEGER = 22
			-- To request a list of all types known to the repository.

	get_stored_time_message: INTEGER = 5
			-- To request the time an object identified by a {PID} was persisted

	get_object_message: INTEGER = 6
			-- Sent to server to request an object given a {PID}.

	get_identifiers_for_type_message: INTEGER = 77
			-- Sent to server to request a list of identifiers (i.e. PIDs)
			-- of objects that refer to an object of a given a {PERSISTENT_TYPE}.

	get_last_id_message: INTEGER = 7
			-- Sent by client to ask server for the `last_oid'.

	get_all_data_message: INTEGER = 8
			-- Used to ask for and recieve a representation of all
			-- the data stored on the repository.

	persist_message: INTEGER = 9
			-- To request the server to store an encoding

	persist_acknowledge_message: INTEGER = 10
			-- Sent by server to inform client that an encoding was persisted

	show_repository_message: INTEGER = 11
			-- Ask the repository to display its data

	is_oid_available_message: INTEGER = 12
			-- Ask the repository if it can produce a new oid.

	recover_oid_message: INTEGER = 13
			-- To send an unused object id back to the repository

	recover_pid_acknowledge_message: INTEGER = 14
			-- Sent by server to acknoledge that a oid was recovered

	store_descriptor_message: INTEGER = 81
			-- Ask the repository to store a {TYPE_DESCRIPTOR}.

	store_descriptor_acknowledge_message: INTEGER = 82
			-- Sent by server to acknowledge that a type was stored.

	update_descriptor_message: INTEGER = 83
			-- Ask the repository to update a {TYPE_DESCRIPTOR}.

	update_descriptor_acknowledge_message: INTEGER = 84
			-- Sent by server to acknowledge that a type was updated.

	request_connection_message: INTEGER = 95
			-- Indicates that this is the first connection to the server.

	server_acknowledge_connection_message: INTEGER = 96
			-- Sent by server to acknowledge a connection request.

	request_notifications_message: INTEGER = 201
			-- Sent by client to ask server to send notification
			-- whenever an object changes.

	reject_notifications_message: INTEGER = 202
			-- Sent by client to ask server to NOT sent object
			-- change notifications.

	pid_list_message: INTEGER = 203
			-- Contains in `data' a list of {PID}.

	shut_down_message: INTEGER = 97
			-- Sent by client to shut down the server; for development/testing

	server_unable_message: INTEGER = 98
			-- Sent by server if unable to understand message.

	server_is_down_message: INTEGER = 99
			-- Sent by server when it goes down

	is_known_type_message: INTEGER = 101
			-- Sent by client to ask if a type is stored in the repository?

	is_stored_message: INTEGER = 102
			-- Sent by client to ask if a {PID} is stored.

	yes_no_answer_message: INTEGER = 9000
			-- Sent by server to answer a true false query.

feature -- Basic operations

	out: STRING_8
			-- Printable representation of Current for testing
		local
			int: INTERNAL
		do
			Result := "PMESSAGE number " + message_number.out + "  from " + sender.out + "  "
			inspect message_type
			when server_unable_message then
				Result.append ("Server_unable_message")
			when get_id_message then
				Result.append ("Get_id_message")
			when get_descriptor_message then
				Result.append ("Get_descriptor_message")
			when get_declared_type_message then
				Result.append ("Get_declared_type_message")
			when get_stored_type_message then
				Result.append ("Get_stored_type_message")
			when get_known_types_message then
				Result.append ("Get_known_types_message")
			when get_stored_time_message then
				Result.append ("Get_stored_time_message")
			when get_object_message then
				Result.append ("Get_object_message")
			when get_identifiers_for_type_message then
				Result.append ("Get_identifiers_for_type")
			when get_last_id_message then
				Result.append ("Get_last_id_message")
			when get_all_data_message then
				Result.append ("Get_all_data_message")
			when persist_message then
				Result.append ("Persist_message")
			when persist_acknowledge_message then
				Result.append ("Persist_acknowledge_message")
			when show_repository_message then
				Result.append ("Show_repository_message")
			when is_oid_available_message then
				Result.append ("Is_pid_available_message_message")
			when recover_oid_message then
				Result.append ("Recover_pid_message")
			when recover_pid_acknowledge_message then
				Result.append ("Recover_pid_acknowledge_message")
			when store_descriptor_message then
				Result.append ("Store_descriptor_message")
			when store_descriptor_acknowledge_message then
				Result.append ("Store_descriptor_acknowledge_message")
			when update_descriptor_message then
				Result.append ("Update_descriptor_message")
			when update_descriptor_acknowledge_message then
				Result.append ("Update_descriptor_acknowledge_message")
			when request_connection_message then
				Result.append ("Request_connection_message")
			when server_acknowledge_connection_message then
				Result.append ("Server_acknowledge_connection_message")
			when shut_down_message then
				Result.append ("Request for server shut down")
			when server_is_down_message then
				Result.append ("The server is going down")
			when Is_known_type_message then
				Result.append ("Is_known_type_message")
			when Is_stored_message then
				Result.append ("is_stored_message")
			when Yes_no_answer_message then
				Result.append ("Yes_or_no_answer_message")
			when request_notifications_message then
				Result.append ("Request_notifcations_message")
			else
				check
					should_not_happend: false
						-- because above inspect covers all types?
				end
			end
			Result.append ("   ")
			create int
--			Result.append ("size = " + int.deep_physical_size_64 (Current).out + " bytes    ")
			if attached data as d then
				Result.append (d.generating_type + "    ")
				Result.append ("data size = " + int.deep_physical_size_64 (d).out + " bytes %N")
--				Result.append (d.out)
			else
				Result.append ("Void")
			end
		end

feature {NONE} -- Implementation

	stringified: STRING_8
			-- Current as a sequence of bytes (i.e. a string).
			-- For preperation to put into a {ZMQ_MESSAGE}.
		local
			rw: SED_MEMORY_READER_WRITER
			fac: SED_STORABLE_FACILITIES
		do
--			io.put_string (generating_type + ".stringified: %N")
				-- Serialize `a_message'.
			create rw.make
			create fac
			fac.store (Current, rw)
				-- Create a {ZMQ_MESSAGE} from the serialized {PMESSAGE}.
				-- Manu in message "Using ZMQ_MESSAGE" on 22 Sep 2016 suggested
				-- converting the serialized data to a string and using that.
			create Result.make (rw.count)
			Result.from_c_substring (rw.buffer.item, 1, rw.count)
--			io.put_string ("   " + "count = " + Result.count.out + " +   Result = " + Result + "%N")
		end

end

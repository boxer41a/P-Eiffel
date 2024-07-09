note
	description: "[
		Holder for a reference (i.e. a {PID}) to a persistent object that
		facilitates lazy loading of objects from the persistent store.
		A {PROXY} .
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	JJ_PROXY

inherit

	PERSISTENCE_FACILITIES
		redefine
			out
		end

create
	make,
	make_with_identifying_field

feature {NONE} -- Initialization

	make (a_pid: PID)
			-- Create a handle to the object referenced by `a_pid'; do not
			-- load the actual object or any of its attributes
		require
			not_attribute: not a_pid.is_attribute
			id_pid_stored: repository.is_stored (a_pid)
		do
			pid := a_pid
			type := repository.stored_type (a_pid)
			time := repository.stored_time (a_pid)
		end

	make_with_identifying_field (a_pid: PID; a_fieldname: STRING_8)
			-- Create a handle to the object referenced by `a_pid', using
			-- the field called `a_fieldname' as a user-recognizable identifier.
			-- Load the value of this field and display it in `out', instead
			-- of the default, which is the `pid'.
		require
			not_attribute: not a_pid.is_attribute
			id_pid_stored: repository.is_stored (a_pid)
			has_field: type_descriptor_from_pid (a_pid).has_field_named (a_fieldname)
--			has_named_field: a_list.for_all (agent
--					(repository.class_descriptor (a_pid)).has_field_named)
		do
			make (a_pid)
			identifying_fieldname_imp := a_fieldname
			refresh
		end

feature -- Access

	pid: PID
			-- The persistent identifier to an object in a {REPOSITORY}.

	user_id: STRING_8
			-- A user-recognizable identifier for the object referenced
			-- by the `pid'.
		do
			if attached id_imp as s then
				Result := s
			else
				Result := out
			end
		end

	type: PERSISTENT_TYPE
			-- The type of the object identified by `pid'.

	time: YMDHMS_TIME
			-- The time the object identified by `pid' was stored.

	object: ANY
			-- The object referenced by the `pid'
		require
--			is_connected: repository.is_connected
		do
			Result := Persistence_manager.loaded (pid)
		end

	attribute_by_name (a_name: STRING_8): detachable ANY
			-- The value of `a_name'-th attribute of the proxied object
		require
			is_proxied_field: has_attribute_named (a_name)
		do
--			Result := attribute_table.item (a_name)
		end

	out: STRING
			-- String represetation of Current
		local
			td: TYPE_DESCRIPTOR
		do
			td := type_descriptor_from_persistent_type (type)
			Result := pid.out + "  " + td.name + "  " + time.as_string
		end

feature -- Element change

	set_id_fieldname (a_fieldname: STRING_8)
			-- Load the field of the object identified by `pid' and begin
			-- using it as the `user_id'.
		require

		do

		end

feature -- Query

	has_attribute_named (a_name: STRING_8): BOOLEAN
			-- Does Current hold the value of the attribute of the proxied object
			-- where the attribute is called `a_name'
		do
--			Result := attribute_table.has (a_name)
		end

feature -- Basic operation

	refresh
			-- Update stored information about the object (e.g. `time' and
			-- `user_id') from the repository.
		local
			td: TYPE_DESCRIPTOR
			id: PID
			i: INTEGER
		do
			time := repository.stored_time (pid)
			if attached identifying_fieldname_imp as fn then
				td := type_descriptor_from_persistent_type (type)
				i := td.name_th_field (fn).index
				if attached identifying_fieldname_imp then
					create id.make_as_attribute (i, pid)
					id_imp := Persistence_manager.loaded (id).out
				end
			end
		end

feature {NONE} -- Implementation

	id_imp: detachable STRING_8
			-- Local storage for the `user_id'.

	identifying_fieldname_imp: detachable STRING_8
			-- The name of the field from which to obtain a user-recognizable
			-- identifier for the object represented by `pid'.

end

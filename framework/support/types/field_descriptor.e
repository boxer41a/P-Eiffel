note
	description: "[
		Describes a field belonging to some class.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	FIELD_DESCRIPTOR

inherit

	CONSTRUCT_DESCRIPTOR
		rename
			make as construct_descriptor_make
		redefine
			as_string
		end

create
	make

feature {NONE} -- Initialization

	make (a_name: like name; a_type_name: STRING_8; a_attachment_flag: BOOLEAN;
				a_index: INTEGER; in_spec: BOOLEAN)
			-- Create an instance representing an attribute called `a_name', of
			-- `a_type_name', that is attribute number `a_index' of some class.
			-- Argument `in_spec' indicates if Current describes a field of some
			-- SPECIAL object.
		require
			is_known_type: (create {REFLECTOR}).dynamic_type_from_string (a_type_name) >= 0
			not_marked: a_name.at (1) /= '!'
		do
			create type
			construct_descriptor_make (a_name)
			type_name := a_type_name
			is_attached := a_attachment_flag
			is_field_of_special := in_spec
			index := a_index
		end

feature -- Access

	type_name: STRING_8
			-- The type as a string

	index: INTEGER
			-- The index of current as an attribute in some class

	is_attached: BOOLEAN
			-- Is the field required to be attached (i.e. not Void)?

	type: PERSISTENT_TYPE
			-- The persistent type of Current

	is_field_of_special: BOOLEAN
			-- Does Current represent a field of a SPECIAL object?

	as_type_descriptor: TYPE_DESCRIPTOR
			-- Create a descriptor for this field
		local
			r: REFLECTOR
			dt: INTEGER
		do
			create r
			dt := r.dynamic_type_from_string (type_name)
			Result := type_descriptor_from_dynamic_type (dt)
		end

feature -- Element change

	set_persistent_type (a_type: PERSISTENT_TYPE)
			-- Set `type' to a_type
		require
			type_exists: a_type /= Void
		do
			type := a_type
		ensure
			type_assigned: type ~ a_type
		end

feature -- Output

	as_string: STRING_8
			-- A readable for representing Current
		do
			Result := ""
			Result.append (name + ":")
			if is_attached then
				Result.append ("attached ")
			end
			Result.append (type_name + ":" + index.out)
		end

invariant

	is_special_implication: is_field_of_special implies index = 1

end

note
	description: "[
		Root class for descriptors of Eiffel constructs (e.g. classes, attributes,
		invaraints, etc) used by a persistent system.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CONSTRUCT_DESCRIPTOR

inherit

	COMPARABLE

	HASHABLE
		undefine
			copy,
			is_equal
		end

	PERSISTENCE_FACILITIES
		undefine
			is_equal
		end

feature {NONE} -- Initialization

	make (a_name: like name)
			-- Create an instance, associating `a_name' (a class name).
		require
--			is_valid_identifier (a_name)
--			is_valid_name: is_valid_type_string (a_name)
--			valid_name_type_pair: is_valid_name_type_pair (a_name, a_type)
		do
			name := a_name
		end

feature -- Access

	name: STRING_8
			-- The generating type as specified in OOSC2 (e.g. COMPARABLE,
			-- HASH_TABLE [FOO, BAR], ...) and in class TYPE from the elks
			-- kernel.

	hash_code: INTEGER
			-- Hash code based on `as_string'
		do
			Result := as_string.hash_code
		end

feature -- Output

	as_string: STRING_8
			-- A readable for representing Current
		do
			Result := ""
			Result.append (name)
		end

feature -- Comparison

	is_less alias "<" (other: like Current): BOOLEAN
			-- Is current object less than `other'?
		do
			Result := as_string < other.as_string
		end

invariant

	name_exists: name /= Void

end

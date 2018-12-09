note
	description: "[
		Contains functions for interpretting a persistence identifier.
		In PEiffel, each object has (in its header) a `persistence_id'
		(i.e. a NATURAL_64), obtainable through `persistence_id' from 
		{PERSISTENCE_FACILITIES}.  This class prvides features that
		interpret the persistence identifier.  A portion of the 64-bits
		represents a persistable reference to an object, and another
		portion can represent an attribute of an identified object.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PID_PARSER

feature -- Constants

	Maximum_value: NATURAL_64 = 9_223_372_034_707_292_159
			-- 0x7FFFFFFF7FFFFFFF

	Maximum_object_count: NATURAL_64 = 2_147_483_647	-- {INTEGER_32}.max_value
			-- The number of objects that can be identified

	Maximum_attribute_index: INTEGER_32 = 2_147_483_647	-- {INTEGER_32}.max_value
			-- The maximum number of attributes allowed for any object

feature -- Access

	as_object_identifier (a_pid: NATURAL_64): NATURAL_64
			-- The part of `a_pid' that represents a reference to an object.
		do
			Result := a_pid.bit_and (0x00000000FFFFFFFF)
		end

	object_identifier (a_pid: NATURAL_64): INTEGER_32
			-- A new PID created from Current where the attribute_identifier
			-- portion has been stripped off (i.e. just the low order bits.)
		do
			Result := (a_pid.bit_and (0x00000000FFFFFFFF)).as_integer_32
		end

	attribute_identifier (a_pid: NATURAL_64): INTEGER_32
			-- The part of `a_pid' that represents the attribute reference.
		do
			Result := (a_pid.bit_shift_right (32)).as_integer_32
		end

feature -- Basic operations

	make_pid_as_attribute (a_index: INTEGER_32; a_pid: NATURAL_64): NATURAL_64
			-- Create a PID to represent a reference to the `a_index'-th
			-- attribute of the object identified by `a_pid'.
		require
			not_void_pid: a_pid > 0
			not_is_attribute_reference: a_pid <= Maximum_object_count
			index_big_enough: a_index >= 1
--			index_small_enough: a_index <= (create {OBJECT_ENCODING}.make (a_pid)).field_count
		do
			Result := a_pid.bit_and (0x00000000FFFFFFFF) +
						a_index.as_natural_64.bit_shift_left (32)
		end

feature -- Status report

	is_attribute_id (a_pid: NATURAL_64): BOOLEAN
			-- Does `a_pid' represent a reference from an attribute of some object?
		do
			Result := attribute_identifier (a_pid) > 0
		end

	is_void_id (a_pid: NATURAL_64): BOOLEAN
			-- Does `a_pid' represent a void reference?
		do
			Result := a_pid = 0
		end

feature -- Output

	as_string (a_pid: NATURAL_64): STRING_8
			-- The string representation of `a_pid'
		do
			Result := "PID: " + object_identifier (a_pid).out + "/" + attribute_identifier (a_pid).out
		end

end

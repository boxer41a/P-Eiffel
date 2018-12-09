note
	description: "[
		A persistent identifier which is the long-lived equivalent of a
		reference to an object.  The identifier is associated with one and
		only one object.

		The `oid' (i.e. the object identifier) portion is obtained from the
		current `repository' (see {PERSISTENCE_FACILITIES} on which the
		associated object is to be persisted.

		The `oid' and `aid' use type INTEGER_32 instead of a more "countable'
		type, because all the containers in base (e.g. HASH_TABLE) used an
		INTEGER_32 for attributes such as the `count'.  While this might
		limit the number of objects/attributes allowed in a system, it makes
		this class play better with other parts of Eiffel.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PID

inherit

	HASHABLE
		redefine
			default_create,
			out
		end

	PERSISTENCE_FACILITIES
		redefine
			default_create,
			out
		end

create
	default_create,
	make_as_attribute,
	make_from_value
--	set

feature {NONE} -- Initialization

	default_create
			-- Initialize as `is_void'
		do
			item := 0
		ensure then
			is_void: is_void
		end

	make_as_attribute (a_index: INTEGER_32; a_pid: PID)
			-- Initialize Current to represent the `a_index'-th reference
			-- (the representation of the pointer, not the attribute value) of
			-- the object referred to by `a_pid'.
		require
			not_void_pid: not a_pid.is_void
			not_is_attrbute_reference: not a_pid.is_attribute
			index_big_enough: a_index >= 1
--			index_small_enough: a_index <= (create {OBJECT_ENCODING}.make (a_pid)).field_count
		do
			item := a_pid.object_identifier.bit_and (0x00000000FFFFFFFF).as_natural_64 +
						a_index.as_natural_64.bit_shift_left (32)
		ensure
			object_identifier_assigned: as_object_identifier ~ a_pid
			attribute_identifier_assigned: attribute_identifier = a_index
			is_attribute_reference: is_attribute
		end

	make_from_value (a_value: NATURAL_64)
			-- Create an instance from `a_value'
		require
			value_big_enough: a_value >= 0
			value_small_enough: a_value <= Maximum_item
		do
			item := a_value
		ensure
			item_assigned: item = a_value
		end

feature -- Constants

	Maximum_item: NATURAL_64 = 9_223_372_034_707_292_159
			-- 0x7FFFFFFF7FFFFFFF

	Maximum_object_count: INTEGER_32 = 2_147_483_647	-- {INTEGER_32}.max_value
	Maximum_attribute_index: INTEGER_32 = 2_147_483_647	-- {INTEGER_32}.max_value

feature -- Access

	item: NATURAL_64
			-- The real value of Current which can be stored in an object's header.

	as_object_identifier: PID
			-- A new PID created from Current where the attribute_identifier
			-- portion has been stripped off (i.e. just the low order bits.)
		do
			create Result.make_from_value (item.bit_and (0x00000000FFFFFFFF))
		end

	object_identifier: INTEGER_32
			-- The part of Current that represents a reference to an object.
		do
			Result := (item.bit_and (0x00000000FFFFFFFF)).as_integer_32
		end

	attribute_identifier: INTEGER_32
			-- The part of Current that represents the attribute reference.
		do
			Result := (item.bit_shift_right (32)).as_integer_32
		end

	hash_code: INTEGER
			-- The hash-code of Current.
		do
			Result := item.hash_code
		end

	out: STRING
			-- Output Current in readable format
		do
			Result := "PID: " + object_identifier.out + "/" + attribute_identifier.out
		end

feature -- Status report

	is_void: BOOLEAN
			-- Is Current the persistent representation of a Void reference?
		do
			Result := item = 0
		end

	is_attribute: BOOLEAN
			-- Does Current represent an attribute (i.e. a reference) instead
			-- of an identifier of an object?
		do
			Result := attribute_identifier > 0
		ensure
			references_some_object: Result implies not is_void
		end

invariant

	attribute_identifier_big_enough: attribute_identifier >= 0
	is_attribute_implies_object_id: attribute_identifier >= 1 implies object_identifier >= 1
	object_id_implies_repository_id: object_identifier >= 1 implies not is_void
	is_void_implication: is_void implies item = 0

end


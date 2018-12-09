note
	description: "[
		Used by {TABULATION} to hold the attributes of all objects of the
		type	 defined by the descriptor.
		Each item `is_basic_type', `is_special_basic_type', or is a PID  indexed 
		an `is_attribute_pid' PID.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"


class
	ATTRIBUTE_TABLE

inherit

	PERSISTENCE_FACILITIES
--		undefine
--			copy,
--			is_equal
--		end

--	HASH_TABLE [ANY, PID]
--		rename
--			make as table_make,
--			force as table_force
--		redefine
--			empty_duplicate
--		end

create
	make


feature {NONE} -- Initialization

	make (a_descriptor: TYPE_DESCRIPTOR)
			-- Create a table to hold objects of of a type described
			-- by `a_descriptor'.
		do
			descriptor := a_descriptor
--			table_make (a_descriptor.field_count)
			create table.make (a_descriptor.field_count)
		end

feature -- Access

	descriptor: TYPE_DESCRIPTOR
			-- Describes the flattened form of the `persistent_type'.

	type: PERSISTENT_TYPE
			-- The type as calculated from the `descriptor'
		do
			Result := descriptor.type
		end

	value (a_pid: PID): ANY
			-- The value at `a_index'.
		require
			is_attribute_id: a_pid.is_attribute
		do
			check attached table.item (a_pid) as v then
				Result := v
			end
		ensure
			valid_for_basic: is_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type) implies
							persistent_type (Result) ~ descriptor.i_th_field (a_pid.attribute_identifier).type
			valid_for_reference: not is_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type) implies
							persistent_type (Result) ~ persistent_pid_type
		end

	item (a_pid: PID): detachable ANY
			-- The item associated with `a_pid'
		do
			Result := table.item (a_pid)
		end

	item_for_iteration: ANY
			-- The element at the current iteration position
		require
			not_off: not after
		do
			Result := table.item_for_iteration
		end

	key_for_iteration: PID
			-- The key at the current iteration position
		require
			not_off: not after
		do
			Result := table.key_for_iteration
		end

feature -- Element change

	force (a_object: ANY; a_pid: PID)
			-- Used to insert into the table.
			-- The preconditions ensure `a_index' is valid for the type of the objects
			-- stored in Current and ensure that only basic types, special-basic types
			-- or a PID is stored.
		require
			is_attribute_reference: a_pid.is_attribute
			index_big_enough: a_pid.attribute_identifier >= 1
			index_small_enough: a_pid.attribute_identifier <= descriptor.field_count or else
								descriptor.is_special
--			store_only_basic_type: is_basic_object (a_object) or is_special_basic_object (a_object)
			valid_basic_type: (is_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type) or
								is_special_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type )) implies
							  persistent_type (a_object) ~ descriptor.i_th_field (a_pid.attribute_identifier).type
			pid_for_reference_type: (not is_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type) and
									not is_special_basic_type (descriptor.i_th_field (a_pid.attribute_identifier).type)) implies
								persistent_type (a_object) ~ persistent_pid_type
		do
--			table_force (a_object, a_pid)
			table.force (a_object, a_pid)
		end

feature -- Query

	has (a_pid: PID): BOOLEAN
			-- Is there an item in the table indexed by `a_pid'?
		do
			Result := table.has (a_pid)
		end

feature -- Cursor movement

	start
			-- Move iteration cursor to first item
		do
			table.start
		end

	forth
			-- Move iteration cursor to next item or `after'
		require
			not_after: not after
		do
			table.forth
		end

	after: BOOLEAN
			-- Is the iteration cursor off the end?
		do
			Result := table.after
		end

--feature {NONE} -- Duplication

--	empty_duplicate (n: INTEGER): like Current
--			-- Create an empty copy of Current but now ignore `n'.
--			-- Redefined to set `descriptor' to appease void-safety.
--		do
--			create Result.make (descriptor)
--			if object_comparison then
--				Result.compare_objects
--			end
--		end

feature {NONE} -- Invariant checking

	has_non_attribute_key: BOOLEAN
			-- Does Current contain a key that does not represent
			-- a reference to an attribute?
		local
			c: like table.cursor
		do
			c := table.cursor
			from table.start
			until table.after or Result
			loop
				Result := table.key_for_iteration.is_attribute
				table.forth
			end
			table.go_to (c)
		end

	table: HASH_TABLE [ANY, PID]
			-- To store the data.

invariant


end

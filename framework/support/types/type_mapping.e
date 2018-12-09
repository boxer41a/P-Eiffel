note
	description: "[
		Used by a persistent system as a three-way map between a dynamic type,
		a persistent type, and the {TYPE_DESCRIPTOR} of a class.  Each `item'
		(i.e. TUPLE) stored in Current also tracks, whether or not that type is
		known to the current repository.
		Implemented as three parallel hash tables, providing look-ups by any 
		of the three items in the tuple.  (See the return type of `item'.)
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	TYPE_MAPPING

inherit

	HASH_TABLE [TUPLE [dt: INTEGER; pt: PERSISTENT_TYPE; td: TYPE_DESCRIPTOR; is_per: BOOLEAN], INTEGER]
		rename
			item as table_item,
			extend as table_extend
		redefine
			make,
			wipe_out,
			accommodate,
			put
		end

create
	make

feature {NONE} -- Initialization

	make (a_capacity: INTEGER_32)
			-- Initialize Current with an initial `a_capacity'
		do
			Precursor (a_capacity)
			create persistent_type_to_tuple_table.make (a_capacity)
			create descriptor_to_tuple_table.make (a_capacity)
		end

feature -- Access

	item (a_dynamic_type: INTEGER):
					TUPLE [dt: INTEGER; pt: PERSISTENT_TYPE; td: TYPE_DESCRIPTOR; is_per: BOOLEAN]
			-- Same as the inherited version (`item' renamed as `table_item')
			-- but checked for attachment.  The `is_per' flag tracks wheather
			-- or not this type is known to the repository.
		require
			has_dynamic_type: has (a_dynamic_type)
		local
			r: REFLECTOR
			s: STRING
			dt: INTEGER
		do
			create r
			s := r.type_name_of_type (a_dynamic_type)
			if s.at (1) = '!' then
				s.remove (1)
				dt := r.dynamic_type_from_string (s)
				check
					is_known_dynamic_type: dt >= 0
						-- Because, ... ?
				end
			else
				dt := a_dynamic_type
			end
			check attached table_item (dt) as t then
				Result := t
			end
		end

	item_by_dynamic_type (a_dynamic_type: INTEGER): like item
			-- The type descriptor tuple indexed by `a_dynamic_type'
		require
			has_dynamic_type: has_dynamic_type (a_dynamic_type)
		do
			Result := item (a_dynamic_type)
		ensure
			result_exists: Result /= Void
		end

	item_by_persistent_type (a_persistent_type: PERSISTENT_TYPE): like item_by_dynamic_type
			-- The type descriptor tuple index by `a_persistent_type'
		require
			type_exists: a_persistent_type /= Void
			has_persistent_type: has_persistent_type (a_persistent_type)
		do
			check attached {like item_by_dynamic_type} persistent_type_to_tuple_table.item (a_persistent_type) as t then
				Result := t
			end
		ensure
			result_exists: Result /= Void
		end

	item_by_descriptor (a_descriptor: TYPE_DESCRIPTOR): like item_by_dynamic_type
			-- The type descriptor tuple index by `a_descriptor'
		require
			descriptor_exists: a_descriptor /= Void
			has_descriptor: has_descriptor (a_descriptor)
		do
			check attached {like item_by_dynamic_type} descriptor_to_tuple_table.item (a_descriptor) as t then
				Result := t
			end
		ensure
			result_exists: Result /= Void
		end

feature -- Query

	has_dynamic_type (a_dynamic_type: INTEGER): BOOLEAN
			-- Does Current contain a mapping for `a_dynamic_type'?
		do
--			Result := dynamic_type_to_tuple_table.has_key (a_dynamic_type)
			Result := has (a_dynamic_type)
		end

	has_persistent_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current contain a mapping for `a_persistent_type'?
		do
			Result := persistent_type_to_tuple_table.has_key (a_persistent_type)
		end

	has_descriptor (a_descriptor: TYPE_DESCRIPTOR): BOOLEAN
			-- Does Current contain a mapping for `a_string'?
		do
			Result := descriptor_to_tuple_table.has_key (a_descriptor)
		end

feature -- Basic operations

	wipe_out
			-- Remove all entries
			-- Useful for testing only
		do
			Precursor
--			dynamic_type_to_tuple_table.wipe_out
			persistent_type_to_tuple_table.wipe_out
			descriptor_to_tuple_table.wipe_out
		end

	add_type (a_dynamic_type: INTEGER)
			-- Add a mapping for `a_dynamic_type'.
			-- Also ensure that the `dual_type' is mapped.
		require
			not_mapped: not has_dynamic_type (a_dynamic_type)
			not_attachment_marked: (create {INTERNAL}).type_name_of_type (a_dynamic_type).at (1) /= '!'
		local
			td: TYPE_DESCRIPTOR
			r: REFLECTOR
			s: STRING
			dt: INTEGER
			i: INTEGER
			fd: FIELD_DESCRIPTOR
		do
				-- Remove any attachment mark.
			create r
			s := r.type_name_of_type (a_dynamic_type)
			if s.at (1) = '!' then
				s.remove (1)
				dt := r.dynamic_type_from_string (s)
				check
					is_known_dynamic_type: dt >= 0
						-- Because, ... ?
				end
			else
				dt := a_dynamic_type
			end
				-- Create the {TYPE_DESCRIPTOR}, mapping the types.
			create td.make (dt)
			extend ([dt, td.type, td, false])
				-- Create a {TYPE_DESCRIPTOR} for each field of `td'.
			from i := 1
			until i > td.field_count
			loop
				fd := td.i_th_field (i)
				s := fd.type_name
				dt := r.dynamic_type_from_string (s)
				check
					is_known_dynamic_type: dt >= 0
						-- Because, ... ?
				end
				if not has_dynamic_type (dt) then
					add_type (dt)
				end
				fd.set_persistent_type (item_by_dynamic_type (dt).pt)
				i := i + 1
			end
			td.find_relations
		ensure
			has_type: has_dynamic_type (a_dynamic_type)
		end

	extend (a_tuple: like item_by_dynamic_type)
			-- Add the `a_tuple' to Current, recording if this type
			-- `is_persistent' or not.
		require
			tuple_exists: a_tuple /= Void
			persistent_type_exists: a_tuple.pt /= Void
			descriptor_exists: a_tuple.td /= Void
			not_has_dynamic_type: not has_dynamic_type(a_tuple.dt)
			not_has_persistent_type: not has_persistent_type (a_tuple.pt)
			not_has_descriptor: not has_descriptor (a_tuple.td)
		do
			table_extend (a_tuple, a_tuple.dt)
			persistent_type_to_tuple_table.extend (a_tuple, a_tuple.pt)
			descriptor_to_tuple_table.extend (a_tuple, a_tuple.td)
		ensure
			has_dynamic_type: has_dynamic_type (a_tuple.dt)
			has_persistent_type: has_persistent_type (a_tuple.pt)
			has_descriptor: has_descriptor (a_tuple.td)
		end

	put (new: like item_by_dynamic_type; key: INTEGER_32)
			-- Insert `new' with `key' if there is no other item
			-- associated with the same key.
			-- Set inserted if and only if an insertion has
			-- been made (i.e. `key' was not present).
			-- If so, set position to the insertion position.
			-- If not, set conflict.
			-- In either case, set found_item to the item
			-- now associated with `key' (previous item if
			-- there was one, `new' otherwise).
			--
			-- To choose between various insert/replace procedures,
			-- see `instructions' in the Indexing clause.
			-- (from HASH_TABLE)
		do
			persistent_type_to_tuple_table.put (new, new.pt)
			descriptor_to_tuple_table.put (new, new.td)
			Precursor (new, key)
		end

feature {NONE} -- Contract support

	has_same_keys: BOOLEAN
			-- Used by invariant to ensure the three hash tables stay parallel
		local
			item_by_dt: like item_by_dynamic_type
			item_by_pt: like item_by_dynamic_type
			item_by_dex: like item_by_dynamic_type
			c: CURSOR
			ptc: CURSOR
			dtc: CURSOR
		do
			c := cursor
			ptc := persistent_type_to_tuple_table.cursor
			dtc := descriptor_to_tuple_table.cursor
			Result := true
			Result := persistent_type_to_tuple_table.count = count and
						descriptor_to_tuple_table.count = count
			if Result then
				from
					start
					persistent_type_to_tuple_table.start
					descriptor_to_tuple_table.start
				until not Result or after
				loop
							-- NO!  This is wrong, because the tables may
							-- not store the items in the same order even
							-- though they contain the same items.
					item_by_dt := item_for_iteration
					item_by_pt := persistent_type_to_tuple_table.item_for_iteration
					item_by_dex := descriptor_to_tuple_table.item_for_iteration
					Result := item_by_dt = item_by_pt and item_by_pt = item_by_dex
					forth
					persistent_type_to_tuple_table.forth
					descriptor_to_tuple_table.forth
				end
			end
			go_to (c)
			persistent_type_to_tuple_table.go_to (ptc)
			descriptor_to_tuple_table.go_to (dtc)
		end

	has_attached_type: BOOLEAN
			-- Does Current contain any dynamic type that represents a
			-- type with an attachment mark (i.e. a "!") on its name?
			-- It should not.
		local
			r: REFLECTOR
			c: CURSOR
		do
			c := cursor
			create r
			from start
			until after or Result
			loop
				Result := r.type_name_of_type (key_for_iteration).at (1) = '!'
				forth
			end
			go_to (c)
		end

feature {NONE} -- Implementation

	accommodate (n: INTEGER_32)
			-- Reallocate table with enough space for `n' items;
			-- keep all current items.
			-- Redefined to keep tables same size.
		do
			persistent_type_to_tuple_table.accommodate (n)
			descriptor_to_tuple_table.accommodate (n)
			Precursor (n)
		end

	persistent_type_to_tuple_table: HASH_TABLE [like item_by_dynamic_type, PERSISTENT_TYPE]
			-- Table mapping a persistent_type to a TUPLE

	descriptor_to_tuple_table: HASH_TABLE [like item_by_dynamic_type, TYPE_DESCRIPTOR]
			-- Table mapping a {TYPE_DESCRIPTOR} (a description of a class) to a TUPLE

invariant

	same_counts: persistent_type_to_tuple_table.count = count and
					descriptor_to_tuple_table.count = count
--	same_keys: has_same_keys

	has_no_attached_marks: not has_attached_type

end


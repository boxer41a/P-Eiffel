note
	description: "[
		Information about each type (not class) in a persistent system, created
		from an object.  This gives a "flattened" form where all attributes
		have there final names as if there is no inheritance.  The declared
		type of an attribute is recorded; not the actual type of an object.

		Feature `initialize' produces and maps {PERSISTENT_TYPE}, which is an
		SHA_1 digest created from the `as_string' representation of Current.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	TYPE_DESCRIPTOR

inherit

	CONSTRUCT_DESCRIPTOR
		rename
			make as construct_make
		redefine
			as_string
		end

create
	make

feature {NONE} -- Initialization

	make (a_dynamic_type: INTEGER)
			-- Create an instance
		require
			not_attachment_marked: Internal.type_name_of_type (a_dynamic_type).at (1) /= '!'
			not_already_recorded: not is_recorded_dynamic_type (a_dynamic_type)
		do
--			Precursor {CONSTRUCT_DESCRIPTOR} (a_name)
			construct_make ("To be determined in `initialize'")
			create fields_by_index.make (Default_field_count)
			create fields_by_name.make (Default_field_count)
			create ancestor_types.make (Default_field_count)
			create descendant_types.make (Default_field_count)
--			create dependencies.make (Default_field_count)
--			create invariants.make
			initialize (a_dynamic_type)
--			if ancestor_types.is_empty then
--				initialize_types
--			end
			show
		end

	initialize (a_dynamic_type: INTEGER)
			-- Fill in the descriptor based on `a_dynamic_type'. In order to prevent
			-- cycles, Current add itself to the `Mapped_types' table.
		require
--			is_valid_type_id: is_valid_type_id (a_dynamic_type)
		local
--			internal: INTERNAL
			cnt: INTEGER
			i: INTEGER
			fst: INTEGER			-- field's static type
			ft_name: STRING_8	-- field's type name (e.g. "BOOLEAN", etc.)
			fn: STRING_8			-- field's name (i.e. the name of the attribute)
			f_at: BOOLEAN		-- Is the field declared as attached?
			f_dex: FIELD_DESCRIPTOR
			tab: HASH_TABLE [INTEGER, FIELD_DESCRIPTOR]
			exp: ARRAYED_SET [INTEGER]		-- explored types
			pt: PERSISTENT_TYPE
			enc: PERSISTENT_TYPE_GENERATOR
		do
--			create internal
			create enc
			if is_recorded_dynamic_type (a_dynamic_type) then
				copy (type_descriptor_from_dynamic_type (a_dynamic_type))
			elseif a_dynamic_type = {INTERNAL}.None_type then
				name := "NONE"
				enc.set_with_string (as_string)
				pt := enc.digest
				Mapped_types.extend ([a_dynamic_type, pt, Current, false])
			else
				create tab.make (100)
				create exp.make (100)
					-- We visited the top-level class (now)
				exp.extend (a_dynamic_type)
					-- Build the top-level representation of the class,
					-- ignoring any attachment mark
				name := Internal.type_name_of_type (a_dynamic_type)
					-- Build the fields
				cnt := Internal.field_count_of_type (a_dynamic_type)
				if Internal.is_special_type (a_dynamic_type) then
					if not Internal.is_special_any_type (a_dynamic_type) then
						is_special_basic := true
						is_special_reference := false
						is_tuple := false
					else
						is_special_basic := false
						is_special_reference := true
						is_tuple := false
					end
				elseif Internal.is_tuple_type (a_dynamic_type) then
					is_special_basic := false
					is_special_reference := false
					is_tuple := true
				else
					-- all false
				end
				if is_special then
					fn := "special"
					fst := a_dynamic_type
					create f_dex.make (fn, name, false, 1, false)
					extend_field (f_dex)
					tab.extend (fst, f_dex)
				else
					from i := 1
					until i > cnt
					loop
						fn := Internal.field_name_of_type (i, a_dynamic_type)
						fst := Internal.field_static_type_of_type (i, a_dynamic_type)
						ft_name := Internal.type_name_of_type (fst)
						if ft_name.at (1) = '!' then
							f_at := true
							ft_name.remove (1)
							fst := (create {REFLECTOR}).dynamic_type_from_string (ft_name)
						else
							f_at := false
						end
						create f_dex.make (fn, ft_name, f_at, i, false)
						extend_field (f_dex)
						tab.extend (fst, f_dex)
						i := i + 1
					end
				end
--					-- At this point we have the class name, number of attributes, and
--					-- the name, attribute number, and a string representation of the
--					-- type of each attribute; from this `as_string' we can produce
--					-- a {PERSISTENT_TYPE} and add it to the `Type_mapping' table.
--					-- We cannot build the `ancestors' and `descendants' at this time,
--					-- because there is no way to determine all the possible types
--					-- that the system might create, and only types for which some
--					-- object exists is known (i.e. by its dynamic type) to the system.
--					-- Therefore, the {PERSISTENT_TYPE} does not account for `ancestors'
--					-- or `descendants'.
--				enc.set_with_string (as_string)
--				pt := enc.digest
--				Mapped_types.extend ([a_dynamic_type, pt, Current, false])
--					-- Now assign a persisent type to each of the fields (whose
--					-- static types were captured above.
--				from tab.start
--				until tab.after
--				loop
--					fst := tab.item_for_iteration
--					f_dex := tab.key_for_iteration
--					if not is_recorded_dynamic_type (fst) then
--						Mapped_types.add_type (fst)
--					end
--					pt := persistent_type_from_dynamic_type (fst)
--					f_dex.set_persistent_type (pt)
--					tab.forth
--				end
			end
		end

feature -- Access

	type: PERSISTENT_TYPE
			-- The type (as an SHA-1 message digest) created from the
			-- string representation of Current.
		local
			enc: PERSISTENT_TYPE_GENERATOR
		do
			create enc
			enc.set_with_string (as_string)
			Result := enc.digest
		end

	i_th_field (a_index: INTEGER_32): FIELD_DESCRIPTOR
			-- The `a_index'-th {FIELD_DESCRIPTOR} of Current.
			-- Since a SPECIAL can have a field at any positive index,
			-- just return the FIELD_DESCRIPTOR at index 1.
		require
			valid_field_index: has_field_at_index (a_index)
		do
			if is_special then
				check attached fields_by_index.item (1) as f then
					Result := f
				end
			else
				check attached fields_by_index.item (a_index) as f then
					Result := f
				end
			end
		end

	name_th_field (a_name: STRING_8): FIELD_DESCRIPTOR
			-- The {FIELD_DESCRIPTOR} representing the field with `a_name'
		require
			valid_field_name: has_field_named (a_name)
		do
			check attached fields_by_name.item (a_name) as f then
				Result := f
			end
		end

	field_count: INTEGER_32
			-- Number of fields in this class' description
		do
			Result := fields_by_index.count
		end

feature -- Status report

	is_types_initialized: BOOLEAN
			-- Have the `ancestor_types' and `descendent_types' of
			-- Current been calculated?
		do
			Result := not ancestor_types.is_empty
				-- Because, all types are descended from ANY.
		end

	is_reference: BOOLEAN
			-- Does Current represent a normal reference?
		do
			Result := not is_tuple and not is_special
		ensure
			Result implies (not is_tuple and not is_special)
		end

	is_tuple: BOOLEAN
			-- Does Current represent a TUPLE type?

	is_special: BOOLEAN
			-- Does Current represent a SPECIAL [XX] where XX is a reference or basic type.
		do
			Result := is_special_reference or is_special_basic
		end

	is_special_reference: BOOLEAN
			-- Does Current represent a SPECIAL [XX] where XX is a reference type?

	is_special_basic: BOOLEAN
			-- Does Current represent a SPECIAL [XX] type where XX is a basic type?

feature -- Element change

	extend_field (a_descriptor: FIELD_DESCRIPTOR)
			-- Add `a_descriptor' to Current, indexable by its `name' or `index'
		require
			descriptor_exists: a_descriptor /= Void
			not_has_key: not has_field_at_index (a_descriptor.index) or else
							(is_special and a_descriptor.index = 1)
		do
			fields_by_index.extend (a_descriptor, a_descriptor.index)
			fields_by_name.extend (a_descriptor, a_descriptor.name)
		end

	find_relations
			-- Compute all the types of the ancestors to the class that
			-- is represented by Current.
		require
--			not_types_initialized: not is_types_initialized
			is_mapped: is_recorded_type (Current.type)
		local
			tup: TUPLE [dt: INTEGER; pt: PERSISTENT_TYPE; td: TYPE_DESCRIPTOR]
			dt, mapped_dt: INTEGER
			mapped_pt: PERSISTENT_TYPE
			mapped_td: TYPE_DESCRIPTOR
			is_td_changed, is_mapped_td_changed: BOOLEAN
			r: REFLECTOR
		do
			create r
				-- Check Current's `type' against all the `mapped_types' and all
				-- the `mapped_types' against Current's `type'.
			dt := mapped_types.item_by_persistent_type (type).dt
--	io.put_string (generating_type + ".find_relations:  checking types %N")
--	io.put_string ("      " + mapped_types.count.out + " items in Mapped_types %N")
			from mapped_types.start
			until mapped_types.after
			loop
--	io.put_string ("  checking conformance between " + r.type_name_of_type (dt) + "  and  ")
--	io.put_string (r.type_name_of_type (mapped_dt) + "  ")
				tup := mapped_types.item_for_iteration
				mapped_dt := tup.dt
				mapped_pt := tup.pt
				mapped_td := tup.td
				if {ISE_RUNTIME}.type_conforms_to (dt, mapped_dt) then
--	io.put_string ("     " + r.type_name_of_type (dt) + "  conforms to  ")
--	io.put_string (r.type_name_of_type (mapped_dt) + "%N")
					ancestor_types.force (true, mapped_pt)
					if not mapped_td.descendant_types.has (type) then
						mapped_td.descendant_types.force (true, type)
						is_mapped_td_changed := true
					end
					is_td_changed := true
				elseif {ISE_RUNTIME}.type_conforms_to (mapped_dt, dt) then
--	io.put_string ("     " + r.type_name_of_type (mapped_dt) + "%T conforms to  ")
--	io.put_string (r.type_name_of_type (dt) + "%N")
					if not mapped_td.ancestor_types.has (type) then
						mapped_td.ancestor_types.force (true, type)
						is_mapped_td_changed := true
					end
					descendant_types.extend (true, mapped_pt)
					is_td_changed := true
				else
					is_mapped_td_changed := false
--	io.put_string ("      No conformance")
				end
--	io.put_string ("%N")
					-- Current might have to talk to the `repository' to determine
					-- if a changed type must be updated to update it.
				if is_mapped_td_changed and then repository.is_known_type (mapped_td.type) then
					repository.update_descriptor (mapped_td)
				end
				mapped_types.forth
			end
			if is_td_changed and repository.is_known_type (type) then
				repository.update_descriptor (Current)
			end
		ensure
--			has_ancestors: not ancestor_types.is_empty
		end


--	record_dependency (a_descriptor: TYPE_DESCRIPTOR)
--			-- Include `a_descriptor' as a class on which the described class depends
--		require
--			descriptor_exists: a_descriptor /= Void
--			not_already_recorded: not depends_on (a_descriptor)
--		do
--			dependencies.extend (a_descriptor, a_descriptor.name)
--		ensure
--			depends_on: depends_on (a_descriptor)
--		end

feature -- Query

	has_field_named (a_name: STRING_8): BOOLEAN
			-- Can `a_index' be used to retrieve a field from Current?
		do
			Result := fields_by_name.has_key (a_name)
		end

	has_field_at_index (a_index: INTEGER_32): BOOLEAN
			-- Does Current contain a field at `a_index'th position?
			-- For a SPECIAL, it could have a field at any positive incex.
		require
			index_big_enough: a_index >= 1
		do
			Result := fields_by_index.has_key (a_index) or else is_special
		end

--	depends_on (a_descriptor: TYPE_DESCRIPTOR): BOOLEAN
--			-- Does Current represent a class that depends on another
--			-- class that is represented by `a_descriptor'
--		require
--			descriptor_exists: a_descriptor /= Void
--		do
--			Result := dependencies.has_key (a_descriptor.name)
--		end

feature -- Output

	as_string: STRING
			-- Information in Current in a readable form; does not include
			-- the `type' as that can be produced from the Result.
		local
			cnt: INTEGER
			temp: TWO_WAY_SORTED_SET [FIELD_DESCRIPTOR]
		do
			Result := "<<"
			Result.append ("{")
			Result.append (name)
			Result.append ("} ")
			cnt := field_count
			Result.append (cnt.out)
			Result.append (" fields [")
				-- Sort the fields alphabetically
			create temp.make
--			temp.set_ordered
			from fields_by_index.start
			until fields_by_index.after
			loop
				temp.extend (fields_by_index.item_for_iteration)
				fields_by_index.forth
			end
				-- Use the sorted list to print results
			from temp.start
			until temp.after
			loop
				Result.append (temp.item.as_string)
				if not temp.islast then
					Result.append (", ")
				end
				temp.forth
			end
			Result.append ("] ")
--			Result.append ("Invariants:")

			Result.append (">>")
		end

	show
			-- Display Current by printing `as_string' followed by Current's
			-- `ancestor_types' and `descendent_types'.
			-- This feature mostly for testing.
		local
			pt: PERSISTENT_TYPE
		do
			io.put_string (generating_type + ".show  %N")
			io.put_string (as_string)
			io.put_string ("  " + name)
			io.put_string ("  ancestors [")
			from ancestor_types.start
			until ancestor_types.after
			loop
				pt := ancestor_types.key_for_iteration
--				io.put_string (pt.as_hex_string)
				io.put_string (Mapped_types.item_by_persistent_type (pt).td.name)
				ancestor_types.forth
				if not ancestor_types.after then
					io.put_string (", ")
				end
			end
			io.put_string ("] ")
			io.put_string (" descendants [")
			from descendant_types.start
			until descendant_types.after
			loop
				pt := descendant_types.key_for_iteration
--				io.put_string (pt.as_hex_string)
				io.put_string (Mapped_types.item_by_persistent_type (pt).td.name)
				descendant_types.forth
				if not descendant_types.after then
					io.put_string (", ")
				end
			end
			io.put_string ("] %N")
		end

feature {TYPE_DESCRIPTOR, TABULATION, REPOSITORY} -- Implementation

	ancestor_types: HASH_TABLE [BOOLEAN, PERSISTENT_TYPE]
			-- A "list" containing the types of all the ancestors of the class
			-- represented by Current.  Implemented as HASH_TABLE in order to
			-- give O(1) lookups.

	descendant_types: HASH_TABLE [BOOLEAN, PERSISTENT_TYPE]
			-- A "list" containing the types of all the descendants of the class
			-- represented by Current.  Implemented as HASH_TABLE in order to
			-- give O(1) lookups.


feature {NONE} -- Implementation

--	dependencies: HASH_TABLE [TYPE_DESCRIPTOR, STRING_8]
			-- Descriptions of classes on which the described class recursively depends
			-- (excluding the described class to prevent cycles)

	fields_by_index: HASH_TABLE [FIELD_DESCRIPTOR, INTEGER_32]
			-- The descriptors for each field (i.e. attribute) of the mapped type
			-- based on the index of the field within the class

	fields_by_name: HASH_TABLE [FIELD_DESCRIPTOR, STRING_8]
			-- The descriptors for each field (i.e. attribute) of the mapped type
			-- indexed based on the name of the field

	invariants: LINKED_LIST [INVARIANT_DESCRIPTOR]
			-- List of invariants mined from the class
		do
			create Result.make
			io.put_string ("CLASS_DESCRIPTOR.invariants:  not implemented yet.  Fix me! %N")
		end

	Default_field_count: INTEGER = 10
			-- The initial number of fields assumed to be in the represented class

invariant

	same_counts: fields_by_index.count = fields_by_name.count
	special_implication: is_special implies field_count = 1

end

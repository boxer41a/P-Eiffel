note
	description: "[
		Simple data structure that can be easily serialized.  It encapsulates
		only the flattened repesentation of an object structure that is to be
		passed to/from a {REPOSITORY}.

		A {TABULATION} can be built up by calling `tabulate', which adds info
		about the objects that are currently marked as dirty in this session.

		A {TABULATION} can also be built up incrementally, but there is an
		implied order in which the features should be called.
		1.  `add_desciptor' - adds a {TYPE_DESCRIPTOR} for a {PERSISTENT_TYPE}
		2. 	`log_object' - informs Current that a object is included
		3.  `set_attribute_value' - repeat for each attribute of an object
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	TABULATION

inherit

	PERSISTENCE_FACILITIES
		redefine
			default_create,
			out
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create an instance that is empty
		do
			create descriptor_table.make (Table_size)
			create root_table.make (Table_size)
			create expanded_table.make (Table_size)
			create objects_table.make (Table_size)
			create index_table.make (Table_size)
			create count_capacity_table.make (Table_size)
			create time.set_now_utc_fine
			session := Session_id
		end

feature -- Access

--	last_error: INTEGER_32
			-- Temporary attribute to catch loading errors.
			-- Fix me to use a once feature and error classes?

	No_errors: INTEGER_32 = 0
	Unrecognized_type: INTEGER_32 = 1
	Class_version_mismatch: INTEGER = 32


	session: like {PERSISTENCE_MANAGER}.Session_id
			-- Identifier for the program that created this encoding

	time: YMDHMS_TIME
			-- The time at which this encoding started

	descriptor (a_type: PERSISTENT_TYPE): TYPE_DESCRIPTOR
			-- The {TYPE_DESCRIPTOR} associated with `a_type'.
		require
			has_descriptor: has_descriptor (a_type)
		do
			check attached descriptor_table.item (a_type) as des then
				Result := des
			end
		end

	logged_type (a_pid: PID): PERSISTENT_TYPE
			-- The {PERSISTENT_TYPE} associated with `a_pid'
		require
			is_logged: is_logged (a_pid)
		do
			check attached index_table.item (a_pid) as tup then
				Result := tup.type
			end
		end

	identifiers_for_type (a_type: PERSISTENT_TYPE): LINKED_LIST [PID]
			-- A list of persistent identifiers to objects in Current
			-- that have the same type as `a_type'.
		local
			d: like TYPE_DESCRIPTOR.descendant_types
		do
			create Result.make
			d := descriptor (a_type).descendant_types
io.put_string (generating_type + ".identifiers_for_type:  descendants = %N")
from d.start
until d.after
loop
	io.put_string ("   " + d.key_for_iteration.as_hex_string + "%N")
	d.forth
end
			from index_table.start
			until index_table.after
			loop
				if d.has (index_table.item_for_iteration.type) then
					Result.extend (index_table.key_for_iteration)
				end
				index_table.forth
			end
		end

	logged_time (a_pid: PID): YMDHMS_TIME
			-- The time associated with `a_pid'
		require
			is_logged: is_logged (a_pid)
		do
			check attached index_table.item (a_pid) as tup then
				Result := tup.time
			end
		end

	expected_type (a_index: INTEGER_32; a_pid: PID): PERSISTENT_TYPE
			-- The type that Current expects for the `a_index'-th field of the
			-- type of the object represented by `a_pid'.
		require
			is_logged: is_logged (a_pid)
		local
			pt: PERSISTENT_TYPE
		do
			check attached index_table.item (a_pid) as tup then
				pt := tup.type
				check attached descriptor_table.item (pt) as td then
					Result := td.i_th_field (a_index).type
				end
			end
		end

	attribute_value (a_index: INTEGER_32; a_pid: PID): ANY
			-- The flattened value for the `a_index'-th field of the object
			-- represented by `a_pid'
		require
			not_attribute_reference: not a_pid.is_attribute
			is_logged: is_logged (a_pid)
			has_attribute: has_attribute (a_index, a_pid)
		do
			check attached index_table.item (a_pid) as tup then
				check attached objects_table.item (tup.type) as tab then
					check attached tab.item (create {PID}.make_as_attribute (a_index, a_pid)) as v then
						Result := v
					end
				end
			end
		end

	count_capacity (a_pid: PID): TUPLE [cnt: INTEGER_32; cap: INTEGER_32]
			-- The count and capacity of the SPECIAL or TUPLE associated with `a_pid'.
		require
			is_logged: is_logged (a_pid)
--			special_or_tuple: is_special (expected_type (a_pid)) or is_tuple (expected_type (a_pid))
		do
			check attached count_capacity_table.item (a_pid) as tup then
				Result := tup
			end
		end

	referenced_objects: HASH_TABLE [BOOLEAN, PID]
			-- List of {PID} for objects listed in Current.
		do
			create Result.make (50)
			from index_table.start
			until index_table.after
			loop
				Result.extend (true, index_table.key_for_iteration)
				index_table.forth
			end
		end

feature -- Element change

	wipe_out
			-- Remove all data from Current
		do
			descriptor_table.wipe_out
			index_table.wipe_out
			root_table.wipe_out
			objects_table.wipe_out
			expanded_table.wipe_out
			count_capacity_table.wipe_out
			queued.wipe_out
			queue.wipe_out
			visited.wipe_out
		end

	reset
			-- Remove objects from `queue', `queued', and `visited' tables,
			-- but leave any previously tabulated objects in the other
			-- tables.  This allows a subsequent `tabulate' call to add
			-- additional objects to Current.
		do
			queued.wipe_out
			queue.wipe_out
			visited.wipe_out
		end

	add_descriptor (a_descriptor: TYPE_DESCRIPTOR; a_type: PERSISTENT_TYPE)
			-- Add `a_descriptor' to in Current and ensure objects of `a_type'
			-- can be stored in Current (i.e. calls `build_object_table').
		require
			not_has_descriptor: not has_descriptor (a_type)
		do
			descriptor_table.extend (a_descriptor, a_type)
			build_object_table (a_descriptor, a_type)
		ensure
			has_item: has_descriptor (a_type)
			item_correct: attached descriptor_table.item (a_type) as des implies des = a_descriptor
		end

	build_object_table  (a_descriptor: TYPE_DESCRIPTOR; a_type: PERSISTENT_TYPE)
			-- Create a table to hold objects of `a_type'
		require
			type_is_known: has_descriptor (a_type)
			no_object_table: not has_object_table (a_type)
		local
			tab: ATTRIBUTE_TABLE
		do
			create tab.make (a_descriptor)
			objects_table.extend (tab, a_type)
		ensure
			has_object_table: has_object_table (a_type)
		end

	log_object (a_tuple: TUPLE [type: PERSISTENT_TYPE; time: YMDHMS_TIME]; a_pid: PID)
			-- Add an index entry, recording the type and time for [the object
			-- represented by] `a_pid'.
		require
			has_descriptor: has_descriptor (a_tuple.type)
			no_type_changes: is_logged (a_pid) implies logged_type (a_pid) ~ a_tuple.type
		do
			index_table.force (a_tuple, a_pid)
		ensure
			has_pid: is_logged (a_pid)
			item_correct: attached index_table.item (a_pid) as tup implies tup = a_tuple
		end

	log_root (a_pid: PID)
			-- Record that `a_pid' represents a root object.
		require
			not_attribute_id: not a_pid.is_attribute
		do
			root_table.force (true, a_pid)
		end

	set_attribute_value (a_index: INTEGER_32; a_pid: PID; a_value: ANY)
			-- Set the representation in Current of the `a_index'-th field of the object
			-- identified `a_pid' to `a_value', where `a_value' is one of the basic types.
			-- The preconditions reflect that only basic values are actually stored in
			-- the tables, making each table hold a "flattenned" representation of an
			-- object.  At this point an Eiffel reference should have already been reduced
			-- to a PID to be passed as `a_value'.
		require
			not_attribute_reference: not a_pid.is_attribute
			is_type_logged: is_logged (a_pid)
			index_big_enough: a_index >= 1
	--		index_small_enough: a_index <= descriptor (logged_type (a_pid)).field_count or else
	--						is_special_
--			is_basic_value: is_basic_object (a_value) or is_special_basic_object (a_value)
			is_valid_basic_type: is_basic_type (expected_type (a_index, a_pid)) implies
									 persistent_type (a_value) ~ expected_type (a_index, a_pid)
			is_valid_reference_type: (not is_basic_type (expected_type (a_index, a_pid)) and
									not is_special_basic_type (expected_type (a_index, a_pid))) implies
									(persistent_type (a_value) ~ persistent_pid_type)
			is_valid_special_type: not is_basic_type (expected_type (a_index, a_pid)) implies
									(is_special_basic_type (expected_type (a_index, a_pid)) implies
									 (persistent_type (a_value) ~ expected_type (a_index, a_pid)))
		do
				-- Find the table in which to place `a_value'
			check attached index_table.item (a_pid) as tup then
				check attached objects_table.item (tup.type) as tab then
					tab.force (a_value, create {PID}.make_as_attribute (a_index, a_pid))
				end
			end
		end

	set_count_capacity (a_tuple: TUPLE [cnt: INTEGER_32; cap: INTEGER_32]; a_pid: PID)
			-- Store the count and capacity of the object associated with `a_pid'
		require
			is_logged: is_logged (a_pid)
		do
			count_capacity_table.force (a_tuple, a_pid)
		end

	set_from_other (a_encoding: TABULATION)
			-- Set the encoding fields based on value of `a_encoding'
		do
			session := a_encoding.session
			time := a_encoding.time
			descriptor_table := a_encoding.descriptor_table
			root_table := a_encoding.root_table
			index_table:= a_encoding.index_table
--			field_table := a_encoding.field_table
--			count_capacity_table := a_encoding.count_capacity_table
		end

	merge (a_other: TABULATION)
			-- Merge the data in `a_other' with Current
			-- Useful for the `cache' features of some {REPOSITORY} classes
		local
			pt: PERSISTENT_TYPE
--			pid: PID
			d: like {TABULATION}.descriptor_table
			ot: like {TABULATION}.objects_table
			t: ATTRIBUTE_TABLE
			td: TYPE_DESCRIPTOR
		do
				-- Class descriptors
			d := a_other.descriptor_table
			from d.start
			until d.after
			loop
				td := d.item_for_iteration
				pt := d.key_for_iteration
				if descriptor_table.has (pt) then
--					check cd.type ~ encoding.descriptor_table.value (pt).type then end
				else
					descriptor_table.extend (td, pt)
				end
				d.forth
			end
				-- index
			index_table.merge (a_other.index_table)
					-- NOTE:  Calling `merge' on the tables does not seem to work.  It
					-- is giving a post-condition violation after the first call to
					-- `force'.
--			from a_other.index_table.start
--			until a_other.index_table.after
--			loop
--				index_table.force (a_other.index_table.item_for_iteration,
--									a_other.index_table.key_for_iteration)
--				a_other.index_table.forth
--			end
				--objects table
			ot := a_other.objects_table
			from ot.start
			until ot.after
			loop
				t := ot.item_for_iteration
				pt := ot.key_for_iteration
				if attached objects_table.item (pt) as cur_t then
						-- Add objects to an existing table
					from t.start
					until t.after
					loop
						cur_t.force (t.item_for_iteration, t.key_for_iteration)
						t.forth
					end
				else
						-- Just add the whole object table
					objects_table.force (t, pt)
				end
				ot.forth
			end
				-- Specials data
			count_capacity_table.merge (a_other.count_capacity_table)
				-- Expnded links
			expanded_table.merge (a_other.expanded_table)
		end

feature -- Status report

	has_descriptor (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current have a {TYPE_DESCRIPTOR} paired with `a_type'?
		do
			Result := descriptor_table.has (a_type)
		end

	has_object_table (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does Current have an {OBJECT_TABLE} paired with `a_type'?
			-- An {OBJECT_TABLE} holds the representation of objects
			-- of a particular {PERSISTENT_TYPE}.
		do
			Result := objects_table.has (a_type)
		end

	is_logged (a_pid: PID): BOOLEAN
			-- Does Current have an index entry for `a_pid'?
		do
			Result := index_table.has (a_pid)
		end

	has_root (a_pid: PID): BOOLEAN
			-- Does Current identify the object referenced by `a_pid'
			-- as a persistent root?
		do
			Result := root_table.has (a_pid)
		end

	has_attribute (a_index: INTEGER_32; a_pid: PID): BOOLEAN
			-- Does Current have a value for the `a_index'-th field of the object
			-- represented by `a_pid'?
		require
			not_attribute_reference: not a_pid.is_attribute
		do
			Result := attached index_table.item (a_pid) as tup and then
						attached objects_table.item (tup.type) as tab and then
							tab.has (create {PID}.make_as_attribute (a_index, a_pid))
		end

	is_reference (a_index: INTEGER_32; a_pid: PID): BOOLEAN
			-- Does the `attribute_value' stored for the `a_index-'th field of
			-- the object referenced by `a_pid' hold a PID?
		require
			has_attribute: has_attribute (a_index, a_pid)
		local
			et: PERSISTENT_TYPE
		do
			et := expected_type (a_index, a_pid)
			Result := not is_basic_type (et) and not is_special_basic_type (et)
		end

feature -- {PERSISTENCE_MANAGER} -- Basic operations

	tabulate (a_object: ANY)
			-- Reduce the dirty parts of object structure rooted at `a_object'
			-- to a flattened (i.e. tabulated) form which can be easily
			-- serialized to a {REPOSITORY}.
			-- Through side effects, this feature may update some of the global
			-- objects that are inherited from {PERSISTENCE_FACILITIES} (e.g.
			-- `Identified_objects', etc).
		require
			not_expanded: not is_expanded_object (a_object)
			not_basic: not is_basic_object (a_object)
			is_pid_paired: is_identified_pid (persistence_id (a_object))
			is_dirty_pid: is_dirty_pid (persistence_id (a_object))
		local
			pid: PID
			pt: PERSISTENT_TYPE
			cd: TYPE_DESCRIPTOR
			a: ANY
		do
--			reset
			time.set_now_utc_fine
				-- Process objects
			pid := persistence_id (a_object)
			from
				queue.extend (pid)
				queued.extend (true, pid)
			until queue.is_empty
			loop
				pid := queue.item
				check
					not_void_pid: not pid.is_void
				end
				check
					is_dirty: is_dirty_pid (pid) or else not Persistence_manager.is_persisting_automatic
				end
					-- Add info about the type of each object associated
					-- with the `pid' to the tables.
				pt := persistent_type_from_pid (pid)
--				cd := type_descriptor_from_pid (pid)
--				if not has_descriptor (pt) then
--					add_descriptor (cd, pt)
--				end
				add_type_information (pid)
					-- Record the time of this object's
				if not is_logged (pid) then
					log_object ([pt, time], pid)
				end
					-- Mark this object as `visited' and remove from `queue'
				a := identified_object (pid)
				check
					not_expanded: not is_expanded_object (a)
						-- because expanded not added to `queue'.
				end
				visited.extend (a, pid)
				queue.remove
				queued.remove (pid)
					-- Process the attributes of the object associated with `pid'.
				process_attributes (a)
				Dirty_objects.remove (pid)
					-- Tabulate as root if required
				if Rooted_objects.has (pid) then
					log_root (pid)
				end
				if Expanded_links.has_referer_to (pid) and then
						not expanded_table.has_referer_to (pid) then
					Expanded_table.force (Expanded_links.referer (pid), pid)
				end
			end
		end

	add_type_information (a_pid: PID)
			-- Include into Current information about the type of the object
			-- associated with `a_pid', including the ancestor and descendant
			-- types of the object.
		require
			not_void: not a_pid.is_void
		local
			q: LINKED_QUEUE [PERSISTENT_TYPE]
			q_tab: HASH_TABLE [BOOLEAN, PERSISTENT_TYPE]
--			v: HASH_TABLE [BOOLEAN, PERSISTENT_TYPE]
			pid: PID
			pt: PERSISTENT_TYPE
			td: TYPE_DESCRIPTOR
		do
			create q.make
			create q_tab.make (10)
--			create v.make (10)
			pt := persistent_type_from_pid (a_pid)
			q.extend (pt)
			q_tab.extend (true, pt)
			from
			until q.is_empty
			loop
				pt := q.item
				q.remove
--				v.extend (true, pt)
				if not has_descriptor (pt) then
					td := type_descriptor_from_persistent_type (pt)
					add_descriptor (td, pt)
						-- Add ancestor types
					from td.ancestor_types.start
					until td.ancestor_types.after
					loop
						pt := td.ancestor_types.key_for_iteration
						if not q_tab.has (pt) then
							q.extend (pt)
							q_tab.extend (true, pt)
						end
						td.ancestor_types.forth
					end
						-- Add descendant types
					from td.descendant_types.start
					until td.descendant_types.after
					loop
						pt := td.descendant_types.key_for_iteration
						if not q_tab.has (pt) then
							q.extend (pt)
							q_tab.extend (true, pt)
						end
						td.descendant_types.forth
					end
				end
			end
		end

	objectify (a_pid: PID): ANY
			-- Attempt to update the {PERSISTENCE_FACILITIES} global objects
			-- (e.g. `Identified_objects', etc) with the objects that are
			-- represented in the tables of Current, returning the object
			-- referenced by `a_pid'.
		require
			pid_is_logged: is_logged (a_pid)
--			all_loaded_types_recognized: not has_unknown_type
		local
			td: TYPE_DESCRIPTOR
			dt: INTEGER_32
			pid: PID
			a: ANY
		do
--			Result := 0
--io.put_string (generating_type + ".objectify:  ")
--io.put_string ("tabulation = %N")
--show
			visited.wipe_out
				-- Ensure all the types of Current are mapped into this system.
				-- This modifies the `Mapped_types' (not temporary), but okay.
			from descriptor_table.start
			until descriptor_table.after
			loop
				td := descriptor_table.item_for_iteration
				dt := Internal.dynamic_type_from_string (td.name)
				check
					is_valid_dynamic_type: dt >= 1
						-- because checked in precondition not `has_unknown_type'
				end
				if not is_recorded_type (td.type) then
--					Persistence_manager.map_dynamic_type (dt)
					Mapped_types.extend ([dt, td.type, td, true])
				end
				descriptor_table.forth
			end
				-- Just build the one object (and reachables)
--			Result := get_object (a_pid)
			a := get_object (a_pid)
				-- For each visited object, ensure it is in 'Identified_objects'.
				-- Ensure the pid for the object is correct.
				-- and marked as clean (because it was just loaded).
				-- Ensure the current session recognizes any root objects.
				-- If `Identified_objects' already has an object with the same
				-- {PID} as a `visited' object, then overwrite the old one.
			from visited.start
			until visited.after
			loop
				a := visited.item_for_iteration
				pid := visited.key_for_iteration
				if attached Identified_objects.item (pid) as old_tup then
						-- The persistent object is already in use.
					check
						same_types: Internal.dynamic_type (a) = Internal.dynamic_type (old_tup.object)
							-- because one object / one pid
					end
					if attached {IDENTIFIABLE} old_tup.object as ro then
							-- Must be an expanded object and must replace it
						check attached index_table.item (pid) as new_tup then
							ro.set_persistence_id (pid)
							Identified_objects.force ([ro, new_tup.type], pid)
						end
					else
						check
							same_persistent_types: persistent_type (a) ~ old_tup.type
								-- Because PID's are the same.
						end
							-- Overwrite the old object; but the `persistence_id'
							-- remains the same.
							-- Do not use `copy' because some objects may
							-- not allow themselves to be copied. This may
							-- temporarily violate a class invariant, but
							-- since there should be no calls on that object
							-- until this feature finishes and all objects are
							-- restored, that should be okay.
						copy_object_from_other (
									create {REFERENCE_IDENTIFIABLE}.make (old_tup.object),
									create {REFERENCE_IDENTIFIABLE}.make (a))
					end
				else
					if attached {IDENTIFIABLE} a as i then
						i.set_persistence_id (pid)
					else
						Handler.set_persistence_id (a, pid)
					end
					check attached index_table.item (pid) as new_tup then
						Identified_objects.extend ([a, new_tup.type], pid)
					end
				end
					-- Ensure the object is no longer marked as dirty.
				Dirty_objects.remove (pid)
					-- Ensure `Rooted_objects' updated
				if root_table.has (pid) then
					Rooted_objects.force (true, pid)
				end
				visited.forth
			end
			Result := identified_object (a_pid)
		end

feature {NONE} -- Implementation

	copy_object_from_other (a_object: IDENTIFIABLE; a_other: IDENTIFIABLE)
			-- Does a field-by-field copy of `a_other' into `a_object'.
			-- Called to copy fields into a previously persistable (i.e. identified)
			-- object.
			-- This is used instead of calling `copy', because `a_object' might
			-- be of a type that does not allow copying, but we still need to
			-- transfer the values that were read into a temporary object during
			-- loading into the pre-existing object.
		require
			same_types: a_object.object.same_type (a_other.object)
			is_persistable: attached a_object.object as obj implies is_persistable (obj)
		local
			i: INTEGER_32
		do
			from i := 1
			until i > a_object.field_count
			loop
				inspect a_object.field_type (i)
				when {REFLECTOR_CONSTANTS}.none_type then
					a_object.set_reference_field (i, void)
				when {REFLECTOR_CONSTANTS}.pointer_type then
					a_object.set_pointer_field (i, a_other.pointer_field (i))
				when {REFLECTOR_CONSTANTS}.reference_type then
					if not attached a_other.field (i) then
						a_object.set_reference_field (i, void)
					else
							-- Only set the field if this field was previously void;
							-- otherwise, `objectify' will eventually copy the correct
							-- values into the referenced object.
						if not attached a_object.field (i) then
								-- Set the previously void field to the new value.
							a_object.set_reference_field (i, a_other.field (i))
						end
					end
						-- If the objected referenced by this field is not already in
						-- the session then make this field point to that new object.
						-- What is the pid of this new object?

						-- otherwise, make this field point to the old object, knowing
						-- that the old object (which has the same pid in the session
						-- as the referenced object has in this tabulation) will be
						-- copied over by the version in this tabulaion.

				when {REFLECTOR_CONSTANTS}.character_8_type then
					a_object.set_character_8_field (i, a_other.character_8_field (i))
				when {REFLECTOR_CONSTANTS}.boolean_type then
					a_object.set_boolean_field (i, a_other.boolean_field (i))
				when {REFLECTOR_CONSTANTS}.integer_32_type then
					a_object.set_integer_32_field (i, a_other.integer_32_field (i))
				when {REFLECTOR_CONSTANTS}.real_32_type then
					a_object.set_real_32_field (i, a_other.real_32_field (i))
				when {REFLECTOR_CONSTANTS}.real_64_type then
					a_object.set_real_64_field (i, a_other.real_64_field (i))
				when {REFLECTOR_CONSTANTS}.expanded_type then
						-- recursive call; there is no "set_expanded_field" feature
					copy_object_from_other (a_object.expanded_field (i), a_other.expanded_field (i))
				when {REFLECTOR_CONSTANTS}.integer_8_type then
					a_object.set_integer_8_field (i, a_other.integer_8_field (i))
				when {REFLECTOR_CONSTANTS}.integer_16_type then
					a_object.set_integer_16_field (i, a_other.integer_16_field (i))
				when {REFLECTOR_CONSTANTS}.integer_64_type then
					a_object.set_integer_64_field (i, a_other.integer_64_field (i))
				when {REFLECTOR_CONSTANTS}.character_32_type then
					a_object.set_character_32_field (i, a_other.character_32_field (i))
				when {REFLECTOR_CONSTANTS}.natural_8_type then
					a_object.set_natural_8_field (i, a_other.natural_8_field (i))
				when {REFLECTOR_CONSTANTS}.natural_16_type then
					a_object.set_natural_16_field (i, a_other.natural_16_field (i))
				when {REFLECTOR_CONSTANTS}.natural_32_type then
					a_object.set_natural_32_field (i, a_other.natural_32_field (i))
				when {REFLECTOR_CONSTANTS}.natural_64_type then
					a_object.set_natural_64_field (i, a_other.natural_64_field (i))
				else
					check
						should_not_happen: false
							-- because all types are covered above
					end
				end
				i := i + 1
			end
		end

	get_object (a_pid: PID): ANY
			-- Create an [unitialized] object of the type associated with `a_pid'
			-- in the `index_table', or the object that is already associated
			-- in the `visited' table with `a_pid', or create new object and
			-- place into `visited'.
		require
--			not_visited: not visited.has (a_pid)
--			is_type_known: dynamic_type_from_pid (a_pid) >= 1
		do
			if attached visited.item (a_pid) as a then
				Result := a
			else
					-- Get the persistent type / dynamic type.
				check attached index_table.item (a_pid) as tup then
					check attached descriptor_table.item (tup.type) as td then
							-- Get the right kind of object to match the type.
							-- The called features add the object to `visited'.
						if td.is_special_basic then
							Result := new_special_basic (a_pid)
						elseif td.is_special_reference then
							Result := new_special_reference (a_pid)
						elseif td.is_tuple then
							Result := new_tuple (a_pid)
						else
							Result := new_object (a_pid)
						end
					end
				end
			end
		ensure
			new_object_was_saved: visited.has (a_pid)
		end

	new_object (a_pid: PID): ANY
			-- Create a new [complex] object, associate it with `a_pid', and
			-- store it in `visited'.  Wrap the result in an {IDENDIFIABLE}
			-- if the object is an expanded type.
		require
			not_visited: not visited.has (a_pid)
			is_logged: is_logged (a_pid)
		local
			td: TYPE_DESCRIPTOR
			dt: INTEGER_32
			a: ANY
			i: INTEGER_32
			val: ANY
			et: PERSISTENT_TYPE
			ro: REFERENCE_IDENTIFIABLE
			pid: PID
		do
				-- Create the [uninitialized] object
			td := descriptor (logged_type (a_pid))
			dt := Internal.dynamic_type_from_string (td.name)
			a := Internal.new_instance_of (dt)
				-- Wrap the object for easier handling.
			create ro.make (a)
			if ro.is_expanded then
				Result := ro
			else
				Result := a
			end
			visited.extend (Result, a_pid)
			check
				is_complex_type: not is_basic_object (a) and
									not is_special_object (a) and
									not is_tuple_object (a)
					-- because of how this feature is called from `get_object'.
			end
				-- Set the attributes
			from i := 1
			until i > ro.field_count
			loop
				val := attribute_value (i, a_pid)
				et := expected_type (i, a_pid)
				if is_basic_type (et) then
					set_basic_field (i, ro, val)
				elseif is_special_basic_type (et) then
					ro.set_reference_field (i, val)
				elseif ro.field_type (i) = {REFLECTOR_CONSTANTS}.expanded_type then
					check attached {PID} val as id and then not id.is_void then
						create pid.make_as_attribute (i, a_pid)
						if not Expanded_links.has (pid) then
							Expanded_links.extend (id, pid)
						end
						check attached {IDENTIFIABLE} get_object (id) as e then
							copy_object_from_other (ro.expanded_field (i), e)
						end
					end
				else
					check attached {PID} val as id then
						if id.is_void then
							ro.set_reference_field (i, void)
						else
							a := get_object (id)
							ro.set_reference_field (i, a)
						end
					end
				end
				i := i + 1
			end
		end

	new_special_basic (a_pid: PID): SPECIAL [ANY]
			-- Decomposition function called by `get_object' to create a new
			-- object when it must be a SPECIAL [XX] where XX is a basic type.
		require
			is_logged: is_logged (a_pid)
			is_special: is_special_basic_type (logged_type (a_pid))
--			has_attribute: has_attribute (a_pid)
		local
			pt: PERSISTENT_TYPE
			n: INTEGER_32
			spec: SPECIAL [ANY]
		do
			pt := logged_type (a_pid)
			check attached {SPECIAL [ANY]} attribute_value (1, a_pid) as v then
				n := v.capacity
				if pt ~ Special_boolean_type then
					create {SPECIAL [BOOLEAN]} spec.make_empty (n)
				elseif pt ~ Special_character_8_type then
					create {SPECIAL [CHARACTER_8]} spec.make_empty (n)
				elseif pt ~ Special_character_32_type then
					create {SPECIAL [CHARACTER_32]} spec.make_empty (n)
				elseif pt ~ Special_integer_8_type then
					create {SPECIAL [INTEGER_8]} spec.make_empty (n)
				elseif pt ~ Special_integer_16_type then
					create {SPECIAL [INTEGER_16]} spec.make_empty (n)
				elseif pt ~ Special_integer_32_type then
					create {SPECIAL [INTEGER_32]} spec.make_empty (n)
				elseif pt ~ Special_integer_64_type then
					create {SPECIAL [INTEGER_64]} spec.make_empty (n)
				elseif pt ~ Special_natural_8_type then
					create {SPECIAL [NATURAL_8]} spec.make_empty (n)
				elseif pt ~ Special_natural_16_type then
					create {SPECIAL [NATURAL_16]} spec.make_empty (n)
				elseif pt ~ Special_natural_32_type then
					create {SPECIAL [NATURAL_32]} spec.make_empty (n)
				elseif pt ~ Special_natural_64_type then
					create {SPECIAL [PID]} spec.make_empty (n)
				elseif pt ~ Special_real_32_type then
					create {SPECIAL [REAL_32]} spec.make_empty (n)
				elseif pt ~ Special_real_64_type then
					create {SPECIAL [REAL_64]} spec.make_empty (n)
				else
					check
						should_not_happen: false then
							-- because these are only special basic types stored
					end
				end
					-- Now fill the special from the data in Current's tables
				check
					conforms: v.conforms_to (spec)
					same_capacity: v.capacity = spec.capacity
				end
--				spec.copy (v)
				spec.copy_data (v, 0, 0, v.count)
				Result := spec
				visited.extend (Result, a_pid)
			end
		ensure
			object_is_special: attached {SPECIAL [ANY]} Result
			is_special_basic: is_special_basic_object (Result)
		end

	new_special_reference (a_pid: PID): SPECIAL [detachable ANY]
			-- Decomposition function called by `get_object' to create a new
			-- object when it must be a SPECIAL [XX] where XX is NOT a basic
			-- type.
		require
			is_logged: is_logged (a_pid)
--			is_special: is_special_reference_type (logged_type (a_pid))
		local
			td: TYPE_DESCRIPTOR
			dt: INTEGER_32
			tup: TUPLE [cnt: INTEGER_32; cap: INTEGER_32]
			spec: SPECIAL [detachable ANY]
			i: INTEGER_32
			val: ANY
			a: ANY
		do
			td := descriptor (logged_type (a_pid))
			dt := Internal.dynamic_type_from_string (td.name)
			tup := count_capacity (a_pid)
			spec := Internal.new_special_any_instance (dt, tup.cap)
			from i := 1
			until i > tup.cnt
			loop
				val := attribute_value (i, a_pid)
				if Internal.generic_dynamic_type (spec, 1) =
							{REFLECTOR_CONSTANTS}.expanded_type then
						-- The Result will contain only expanded types, so
						-- ensure we find a [persistent] reference.
					check attached {PID} val as pid and then not pid.is_void then
						a := get_object (pid)
						spec.force (a, i - 1)	-- SPECIALs are zero based
					end
				elseif attached {PID} val as pid then
						-- We have a reference, perhaps void, to some object
					if pid.is_void then
						spec.force (Void, i - 1)
					else
						a := get_object (pid)
						spec.force (a, i - 1)
					end
				else
					check
						is_basic_object: is_basic_object (val)
							-- Because the retrieve value not expanded or PID
					end
					spec.force (val, i - 1)
				end
				i := i + 1
			end
			Result := spec
			visited.extend (Result, a_pid)
		ensure
			is_special: is_special_object (Result)
			not_basic: not is_special_basic_object (Result)
		end

	new_tuple (a_pid: PID): TUPLE
			-- Decomposition function called by `get_object' to create a new
			-- object when it must be a TUPLE.
			-- This feature recursively calls `get_object', because all the
			-- objects that go into the TUPLE must be known in order to create
			-- the TUPLE.
		local
			n: INTEGER_32
			i: INTEGER
			spec: SPECIAL [detachable ANY]
			et: PERSISTENT_TYPE
			td: TYPE_DESCRIPTOR
			dt: INTEGER_32
			val: ANY
			a: ANY
		do
				-- To build a TUPLE must first build a SPECIAL of the correct size
			check attached count_capacity_table.item (a_pid) as tup then
				n := tup.cnt
				create spec.make_empty (n)
				from i := 1
				until i > n
				loop
					et := expected_type (i, a_pid)
					val := attribute_value (i, a_pid)
					if is_normal_type (et) then
						check attached {PID} val as pid then
							if pid.is_void then
								spec.force (Void, i - 1)
							else
								a := get_object (pid)
								spec.force (a, i - 1)
							end
						end
					else
						print (generating_type + ".new_tuple:  fix me ! %N")
					end
					i := i + 1
				end
			end
				-- Now create the tuple
			td := descriptor (logged_type (a_pid))
			dt := Internal.dynamic_type_from_string (td.name)
			check attached Internal.new_tuple_from_special (dt, spec) as t then
				Result := t
			end
			visited.extend (Result, a_pid)
		end

	set_basic_field (a_index: INTEGER; a_reflected: IDENTIFIABLE; a_value: ANY)
			-- Set the `a_index'-th field of the object encapsulate by
			--`a_object' to `a_value'.
		require
			not_basis_type: not is_basic_object (a_reflected.object)
			not_special: not a_reflected.is_special
			not_tuple: not a_reflected.is_tuple
			index_big_enough: a_index >= 1
			index_small_enough: a_index <= a_reflected.field_count
			value_exists: a_value /= Void
		local
			et: INTEGER				-- expected static type
			at: INTEGER				-- actual type
		do
			et := a_reflected.field_type (a_index)
			at := dynamic_type (a_value)
--			check
--				conformance: a_object.field_conforms_to (et, at)
--			end
			check
				not_reference: et /= {REFLECTOR_CONSTANTS}.reference_type
				not_expanded: et /= {REFLECTOR_CONSTANTS}.expanded_type
			end
			if et = {REFLECTOR_CONSTANTS}.boolean_type then
				check attached {BOOLEAN} a_value as v then
					a_reflected.set_boolean_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Character_8_type then
				check attached {CHARACTER_8} a_value as v then
					a_reflected.set_character_8_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Character_32_type then
				check attached {CHARACTER_32} a_value as v then
					a_reflected.set_character_32_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Integer_8_type then
				check attached {INTEGER_8} a_value as v then
					a_reflected.set_integer_8_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Integer_16_type then
				check attached {INTEGER_16} a_value as v then
					a_reflected.set_integer_16_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Integer_32_type then
				check attached {INTEGER_32} a_value as v then
					a_reflected.set_integer_32_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Integer_64_type then
				check attached {INTEGER_64} a_value as v then
					a_reflected.set_integer_64_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Natural_8_type then
				check attached {NATURAL_8} a_value as v then
					a_reflected.set_natural_8_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Natural_16_type then
				check attached {NATURAL_16} a_value as v then
					a_reflected.set_natural_16_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Natural_32_type then
				check attached {NATURAL_32} a_value as v then
					a_reflected.set_natural_32_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Natural_64_type then
				check attached {NATURAL_64} a_value as v then
					a_reflected.set_natural_64_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Real_32_type then
				check attached {REAL_32} a_value as v then
					a_reflected.set_real_32_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Real_64_type then
				check attached {REAL_64} a_value as v then
					a_reflected.set_real_64_field (a_index, v)
				end
			elseif et = {REFLECTOR_CONSTANTS}.Pointer_type then
				io.put_string (generating_type + ".set_basic_field:  fix for pointer type %N")
			else
				check
					should_not_happen: false
						-- because this covers all possible field types
				end
			end  -- if ... elseif ...
		end

feature -- Basic operations

	out: STRING_8
			-- Display data for testing.
		local
			td: TYPE_DESCRIPTOR
			t: YMDHMS_TIME
			pt, at, dt: PERSISTENT_TYPE
			pid: PID
			tab: ATTRIBUTE_TABLE
			i: INTEGER
		do
			create Result.make (100)
			Result.append (generating_type + ".out: %N")

			Result.append ("vvvv " + generating_type)
			from i := 1
			until i > 3
			loop
				Result.append (" vvvvvvvv " + generating_type)
				i := i + 1
			end
				-- Show session and time.
			Result.append ("%N")
			Result.append ("%T session = " + session.out + " %T time = " + time.as_string + "%N")
--			Result.append ("%N")
--				-- Show the `descriptor_table'.
			Result.append ("descriptor_table: %N")
			Result.append ("       PERSISTENT_TYPE (key)              name %N")
			from descriptor_table.start
			until descriptor_table.after
			loop
				td := descriptor_table.item_for_iteration
				pt := descriptor_table.key_for_iteration
				Result.append (pt.as_string + "%N")
				Result.append (td.as_string)
				Result.append ("  ancestors [")
				from td.ancestor_types.start
				until td.ancestor_types.after
				loop
					at := td.ancestor_types.key_for_iteration
--					check attached descriptor_table.item (at) as d then
					if attached descriptor_table.item (at) as d then
						Result.append (d.name)
					else
						Result.append ("unknown type not in " + generating_type.out + "`decriptor_table' %N")
					end
					td.ancestor_types.forth
					if not td.ancestor_types.after then
						Result.append (", ")
					end
				end
				Result.append ("] ")
				Result.append (" descendants [")
				from td.descendant_types.start
				until td.descendant_types.after
				loop
					dt := td.descendant_types.key_for_iteration
--					check attached descriptor_table.item (dt) as d then
					if attached descriptor_table.item (dt) as d then
						Result.append (d.name)
					else
						Result.append ("unknown type not in " + generating_type.out + "`decriptor_table' %N")
					end
					td.descendant_types.forth
					if not td.descendant_types.after then
						Result.append (", ")
					end
				end
				Result.append ("] %N")
				descriptor_table.forth
			end
			Result.append ("%N")
				-- Show the `index_table'.
			Result.append ("index_table: %N")
			Result.append ("     pt (key)  [                    pt,                            time         ] %N")
			from index_table.start
			until index_table.after
			loop
				pid := index_table.key_for_iteration
				pt := index_table.item_for_iteration.type
				t := index_table.item_for_iteration.time
				Result.append ("   " + pid.out + "   " + " [ " + pt.as_string + ",  " + t.as_string + " ]%N")
				index_table.forth
			end
			Result.append ("%N")
				-- Show the `objects_table.
			Result.append ("objects_table': %N")
			Result.append ("     Table       PERSISTENT_TYPE (key) %N")
			from objects_table.start
			until objects_table.after
			loop
				pt := objects_table.key_for_iteration
				tab := objects_table.item_for_iteration
				Result.append ("   Table:  {" + tab.descriptor.name + "} %T" + pt.as_string + "%N")
				Result.append ("        PID (key)      value %N")
				from tab.start
				until tab.after
				loop
					pid := tab.key_for_iteration
					pt := tab.descriptor.i_th_field (pid.attribute_identifier).type
					Result.append ("        " + pid.out + "   ")
					if is_basic_type (pt) then
						Result.append (tab.item_for_iteration.out)
					elseif is_special_basic_type (pt) then
						check attached {SPECIAL [ANY]} tab.item_for_iteration as spec then
							from i := 1
							until i > spec.count.min (15)
							loop
								Result.append (spec.at (i - 1).out)
								if i < spec.count and i < spec.count.min (15) then
									Result.append (",")
								end
								i := i + 1
							end
						end
					else
						check attached {PID} tab.item_for_iteration as id then
							Result.append (id.out)
						end
					end
					tab.forth
					Result.append ("%N")
				end
				Result.append ("%N")
				objects_table.forth
			end
				-- Show the `root_table'.
			Result.append ("root_table: %N")
			Result.append ("    pid (key)     value %N")
			from root_table.start
			until root_table.after
			loop
				Result.append ("    " + root_table.key_for_iteration.out)
				Result.append ("      " + root_table.item_for_iteration.out)
				Result.append ("%N")
				root_table.forth
			end
			Result.append ("%N")
--				-- Show the `expanded_table'.
--			Result.append ("expanded_table: %N")
--			Result.append ("    pid (key)     value %N")
--			from expanded_table.start
--			until expanded_table.after
--			loop
--				Result.append ("    " + expanded_table.key_for_iteration.out)
--				Result.append ("    " + expanded_table.item_for_iteration.out)
--				Result.append ("%N")
--				expanded_table.forth
--			end
--			Result.append ("%N")
				-- Show the `count_capacity_table'.
			Result.append ("count_capacity_table: %N")
			Result.append ("    pid (key)   [ count / capacity ] %N")
			from count_capacity_table.start
			until count_capacity_table.after
			loop
				Result.append ("    " + count_capacity_table.key_for_iteration.out)
				Result.append ("       " + count_capacity_table.item_for_iteration.cnt.out)
				Result.append ("    /   " + count_capacity_table.item_for_iteration.cap.out)
				Result.append ("%N")
				count_capacity_table.forth
			end
			Result.append ("%N")
				-- Show the `Visited_objects'.
			Result.append ("%N")
			Result.append ("Visited objects:   count = " + visited.count.out + "   ")
			from visited.start
			until visited.after
			loop
				Result.append (visited.key_for_iteration.out + "  ")
				visited.forth
			end
			Result.append ("%N%N")
			Result.append ("^^^^ " + generating_type)
			from i := 1
			until i > 3
			loop
				Result.append (" ^^^^^^^^ " + generating_type)
				i := i + 1
			end
			Result.append ("%N")
		end

feature {NONE} -- Implementation

	process_attributes (a_object: ANY)
			-- Decomposition feature used by `tabulate' to step through the
			-- the attributes of `a_object', adding non-basic attribute
			-- objects to the `queue' for processing later.
		require
			not_expanded: not is_expanded_object (a_object)
			is_dirty: is_dirty (a_object) or else not Persistence_manager.is_persisting_automatic
		local
			ro: REFERENCE_IDENTIFIABLE
			i: INTEGER
			pid, id: PID
		do
			pid := persistence_id (a_object)
			if is_special_basic_object (a_object) then
					-- Just store the whole special as one value
				set_attribute_value (1, pid, a_object)
				check attached {SPECIAL [ANY]} a_object as spec then
					set_count_capacity ([spec.count, spec.capacity], pid)
				end
			elseif is_special_object (a_object) then
-- added "detachable ANY" instead of just "ANY" to fix a bug.
-- I don't know why a SPECIAL [DISK] does not conform to SPECIAL [ANY].
				check attached {SPECIAL [detachable ANY]} a_object as spec then
					set_count_capacity ([spec.count, spec.capacity], pid)
					process_special (spec)
				end
			else
					-- It is a normal object or a TUPLE
				create ro.make (a_object)
				from i := 1
				until i > ro.field_count
				loop
					if ro.is_field_statically_expanded (i) then
						process_expanded_field (ro.expanded_field (i), i, pid)
					elseif attached ro.field (i) as f then
--						print (generating_type + ".process_attributes: field (" + i.out + "), " + ro.field_name (i) + ", ")
--						print (" NOT statically expanded. %N")
						if is_basic_object (f) or is_special_basic_object (f) then
								-- Just store the [basic] value
							set_attribute_value (i, pid, f)
						else
							if not is_persistable (f) then
								Persistence_manager.identify (f)
							end
							id := Handler.persistence_id (f)
								-- Store the [persistent] reference and queue if dirty
							set_attribute_value (i, pid, id)
							if not queued.has (id) and not visited.has (id) then
								if should_persist (id) then
									add_to_queue (id)
								end
							end
						end
					else
							-- Store a void [persistent] reference
						set_attribute_value (i, pid, create {PID})
					end
					i := i + 1
				end
			end
		end

	should_persist (a_pid: PID): BOOLEAN
			-- Should the object identified by `a_pid' be visited?
			-- This is called to check if an attribute should be added to the `queue'
			-- as `tabulate' is walking through the objects.
			-- The reasoning behind this feature is:
			--   1) It is called only when the traversal has reached the attribute.
			--   2) If `is_dirty', overwrite the stored version.
			--   3) If not `is_marking_dirty', then can't just ignore the attribute.
			--   4) If not yet `is_stored', then must store it.  Otherwise objects
			--      that have not yet been peristed will never be marked dirty
			--      automatically and will be missed.
		require
			not_void: not a_pid.is_void
		do
			Result := (is_dirty_pid (a_pid) or else
						not Persistence_manager.is_marking_dirty) or else
						not repository.is_stored (a_pid)
		end

	add_to_queue (a_pid: PID)
			-- Adds `a_pid' to the `queue' and to `queued'.
			-- Before extending the queues, it first ensures that `a_pid' is
			-- marked as dirty to satisfy the conditions for `process_attributes'.
		do
			Dirty_objects.force (true, a_pid)
			queue.extend (a_pid)
			queued.extend (true, a_pid)
		end

	process_special (a_object: SPECIAL [detachable ANY])
			-- Store the items of `a_object'
		require
			is_special: is_special_object (a_object)
			not_special_basic: not is_special_basic_object (a_object)
			is_identified: is_persistable (a_object)
			is_dirty: is_dirty (a_object)
		local
			ro: REFERENCE_IDENTIFIABLE
--			ero: COPY_SEMANTICS_IDENTIFIABLE
			i: INTEGER
			pid, id: PID
		do
			create ro.make (a_object)
			pid := persistence_id (a_object)
			from i := 1
			until i > a_object.count
			loop
				if ro.is_special_of_expanded then
					process_expanded_field (ro.special_copy_semantics_item (i), i, pid)
--					ero := ro.special_copy_semantics_item (i - 1)
--					if not is_expanded_identified (i, a_pid) then
--						Persistence_manager.identify_expanded (ero, i, pid)
--					end
--					id := ero.persistence_id
--						-- Store the [persistent] reference and assume expanded is dirty
--					expanded_table.extend (id, create {PID}.make_as_attribute (i, pid))
--					set_attribute_value (i, pid, id)

--		-- no it's expanded; call `process_attributes_of_expanded'			
--					if not queued.has (id) and not visited.has (id) then
--						Dirty_objects.extend (true, id)
--						queue.extend (id)
--						queued.extend (true, id)
--					end
				else
					check
						has_references: ro.is_special_of_reference
							-- because does not contain expanded
					end
					if attached a_object.item (i - 1) as v then	-- zero based
						if is_basic_object (v) then
								-- Just store the [basic] value
							set_attribute_value (i, pid, v)
--							elseif  then
	-- Do I need to check if `v' is expanded?  I think so
						else
							if not is_persistable (v) then
								Persistence_manager.identify (v)
							end
							id := persistence_id (v)
								-- Store the [persistent] reference and queue if dirty
							set_attribute_value (i, pid, id)
							if not queued.has (id) and not visited.has (id) then
								if should_persist (id) then
									add_to_queue (id)
								end
							end
						end
					else
							-- Store a void [persistent] reference
						set_attribute_value (i, pid, create {PID})
					end
				end
				i := i + 1
			end
		end

	process_expanded_field (a_reflected: IDENTIFIABLE; a_field: INTEGER; a_pid: PID)
			-- Decomposition feature used to process field `i' of object `a_pid'
			-- when that field `is_field_statically_expanded'.  The object to be
			-- processed is wrapped in a {REFLECTED_OBJECT} called `a_reflected'.
		require
			is_expanded: a_reflected.is_expanded
		local
			pid: PID
			pt: PERSISTENT_TYPE
			td: TYPE_DESCRIPTOR
			i: INTEGER
			id: PID
		do
--			print (generating_type + ".process_expanded_field: field (" + i.out + "), " + ro.field_name (i) + ", ")
--			print (" statically expanded. %N")
			if not is_expanded_identified (a_field, a_pid) then
				Persistence_manager.identify_expanded (a_reflected, a_field, a_pid)
			end
			pid := a_reflected.persistence_id
				-- Add info about object associated with `pid' to tables; expanded
				-- types are not put in the `queue', so must record this info here.
			pt := persistent_type_from_pid (pid)
			td := type_descriptor_from_pid (pid)
			if not has_descriptor (pt) then
				add_descriptor (td, pt)
			end
			if not is_logged (pid) then
				log_object ([pt, time], pid)
			end
			expanded_table.extend (pid, create {PID}.make_as_attribute (a_field, a_pid))
			set_attribute_value (a_field, a_pid, pid)
				-- Since the fields of the expanded object are add here, go
				-- ahead and mark the object as `visited'.
			check
				not_visited: not Visited.has (pid)
			end
			Visited.extend (true, pid)
			from i := 1
			until i > a_reflected.field_count
			loop
				if a_reflected.is_field_statically_expanded (i) then
					process_expanded_field (a_reflected.expanded_field (i), i, pid)
				elseif attached a_reflected.field (i) as f then
--						print (generating_type + ".process_attributes: field (" + i.out + "), " + ro.field_name (i) + ", ")
--						print (" NOT statically expanded. %N")
					if is_basic_object (f) then
							-- Just store the [basic] value
--							print (generating_type + ".process_attributes: expected_type (" + i.out + ", " + a_pid.out)
--							print (" = " + descriptor (expected_type (i, a_pid)).name + "%N")
						set_attribute_value (i, pid, f)
					else
						if not is_persistable (f) then
							Persistence_manager.identify (f)
						end
						id := Handler.persistence_id (f)
							-- Store the [persistent] reference and queue if dirty
						set_attribute_value (i, pid, id)
						if not queued.has (id) and not visited.has (id) then
							if should_persist (id) then
								add_to_queue (id)
							end
						end
					end
				else
						-- Store a void [persistent] reference
					set_attribute_value (i, pid, create {PID})
				end
				i := i + 1
			end
		end


--	process_attributes_of_expanded (a_reflected: COPY_SEMANTICS_IDENTIFIABLE)
--			-- Store the attributes of the object enclosed by `a_reflected'.
--			-- The expanded object is wrapped in a {REFLECTED_OBJECT} to avoid
--			-- passing copies.
--		require
--			is_expanded: a_reflected.is_expanded
--			not_special: not a_reflected.is_special
--		local
--			i: INTEGER
--		do
--			from i := 1
--			until i > a_reflected.field_count
--			loop
--				i := i + 1
--			end
--		end

feature {NONE} -- Contract support

--	has_unknown_type: BOOLEAN
--			-- Does Current contain a type that is not known to this session?
--			-- If not set `last_error' appropriately.
--		local
--			td: TYPE_DESCRIPTOR
--			pt: PERSISTENT_TYPE
--			dt: INTEGER_32
--		do
--			from descriptor_table.start
--			until descriptor_table.after or Result
--			loop
--				pt := descriptor_table.key_for_iteration
--				td := descriptor_table.item_for_iteration
--				dt := Internal.dynamic_type_from_string (td.name)
----				if is_valid_dynamic_type (dt) then
--				if dt >= 1 then
--						-- Does the new `pt' match any previous mapping.
--					if is_recorded_type (dt) then
--						if pt /~ persistent_type_of_type (dt) then
--							last_error := Class_version_mismatch
--							Result := true
--						end
--					end
--				else
--					last_error := Unrecognized_type
--					Result := true
--				end
--				descriptor_table.forth
--			end
--		end

--	build_relationships
--			-- Called at the end of `tabulate' to build the `relationships'
--			-- table from the types in the `descriptor_table'.  At this point
--			-- feature `tabulate' has added the persistent representaion of
--			-- the generating type of each object (i.e. a {PERSISTENT_TYPE}
--			-- to the the `descriptor_table'.  For each of the types in the
--			-- `descriptor_table', calculate its ancestor and descendant types.
--		do
--			from descriptor_table.start
--			until descriptor_table.after
--			loop
--				pt := descriptor_table.key_for_iteration
--				td := descriptor_table.item_for_iteration
--				
--				descriptor_table.forth
--			end
--		end

feature {TABULATION, REPOSITORY} -- Implementation

	descriptor_table: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			-- The descriptors of the types necessary to reconstruct an object
			-- indexed by their {PERSISTENT_TYPE}.

	index_table: HASH_TABLE [TUPLE [type: PERSISTENT_TYPE; time: YMDHMS_TIME], PID]
			-- The actual type of each object and tabulation time of each
			-- object indexed by the {PID}.
			-- Objects only; no attribute references.

	objects_table: HASH_TABLE [ATTRIBUTE_TABLE, PERSISTENT_TYPE]
			-- Each item contains a table that holds the attributes of all the
			-- the objects of the same type as the key.

	root_table: HASH_TABLE [BOOLEAN, PID]
			-- Each object whose {PID} is in this table is a "persistent root"
			-- and therefore not subject to [persistent] garbage collection.

	expanded_table: EXPANDED_LINKS_TABLE
			-- Each object whose {PID} is in this table is of an expanded
			-- type, indexed by a {PID} that `is_attribute_id'.

	count_capacity_table: HASH_TABLE [TUPLE [cnt: INTEGER_32; cap: INTEGER_32], PID]
			-- Records the count and capacity of specials and tuples, because that
			-- information is need to reconstruct those object types.

--	relationships: HASH_TABLE [RELATIONSHIP_TABLE, PERSISTENT_TYPE]
--			-- A table containing relationships (ancestors and descendants) for
--			-- particulare {PERSISTENT_TYPE}'s.

feature {NONE}

	queue: LINKED_QUEUE [PID]
			-- Used by `tabulate' and `objectify' to traverse an object structure
			-- by following references in breadth-first order.
			-- Declared as once to avoid adding an attribute, easing serializaion.
		once
			create Result.make
		end

	queued: HASH_TABLE [BOOLEAN, PID]
			-- Used by `tabulate' and `objectify' to help determine in O(1) time
			-- if an PID has been placed into the `queue'.
			-- Declared as once to avoid adding an attribute, easing serializaion.
		once
			create Result.make (Table_size)
		end

	visited: HASH_TABLE [ANY, PID]
			-- Used by `tabulate' and `objectify' to indicate that the object
			-- has been seen during the traversal of the structure.
			-- Declared as once to avoid adding an attribute, easing serializaion.
		once
			create Result.make (Table_size)
		end

invariant

	no_void_pids_in_queue: not queue.is_empty implies not queue.item.is_void

end

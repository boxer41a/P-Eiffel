note
	description: "[
		Features used by persistent systems that are required for classes
		other than just the {PERSISTENCE_MANAGER}.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PERSISTENCE_FACILITIES

feature -- Once features (globals)

	Persistence_manager: PERSISTENCE_MANAGER
			-- Provides a handle to persistence features and performs
			-- persistence-related operations
		once
			create Result
		end

	Handler: CALLBACK_HANDLER
			-- Handle to functions access the 64-bit persistent identifier
			-- in the header of objects.
		once
			create Result
		end

	Parser: PID_PARSER
			-- Handle to functions for manipulating PIDs
		once
			create Result
		end

	Internal: INTERNAL
			-- Handle to an {INTERNAL} for conveniece
		once
			create Result
		end

	Session_id: UUID
			-- An identifier for the current execution
		local
			gen: UUID_GENERATOR
		once
			create gen
			Result := gen.generate_uuid
		end

	repository: REPOSITORY
			-- The current data store on which objects will be persisted.
			-- Change with `set_repository'.
			-- The programmer must assign a repository before uing persistence.
		require
			is_repository_set: is_repository_set
		do
			check attached Repository_ref.item as r then
				Result := r
			end
		end

	Tabulation: TABULATION
			-- The data last passed between Current and the `repository'.
		once
			create Result
		end

feature -- Access

	persistence_id (a_object: ANY): PID
			-- Convinience feature, wrapping the call from `handler'.
		do
			Result := Handler.persistence_id_from_handler (a_object)
		end

	dynamic_type (a_object: ANY): INTEGER_32
			-- The dynamic type of Current as defined by the runtime.  (See
			-- INTERNAL and REFLECTED_OBJECT.)  This is an integer that is
			-- assigned to for a particular type during a session.  It can
			-- differ from one session to another.
		do
			Result := {ISE_RUNTIME}.dynamic_type (a_object)
		end

	persistent_type (a_object: ANY): PERSISTENT_TYPE
			-- The persistable representation (as a SHA-1 digest) of the type
			-- of `a_object'.
			-- This feature has a side effect of ensuring `is_type_mapped'
			-- true for `a_object'.
		do
			Result := persistent_type_from_dynamic_type (dynamic_type (a_object))
		ensure
			is_type_mapped: is_type_mapped_object (a_object)
		end

	type_descriptor (a_object: ANY): TYPE_DESCRIPTOR
			-- The descriptor for the type of `a_object'.
		require
			is_identified: is_persistable (a_object)
			is_known_type: is_type_mapped_object (a_object)
		do
			check attached Mapped_types.item_by_dynamic_type (dynamic_type (a_object)) as m then
				Result := m.td
			end
		end

feature -- Status report

	is_repository_set: BOOLEAN
			-- Has the user (i.e. programmer) made a call to `set_repository',
			-- establishing the location to with objects are to persist?
		do
			Result := attached repository_ref.item
		end

	is_persistable (a_object: ANY): BOOLEAN
			-- Is `a_object' automatically persistable?
			-- Yes if `a_object' has been paired with its `persistence_id' with
			-- a call to `identify' or upon loading from a {REPOSITORY}.
		do
			Result := is_identified_pid (persistence_id (a_object))
		end

	is_persistent (a_object: ANY): BOOLEAN
			-- Is `a_object' stored in the `repository'?
		local
			pid: PID
		do
			pid := Handler.persistence_id (a_object)
			if not pid.is_void then
				Result := repository.is_stored (pid)
			end
		end

	is_dirty (a_object: ANY): BOOLEAN
			-- Is `a_object' marked as changed?
		do
			Result := is_dirty_pid (Handler.persistence_id (a_object))
		end

	is_rootable (a_object: ANY): BOOLEAN
			-- Is `a_object', when persisted, stored as a persistent root?
		local
			pid: PID
		do
			pid := Handler.persistence_id (a_object)
			Result := Rooted_objects.has (pid)
		end

	is_persistent_root (a_object: ANY): BOOLEAN
			-- Has `a_object' been stored as a persitent root in the `repository'?
			-- If yes, then the persistent image of `a_object' (if any) on
			-- the `repository' will not be collected by the persistent
			-- garbage collector unless explicitly asked.
		local
			pid: PID
		do
			pid := Handler.persistence_id (a_object)
			Result := repository.is_stored_root (pid)
		end

	is_type_mapped_object (a_object: ANY): BOOLEAN
			-- Is the type of `a_object' recorded in the `mapped_types' table?
		do
			Result := mapped_types.has_dynamic_type (dynamic_type (a_object))
		end

	is_basic_object (a_object: ANY): BOOLEAN
			-- Is the type of `a_object' one of the basic types?
		do
			Result := basic_types.has ({ISE_RUNTIME}.dynamic_type (a_object))
		end

	is_special_object (a_object: ANY): BOOLEAN
			-- Is the type of `a_object' a SPECIAL?
		do
			Result := attached {SPECIAL [detachable ANY]} a_object
		end

	is_special_basic_object (a_object: ANY): BOOLEAN
			-- Is the type of `a_object' a SPECIAL [XX] where XX is
			-- one of the basic types?
		do
			Result := is_special_basic_type (persistent_type (a_object))
		end

	is_tuple_object (a_object: ANY): BOOLEAN
			-- Is the type of `a_object a TUPLE?
		do
			Result := attached {TUPLE} a_object
		end

--	is_non_basic_object (a_object: ANY): BOOLEAN
--			-- Is the type of `a_object' a reference and not `is_basic_object'
--			-- and not `is_special_basic_object'.
--		do
--			Result := not is_special_basic_object (a_object) and
--							not is_basic_object (a_object)
--		end

	is_expanded_object (a_object: ANY): BOOLEAN
			-- Is `a_object' expanded?
		local
			ro: REFLECTED_REFERENCE_OBJECT
		do
			create ro.make (a_object)
			Result := ro.is_expanded
		end

	is_identified_pid (a_pid: PID): BOOLEAN
			-- Is `a_pid' paired with some object during this session?
		do
			Result := Identified_objects.has (a_pid)
		end

	is_expanded_identified (a_index: INTEGER; a_pid: PID): BOOLEAN
			-- Has an object been paired as the `a_index'-th attribute of
			-- the object associated with `a_pid'?
		do
			Result := is_identified_pid (a_pid) and then
					expanded_links.has (create {PID}.make_as_attribute (a_index, a_pid))
		end

	is_dirty_pid (a_pid: PID): BOOLEAN
			-- Is the object associated with `a_pid' marked as dirty?
		require
			is_pid_identified: is_identified_pid (a_pid)
		do
			Result := Dirty_objects.has (a_pid)
		end

	is_basic_type (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_type' represent one of the basic types (e.g. BOOLEAN,
			-- INTEGER_32, REAL_64, CHARACTER_8, etc.)?
		do
			Result := a_type ~ Persistent_boolean_type or
						a_type ~ Persistent_Character_8_type or a_type ~ Persistent_character_32_type or
						a_type ~ Persistent_integer_8_type or a_type ~ Persistent_integer_16_type or
						a_type ~ Persistent_integer_32_type or a_type ~ Persistent_integer_64_type or
						a_type ~ Persistent_natural_8_type or a_type ~ Persistent_natural_16_type or
						a_type ~ Persistent_natural_32_type or a_type ~ Persistent_natural_64_type or
						a_type ~ Persistent_real_32_type or a_type ~ Persistent_real_64_type or
						a_type ~ Persistent_pointer_type
		end

	is_special_type (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_type' represent a type that is a SPECIAL [XX]?
		do
			Result := --a_type ~ special_pid_type or
						a_type ~ special_any_type or is_special_basic_type (a_type) or
						a_type ~ special_boolean_type or
						a_type ~ special_character_8_type or a_type ~ special_character_32_type or
						a_type ~ special_integer_32_type or a_type ~ special_integer_64_type or
						a_type ~ special_natural_8_type or a_type ~ special_natural_16_type or
						a_type ~ special_natural_32_type or a_type ~ special_natural_64_type or
						a_type ~ special_real_32_type or a_type ~ special_real_64_type or
						a_type ~ special_pointer_type
		end

	is_special_basic_type (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_type' represent a type for a SPECIAL [XX] where XX is a basic type
		do
			Result := a_type ~ special_boolean_type or
						a_type ~ special_character_8_type or a_type ~ special_character_32_type or
						a_type ~ special_integer_32_type or a_type ~ special_integer_64_type or
						a_type ~ special_natural_8_type or a_type ~ special_natural_16_type or
						a_type ~ special_natural_32_type or a_type ~ special_natural_64_type or
						a_type ~ special_real_32_type or a_type ~ special_real_64_type or
						a_type ~ special_pointer_type
		end

	is_special_reference_type (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_type' represent a type for a SPECIAL [XX] where XX
			-- is a reference type
		do
			Result := is_special_type (a_type) and not is_special_basic_type (a_type)
		end

	is_normal_type (a_type: PERSISTENT_TYPE): BOOLEAN
			-- Does `a_type' represent a type for an object that is not a
			-- basic type, a special, or a tuple?
		do
			Result := not is_basic_type (a_type) and not is_special_type (a_type)
							-- and not is_tuple_type (a_type)
		end

	is_recorded_dynamic_type (a_dynamic_type: INTEGER_32): BOOLEAN
			-- Is `a_dynamic_type' in the `mapped_types'?
		do
			Result := mapped_types.has_dynamic_type (a_dynamic_type)
		end

	is_recorded_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Is `a_persistent_type' mapped during this session?
		do
			Result := mapped_types.has_persistent_type (a_persistent_type)
		end

	is_persisted_type (a_persistent_type: PERSISTENT_TYPE): BOOLEAN
			-- Is `a_persistent_type' known to the `repository'?
			-- This feature does not ask the repository; it gets the
			-- answer from a TUPLE in the `Mapped_types' table.
		do
			Result := is_recorded_type (a_persistent_type) and then
				Mapped_types.item_by_persistent_type (a_persistent_type).is_per
		end

feature -- Query

	dynamic_type_from_pid (a_pid: PID): INTEGER_32
			-- The dynamic type of the object paired with `a_pid'
		require
			is_pid_paired_with_object: is_identified_pid (a_pid)
		local
			a: ANY
		do
			a := identified_object (a_pid)
			if attached {IDENTIFIABLE} a as e then
				Result := e.dynamic_type
			else
				Result := dynamic_type (a)
			end
		end

	persistent_type_from_pid (a_pid: PID): PERSISTENT_TYPE
			-- The type identifier for the type of the object that `is_paired'
			-- with `a_pid.
		require
			is_pid_paired_with_object: is_identified_pid (a_pid)
		do
			Result := persistent_type_from_dynamic_type (dynamic_type_from_pid (a_pid))
		end

	type_descriptor_from_pid (a_pid: PID): TYPE_DESCRIPTOR
			-- The descriptor for the type of `a_object' paired with `a_pid'
		require
			is_pid_paired_with_object: is_identified_pid (a_pid)
		local
			dt: INTEGER_32
		do
			dt := dynamic_type_from_pid (a_pid)
			check attached Mapped_types.item_by_dynamic_type (dt) as m then
				Result := m.td
			end
		end

	persistent_type_from_dynamic_type (a_dynamic_type: INTEGER_32): PERSISTENT_TYPE
			-- The persistent identification of `a_dynamic_type'.
			-- This will be the same in any system, because we "stringify" the
			-- `dynamic_type' then compute the {SHA_DIGEST} from that string.
			-- The format of the string is standard and the same in session.
			-- Asking for the `persistent_type' of an object with this feature
			-- causes Current's type to be `is_type_mapped'.
		do
				-- Memoization using `mapped_types'
			if not is_recorded_dynamic_type (a_dynamic_type) then
				Mapped_types.add_type (a_dynamic_type)
			end
			check
				type_is_recorded: is_recorded_dynamic_type (a_dynamic_type)
					-- because the type was already there or was just added
			end
			Result := Mapped_types.item_by_dynamic_type (a_dynamic_type).pt
		ensure
			result_exists: Result /= Void
			is_type_mapped: is_recorded_dynamic_type (a_dynamic_type)
		end

	type_descriptor_from_dynamic_type (a_dynamic_type: INTEGER): TYPE_DESCRIPTOR
			-- The information about the class identified [in this session]
			-- with `a_dynamic_type'.
		require
			is_valid_type_id: is_valid_dynamic_type (a_dynamic_type)
		do
				-- Memoization using `Type_map'
			if not is_recorded_dynamic_type (a_dynamic_type) then
				Mapped_types.add_type (a_dynamic_type)
			end
			check
				dynamic_type_is_recorded: is_recorded_dynamic_type (a_dynamic_type)
					-- because the type was either there or was just added
			end
			Result := mapped_types.item_by_dynamic_type (a_dynamic_type).td
		ensure
			result_exists: Result /= Void
			is_type_mapped: is_recorded_dynamic_type (a_dynamic_type)
		end

	type_descriptor_from_persistent_type (a_persistent_type: PERSISTENT_TYPE): TYPE_DESCRIPTOR
			-- The information about the class identified [in this session]
			-- with `a_persistent_type'
		require
			is_persistent_type_mapped: is_recorded_type (a_persistent_type)
		do
			Result := mapped_types.item_by_persistent_type (a_persistent_type).td
		end

	is_valid_dynamic_type (a_dynamic_type: INTEGER): BOOLEAN
			-- Does the application recognize, or know about, `a_dynamic_type'?
		do
			Result := a_dynamic_type >= 0 or a_dynamic_type = {INTERNAL}.none_type
				-- FIX ME!!  need more but do not know how to get past an
				-- SEGMENTAION FAULT thrown by {ISE_RUNTIME} when `a_type' is
				-- too big or unknown.
		end

feature -- Query

	identified_object (a_pid: PID): ANY
			-- The object associated with `a_pid'.
			-- If the result is a {IDENTIFIABLE}, the object is expanded.
		do
			check attached Identified_objects.item (a_pid) as tup then
				Result := tup.object
			end
		ensure
			is_expanded_result: attached {IDENTIFIABLE} Result
				 as ident implies ident.is_expanded
		end

feature -- Constants

	persistent_pid_type: PERSISTENT_TYPE
			-- The persistent store representation for the type of a PID,
			-- used for type checking when storing a persistent reference
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {PID}))
		end

	persistent_boolean_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {BOOLEAN}))
		end

	persistent_character_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {CHARACTER_8}))
		end

	persistent_character_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {CHARACTER_32}))
		end

	persistent_integer_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {INTEGER_8}))
		end

	persistent_integer_16_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {INTEGER_16}))
		end

	persistent_integer_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {INTEGER_32}))
		end

	persistent_integer_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {INTEGER_64}))
		end

	persistent_natural_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {NATURAL_8}))
		end

	persistent_natural_16_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {NATURAL_16}))
		end

	persistent_natural_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {NATURAL_32}))
		end

	persistent_natural_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {NATURAL_64}))
		end

	persistent_real_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {REAL_32}))
		end

	persistent_real_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {REAL_64}))
		end

	persistent_pointer_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {POINTER}))
		end

	persistent_void_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type ({INTERNAL}.none_type)	-- i.e. Void
		end

	special_boolean_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [BOOLEAN]}.make_empty (1)))
		end

	special_character_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [CHARACTER_8]}.make_empty (1)))
		end

	special_character_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [CHARACTER_32]}.make_empty (1)))
		end

	special_integer_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [INTEGER_8]}.make_empty (1)))
		end

	special_integer_16_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [INTEGER_16]}.make_empty (1)))
		end

	special_integer_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [INTEGER_32]}.make_empty (1)))
		end

	special_integer_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [INTEGER_64]}.make_empty (1)))
		end

	special_natural_8_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [NATURAL_8]}.make_empty (1)))
		end

	special_natural_16_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [NATURAL_16]}.make_empty (1)))
		end

	special_natural_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [NATURAL_32]}.make_empty (1)))
		end

	special_natural_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [NATURAL_64]}.make_empty (1)))
		end

	special_real_32_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [REAL_32]}.make_empty (1)))
		end

	special_real_64_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [REAL_64]}.make_empty (1)))
		end

	special_pointer_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [POINTER]}.make_empty (1)))
		end

	special_any_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [ANY]}.make_empty (1)))
		end

	special_pid_type: PERSISTENT_TYPE
		once
			Result := persistent_type_from_dynamic_type (dynamic_type (create {SPECIAL [PID]}.make_empty (1)))
		end

	show_facilities
			-- Conditionally print (see `io.put_string') the hash tables, showing the
			-- state of the global structures.
		local
			id_tup: like identified_objects.item_for_iteration
--			ex_tup: like expanded_objects.item_for_iteration
			map_tup: like Mapped_types.item_for_iteration
			pid: PID
		do
--			io.put_string ("  ---- > Identified_objects:     <-----%N")
--			from identified_objects.start
--			until identified_objects.after
--			loop
--				id_tup := identified_objects.item_for_iteration
--				io.put_string (identified_objects.key_for_iteration.out + "%N")
--				io.put_string ("---")
--				io.put_string (id_tup.object.out)
--				io.put_string ("--- %N")
--				identified_objects.forth
--			end
--			io.put_string ("  ---- > Expanded_objects:     <-----%N")
--			from Expanded_objects.start
--			until Expanded_objects.after
--			loop
--				ex_tup := Expanded_objects.item_for_iteration
--				io.put_string (Expanded_objects.key_for_iteration.out + "%N")
--				io.put_string ("---")
--				io.put_string (ex_tup.ro.object.out)
--				io.put_string ("--- %N")
--				identified_objects.forth
--			end
--			io.put_string ("  -----> Dirty_objects:     <-----%N")
--			from Dirty_objects.start
--			until Dirty_objects.after
--			loop
--				pid := Dirty_objects.key_for_iteration
--				io.put_string (pid.out + "%N")
----				check attached Identified_objects.item (pid) as v then
----					io.put_string (v.out)
----				end
--				Dirty_objects.forth
--			end
			io.put_string ("  ---- > Mapped_types:     <-----%N")
			io.put_string ("          " + Mapped_types.count.out + "  items %N")
			from Mapped_types.start
			until Mapped_types.after
			loop
				map_tup := Mapped_types.item_for_iteration
				io.put_string ("---")
				map_tup.td.show
				Mapped_types.forth
			end
		end


feature {NONE} -- Implementation

	Repository_ref: REPOSITORY_REF
			-- A once object holding a reference to a REPOSITORY, from which
			-- new persistent identifiers are obtained.
			-- The default is set to a default {LOCAL_REPOSITORY}; changed
			-- by calling `set_repository'.
		once
			create Result
		end

	Basic_types: HASH_TABLE [BOOLEAN, INTEGER]
			-- Table used to determine if `is_basic_object'.
		once
			create Result.make (14)
			Result.extend (True, ({INTEGER_8}).type_id)
			Result.extend (True, ({INTEGER_16}).type_id)
			Result.extend (True, ({INTEGER_32}).type_id)
			Result.extend (True, ({INTEGER_64}).type_id)
			Result.extend (True, ({NATURAL_8}).type_id)
			Result.extend (True, ({NATURAL_16}).type_id)
			Result.extend (True, ({NATURAL_32}).type_id)
			Result.extend (True, ({NATURAL_64}).type_id)
			Result.extend (True, ({REAL_32}).type_id)
			Result.extend (True, ({REAL_64}).type_id)
			Result.extend (True, ({CHARACTER_8}).type_id)
			Result.extend (True, ({CHARACTER_32}).type_id)
			Result.extend (True, ({BOOLEAN}).type_id)
			Result.extend (True, ({POINTER}).type_id)
		end

feature {NONE} -- Invariant support

	has_identifier_mismatch: BOOLEAN
			-- Do any of the keys in `Identified_objects' NOT match
			-- the `persistence_id' of the object with which it is paired?
		local
			c: CURSOR
			a: ANY
			pid: PID
		do
			c := Identified_objects.cursor
			from Identified_objects.start
			until Identified_objects.after or not Result
			loop
				a := Identified_objects.item_for_iteration
				pid := Identified_objects.key_for_iteration
				if attached {IDENTIFIABLE} a as i then
					Result := i.persistence_id ~ pid
				else
					Result := persistence_id (a) ~ pid
				end
				Identified_objects.forth
			end
			Identified_objects.go_to (c)
		end

feature {NONE} -- Implementation

	Identified_objects: HASH_TABLE [TUPLE [object: ANY; type: PERSISTENT_TYPE], PID]
			-- Each item indexed by a {PID} contains the associated object and
			-- the [persistent_type] of that object.
		once
			create Result.make (Table_size)
		end

	Expanded_links: EXPANDED_LINKS_TABLE
			-- Each item in this table is the key into the `Identified_objects'
			-- table; each key in this table is the persistent representation
			-- of a an attribute of some object.  Identification of expanded
			-- objects requires this two-level indirection because of the copy
			-- semantics of expanded objects.
			-- Feature `identify' from {PERSISTENT_MANAGER} is never called for
			-- an expanded object.
		once
			create Result.make (Table_size)
		end

	Rooted_objects: HASH_TABLE [BOOLEAN, PID]
			-- Each key is the identifier of an object that is known to be
			-- a "persistent root".  A {PERSISTABLE} object is always a root,
			-- as is any object persisted by an explicit (i.e. non-automatic)
			-- call to `persist_as_root'.
			-- A persistent root is never deleted by the persistent garbage
			-- collector of a {REPOSITORY}; a persistent root must be explicitly
			-- deleted by a database manager program or a specific call.  Call
			-- `persist_as_root' to promote an object to a "persistent root".
		once
			create Result.make (Table_size)
		end

	Dirty_objects: HASH_TABLE [BOOLEAN, PID]
			-- Objects that have been marked as dirty.
		once
			create Result.make (Table_size)
		end

	Mapped_types: TYPE_MAPPING
			-- A three-way map between the `dynamic type', `persistent type',
			-- and the {TYPE_DESCRIPTOR} of some types used in this system.
			-- Determine if a type is mapped with the query `is_recorded_type'.
		local
			a: ANY
		once
			create Result.make (Table_size)
--			create a
--			Result.add_type ({ISE_RUNTIME}.dynamic_type (a))
		end

	Table_size: INTEGER_32 = 0
			-- Used to initialize all the hash tables in the
			-- peristence-related classes.

invariant

	all_id_consistent: not has_identifier_mismatch

end

note
	description: "[
		Provides the means through which a system interfaces with
		the underlying persistence mechanism.  Responsible for scheduling
		persistence operations and ...?
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PERSISTENCE_MANAGER

inherit

	PERSISTENCE_FACILITIES

create
	default_create

feature -- Constansts

	No_automation: INTEGER_32 = 1
			-- No automatic persistence

	Marking_dirty: INTEGER_32 = 2
			-- Automatically mark persistable objects dirty when modified.

	Persisting_automatic: INTEGER_32 = 3
			-- Automatically mark persistable objects dirty when modified and
			-- automatically `persist' persistable objects after a qualified
			-- feature calls on that object.

feature -- Access

	persistence_level: INTEGER_32
			-- Shows the amount of persistence automation.
			-- One of `No_automation', `Marking_dirty', or `persisting_automatic'.
		do
			Result := persistence_level_imp.item
		end

feature -- Element change

	set_persistence_level (a_level: INTEGER_32)
			-- Set the amount of automation (none, mark dirty, persist automatic)
			-- based on `a_level'.  The constants are above.
		require
			level_big_enough: a_level >= No_automation
			level_small_enough: a_level <= persisting_automatic
		do

			persistence_level_imp.set_item (a_level)
			if a_level = No_automation then
				Handler.disable_callbacks
			else
				Handler.enable_callbacks
			end
		end

	set_repository (a_repository: like repository)
			-- Change the `repository' to `a_repository'.
			-- The `persistent_identifiers' that were assigned from the old
			-- `repository' are no longer valid and must be removed.
		require
			can_recognize_types: can_recognize_types (a_repository)
		local
			arr: ARRAYED_LIST [ANY]
			b: BOOLEAN
		do
				-- Because the new factory could produce a `next_pid' that is
				-- the same as one used by the old factory, we must wipe out
				-- the tables before calling `unidentify' on any object; feature
				-- `unidentify' might be redefined to re-identify the object
				-- (e.g. in the {PERSISTABLE} class ?).
			if attached repository_ref.item and then a_repository /= repository then
				b := {ISE_RUNTIME}.check_assert (false)
				arr := identified_objects.linear_representation
				identified_objects.wipe_out
				from arr.start
				until arr.after
				loop
--					id := arr.item.on_unidentify
					arr.forth
				end
				b := {ISE_RUNTIME}.check_assert (b)
			end
			repository_ref.set_item (a_repository)
			map_repository_types
		ensure
			repository_was_set: is_repository_set
			repository_set_correctly: attached repository_ref.item and then repository_ref.item = a_repository
		end

	map_repository_types
			-- Ensure each type in the `repository' is added to `mapped_types'.
		local
			td_tab: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			td: TYPE_DESCRIPTOR
			dt: INTEGER
			r: REFLECTOR
		do
			create r
			td_tab := repository.known_types
			from td_tab.start
			until td_tab.after
			loop
				if not is_recorded_type (td_tab.key_for_iteration) then
					td := td_tab.item_for_iteration
					dt := r.dynamic_type_from_string (td.name)
					add_type_mapping (dt, td.type, td, true)
				end
				td_tab.forth
			end
io.put_string ("--------------------------%N")
io.put_string ("     at end of PERSISTENCE_MANAGER.map_repository_types %N")
			show_facilities
		end

feature -- Status report

	is_marking_dirty: BOOLEAN
			-- Is the persistence mechanism marking objects as dirty when
			-- an attribute of that object changes?
			-- Enable with `set_mark_automatic' or `set_persist_automatic' and disable
			-- with `set_manual'.
		do
			Result := persistence_level >= Marking_dirty
		end

	is_persisting_automatic: BOOLEAN
			-- Was the automatic persistence mechanism enabled?
			-- Enable with `set_persist_automatic' and disable with `set_manual'.
			-- If this feature is true and the system has been compiled with
			-- the persistence-enabled compiler, then an object will be marked
			-- as dirty after one of that object's attributes has changed and
			-- it will be automatically persisted after creation and whenever
			-- it has been the target of a qualified feature call.
		do
			Result := persistence_level >= persisting_automatic
		end

feature -- Status setting

	set_manual
			-- Turn all automatic persistent off.
		do
			set_persistence_level (No_automation)
		ensure
			definition: persistence_level = No_automation
			not_marking_auto: not is_marking_dirty
			not_fully_auto: not is_persisting_automatic
		end

	set_mark_dirty
			-- Make the persistence mechanism mark objects as dirty, but not
			-- automatically store them.
		do
			set_persistence_level (Marking_dirty)
		ensure
			definition: persistence_level = Marking_dirty
			is_marking_auto: is_marking_dirty
			not_fully_auto: not is_persisting_automatic
		end

	set_persist_automatic
			-- Make the persistence mechanism automaticly store dirty,
			-- persitable objects.
		do
			set_persistence_level (persisting_automatic)
		ensure
			definition: persistence_level = persisting_automatic
			is_marking_auto: is_marking_dirty
			is_fully_auto:  is_persisting_automatic
		end

--	unidentify (a_pid: PID): PID
--			-- Most likely, the only reason to call this feature is if the `pid_factory'
--			-- was changed in which case the `persistent_id' for Current is not valid;
--			-- but because Current must always have a `persistent_id' that is not zero,
--			-- it must be reidentified on the new `pid_factory'.  This implementation
--			-- temporarily violates the invaraint, but restores it before exit.
--			-- Returns the new `pid'.
--			-- Copied here just in case I need it.  After unidentifying a {PERSISTABLE}
--			-- it must be reidentified to maintain its invariant.
--		local
--			b: BOOLEAN
--		do
--				-- Violate Precursor's post-condition, because `persistent_id' is wrong
--			b := {ISE_RUNTIME}.check_assert (false)
--			Result := Precursor
--			Result := on_identify
--			b := {ISE_RUNTIME}.check_assert (b)
--		end

feature -- Query

	can_recognize_types (a_repository: REPOSITORY): BOOLEAN
			-- Does Current know about all types stored in `repository'?
			-- Used as precondition to `set_repository'.
		local
			des: HASH_TABLE [TYPE_DESCRIPTOR, PERSISTENT_TYPE]
			tup: TUPLE [dt: INTEGER; pt: PERSISTENT_TYPE; td: TYPE_DESCRIPTOR]
			repo_td, mapped_td: TYPE_DESCRIPTOR
			repo_pt, mapped_pt: PERSISTENT_TYPE
		do
			Result := true
			des := a_repository.known_types
			from des.start
			until des.after or not Result
			loop
				repo_td := des.item_for_iteration
				repo_pt := des.key_for_iteration
				if mapped_types.has_persistent_type (repo_pt) then
					tup := mapped_types.item_by_persistent_type (repo_pt)
					mapped_td := tup.td
					mapped_pt := tup.pt
					if not (repo_td ~ mapped_td) then
						Result := false
					end
				end
				des.forth
			end
		end

feature -- Basic operations

	mark (a_object: ANY)
			-- Mark `a_object' as "dirty".
		require
			not_basic: not is_basic_object (a_object)
			not_expanded: not is_expanded_object (a_object)
		local
			pid: PID
		do
				-- Ignore expanded objects, because asking for a `persistent_id'
				-- would pass in a copy, which would never be found in the table.
				-- Instead, `tabulate' (from {TABULATION}) always assumes an
				-- expanded object encountered during traversal is dirty and
				-- adds that object to the traversal queue.
			if not is_persistable (a_object) then
				identify (a_object)
			end
			pid := Handler.persistence_id (a_object)
			Dirty_objects.force (true, pid)
		end

	persist (a_object: ANY)
			-- Write `a_object' to the `repository'.
			-- Objects that do not inherit from {PERSISTABLE} are subject to
			-- [persistent] garbage collection.  To make any `a_object' not
			-- subject to collection, use `persist_as_root' instead, which
			-- promotes that object to a "persistent root".
			-- Remove a "persistent root' by calling `unpersist'.
			-- If `a_object' is not yet auto-persistable then `identify'
			-- `a_object' before writing it to the `repository'.
		require
			not_expanded: not is_expanded_object (a_object)
			not_basic: not is_basic_object (a_object)
		local
			pid: PID
			b: BOOLEAN
		do
			b := Handler.is_callbacks_disabled
			Handler.disable_callbacks
			if not is_persistable (a_object) then
				identify (a_object)
			end
				-- Ensure the object is marked dirty, in case this
				-- feature was called manually.
			pid := Handler.persistence_id (a_object)
			Dirty_objects.force (true, pid)
				-- Tabulate the object.
			Tabulation.wipe_out
			Tabulation.tabulate (a_object)
--			io.put_string (Tabulation.out)
--			repository.store_types (Tabulation.relationships)
			repository.store (Tabulation)
--repository.show
			if not b then
				Handler.enable_callbacks
			end
		end

	persist_as_root (a_object: ANY)
			-- Same as `persist' but promotes `a_object' to a "persistent root".
		require
			not_expanded: not is_expanded_object (a_object)
			not_basic: not is_basic_object (a_object)
		do
			persist (a_object)
			Rooted_objects.force (True, Handler.persistence_id (a_object))
		end

	checkpoint
			-- Persist all dirty objects.
		local
			pid: PID
		do
				-- Startint with a clean slate...
			Tabulation.wipe_out
				-- repeat until there a no more `Dirty_objects'.  (Remember,
				-- `tabulate' removes items from `Dirty_objects'.)
			from Dirty_objects.start
			until Dirty_objects.is_empty
			loop
					-- Prepare `Tabulation' to receive more data.
				Tabulation.reset
				pid := Dirty_objects.key_for_iteration
				check attached Identified_objects.item (pid) as tup then
						-- Skip expanded objects.
					if attached {IDENTIFIABLE} tup.object as ident then
						check
							expanded_object_found: ident.is_expanded
								-- because non-expanded objects are not wrapped
						end
						Dirty_objects.forth
					else
							-- Store a non-expanded object.
						persist (tup.object)
						Dirty_objects.start
					end
				end
			end
		end

	loaded (a_pid: PID): ANY
			-- Retrieve the object that was persistently associated with
			-- `a_pid' from the current `repository'.
		require
-- ? do I need this?			not_attribute_pid: not a_pid.is_attribute
			is_stored: repository.is_stored (a_pid)
		local
			t: TABULATION
			lev: INTEGER_32
		do
			lev := persistence_level
			set_persistence_level (No_automation)
			t := repository.loaded (a_pid)
				-- Build objects into a temporary table.  If all goes well
				-- overwrite any existing objects, putting into Identified.
			Result := t.objectify (a_pid)
			set_persistence_level (lev)
		ensure
			pid_is_paired: is_identified_pid (a_pid)
			is_identified: Identified_objects.has (a_pid)
			correct_object: identified_object (a_pid) = Result
		end

	loaded_by_type (a_type: PERSISTENT_TYPE): LINKED_LIST [JJ_PROXY]
			-- Get a list of proxies to all objects in the `repository'
			-- that are the same type as `a_type'.
		require
			is_mapped_type: is_recorded_type (a_type)
		local
			lev: INTEGER_32
			ids: LINKED_LIST [PID]
			p: JJ_PROXY
		do
io.put_string (generating_type + ".loaded_by_type:  ")
io.put_string ("Looking in Mapped_type for  " + Mapped_types.item_by_persistent_type (a_type).td.name + "%N")
				-- Ensure the repository knows about `a_type'
			if not repository.is_known_type (a_type) then
				repository.store_descriptor (type_descriptor_from_persistent_type (a_type))
			end
			create Result.make
			lev := persistence_level
			set_persistence_level (No_automation)
			ids := repository.identifiers_for_type (a_type)
				-- Now create the proxies
			from ids.start
			until ids.exhausted
			loop
				create p.make (ids.item)
				Result.extend (p)
				ids.forth
			end
			set_persistence_level (lev)
		end

	query_repository (a_query: STRING_8): LINKED_LIST [ANY]
			-- Parse and execute an SQL query.
-- fix me
		do
			create Result.make
		end

feature -- Basic operations

	add_type_mapping (a_dynamic_type: INTEGER; a_persistent_type: PERSISTENT_TYPE;
						a_descriptor: TYPE_DESCRIPTOR; a_flag: BOOLEAN)
			-- Create an association between the three arguments.
		do
			Mapped_types.extend ([a_dynamic_type, a_persistent_type, a_descriptor, a_flag])
		end

	map_dynamic_type (a_dynamic_type: INTEGER)
			-- Add a mapping from `a_dynamic_type' (can change between sessions)
			-- to the correspoonding persistent type and string representation
			-- of the types.
			-- This feature should be called the first time the persistent
			-- mechanism encounters a new type for some object.
		require
			not_mapped: not is_recorded_dynamic_type (a_dynamic_type)
		local
			td: TYPE_DESCRIPTOR
		do
				-- Creating a {TYPE_DESCRIPTOR} maps its type;
				-- see {TYPE_DESCRIPTOR}.`initialize'.
--			create td.make (a_dynamic_type)
			Mapped_types.add_type (a_dynamic_type)
		ensure
			is_mapped: is_recorded_dynamic_type (a_dynamic_type)
			has_dynamic_type: Mapped_types.has_dynamic_type (a_dynamic_type)
			has_persistent_type: Mapped_types.has_persistent_type (persistent_type (a_dynamic_type))
		end

	identify (a_object: ANY)
			-- Ensures `a_object' is associated with a PID for reverse lookup.
		require
			not_basic: not is_basic_object (a_object)
			not_expanded: not is_expanded_object (a_object)
			not_identified: not is_persistable (a_object)
			not_reflected: not attached {REFLECTED_OBJECT} a_object
		local
			pt: PERSISTENT_TYPE
			pid, pid2: PID
		do
			pt := persistent_type (a_object)
			if Handler.persistence_id (a_object).is_void then
				Handler.set_persistence_id (a_object, repository.next_pid)
			end
--			Dirty_objects.force (true, Handler.persistence_id (a_object))
			check
				not_already_identified: not is_already_identified (a_object)
					-- because we should not attempt to add an object to `Identfied_objects'
					-- if it is already in the table.  This check was added as a debugging
					-- aid, becasue somewhere the `persistence_id' of some objects seem to
					-- get reset to zero (or some other value), in which case the pre-
					-- conditions are not enough to detect the violation.
			end
			pid := Handler.persistence_id (a_object)
			Identified_objects.extend ([a_object, pt], pid)
			pid2 := Handler.persistence_id (a_object)
			check
				same_id: pid ~ pid2
			end
		ensure
			not_void_id: not Handler.persistence_id (a_object).is_void
			is_identified: is_persistable (a_object)
--			is_dirty: Dirty_objects.has (Handler.persistence_id (a_object))
		end

	identify_expanded (a_reflected: IDENTIFIABLE; a_index: INTEGER_32; a_pid: PID)
			-- Associate the expanded object enclosed in `a_reflected' with the `a_index'-th
			-- field of the object associated with `a_pid'.
		require
			is_expanded: a_reflected.is_expanded
			parent_identified: is_identified_pid (a_pid)
			not_pid_assigned: a_reflected.persistence_id.is_void
			index_big_enough: a_index >= 1
			index_small_enough: a_index <= type_descriptor_from_pid (a_pid).field_count
		local
			pt: PERSISTENT_TYPE
			id: PID
		do
			pt := persistent_type (a_reflected.object)
			check
				not_yet_identified: a_reflected.persistence_id.is_void
					-- because of precondition
			end
			a_reflected.set_persistence_id (repository.next_pid)
			id := a_reflected.persistence_id
			Identified_objects.extend ([a_reflected, pt], id)
--			Expanded_objects.extend ([a_reflected, pt], id)
			Expanded_links.extend (id, create {PID}.make_as_attribute (a_index, a_pid))
		ensure
			pid_assigned: not a_reflected.persistence_id.is_void
			is_expanded_identified: is_expanded_identified (a_index, a_pid)
		end

feature {NONE} -- Implementation

	persistence_level_imp: INTEGER_32_REF
			-- The `persistence_level' is the same throughout.
		once
			create Result
			Result.set_item (No_automation)
		end

	is_already_identified (a_object: ANY): BOOLEAN
			-- Has `a_object' already been placed into `Identified_objects'?
			-- This is only used as an assertion check in `identify' for debugging.
			-- It performs a sequential search of the table for `a_object'.
		do
			from Identified_objects.start
			until Identified_objects.after or Result
			loop
				Result := Identified_objects.item_for_iteration = a_object
				Identified_objects.forth
			end
		end

feature -- Testing support

	wipe_out
			-- Clean all the tables, so `loaded' can be tested.
		do
			Identified_objects.wipe_out
			Expanded_links.wipe_out
			Rooted_objects.wipe_out
			Dirty_objects.wipe_out
			Mapped_types.wipe_out
			Tabulation.wipe_out
		end

end

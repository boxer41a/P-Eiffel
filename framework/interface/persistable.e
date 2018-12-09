note
	description: "[
		This class can be used as ancestor to classes that should
		be automaticly persistable and should be seen as persistent
		roots on a {REPOSITORY}.
		
		A {PERSISTABLE} always has an associated `persistent_id', allowing
		some persistence operations to operate in O(1) time.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PERSISTABLE

inherit

	PERSISTENCE_FACILITIES
		rename
			persistence_id as persistence_id_from_facilities,
			is_persistable as is_persistable_from_facilities,
			is_persistent as is_persistent_from_facilities,
			is_dirty as is_dirty_from_facilities,
			is_rootable as is_rootable_from_facilities,
			is_persistent_root as is_persistent_root_from_facilities
		redefine
			default_create
		end

create
	default_create,
	load

feature {NONE} -- Initialization

	default_create
			-- Create an instance.
		local
			pid: PID
		do
			if Persistence_manager.is_marking_dirty then
				Persistence_manager.mark (Current)
			else
				Persistence_manager.identify (Current)
			end
			pid := Handler.persistence_id (Current)
			Rooted_objects.extend (true, pid)
		ensure then
			id_big_enough: not persistence_id.is_void
			is_identified: is_persistable
--			is_dirty: is_dirty
			is_rooted: is_rootable
		end

feature -- Access

	persistence_id: PID
			-- Convience feature to get the identifer of Current,
			-- allowing a qualified call.
		do
			Result := persistence_id_from_facilities (Current)
		end

feature -- Status Report

	is_persistable: BOOLEAN
			-- Is Current automatically persistable?  Yes!
			-- Convinience feature, corresponding to feature `is_persistable'
			-- from {PERSISTENCE_FACILITIES} but taking no argument.
		do
			Result := true
		ensure
			true_by_definition: Result
		end

	is_persistent: BOOLEAN
			-- Is `a_object' stored in the `repository'?
			-- Convinience feature, corresponding to feature `is_persistent'
			-- from {PERSISTENCE_FACILITIES} but taking no argument.
		do
			Result := is_persistent_from_facilities (Current)
		end

	is_dirty: BOOLEAN
			-- Is Current marked as dirty?
			-- Convenience feature, wrapping the corresponding
			-- feature from {PERSISTENCE_FACILITIES}.
		do
			Result := is_dirty_from_facilities (Current)
		end

	is_rootable: BOOLEAN
			-- Is Current marked to be store as a persistence root?
			-- Convenience feature, wrapping the corresponding
			-- feature from {PERSISTENCE_FACILITIES}.
		do
			Result := is_rootable_from_facilities (Current)
		end

	is_persistent_root: BOOLEAN
			-- Has `a_object' been stored as a persitent root in the `repository'?
			-- Convinience feature, corresponding to feature `is_persistent_root'
			-- from {PERSISTENCE_FACILITIES} but taking no argument.
		do
			Result := is_persistent_root_from_facilities (Current)
		end

feature -- Basic operations

	persist
			-- Convience feature to persist Current onto the `repository'.
		do
			Persistence_manager.persist (Current)
		ensure
			is_persistent: is_persistent
		end

	restore
			-- Using Current's `persistence_id', load the last persistent
			-- image of Current from the `repository'.
		require
			is_persistent: is_persistent
		do
			load (persistence_id)
		end

	load (a_pid: PID)
			-- Initialize Current from the persistent object associated
			-- with `a_pid' that is stored in the `repository'
		require
			is_pid_persistent: repository.is_stored (a_pid)
			same_type: repository.stored_type (a_pid) ~ persistent_type (Current)
		do
			check attached {like Current} Persistence_manager.loaded (a_pid) as p then
				copy (p)
			end
		end

invariant

	is_automatically_persitable: is_persistable

end

note
	description: "[
		A handler for callbacks from the C runtime into Eiffel code.
		The basic idea for this class was provided by Roman Schmocker along
		with a patch to the runtime.  The patch allows this class to call
		features from the persistence cluster after a creation call, a
		qualified feature call, or an assignment statement.
		]"
	author: "Roman Schmocker"
	date: "$Date$"
	revision: "$Revision$"

class
	CALLBACK_HANDLER

inherit

	PERSISTENCE_FACILITIES

feature -- Access

	persistence_id_from_handler (a_object: ANY): PID
			-- The persistence ID of `a_object' as stored in the object's header.
		require
			not_expanded_type: not is_expanded_object (a_object)
		local
			n: NATURAL_64
		do
				-- Note: Do not precompute the pointer to `a_object'.
			n := c_persistence_id ($a_object)
			create Result.make_from_value (n)
		end

feature {PERSISTENCE_MANAGER, TABULATION} -- Basic operations

	set_persistence_id (a_object: separate ANY; a_id: PID)
			-- Set the persistence ID of `a_object' to `a_id'.
		require
			not_attribute: not a_id.is_attribute
		local
			n: NATURAL_64
		do
			n := a_id.item
				-- Note: Do not precompute the pointer to `a_object'.
			c_set_persistence_id ($a_object, n)
		ensure
			id_was_set: persistence_id (a_object) ~ a_id
		end

	enable_callbacks
			-- Register the current object as the callback handler.
		do
			is_callbacks_disabled := false
			c_register_handler ($Current, $c_execute_callback)
		end

	disable_callbacks
			-- Remove the callback hanlder, if any.
		local
			null_pointer: POINTER
		do
			c_register_handler (null_pointer, null_pointer)
			is_callbacks_disabled := true
		end

feature {NONE} -- Constants

	assignment_performed: INTEGER = 1
			-- Constant that the modified runtime passes to `execute_callback'
			-- after executing an assignment statement.
			-- Mirrors EIF_AP_DIRTY from "eif_portable.h".

	feature_called: INTEGER = 2
			-- Constant that the modified runtime passes to `execute_callback'
			-- after executing a qualifie feature call.
			-- Mirrors EIF_AP_QUALIFIED_CALL from "eif_portable.h".

	object_created: INTEGER = 3
			-- Constant that the modified runtime passes to `execute_callback'
			-- after executing a creation statement.
			-- Mirrors EIF_AP_CREATION from "eif_portable.h".

feature {PERSISTENCE_MANAGER} -- Status report

	is_callbacks_disabled: BOOLEAN
			-- Set with `disable_callbacks' to prevent callbacks while inside
			-- the callback functions `on_modified' and `on_targeted'.

feature {NONE} -- Basic operations

	on_modified (a_object: ANY)
			-- Mark `a_object' as "dirty" if it is automatically persistable.
			-- Technically, an object becomes automatically persistable when
			--`identify' has been called with that object.  Logically, an
			-- object is automatically persistable if its generating class
			-- inherits from {PERSISTABLE} or if it is reachable from some
			-- other automatically persistable object.
			-- When `is_markking_automatic', this feature is automatically called
			-- after an assignment statement targets an attribute of `a_object'.
		require
			not_basic: not is_basic_object (a_object)
			not_expanded: not is_expanded_object (a_object)
			callbacks_enabled: not is_callbacks_disabled
		local
			pid: PID
		do
				-- Ignore expanded objects, because asking for a `persistent_id'
				-- would pass in a copy, which would never be found in the table.
				-- Instead, `tabulate' (from {TABULATION}) always assumes an
				-- expanded object encountered during traversal is dirty and
				-- adds that object to the traversal queue.
			if Persistence_manager.is_marking_dirty then
				disable_callbacks
				pid := persistence_id_from_handler (a_object)
				if not pid.is_void then
						-- The following bypasses a few feature calls by not calling
						-- the versions from the `Persistence_manager'.
					Dirty_objects.force (true, pid)
				end
				enable_callbacks
			end
		end

	on_targeted (a_object: ANY)
			-- `Persist' `a_object' if it is automatically persistable.
			-- Technically, an object becomes automatically persistable when
			--`identify' has been called with that object.  Logically, an
			-- object is automatically persistable if its generating class
			-- inherits from {PERSISTABLE} or if it is reachable from some
			-- other automatically persistable object.
			-- When `is_persisting_automatic', this feature is automatically called
			-- after any qualified feature call with `a_object' as target of the call.
		require
			not_basic: not is_basic_object (a_object)
			not_expanded: not is_expanded_object (a_object)
			callbacks_enabled: not is_callbacks_disabled
		local
			pid: PID
		do
			if Persistence_manager.is_persisting_automatic then
				disable_callbacks
				pid := persistence_id_from_handler (a_object)
				if not pid.is_void then
					Persistence_manager.persist (a_object)
				end
				enable_callbacks
			end
		end

	execute_callback (a_object: ANY; a_task: INTEGER)
			-- Perform a callback.
		do
			if not is_basic_object (a_object) and not is_expanded_object (a_object) then
				inspect a_task
				when assignment_performed then
					on_modified (a_object)
				when feature_called then
					on_targeted (a_object)
				when object_created then
					on_targeted (a_object)
				else
					do_nothing
				end
			end
		end

feature {NONE} -- C externals

	frozen c_execute_callback (a_object: detachable ANY; a_task: INTEGER)
			-- Entry point for Eiffel, called by the C side.
			--| Note: Dynamic binding is probably broken when called from C,
			--| that's why the feature is marked as frozen.
		do
			if attached a_object then
				execute_callback (a_object, a_task)
			else
				print ("Error in {CALLBACK_HANDLER.`c_execute_callback'")
			end
		end

	frozen c_register_handler (a_handler: POINTER; a_feature: POINTER)
			-- C external to register a callback handler.
		external
			"C inline"
		alias
			"eif_auto_persistence_init ($a_handler, $a_feature)"
		end

feature {IDENTIFIABLE} -- Implementation

	frozen c_persistence_id (a_object: POINTER): NATURAL_64
			-- C external for the SCOOP region ID of an object.
		external
			"C inline"
		alias
			"return HEADER($a_object)->ov_head.ovu.ovs.persistence_id"
		end

	frozen c_set_persistence_id (a_object: POINTER; a_id: NATURAL_64)
			-- C external to set the persistence ID of an object.
		external
			"C inline"
		alias
			"HEADER($a_object)->ov_head.ovu.ovs.persistence_id = $a_id"
		end

end

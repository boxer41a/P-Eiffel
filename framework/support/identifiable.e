note
	description: "[
		Encapsulates an object for placement into the `Identified_objects'.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	IDENTIFIABLE

inherit

	PERSISTENCE_FACILITIES
		rename
			persistence_id as persistence_id_from_facilities,
			dynamic_type as facilities_dynamic_type
		end

	REFLECTED_OBJECT
		redefine
			copy_semantics_field,
			special_copy_semantics_item
		end

feature -- Access

	persistence_id: PID
			-- The persistence identifier assigned to the object
			-- that is enclosed in Current.
		local
			c: BOOLEAN
			n: NATURAL_64
		do
			c := {MEMORY}.collecting
			{MEMORY}.collection_off
			n := {CALLBACK_HANDLER}.c_persistence_id (object_address)
			if c then
				{MEMORY}.collection_on
			end
			create Result.make_from_value (n)
		end

	copy_semantics_field (i: INTEGER): COPY_SEMANTICS_IDENTIFIABLE
			-- Object attached to the `i'-th field of `object'
			-- (directly or through a reference).
			-- Field (i) must be a reference_type and `is_copy_semantics_field'.
		deferred
		end

	special_copy_semantics_item (i: INTEGER): COPY_SEMANTICS_IDENTIFIABLE
			-- Object attached to the `i'th item of special.
			-- Redefined to change type to an {IDENTIFIABLE}.
		do
				-- Don the same as in REFLECTED_OBJECT
			create Result.make_special (twin, i)
		end

	expanded_field (i: INTEGER): IDENTIFIABLE
			-- Object representation of the `i'-th field of `object'
			-- which is expanded. We provide a wrapper that enables
			-- direct editing of the field without duplicating
			-- the expanded object.
			-- Must not be `is_special' and field (i) must be an `expanded_type'
		deferred
		end

feature -- Element change

	set_persistence_id (a_pid: PID)
			-- Assign `a_pid' to the persistence_id header of the enclosed object.
			-- This calls the C routines, passing the address of the enclosed object,
			-- so it should work for an enclosed expanded object.
		require
			not_identified: not is_identified_pid (persistence_id)
		local
			c: BOOLEAN
		do
			c := {MEMORY}.collecting
			{MEMORY}.collection_off
			{CALLBACK_HANDLER}.c_set_persistence_id (object_address, a_pid.item)
			if c then
				{MEMORY}.collection_on
			end
		ensure
			pid_assigned: persistence_id ~ a_pid
			implication: not is_expanded implies Handler.persistence_id (object) ~ a_pid
		end

end

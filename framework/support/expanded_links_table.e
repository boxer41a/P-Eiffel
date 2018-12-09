note
	description: "[
		A HASH_TABLE that pairs a attribute reference PID with the PID of
		some expanded object.  Feature `referenced' allows lookup of the PID
		of an expanded object given an attribute id, and feature `referer'
		allows lookup of the attribute id given the PID of an expanded object.

		This implementation has a second table for the reverse lookup.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	EXPANDED_LINKS_TABLE

inherit

	PERSISTENCE_FACILITIES
		undefine
			copy,
			is_equal
		end

	HASH_TABLE [PID, PID]	-- [object's PID, attribute PID]
		export
			{NONE}
				replace,
				replace_key
			{EXPANDED_LINKS_TABLE}
				put
		redefine
			make,
			extend,
			force,
			remove,
			merge,
			wipe_out
		end

create
	make

feature {NONE} -- Initialization

	make (a_capacity: INTEGER_32)
			-- Create a table with an initial `a_capacity'.
		do
			Precursor (a_capacity)
			create referers_table.make (a_capacity)
		end

feature -- Access

	referenced (a_pid: PID): PID
			-- The PID associated with `a_pid' where `a_pid' is the persistent
			-- representation of an attribute of a particular object.
		require
			is_attribute: a_pid.is_attribute
			has_reference_from: has_reference_from (a_pid)
		do
			check attached item (a_pid) as v then
				Result := v
			end
		end

	referer (a_pid: PID): PID
			-- A "reverse" lookup to find the PID of the attribute that
			-- refers to `a_pid'.
		require
			not_attribute: not a_pid.is_attribute
			has_referer_to: has_referer_to (a_pid)
		do
			check attached referers_table.item (a_pid) as v then
				Result := v
			end
		end

feature -- Query

	has_reference_from (a_pid: PID): BOOLEAN
			-- Does Current contain a value referenced by `a_pid'?
		require
			is_attribute: a_pid.is_attribute
		do
			Result := has (a_pid)
		end

	has_referer_to (a_pid: PID): BOOLEAN
			-- Does Current contain a value that refers to `a_pid'?
		require
			not_attribute: not a_pid.is_attribute
		do
			Result := referers_table.has (a_pid)
		end

feature -- Basic operations

	merge (other: EXPANDED_LINKS_TABLE)
			-- Add the items of `other' to Current
		do
			from other.start
			until other.after
			loop
				force (other.item_for_iteration, other.key_for_iteration)
				other.forth
			end
		end

	extend (a_object_id: PID; a_attribute_id: PID)
			-- Add the association between the two arguments to Current.
		require else
			not_has_reference_from: not has_reference_from (a_attribute_id)
			not_has_referer_to: not has_referer_to (a_object_id)
			object_id_not_void: not a_object_id.is_void
			attribute_id_not_void: not a_attribute_id.is_void
			is_object_reference: not a_object_id.is_attribute
			is_attribute: a_attribute_id.is_attribute
		do
			Precursor (a_object_id, a_attribute_id)
			referers_table.extend (a_attribute_id, a_object_id)
		ensure then
			not_has_reference_from: has_reference_from (a_attribute_id)
			not_has_referer_to: has_referer_to (a_object_id)
		end

	force (a_object_id: PID; a_attribute_id: PID)
			-- Add the association between the two arguments to Current.
		require else
			object_id_not_void: not a_object_id.is_void
			attribute_id_not_void: not a_attribute_id.is_void
			is_object_reference: not a_object_id.is_attribute
			is_attribute: a_attribute_id.is_attribute
		do
			Precursor (a_object_id, a_attribute_id)
			referers_table.force (a_attribute_id, a_object_id)
		ensure then
			not_has_reference_from: has_reference_from (a_attribute_id)
			not_has_referer_to: has_referer_to (a_object_id)
		end

	remove (a_pid: PID)
			-- <Precursor>
		do
			if has_referer_to (a_pid) then
				referers_table.remove (referer (a_pid))
			end
			Precursor (a_pid)
		end

	wipe_out
			-- Remove all items
		do
			Precursor
			referers_table.wipe_out
		end

feature {NONE} -- Implementation

	referers_table: HASH_TABLE [PID, PID]
			-- A table parrallel to the inherited version, allowing lookup
			-- of the attribute reference given a pid reference.

end

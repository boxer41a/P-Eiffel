note
	description: "[
		A class to simplify type declarations.  We need a
		class because once features cannot have anchored types as result.
		Using "persistent_type" as the name is more descriptive then
		{SHA_1_MESSAGE_DIGEST} and allows for future changes.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PERSISTENT_TYPE

inherit

	SHA_DIGEST_1

--	PERSISTENCE_FACILITIES	-- for access to `Mapped_types'

create
	default_create,
	initialize,
	set_all

--feature -- Query

--	conforms_to_type (a_other: PERSISTENT_TYPE): BOOLEAN
--			-- Does this type conform to `a_other' type?
--		require
--			is_mapped: is_recorded_type (Current)
--			other_is_mapped: is_recorded_type (a_other)
--		local
--			dt, o_dt: INTEGER
--		do
--			dt := Mapped_types.item_by_persistent_type (Current).dt
--			o_dt := Mapped_types.item_by_persistent_type (a_other).dt
--			Result := {ISE_RUNTIME}.type_conforms_to (dt, o_dt)
--		end

end

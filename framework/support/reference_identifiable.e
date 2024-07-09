note
	description: "[
		Encapsulates an object for placement into the `Identified_objects',
		where the enclosed object is a reference type.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	REFERENCE_IDENTIFIABLE

inherit

	IDENTIFIABLE

	REFLECTED_REFERENCE_OBJECT
		undefine
			special_copy_semantics_item
		redefine
			copy_semantics_field,
			expanded_field
		end

create
	make

create {REFERENCE_IDENTIFIABLE}
	make_for_expanded_field, make_for_expanded_field_at

feature -- Access

	copy_semantics_field (i: INTEGER): COPY_SEMANTICS_IDENTIFIABLE
			-- <Precursor>
		do
				-- Do the same as in REFLECTED_REFERENCE_OBJECT
			create Result.make (twin, i)
		end

	expanded_field (i: INTEGER): REFERENCE_IDENTIFIABLE
			-- <Precursor>
		do
				-- Do the same as in REFLECTED_REFERENCE_OBJECT
			create Result.make_for_expanded_field (Current, i)
		end

end

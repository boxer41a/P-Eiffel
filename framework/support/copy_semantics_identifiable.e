note
	description: "[
		Encapsulates an object for placement into the `Identified_objects',
		where the enclosed object is an object with copy semantics.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	COPY_SEMANTICS_IDENTIFIABLE

inherit

	IDENTIFIABLE

	REFLECTED_COPY_SEMANTICS_OBJECT
		undefine
			special_copy_semantics_item
		redefine
			copy_semantics_field,
			expanded_field,
			special_copy_semantics_item
		end

create
	make, make_special
create {COPY_SEMANTICS_IDENTIFIABLE}
	make_recursive

feature -- Access

	copy_semantics_field (i: INTEGER): COPY_SEMANTICS_IDENTIFIABLE
			-- <Precursor>
		do
				-- Do the same as donein REFLECTED_COPY_SMANTICS_OBJECT
			create Result.make (twin, i)
		end

	expanded_field (i: INTEGER): COPY_SEMANTICS_IDENTIFIABLE
			-- <Precursor>
		do
				-- Do the same as REFLECTED_COPY_SEMANTICS_OBJECT
			create Result.make_recursive (Current, i)
		end

end

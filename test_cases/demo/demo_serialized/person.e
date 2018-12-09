note
	description: "[
		Top class in the hierarchy of classes used as examples 
		in the dissertation perposal.
		]"
	author: "Jimmy J. Johnson"

class
	PERSON

inherit

	COMPARABLE
		redefine
			default_create,
			out
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Create a person with an "Unknown" `name'
		do
			name := "Unknown name for {PERSON}"
			Index_imp.set_item (Index_imp.item + 1)
				-- Set index; multiply by 1000 just to make it more obvious for testing.
			Index := index_imp.item * 1000
		end

	make (a_name: STRING)
			-- Create a person with `a_name'
		require
			name_exists: a_name /= Void
		do
			default_create
			name := a_name
		end

feature --  Access

	name: STRING_8
			-- The person's name

	index: INTEGER_32
			-- Ordinal showing when this object was created, unless changed.

feature -- Element change

	set_name (a_name: STRING)
			-- Change the `name'
		require
			name_exists: a_name /= Void
		do
			name := a_name
		end

	set_index (a_index: INTEGER)
			-- Change the `index'
		do
			index := a_index
		end

feature -- Comparison

	is_less alias "<" (other: like Current): BOOLEAN
			-- Is current object less than `other'?
		do
			Result := name < other.name
		end

feature -- Output

	out: STRING
			-- String representation of Current
		do
			Result := ""
			Result.append (generating_type + "%N")
			Result.append ("  name = '" + name.out + "' %N")
			Result.append ("  index = " + index.out + "%N")
		end

feature{NONE} -- Implementation

	Index_imp: INTEGER_REF
			-- Keeps track of last index
		once
			create Result
		end

invariant

	name_exists: name /= Void

end

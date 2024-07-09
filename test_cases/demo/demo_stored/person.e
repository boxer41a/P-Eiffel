note
	description: "[
		Top class in the hierarchy of classes used as examples 
		in the dissertation perposal.
		]"
	author:		"Jimmy J. Johnson"
	copyright:	"Copyright 2013, Jimmy J. Johnson"
	license:		"Eiffel Forum License v2 (see forum.txt)"
	URL: 		"$URL:$"
	date:		"$Date: $"
	revision:	"$Revision: $"

class
	PERSON

inherit

	COMPARABLE
		undefine
			default_create
		redefine
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

	persistence_id: INTEGER_32
			-- Holds the identifier associated with Current.  The value
			-- That value is retrieved from the database and assigned to
			-- Current right after Current is stored.

feature -- Element change

	set_persistence_id (a_id: INTEGER_32)
			-- Change the `persistence_id'.
		do
			persistence_id := a_id
		end

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
			Result.append (generating_type + "  " + persistence_id.out + "%N")
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

note
	description: "[
		A range of persistent identifiers between `first' and `last' inclusive.
		The `first' PID is the `min_value' of whatever representation of a PID
		plus one, because the `min_value' represents a Void reference.
		This is used by {ID_BUCKET}.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	OID_INTERVAL

inherit

	PART_COMPARABLE

create
	make,
	set

feature {NONE}

	make (a_maximum: INTEGER_32)
			-- Create an interval from 1 to `a_maximum'.
		do
			first := 1
			last := a_maximum
			maximum := a_maximum
		end

feature -- Access

	first: INTEGER_32
			-- The lower value in the interval

	last: INTEGER_32
			-- The upper value in the interval

	maximum: INTEGER_32
			-- The maximum value assignable to `last' (or `first').

feature -- Element change

	set (a_first, a_last: like first)
			-- Change `first' and `last'
		require
			first_big_enough: a_first >= 1
			last_small_enough: a_last <= {like first}.max_value
			correct_relation: a_first <= last
		do
			first := a_first
			last := a_last
		end

	set_first (a_first: like first)
			-- Change `first'
		require
			first_big_enough: a_first >= 1
			first_small_enough: a_first <= last
		do
			first := a_first
		end

	set_last (a_last: like last)
			-- Change `last'
		require
			last_big_enough: a_last >= first
			last_small_enough: a_last <= {like first}.max_value
		do
			last := a_last
		end

feature -- Query

	is_less alias "<" (other: like Current): BOOLEAN
			-- Is current object less than `other'?
		do
			Result := first < other.first
		end

	overlaps (other: like Current): BOOLEAN
			-- Does Current and other have any items in common?
		do
			Result := contains (other.first) or contains (other.last) or
						other.contains (first) or other.contains (last)
		end

	contains (a_value: like first): BOOLEAN
			-- Does `a_value' lie in the closed interfal `first' to `last' inclusive?
		do
			Result := a_value >= first and a_value <= last
		end

invariant

	first_large_enough: first >= 1
	first_small_enough: first <= maximum
	last_large_enough: last >= 1
	last_small_enough: last <= maximum
	first_less_than_last: first <= last

end

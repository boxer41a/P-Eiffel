note
	description: "[
		An object that produces a unique object identifier for use by (PID) when 
		asked for `next_oid'.  Feature `last_oid' is available to obtain the same
		value again.

		Logically, a {ID_BUCKET} starts full, (i.e. it contains every identifier
		available, that is , all the values from one up to the maximum allowed
		for `next_oid'.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	ID_BUCKET

inherit

	PERSISTENCE_FACILITIES
		redefine
			default_create
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Initialize Current, making all PID's available
		local
			int: like available_ids.item
		do
			create available_ids.make
			create int.make ({PID}.Maximum_object_count)
			available_ids.extend (int)
		end

feature -- Access

	next_oid: INTEGER_32
			-- The next number in sequence.
			-- Change Current's state so that the next call to this feature
			-- returns a new value.
		require
			not_empty: not is_empty
		local
			int: like available_ids.item
		do
				-- Find the first (i.e. smallest available pid) which will be
				-- the first item in the first interval.
			int := available_ids.i_th (1)
			Result := int.first
				-- Remove that interval if it is used up
			if Result = int.last then
				available_ids.go_i_th (1)
				available_ids.remove
			else
				int.set_first (int.first + 1)
			end
		ensure
			result_large_enough: Result >= 1
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Are there no more identifiers available?
		do
			Result := available_ids.is_empty
		end

feature -- Basic operations

	reset
			-- Restore Current to its default.
			-- Used for testing.
		do
			available_ids.wipe_out
			available_ids.extend (create {OID_INTERVAL}.make ({PID}.maximum_object_count))
		end

	recover_oid (a_oid: like next_oid)
			-- Make `a_oid' availble to be used again.  This assumes `a_oid' is
			-- not contained by any {PID} used as a key in `identified_objects'
			-- table from ANY.
		require
			oid_big_enough: a_oid >= 1
			oid_small_enough: a_oid <= {PID}.maximum_object_count
			not_being_used: not is_oid_used (a_oid)
--			not_empty_requirement: not is_empty implies a_oid < i_th (count).first
		local
			oid: like next_oid
			i: INTEGER
			int: like available_ids.item
		do
			oid := a_oid
			if available_ids.is_empty then
					-- All oid's have been used, and we are recovering one.
					-- Simply create a new interval.
				create int.set (oid, oid)
				available_ids.extend (int)
			else
				check
					at_least_one_interval: available_ids.count >= 1
						-- by definition of not `is_empty'
				end
					-- To which interval does `oid' belong?  We search until
					-- `oid' belongs just in front of the first item of the
					-- interval that is reached.  It may need to become the
					-- first item of that interval, or a new interval may need
					-- to be created before the one reached.
					-- The examples use the [somewhat extreme] interval state:
					--   [5..10] [15..20]
					-- This means all pid except 5 through 10 and 15 through 20
					-- have been used and not recovered.
				from i := 1
				until i > available_ids.count or else oid < available_ids.i_th (i).first
				loop
					check
						not_inside_an_interval: not available_ids.i_th (i).contains (oid)
							-- because the intervals are continuous; a used pid
							-- being put back must be outside existing intervals
						after_this_interval: oid > available_ids.i_th (i).last
							-- because it is not before this interval, it must be after
					end
					i := i + 1
				end
				if i > available_ids.count then
						-- `oid' belongs at the end of the last interval or
						-- in a new interval that is after the last interval
					if oid ~ available_ids.i_th (available_ids.count).last + 1 then
							-- Make `a_pid' the end of the last interval
							-- Example:  recover a pid > 21
							--    [5..10] [15..21]
						available_ids.i_th (available_ids.count).set_last (oid)
					else
							-- Add `oid' in an interval of its own
							-- Example:  recover (100)
							--    [5..10] [15..20] [100..100]
						create int.set (oid, oid)
						available_ids.extend (int)
					end
				else
						-- `oid' belongs in the interval before the i_th interval
						-- or as the `first' value of the i_th interval.
						-- Example: recover a pid between "1" and "4" inclusive
					if oid ~ available_ids.i_th (i).first - 1 then
							-- Examples:  recover "4" or "14"
							--    [4..10] [15..max]  or  [5..10] [14..20]
						available_ids.i_th (i).set_first (oid)
					else
							-- Create a new interval in front of existing one
							-- Example:   recover "2"  or recover "12"
							--    [2..2] [5..10] [15..20]  or  [5..10] [12..12] [15..20]
						create int.set (oid, oid)
						available_ids.go_i_th (i)
						available_ids.put_left (int)
					end
				end
			end
		end

feature -- Query

	is_oid_used (a_oid: like next_oid): BOOLEAN
			-- Is `a_oid' in use [as the `oid' of some PID used as a key
			-- in the `identified_objects' table from ANY]?
		do
				-- Must do a sequential search of the entire table.
			from Identified_objects.start
			until Identified_objects.after or Result
			loop
				Result := a_oid = Identified_objects.key_for_iteration.object_identifier
				Identified_objects.forth
			end
		end

feature {NONE} -- Implementation

	available_ids: PART_SORTED_TWO_WAY_LIST [OID_INTERVAL]
			-- Set of persistent object identifiers from which
			-- to choose the `next_pid'.

invariant

--	no_overlapping_intervals:

end

note
	description: "[
		A heroic {PERSON} who *may* have a `companion' (e.g. Lone Ranger 
		& Tonto) to demonstrate circular references
		]"
	author: "Jimmy J. Johnson"

class
	HERO

inherit

	PERSON
		redefine
			copy,
			is_equal,
			out
		end

create
	make

feature -- Access

	companion: detachable HERO
			-- A {HERO} that hangs out with Current

feature -- Element change

	set_companion (other: HERO)
			-- Set `companion' to `other'
		local
			b: BOOLEAN
		do
			if companion /= other then
				b := {ISE_RUNTIME}.check_assert (False)
				remove_companion
				companion := other
				if other.companion /= Current then
					other.set_companion (Current)
				end
				b := {ISE_RUNTIME}.check_assert (b)
			end
		end

	remove_companion
			-- Set `companion' to Void; also removes Current from other
		local
			b: BOOLEAN
		do
			b := {ISE_RUNTIME}.check_assert (False)
			if attached companion as c then
				companion := Void
				c.remove_companion
			end
			b := {ISE_RUNTIME}.check_assert (b)
		end

feature -- Basic operations

	copy (other: like Current)
			-- Update current object using fields of object attached
			-- to `other', so as to yield equal objects.
			-- Redefined because up to four objects (Current and its `companion'
			-- along with `other' and its `companion') are involved in the
			-- copy operation which otherwise would violate the invariant.
			-- This copies other's values into Current, except for other's
			-- `companion' which is copied and then that copy is assigned
			-- as Current's `companion'.
		local
			other_com: detachable HERO
		do
				-- Save the companion of other
			if attached other.companion as c then
				other_com := c
			end
				-- Remove "referential_integrity" connections and copy both
			remove_companion
			other.remove_companion
			check
				has_no_companion: not attached companion
				other_has_no_companion: not attached other.companion
			end
			Precursor (other)		-- copy other's values into Current
			check
				has_no_companion: not attached companion
				other_has_no_companion: not attached other.companion
			end
			if attached other_com as c then
				set_companion (c.twin)
				other.set_companion (c)
			end
		end

	is_equal (other: like Current): BOOLEAN
			-- Is `other' attached to an object considered
			-- equal to current object?
		local
			com: detachable HERO
			other_com: detachable HERO
		do
			if Current = other then
				Result := true
			else
					-- Save then detach the companions
				if attached companion then
					com := companion
				end
				if attached other.companion as c then
					other_com := c
				end
				remove_companion
				other.remove_companion
				check
					has_no_companion: not attached companion
					other_has_no_companion: not attached other.companion
				end
					-- The actual check
				Result := Precursor (other) and then com ~ other_com
					-- Restore the companions
				if attached com as c then
					set_companion (com)
				end
				if attached other_com as c then
					other.set_companion (c)
				end
			end
		end

	out: STRING
			-- String representation of Current
		do
			Result := Precursor
			Result.append ("  companion = ")
			if attached companion as c then
				Result.append (c.name + "  ")
			else
				Result.append ("Void")
			end
			Result.append ("%N")
		end

invariant

	forward_integrity: attached companion as c implies c.companion = Current

end

note
	description: "[
		A {SUPER} (has an `alter_ego') that is also a {HERO} (has a `companion' but
		renamed to `sidekick') to demonstrate multiple inheritance and renaming.
		]"
	author: "Jimmy J. Johnson"

class
	SUPERHERO

inherit

	SUPER
		undefine
			copy,
			is_equal,
			out
		redefine
--			out
		end

	HERO
		rename
			make as person_make,
			companion as sidekick
		undefine
			default_create
		redefine
--			out
		end

create
	make

feature -- Access

--	out: STRING
--			-- String representation of Current
--		do
--			Result := Precursor {SUPER}
--			Result.append ("  sidekick = ")
--			if attached sidekick as s then
--				Result.append (s.name)
--			else
--				Result.append ("Void")
--			end
----			Result.append ("%N")
--		end


end

note
	description: "[
		A {SUPER} (has an `alter_ego') that is also a {HERO} (has a `companion')
		to demonstrate multiple inheritance.
		]"
	author: "Jimmy J. Johnson"

class
	SIDEKICK

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
			make as person_make
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
--			Result.append ("  companion = ")
--			if attached companion as c then
--				Result.append (c.name)
--			else
--				Result.append ("Void")
--			end
--			Result.append ("%N")
--		end


end

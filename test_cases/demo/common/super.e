note
	description: "[
		A {PERSON} with super-human abilities, having an `alter_ego' (e.g. superman)
		]"
	author: "Jimmy J. Johnson"

class
	SUPER

inherit

	PERSON
		rename
			make as person_make
		redefine
			default_create,
			out
		end

create
	make

feature -- Make

	default_create
			-- Create an instance
		do
			create alter_ego
			Precursor
		end

	make (a_name: STRING_8; a_alter_name: STRING_8; a_age: INTEGER_32)
			-- Initialize Current and set up it `alter_ego'.
		do
			person_make (a_name)
			create alter_ego.make (a_alter_name, a_age)
		end

feature -- Access

	alter_ego: ALTER_EGO
			-- Every {SUPER} must protect his identity.
			-- Remember, {ALTER_EGO} is expanded.

feature -- Element change

	set_alter_ego_name (a_name: STRING)
			-- Set the `name' of Current's `alter_ego'
		do
			alter_ego.set_name (a_name)
		end

	set_alter_ego_age (a_age: INTEGER_32)
			-- Set the `age' of Current's `alter_ego'
		do
			alter_ego.set_age (a_age)
		end

feature -- Output

	out: STRING
			-- String representation of Current
		do
			Result := Precursor
			Result.append ("  Alter ego = %N")
			Result.append ("     name = " + alter_ego.name + "%N")
			Result.append ("      age = " + alter_ego.age.out)
		end

end

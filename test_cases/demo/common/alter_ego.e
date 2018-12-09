note
	description: "[
		Every {SUPER} must have an alter ego to protect his identity. 
		It is expanded because no other {SUPER} can have the *same* alter 
		ego, though it may look the same (i.e. copy semantics).
		]"
	author: "Jimmy J. Johnson"

expanded class
	ALTER_EGO

inherit

	ANY
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
			name := "Unknown name for {ALTER_EGO}"
			age := -99
		end

	make (a_name: STRING; a_age: INTEGER_32)
			-- Create a person with `a_name'
		require
			name_exists: a_name /= Void
		do
			default_create
			name := a_name
			age := a_age
		end

feature --  Access

	name: STRING_8
			-- The person's name

	age: INTEGER_32
			-- The precieved age of the {ALTER_EGO}.

feature -- Element change

	set_name (a_name: STRING_8)
			-- Change the `name'
		do
			name := a_name
		end

	set_age (a_age: INTEGER_32)
			-- Change the `age'
		do
			age := a_age
		end

feature -- Output

	out: STRING
			-- String representation of Current
		do
			Result := generating_type + "%N"
			Result.append ("  name = '" + name.out + "' %N")
			Result.append ("  age = " + age.out + "%N")
		end

end

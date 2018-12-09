note
	description : "Test the PEiffel callback behavior."
	date        : "$Date$"
	revision    : "$Revision$"

class
	APPLICATION

inherit

	PERSISTENCE_FACILITIES

create
	make

feature {NONE} -- Initialization

	attr: detachable ANY

	intattr: INTEGER

	make
			-- Run application.
		local
			i: INTEGER
			a: ANY
			r: REAL_64_REF
		do
			Persistence_manager.set_persist_automatic

			Current.do_nothing 	-- Qualified call -> triggers callback
			do_nothing			-- Unqualified call -> no callback

			i := get_something	-- local assignment -> no callback
			i := 42 				-- local assignment -> no callback

			create a 			-- creation instruction -> callback
			attr := a 			-- attribute assignment -> callback
			intattr := 43 -- attribute assignment -> callback

			r := 1.0				-- local assignment -> no callback
			r.zero.do_nothing
		end

feature -- Basic operation

	get_something: INTEGER
			-- Test assignment to Result.
		do
			Result := 9
		end

end

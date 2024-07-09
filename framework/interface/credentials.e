note
	description: "[
		Information, such as `hostname' and for a network, username and password
		used to connect to a {REPOSITORY}.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	CREDENTIALS

create
	make

feature {NONE} -- Initialize

	make (a_uri: like uri)
			-- Initialize Current, setting the `uri'
		require
			is_valid_uri: is_valid_uri (a_uri)
		do
			uri := a_uri
		end

feature -- Access

	uri: STRING_8
			-- Location information used to connect to a {REPOSITORY} and
			-- passed as parameter to the creation routine of a {REPOSITORY}.
			-- The default assumes a simple filename, but descendants could
			-- redefine to provide a port number, username, passwords, etc.

feature -- Elment change

	set_uri (a_uri: STRING)
			-- Change the `uri'.
		require
			is_valid_uri: is_valid_uri (a_uri)
		do
			uri := a_uri
		end

feature -- Query

	is_valid_uri (a_string: STRING_8): BOOLEAN
			-- Is `a_string' in the correct for for a uri?
		do
			print (generating_type + ".is_valid_uri:  Fix me! ")
			Result := true
		end

end

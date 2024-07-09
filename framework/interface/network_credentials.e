note
	description: "[
		Information (e.g. username and password) used to connect to
		a {NETWORK_REPOSITORY}.
		]"
	author: "Jimmy J.Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	NETWORK_CREDENTIALS

inherit

	CREDENTIALS
		redefine
			default_create,
			make
		end

create
	default_create,
	make

feature {NONE} -- Initialize

	default_create
			-- Initialize Current to default settings.
		do
			uri := "127.0.0.1"
--			hostname := "127.0.0.1"
			hostname := "localhost"
			port := 2221
			username := ""
			password := ""
		end

	make (a_uri: like uri)
			-- Initialize Current, setting the `uri'.
			-- Sets the `username' and `password' to empty strings.
		do
			default_create
			Precursor (a_uri)
		end

feature -- Access

	hostname: STRING
			-- The name of the host (e.g. "localhost" or "191.177.1.100".

	port: INTEGER
			-- The port on which Current will communicate with the datastore

	username: STRING_8
			-- The "username" for connecting to a network.

	password: STRING_8
			-- The "password" for connecting to a network.

feature -- Element change

	set_host_port (a_host: like hostname; a_port: like port)
			-- Set the `hostname' and `port'.
		do
			hostname := a_host
			port := a_port
		end

	set_username_password (a_username: like username; a_password: like password)
			-- Set the `username' and `password'.
		do
			username := a_username
			password := a_password
		end

end

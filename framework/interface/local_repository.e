note
	description: "[
		Interface to an underlying datastore, where the data is a
		{TABLULATION} that is written to a local file.
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	LOCAL_REPOSITORY

inherit

	MEMORY_REPOSITORY
		redefine
			make,
			store,
			connect,
			disconnect,
			is_connected,
			commit
		end

create
	make

feature {NONE} -- Initialization

	make (a_credentials: CREDENTIALS)
			-- Create a repository to which a connection can be
			-- established using `a_credentials'.
		do
			create data_file.make_with_name (a_credentials.uri)
			Precursor {MEMORY_REPOSITORY} (a_credentials)
			initialize
		end

	initialize
			-- Set up the underlying datastore
		do
--			if data_file.exists then
--				data_file.open_read
--				check attached {TUPLE [buck: ID_BUCKET; dat: TABULATION]} data_file.retrieved as tup then
--					id_bucket := tup.buck
--					data_imp := tup.dat
--				end
--				data_file.close
--			else
				commit
--			end
		end

feature -- Access

feature -- Basic operations

	store (a_tabulation: TABULATION)
			-- Store `a_encoding'.
			-- So, this should only be called when `a_object' is in a valid
			-- state; other objects may be changing and in an invalid state,
			-- so we should not touch that part of the encoding yet.
		do
			Precursor (a_tabulation)
			commit
		end

	commit
			-- Brute force write the whole object
			-- This effected version simply writes the `simulated_store' to
			-- the represented file, and closes the file.
		do
			data_file.open_write
			data_file.independent_store ([id_bucket, data_imp])
			data_file.close
		end

feature -- Query

	is_connected: BOOLEAN
			-- Is Current able to communicate with the underlying physical store?
			-- For a {FILE_REPOSITORY}, yes if the file exists and is_open_read_write
		local
--			f: like implementation
		do
--			f := implementation
----			f.open_read_write
--			check
--				file_exists: f.exists
--			end
--			check
--				file_open_read: f.is_open_read
--			end
--			check
--				file_open_write: f.is_open_write
--			end
--			Result := f.exists and f.is_open_read and f.is_open_write

			Result := true
		end

feature -- Status setting

	connect
			-- Make Current able to communicate with the underlying physical store
		do
--			implementation.open_read_write
		end

	disconnect
			-- Make Current unable to communicate with the underlying physical store
		do
--			implementation.close
		end

feature -- Implementation

	data_file: RAW_FILE
			-- File in which to store the `encoding'

--	Default_data_filename: STRING = "datafile.dat"
			-- Name of the file in which to store persistent information

end

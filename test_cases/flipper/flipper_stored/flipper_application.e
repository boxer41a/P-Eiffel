note
	description: "[
		Root class to test FLIPPER where the games are checkpointed
		into a MySQL database with feature `on_store' in class
		{FLIPPER_MAIN_WINDOW}.
		]"
	author:		"Jimmy J. Johnson"

class
	FLIPPER_APPLICATION

inherit

	JJ_APPLICATION
		redefine
			create_interface_objects,
			window_anchor
		end

	DATABASE_APPL [MYSQL]
		undefine
			default_create,
			copy
		end

create
	make_and_launch

feature {NONE} -- Initialization

	create_interface_objects
			-- Create objects to be used by `Current' in initialize to adhere
			-- to void-safety due to the implementation bridge pattern.
		do
			create target
			set_application ("flipper_db")
			login ("root", "Zaq1@wsx")
			set_base
			create db_control.make
			try_connecting
		end

	try_connecting
			-- Attempt to connect to the database and build the game table
			-- if not already built.
		local
			db_rep: DB_REPOSITORY
			db_chg: DB_CHANGE
			q: STRING
		do
			db_control.connect
			if db_control.is_connected then
					-- Create the game table if not already created.
				create db_rep.make ("game")
				db_rep.load
				if not db_rep.exists then
					create db_chg.make
					q := "CREATE TABLE game ( %N%
							%  game_id INTEGER NOT NULL AUTO_INCREMENT, %N%
							%  game_time DATETIME, %N%
							%  width INTEGER NOT NULL, %N%
							%  height INTEGER NOT NULL, %N%
							%  current_player_id INTEGER, %N%
							%  PRIMARY KEY (game_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the game table if not already created.
				create db_rep.make ("disk")
				db_rep.load
				if not db_rep.exists then
					create db_chg.make
					q := "CREATE TABLE disk ( %N%
							%  disk_id INTEGER NOT NULL, %N%
							%  game_id INTEGER NOT NULL, %N%
							%  owner_id INTEGER NOT NULL, %N%
							%  PRIMARY KEY (disk_id, game_id), %N%
							%  FOREIGN KEY (game_id) REFERENCES game (game_id) %N%
							%);"
					db_chg.modify (q)
				end
			else
				io.put_string ("Unable to connect to database. %N")
			end
		end

feature -- Access

	target: FLIPPER
			-- The game currently in play.

feature {NONE} -- Implementation (anchors)

	window_anchor: FLIPPER_MAIN_WINDOW
			-- Anchor for the type of `first_window'
			-- Not to be called; just used to anchor types.
			-- Declared as a feature to avoid adding an attribute.
		require else
			not_callable: False
		do
			check
				do_not_call: False then
					-- Because give no info; simply used as anchor.
			end
		end

feature {FLIPPER_MAIN_WINDOW} -- Implementation (Eiffel Store related)

	db_control: DB_CONTROL
			-- Manages the database (i.e. establish connection, disconnect,
			-- handle errors, and get information about database.)

end

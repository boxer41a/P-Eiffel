note
	description: "[
		This class attempts to emmulate the P-Eiffel facilities that
		are demonstrated in the P-Eiffel version of DEMO, using Eiffel
		Software's Store cluster (i.e. the DB_xxx classes.)
		]"
	author: "Jimmy J. Johnson"

class
	DEMO

inherit

	DATABASE_APPL [MYSQL]

create
	make,
	execute_all

feature {NONE} -- Initialization

	make
			-- Run application.
		do
				-- Clear some of the terminal
			io.put_string ("%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N%N")
			io.put_string ("Persistence DEMO program %N")
				-- Setup the database
			set_application ("demo_db")
			login ("root", "Zaq1@wsx")
			set_base
			create person_table.make (10)
			create db_control.make
			try_connecting
			initialize
			io.put_string ("End Persistence DEMO.make %N")
		end

	try_connecting
			-- Attempt to connect to the database and build the game table
			-- if not already built.
		local
			db_rep: DB_REPOSITORY
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			db_control.connect
			if db_control.is_connected then
					-- Create the game table if not already created.
				create db_rep.make ("person")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE person ( %N%
							%  person_id INTEGER NOT NULL AUTO_INCREMENT, %N%
							%  person_index INTEGER, %N%
							%  person_name VARCHAR(80) NOT NULL, %N%
							%  is_member BOOL NOT NULL DEFAULT FALSE, %N%
							%  PRIMARY KEY (person_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the alter_ego table if not already created.
				create db_rep.make ("alter_ego")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE alter_ego ( %N%
							%  alter_ego_id INTEGER NOT NULL AUTO_INCREMENT, %N%
							%  person_id INTEGER NOT NULL, %N%
							%  name VARCHAR(80) NOT NULL, %N%
							%  age INTEGER NOT NULL, %N%
							%  PRIMARY KEY (alter_ego_id), %N%
							%  FOREIGN KEY (person_id) REFERENCES person (person_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the hero table if not already created.
				create db_rep.make ("hero")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE hero ( %N%
							%  person_id INTEGER NOT NULL, %N%
							%  companion_id INTEGER, %N%
							%  PRIMARY KEY (person_id), %N%
							%  FOREIGN KEY (person_id) REFERENCES person (person_id), %N%
							%  FOREIGN KEY (companion_id) REFERENCES person (person_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the super table if not already created.
				create db_rep.make ("super")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE super ( %N%
							%  person_id INTEGER NOT NULL, %N%
							%  alter_ego_id INTEGER NOT NULL, %N%
							%  PRIMARY KEY (person_id), %N%
							%  FOREIGN KEY (person_id) REFERENCES person (person_id), %N%
							%  FOREIGN KEY (alter_ego_id) REFERENCES alter_ego (alter_ego_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the sidekick table if not already created.
				create db_rep.make ("sidekick")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE sidekick ( %N%
							%  person_id INTEGER NOT NULL, %N%
							%  PRIMARY KEY (person_id), %N%
							%  FOREIGN KEY (person_id) REFERENCES person (person_id) %N%
							%);"
					db_chg.modify (q)
				end
					-- Create the sidekick table if not already created.
				create db_rep.make ("superhero")
				db_rep.load
				if not db_rep.exists then
					q := "CREATE TABLE superhero ( %N%
							%  person_id INTEGER NOT NULL, %N%
							%  PRIMARY KEY (person_id), %N%
							%  FOREIGN KEY (person_id) REFERENCES person (person_id) %N%
							%);"
					db_chg.modify (q)
				end
			else
				io.put_string ("Unable to connect to database. %N")
			end
		end

	Initialize
			-- Setup the test object structure.
		do
			create members.make
			create chewie.make ("Chewie")
			create han.make ("Han Solo")
			create incredible.make ("Incredible", "Bob", 40)
			create batman.make ("Batman", "Adam West", 35)
			chewie.set_companion (han)
			members.extend (chewie)
			members.extend (han)
			members.extend (batman)
			members.extend (incredible)
			step := 1
		end

feature -- Access

	members: TWO_WAY_SORTED_SET [PERSON]
			-- Holds the other objects

	john: detachable PERSON
			-- John Galt object having a `name' and an `index'.

	incredible: SUPER
			-- Mr. Incredible has an `alter_ego' and void `companion'.
			-- (He has not yet met Elasti-Girl.)

	han: HERO
			-- Han Solo, a `companion' (from {HERO}) of `chewie'

	chewie: HERO
			-- Chewbacca, the `companion' of `han'

	batman: SUPERHERO
			-- Object with multiple inheritance (from {SUPER} and {HERO}) having
			-- an `alter_ego' (from {SUPER}) and a `sidekick' (renamed `compainion'
			-- from {HERO})
			-- Sidekick of `robin'

	robin: detachable SIDEKICK
			-- Object with an `alter_ego', which is expanded {ALTER_EGO} type
			-- Object with multiple inheritance (from {SUPER} and {HERO}) having
			-- an `alter_ego' (from {SUPER}) and a `sidekick' (renamed `compainion'
			-- from {HERO})
			-- Sidekick of `batman'

feature -- Access

	step: INTEGER
			-- The current step in the sequence of demo steps.

	pre_step_message (a_step: INTEGER): STRING_8
			-- Describes the action to be taken when the step indexed
			-- by `a_step' is performed.
		require
			step_big_enough: a_step >= 0
			step_small_enough: a_step <= Max_steps
		do
			check attached step_actions.item (a_step) as tup then
				Result := tup.pre_message
			end
		end

	post_step_message (a_step: INTEGER): STRING_8
			-- Describes the action that was taken by the step indexed
			-- by `a_step'.
		require
			step_big_enough: a_step >= 0
			step_small_enough: a_step <= Max_steps
		do
			check attached step_actions.item (a_step) as tup then
				Result := tup.post_message
			end
		end

feature -- Basic operations

	execute_all
			-- Perform all the steps in the demo program
		do
			io.put_string ("%N%N Begin Persistence DEMO.execute_all %N")
			make
			from step := 1
			until step > max_steps
			loop
				execute_next
			end
			io.put_string ("%N%N End Persistence DEMO.execute_all %N")
		end

	execute_next
			-- Execute the action corresponding the current `step'.
		require
			step_big_enough: step >= 1
			step_small_enough: step <= Load_list_step
		do
			io.put_string ("======================================================== %N")
			io.put_string ("Step " + step.out + "   " + pre_step_message (step) + "%N")
			check attached step_actions.item (step) as s then
				s.action.call
			end
			io.put_string ("End Step " + step.out + "   " + post_step_message (step) + "%N")
			io.put_string ("======================================================== %N")
			if step <= Max_steps then
				step := step + 1
			end
		end

	manually_persist_chewie
			-- Manaully persist `chewie', and by reachability `han',
			-- showing persistence-by-reachability and persistence of
			-- circular references.
		do
			store (chewie)
		end

	manually_persist_incredible
			-- Manually persist `incredible', showing persistence of
			-- an expanded object.
		do
			store (incredible)
		end

	manually_mark_batman
			-- Mark `batman' as dirty.
		do
			mark (batman)
		end

	set_mark_dirty
			-- Turn on dirty marking
		do
		end

	set_incredible_name
			-- Change `incredible's name.
		do
			incredible.set_name ("Mr Incredible")
			mark (incredible)
		end

	checkpoint
			-- `store' each object in `dirty_objects' and remove it.
			-- This feature does NOT preserve object identity.
		do
			from dirty_objects.start
			until dirty_objects.after
			loop
				store (dirty_objects.item)
					-- No need to go forth, since `store' deletes
					-- the item and moves to right neighbor.
--					dirty_objects.forth
			end
		end

	set_chewie_name
			-- Change `chewie's name
		do
			chewie.set_name ("Chewbacca")
			mark (chewie)
		end

	create_robin
			-- Create the `robin' object and add to set.
		do
			create robin.make ("Robin", "Dick Grayson", 16)
			check attached robin as r then
				mark (r)
				members.extend (r)
			end
		end

	persist_list_as_root
			-- Ensure the `members' is saved to the `repository'.
		do
			checkpoint
			store_members_list
		end

	set_persistence_automatic
			-- Turn on the automatic persistence mechanism
		do
			is_automatic := true
		end

	set_batman_companion
			-- Make `robin' the companion of `batman'
		do
			check attached robin as r then
				batman.set_companion (r)
				mark (batman)
				mark (r)
				checkpoint
			end
		end

	set_batman_alter_ego_name
			-- Correct the `name' of `robin's `alter_ego'.
		do
			batman.set_alter_ego_name ("Bruce Wayne")
			mark (batman)
			checkpoint
		end

	create_john
			-- Create the `john' object.
		do
			create john.make ("John Galt")
			check attached john as j then
				store (j)
			end
		end

	add_john_to_list
			-- Add `john' to the `members'.
		do
			check attached john as j then
				members.extend (j)
				store_members_list
			end
		end

	load_chewie
			-- Restore `chewie' to its previous state to demonstrate manual loading.
		local
			p: PERSON
		do
			check attached {HERO} loaded (chewie.persistence_id) as c then
--				check equivalent_to_old: c ~ p then end
				check same_objects: c = chewie then end
			end
		end

	load_incredible
			-- Load `incredible' to test loading of expanded objects
		do
			check attached {SUPER} loaded (incredible.persistence_id) as v then
				check equivalent_objects: v ~ incredible then end
			end
		end

	load_list
			-- Load the `members'.
			-- This should not duplicate `chewie' or `incredible' which were loaded
			-- in previous steps.
		do
			check attached {TWO_WAY_SORTED_SET [PERSON]} loaded_list as ss then
				members := ss
			end
		end

feature -- Status report

	is_stepping_complete: BOOLEAN
			-- Have all the demostration steps been done?
		do
			Result := step >= Notify_completed_step
		end

feature -- constants

	Initialize_step: INTEGER = 0
		-- Manual steps
	Manually_persist_chewie_step: INTEGER = 1
	Manually_persist_incredible_step: INTEGER = 2
	Manually_mark_batman_step: INTEGER = 3
		-- Marking dirty steps
	Set_mark_dirty_step: INTEGER =4
	Set_incredible_name_step: INTEGER = 5
	Checkpoint_step: INTEGER = 6
	Set_chewie_name_step: INTEGER = 7
	Create_robin_step: INTEGER = 8
	Persist_list_as_root_step: INTEGER = 9
		-- Automatic steps
	Set_persist_automatic_step: INTEGER = 10
	Set_batman_companion_step: INTEGER = 11
	Set_batman_alter_ego_name_step: INTEGER = 12
	Create_john_step: INTEGER = 13
	Add_john_to_list_step: INTEGER = 14
		-- loading
	Load_chewie_step: INTEGER = 15
	Load_incredible_step: INTEGER = 16
	Load_list_step: INTEGER = 17
	Notify_completed_step: INTEGER = 18

	max_steps: INTEGER
			-- The number of times to call `execute'.
		once
			Result := Load_list_step	-- Notify_completed_step
		end

feature {NONE} -- Implementation

	step_actions: HASH_TABLE [TUPLE [action: PROCEDURE;
								pre_message: STRING_8; post_message: STRING_8],
								INTEGER]
			-- Procedures to be executed at a particular `step' (the key) and
			-- messages; `pre_message' to inform what the `action' will do when
			-- executed, and `post_message' to inform what the `action' just did.
		once
			create Result.make (20)
			Result.extend ([agent initialize, "", "Data initialized"], Initialize_step)
				-- Manual steps
			Result.extend ([agent manually_persist_chewie, "Manually Persist Chewie", "Chewie was stored"], Manually_persist_chewie_step)
			Result.extend ([agent manually_persist_incredible, "Manually Persist Incredible", "Incredible was stored"], Manually_persist_incredible_step)
			Result.extend ([agent manually_mark_batman, "Manually Mark Batman as Dirty", "Batman was marked dirty"], Manually_mark_batman_step)
				-- Mark dirty steps
			Result.extend ([agent set_mark_dirty, "Begin marking dirty objects", "Dirty objects are now marked"], Set_mark_dirty_step)
			Result.extend ([agent set_incredible_name, "Change Mr Incredibles's name", "Mr Incredibles's name was changed"], Set_incredible_name_step)
			Result.extend ([agent checkpoint, "Checkpoint dirty objects", "Checkpoints dirty chewie and incredible"], Checkpoint_step)
			Result.extend ([agent set_chewie_name, "Change Chewie's name", "Chewie's name was changed"], Set_chewie_name_step)
			Result.extend ([agent create_robin, "Create Robin and add to list", "Robin was created and added to list"], Create_robin_step)
			Result.extend ([agent persist_list_as_root, "Persist the list as a root", "The list was stored as a root"], Persist_list_as_root_step)
				-- Automatic persistence steps
			Result.extend ([agent set_persistence_automatic, "Enable auto-persistence", "Auto-persistence was enabled"], Set_persist_automatic_step)
			Result.extend ([agent set_batman_companion, "Set Batman's companion", "Batman's companion was set"], Set_batman_companion_step)
			Result.extend ([agent set_batman_alter_ego_name, "Change Batman's alter-ego name", "Batman's alter-ego name was changed"], Set_batman_alter_ego_name_step)
			Result.extend ([agent create_john, "Create John", "John was created"], create_john_step)
			Result.extend ([agent add_john_to_list, "Add John to the List", "John was added to the list"], add_john_to_list_step)
				-- Loading
			Result.extend ([agent load_chewie, "Load chewie", "Chewie was loaded"], Load_chewie_step)
			Result.extend ([agent load_incredible, "Load incredible", "Incredible was loaded"], Load_incredible_step)
			Result.extend ([agent load_list, "Load hero_list", "Hero_list was loaded"], Load_list_step)
				-- Finish demo
			Result.extend ([agent do_nothing, "Do nothing", "Demo steps completed"], Notify_completed_step)
		end

feature {NONE} -- Implementation (persistence operations simulations)

	is_automatic: BOOLEAN
			-- Is storage set to automatic mode?

	mark (a_person: PERSON)
			-- Mark `a_object' as dirty.
		do
			dirty_objects.extend (a_person)
			if is_automatic then
				checkpoint
			end
		end

	dirty_objects: LINKED_LIST [PERSON]
			-- List of objects marked as dirty.
		once
			create Result.make
		end

	store_members_list
			-- Ensure each {PERSON} object that is in `members' is
			-- marked as such in the database, and any {PERSON} that
			-- is not in `members' is not marked as lin the list.
		local
			q: STRING
			con: ARRAYED_LIST [DB_RESULT]
			id_tab: HASH_TABLE [BOOLEAN, INTEGER]
			p: PERSON
			db_sel: DB_SELECTION
			db_tup: DB_TUPLE
		do
			create id_tab.make (10)
			create con.make (10)
			create db_sel.make
			create db_tup.make
				-- Get identifiers of all {PERSON} objects in the database.
			q := "SELECT person_id FROM person;"
			db_sel.query (q)
			db_sel.set_container (con)
			db_sel.load_result
			from con.start
			until con.after
			loop
				db_tup.copy (con.item)
				check attached {INTEGER_REF} db_tup.item (1) as ir then
					id_tab.extend (true, ir.item)
				end
				con.forth
			end
			db_sel.terminate
				-- Go through the list storing person objects.
			from members.start
			until members.after
			loop
				p := members.item
				if is_person_stored (p.persistence_id) then
					modify_person (p)
					id_tab.remove (p.persistence_id)
				else
					insert_person (p)
				end
				add_list_mark (p.persistence_id)
				members.forth
			end
				-- For any identifiers still in the table, mark as removed.
			from id_tab.start
			until id_tab.after
			loop
				remove_list_mark (id_tab.key_for_iteration)
				id_tab.forth
			end
		end

	store (a_person: PERSON)
			-- Store `a_person' using SQL queries into a MySQL database.
			-- This feature consolidates the persistence
			-- operations into one place to align as close a possible to the
			-- P-Eiffel {DEMO} program.
		do
			if db_control.is_connected then
				if is_person_stored (a_person.persistence_id) then
					modify_person (a_person)
				else
					insert_person (a_person)
				end
			else
				io.put_string ("Unable to store " + generating_type + " ")
				io.put_string (a_person.name + ":  not connected to database %N")
			end
			dirty_objects.start
			dirty_objects.prune (a_person)
		end

	insert_person (a_person: PERSON)
			-- Store `a_person' into the database.
		require
			not_stored: not is_person_stored (a_person.persistence_id)
		local
			q: STRING
			db_chg: DB_CHANGE
			db_sel: DB_SELECTION
			db_res: DB_RESULT
			db_tup: DB_TUPLE
		do
			create db_chg.make
			create db_sel.make
			create db_tup.make
			q := "INSERT INTO person (person_name, person_index) VALUES "
			q := q + "('" + a_person.name + "', " + a_person.index.out + ");"
			db_chg.modify (q)
				-- Get the database assigned identifier.
			q := "SELECT LAST_INSERT_ID()"
			db_sel.query (q)
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				check attached {INTEGER_REF} db_tup.item (1) as id then
					a_person.set_persistence_id (id)
				end
			end
			db_sel.terminate
				-- Add `a_person' to `person_table'.
			person_table.extend (a_person, a_person.persistence_id)
			if attached {SUPERHERO} a_person as sh then
				insert_superhero (sh)
			elseif attached {SIDEKICK} a_person as sk then
				insert_sidekick (sk)
			elseif attached {SUPER} a_person as s then
				insert_super (s)
			elseif attached {HERO} a_person as h then
				insert_hero (h)
			end
		end

	insert_superhero (a_superhero: SUPERHERO)
			-- Add `a_superhero' to the database
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			q := "INSERT INTO superhero (person_id) VALUES "
			q := q + "(" + a_superhero.persistence_id.out + ");"
			db_chg.modify (q)
			insert_super (a_superhero)
			insert_hero (a_superhero)
		end

	insert_sidekick (a_sidekick: SIDEKICK)
			-- Add `a_sidekick' to the database
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			q := "INSERT INTO sidekick (person_id) VALUES "
			q := q + "(" + a_sidekick.persistence_id.out + ");"
			db_chg.modify (q)
			insert_super (a_sidekick)
			insert_hero (a_sidekick)
		end

	insert_super (a_super: SUPER)
			-- Add `a_super' to the database.
		local
			q: STRING
			id: INTEGER
			db_chg: DB_CHANGE
			db_sel: DB_SELECTION
			db_res: DB_RESULT
			db_tup: DB_TUPLE
		do
			create db_sel.make
			create db_tup.make
			create db_chg.make
				-- Insert the alter ego fields.
			q := "INSERT INTO alter_ego (person_id, name, age) VALUES "
			q := q + "(" + a_super.persistence_id.out + ","
			q := q + " '" + a_super.alter_ego.name
			q := q + "', " + a_super.alter_ego.age.out + ");"
			db_chg.modify (q)
				-- Get the alter_ego id.
			q := "SELECT LAST_INSERT_ID()"
			db_sel.query (q)
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				check attached {INTEGER_REF} db_tup.item (1) as i then
					id := i
				end
			end
			db_sel.terminate
				-- Insert into he sidekick table.
			q := "INSERT INTO super (person_id, alter_ego_id) VALUES "
			q := q + "(" + a_super.persistence_id.out + ", " + id.out + ");"
			db_chg.modify (q)
		end

	insert_hero (a_hero: HERO)
			-- Add `a_hero' to the database.
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			if attached a_hero.companion as c then
				if not is_person_stored (c.persistence_id) then
					insert_person (c)
				end
				q := "INSERT INTO hero (person_id, companion_id) VALUES "
				q := q + "(" + a_hero.persistence_id.out + ", " + c.persistence_id.out + ");"
			else
				q := "INSERT INTO hero (person_id) VALUES "
				q := q + "(" + a_hero.persistence_id.out + ");"
			end
			db_chg.modify (q)
		end

	modify_person (a_person: PERSON)
			-- Modify `a_person' that was previously stored in the database.
		require
			is_stored: is_person_stored (a_person.persistence_id)
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			q := "UPDATE person SET person_name = '" + a_person.name + "', "
			q := q + "person_index = " + a_person.index.out
			q := q + " WHERE person_id = " + a_person.persistence_id.out +  ";"
			db_chg.modify (q)
			if attached {SUPERHERO} a_person as sh then
				modify_superhero (sh)
			elseif attached {SIDEKICK} a_person as sk then
				modify_sidekick (sk)
			elseif attached {SUPER} a_person as s then
				modify_super (s)
			elseif attached {HERO} a_person as h then
				modify_hero (h)
			end
		end

	modify_superhero (a_superhero: SUPERHERO)
			-- Change `a_superhero' in the database.
		do
			modify_super (a_superhero)
			modify_hero (a_superhero)
		end

	modify_sidekick (a_sidekick: SIDEKICK)
			-- Change `a_sidekick' in the database.
		do
			modify_super (a_sidekick)
			modify_hero (a_sidekick)
		end

	modify_super (a_super: SUPER)
			-- Change `a_super' in the database.
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
				-- Modify the alter ego fields.
			q := "UPDATE alter_ego SET name = '" + a_super.alter_ego.name + "', "
			q := q + "age = " + a_super.alter_ego.age.out
			q := q + " WHERE person_id = " + a_super.persistence_id.out + ";"
			db_chg.modify (q)
		end

	modify_hero (a_hero: HERO)
			-- Change `a_hero' in the database.
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			if attached a_hero.companion as c then
				if not is_person_stored (c.persistence_id) then
					insert_person (c)
				end
				q := "UPDATE hero SET companion_id = " + c.persistence_id.out
			else
				q := "UPDATE hero SET companion_id = NULL"
			end
			q := q + " WHERE person_id = " + a_hero.persistence_id.out + ";"
			db_chg.modify (q)
		end

	is_person_stored (a_id: INTEGER): BOOLEAN
			-- Has a {PERSON} with `a_id' been stored into the database?
		do
			Result := is_stored_imp (a_id, "person")
		end

	is_hero_stored (a_id: INTEGER): BOOLEAN
			-- Does a {HERO} with `a_id' exist in the database?
		do
			Result := is_stored_imp (a_id, "hero")
		end

	is_super_stored (a_id: INTEGER): BOOLEAN
			-- Does a {SUPER} with `a_id' exist in the database?
		do
			Result := is_stored_imp (a_id, "super")
		end

	is_superhero_stored (a_id: INTEGER): BOOLEAN
			-- Does a {SUPEHERO} with `a_id' exist in the database?
		do
			Result := is_stored_imp (a_id, "superhero")
		end

	is_sidekick_stored (a_id: INTEGER): BOOLEAN
			-- Does a {SIDEKICK} with `a_id' exist in the database?
		do
			Result := is_stored_imp (a_id, "sidekick")
		end

	is_stored_imp (a_id: INTEGER; a_name: STRING): BOOLEAN
			-- Does the table called `a_name' contain `a_id'?
			-- Used by features such as `is_person_stored', `is_hero_stored'.
		local
			q: STRING
			db_sel: DB_SELECTION
			db_res: DB_RESULT
			db_tup: DB_TUPLE
		do
			create db_sel.make
			create db_tup.make
			q := "SELECT EXISTS (SELECT * FROM "
			q := q + a_name + " WHERE person_id = " + a_id.out + ");"
			db_sel.set_query (q)
			db_sel.execute_query
			db_sel.load_result
			db_res := db_sel.cursor
			check attached db_res as r then
				db_tup.copy (r)
				Result := attached {INTEGER_REF} db_tup.item (1) as ir and then
					not (ir.item = 0)
			end
			db_sel.terminate
		end

	add_list_mark (a_id: INTEGER)
			-- Ensure the database shows the corresponding row in the
			-- person table as being in the list.
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			q := "UPDATE person SET is_member = TRUE"
			q := q + " WHERE person_id = " + a_id.out +  ";"
			db_chg.modify (q)
		end

	remove_list_mark (a_id: INTEGER)
			-- Ensure the database does not show the object identified
			-- by `a_id' in the list of person objects.
		local
			q: STRING
			db_chg: DB_CHANGE
		do
			create db_chg.make
			q := "UPDATE person SET is_member = FALSE"
			q := q + " WHERE person_id = " + a_id.out +  ";"
			db_chg.modify (q)
		end

	loaded (a_id: INTEGER): detachable PERSON
			-- Attempt to load the identified {PERSON} from a MySQL database.
		local
			db_sel: DB_SELECTION
			db_res: DB_RESULT
			db_tup: DB_TUPLE
			q: STRING
			ndx: INTEGER
			n, ae_name: STRING
			ae_age: INTEGER
			is_h, is_s, is_sh, is_sk: BOOLEAN
			c_id: INTEGER
			p: PERSON
			c: detachable PERSON
		do
			create db_sel.make
			create db_tup.make
			n := "name not yet read"
			ae_name := "alter_ego name not yet read"
			if is_person_stored (a_id) then
					-- Get the {PERSON} data.
				q := "SELECT person_index, person_name FROM person "
				q := q + "WHERE person_id = " + a_id.out + ";"
				db_sel.query (q)
				db_sel.load_result
				db_res := db_sel.cursor
				check attached db_res as r then
					db_tup.copy (r)
					check attached {INTEGER_REF} db_tup.item (1) as ir then
						ndx := ir.item
					end
					check attached {STRING} db_tup.item (2) as s then
						n := s
					end
				end
				db_sel.terminate
					-- Determine type(s) of stored object
				is_h := is_hero_stored (a_id)
				is_s := is_super_stored (a_id)
				is_sh :=  is_superhero_stored (a_id)
				is_sk := is_sidekick_stored (a_id)
					-- Load appropriate data
				if is_s then
						-- Load `alter_ego' data for use in creation.
					q := "SELECT name, age FROM alter_ego "
					q := q + "WHERE person_id = " + a_id.out + ";"
					db_sel.query (q)
					db_sel.load_result
					db_res := db_sel.cursor
					check attached db_res as r then
						db_tup.copy (r)
						check attached {STRING} db_tup.item (1) as s then
							ae_name := s
						end
						check attached {INTEGER_REF} db_tup.item (2) as ir then
							ae_age := ir.item
						end
					end
					db_sel.terminate
				end
						-- Create the correct type.
				if is_sh then
					create {SUPERHERO} p.make (n, ae_name, ae_age)
				elseif is_sk then
					create {SIDEKICK} p.make (n, ae_name, ae_age)
				elseif is_s then
					create {SUPER} p.make (n, ae_name, ae_age)
				elseif is_h then
					create {HERO} p.make (n)
				else
					create {PERSON} p.make (n)
				end
					-- Set common attributes not set during creation.
				p.set_persistence_id (a_id)
				p.set_index (ndx)
					-- If necessary, get and set the `companion'.
				if attached {HERO} p as h then
					q := "SELECT companion_id FROM hero "
					q := q + "WHERE person_id = " + a_id.out + ";"
					create db_sel.make
					db_sel.query (q)
					db_sel.load_result
					db_res := db_sel.cursor
					check attached db_res as r then
						db_tup.copy (r)
						check attached {INTEGER_REF} db_tup.item (1) as ir then
							c_id := ir.item
						end
					end
					db_sel.terminate
					if c_id > 0 and not is_loading_companion then
						is_loading_companion := true
						c := loaded (c_id)
						is_loading_companion := false
					end
					if attached {HERO} c as ot_c then
						h.set_companion (ot_c)
					else
						h.remove_companion
					end
				end
				Result := person_table.item (a_id)
				if attached Result then
					Result.copy (p)
				else
					person_table.force (p, p.persistence_id)
					if attached {HERO} p as h then
						person_table.force (h, h.persistence_id)
					end
					Result := p
				end
			end
		end

	is_loading_companion: BOOLEAN
			-- Used to break cycles in the `companion' attribute when
			-- loading {HERO} objects.

	loaded_list: like members
			-- Create a list of {PERSON} objects from data in the database.
		local
			q: STRING
			con: ARRAYED_LIST [DB_RESULT]
			per: PERSON
			db_sel: DB_SELECTION

			db_tup: DB_TUPLE
		do
			create Result.make
			create db_sel.make
			create db_tup.make
			create con.make (10)
			q := "SELECT person_id FROM person;"
			db_sel.set_container (con)
			db_sel.query (q)
			db_sel.load_result
			from con.start
			until con.after
			loop
				db_tup.copy (con.item)
				check attached {INTEGER_REF} db_tup.item (1) as ir then
					per := loaded (ir.item)
					check attached per as p then
						Result.extend (p)
					end
				end
				con.forth
			end
			db_sel.terminate
		end

	person_table: HASH_TABLE [PERSON, INTEGER]
			-- Associates a database-generated id with a {PERSON}.

feature {NONE} -- Implementation (Eiffel Store related)

	db_control: DB_CONTROL
			-- Manages the database (i.e. establish connection, disconnect,
			-- handle errors, and get information about database.)

end

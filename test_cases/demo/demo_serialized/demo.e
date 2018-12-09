note
	description: "[
		This class used Eiffel Software's serialization features,
		such as RAW_FILE.independent_store and RAW_FILE.retrieved, to
		immulate as closely as possible the facilities provided by
		P-Eiffel.  Comparing this class' metrics to the equivalent
		one in the P-Eiffel test gives insight into the benefits of
		P-Eiffel.
		]"
	author:     "Jimmy J. Johnson"

class
	DEMO

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
				-- Must set the repository before creating identified objects
			initialize
			io.put_string ("End Persistence DEMO.make %N")
		end

	Initialize
			-- Setup the test object structure.
		do
				-- Create the objects
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
			-- Holds the other objects.

	john: detachable PERSON
			-- John Galt object having a `name' and an `index'.

	incredible: SUPER
			-- Mr. Incredible has an `alter_ego' and void `companion'.
			-- (He has not yet met Elasti-Girl.)

	han: HERO
			-- Han Solo, a `companion' (from {HERO}) of `chewie'.

	chewie: HERO
			-- Chewbacca, the `companion' of `han'.

	batman: SUPERHERO
			-- Object with multiple inheritance (from {SUPER} and {HERO}) having
			-- an `alter_ego' (from {SUPER}) and a `sidekick' (renamed `compainion'
			-- from {HERO})
			-- Sidekick of `robin'

	robin: detachable SIDEKICK
			-- Object with an `alter_ego', which is expanded {ALTER_EGO} type
			-- Object with multiple inheritance (from {SUPER} and {HERO}) having
			-- an `alter_ego' (from {SUPER}) and a `sidekick' (renamed `compainion'
			-- from {HERO}).
			-- Sidekick of `batman'.

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
			-- Perform all the steps in the demo program.
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
--			io.put_string ("The last tabulation is: ")
--			Tabulation.show
--			repository.show
--			Persistence_manager.show_facilities
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
			-- Call `store' on each object that is in `dirty_objects'
			-- and ensure that object is no longer dirty.
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
			store (members)
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
			end
		end

	set_batman_alter_ego_name
			-- Correct the `name' of `robin's `alter_ego'.
		do
			batman.set_alter_ego_name ("Bruce Wayne")
			mark (batman)
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
				store (members)
			end
		end

	load_chewie
			-- Restore `chewie' to its previous state to demonstrate
			-- manual loading.
		do
			check attached {HERO} loaded (chewie) as c then
				if c /= chewie then
					io.put_string ("  Loaded chewie NOT the same object as with persistence. %N")
				end
			end
				-- Load `chewie'
			check attached {HERO} loaded (chewie) as c2 then
				check not_same_objects: c2 /= chewie then end
				check equivalent_objects: c2 ~ chewie then end
				check deep_equal_objecs: c2.is_deep_equal (chewie) then end
			end
		end

	load_incredible
			-- Load `incredible' to test loading of expanded objects.
		do
			check attached {SUPER} loaded (incredible) as i then
				check equivalent_objects: i ~ incredible then end
			end
		end

	load_list
			-- Load the `members'.
			-- This should not duplicate `chewie' or `incredible' which were loaded
			-- in previous steps.
		do
			check attached {TWO_WAY_SORTED_SET [PERSON]} loaded (members) as ss then
					-- This fails because we lose object identity.
--				check ss.is_deep_equal (members) end
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

	step_actions: HASH_TABLE [TUPLE [action: PROCEDURE [ANY, TUPLE];
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

	mark (a_object: ANY)
			-- Mark `a_object' as dirty.
		do
			dirty_objects.extend (a_object)
			if is_automatic then
				checkpoint
			end
		end

	dirty_objects: LINKED_LIST [ANY]
			-- List of objects marked as dirty.
		once
			create Result.make
		end

	store (a_object: ANY)
			-- Store `a_object' using IO_MEDIUM.independent_store into a file
			-- with the generating_type of `a_object' plus its "name" feature, if
			-- there is such a feature.  This feature consolidates the persistence
			-- operations into one place to align as close a possible to the
			-- P-Eiffel {DEMO} program.
		local
			s: STRING_8
			f: RAW_FILE
		do
			s := a_object.generating_type
			if attached {PERSON} a_object as p then
				s := s + "_" + p.name
			end
			create f.make_open_write (s)
			f.independent_store (a_object)
			dirty_objects.start
			dirty_objects.prune (a_object)
		end

	loaded (a_object: ANY): detachable ANY
			-- Attempt to load the object from the file that was created when
			-- the object `a_object' was stored.
		local
			s: STRING_8
			f: RAW_FILE
		do
			s := a_object.generating_type
			if attached {PERSON} a_object as p then
				s := s + "_" + p.name
			end
			create f.make_open_read (s)
			Result := f.retrieved
		end

end

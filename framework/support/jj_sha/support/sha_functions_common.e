note
	description: "[
		Base class for SHA (Secure Hash Algorithms) generator classes which
		produce a multi-bit `digest' from a string `message'.  Some of these
		functions only apply to a subset of the descendent classes (e.g. `parity',
		which is only used by SHA_).
		
--		Implemented by combining SHA_MESSAGE, which is inherited, with an SHA_PARSER,
--		which is an attribute.

		See FIPS Pub 180-4 (Mar 2012).
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SHA_FUNCTIONS_COMMON

inherit

	SHA_PARSER
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize Current
		do
			create message_schedule.make_filled (Void, 0, Upper_index)
		end

feature {NONE} -- Basic operations

	rotate_left (x: like word_type; n: INTEGER): like word_type
			-- Circular left shift of 'x' by `n'
			-- (x << n) v (x >> w-n) where w = `bits_per_word'
			-- FIBS Pub 180-4 (Mar 2012) pages 8-9
		require
			n_big_enough: n >= 0
			n_small_enough: n < bits_per_word
		do
			Result := x.bit_shift_left (n) | x.bit_shift_right (bits_per_word - n)
		end

	rotate_right (x: like word_type; n: INTEGER): like word_type
			-- Circular right shift of 'x' by `n'
			-- (x >> n) v (x << w-n) where w = `bits_per_word'
			-- FIBS Pub 180-4 (Mar 2012) pages 8-9
		require
			n_big_enough: n >= 0
			n_small_enough: n < bits_per_word
		do
			Result := x.bit_shift_right (n) | x.bit_shift_left (bits_per_word - n)
		end

	right_shift (x: like word_type; n: INTEGER): like word_type
			-- The "right shift" function used by SHA-224, SHA-256, SHA-384,
			-- SHA-512, SHA-512/224, and SHA-512/256 as defined in
			-- FIBS Pub 180-4 (Mar 2012) page 8.
		require
			n_big_enough: n >= 0
			n_small_enough: n < bits_per_word
		do
			Result := x.bit_shift_right (n)
		end

	ch (x, y, z: like word_type): like word_type
			-- The "Ch(x,y,z)" function as defined in
			-- FIBS Pub 180-4 (Mar 2012) pages 10-11
		do
			Result := (x & y).bit_xor (x.bit_not & z)
		end

	maj (x, y, z: like word_type): like word_type
			-- The "Maj(x,y,z)" function as defined in
			-- FIBS Pub 180-4 (Mar 2012) pages 10-11
		do
			Result := ((x & y).bit_xor (x & z)).bit_xor (y & z)
		end

	w_sub_t (t, i: INTEGER): like word_type
			-- The `t'-th word from the schedule (i.e. `blocks') of the hash
			-- for i-th block
		require
			t_big_enough: t >= 0
			t_small_enough: t <= Upper_index
			i_big_enough: i >= 1
			i_small_enough: i <= blocks.count
		deferred
		end

feature {NONE} -- Implementation (Constants array)

	Upper_index: INTEGER
			-- One less than the number of intermediate hash calculations performed
			-- by the algorithm; the index of the last calculation or accessed word
		deferred
		ensure
			valid_result: Result = 79 or Result = 63
		end

	big_k: ARRAY [like word_type]
			-- Zero-based array holding constants (represented by "K") in
			-- FIPS Pub 180-4 (Mar 2012) pages 11-12.
			-- Effected features should choose from one of `K_1_constants',
			-- `K_256_constants', or `K_512_constants'.
		deferred
		ensure
			correct_lower_bount: Result.lower = 0
			correct_upper_bound: Result.upper = Upper_index
			correct_count: Result.count = Upper_index + 1
			correct_capacity: Result.capacity = Upper_index + 1
		end

	k_sub_t (t: INTEGER): like word_type
			-- Access into the `big_k' array
		require
			t_big_enough: t >= 0
			t_small_enough: t <= Upper_index
		do
			Result := big_k [t]
		end

	message_schedule: ARRAY [detachable like word_type_reference]
			-- The message schedule for this hash iteration
			-- This allows dynamic programming, saving values as they are calculated

	new_word_ref (a_word: like word_type): CELL [like word_type]
			-- Create a new reference containing `a_word' stored in `blocks'
		do
			create Result.put (a_word)
		end

feature {NONE} -- Anchors

	word_type_reference: CELL [like word_type]
			-- Anchor for type used by the SHA calculations; 32 or 64 bits.
			-- This should really be some ancestor common to both NATURAL_32_REF
			-- and NATURAL_64_REF, but (other than ANY) that does not exist.
			-- Not to be called; just used to anchor types.
			-- Declared as a feature to avoid adding an attribute.
		require
			not_callable: False
		do
			check
				do_not_call: False then
					-- Because gives no info; simply used as anchor.
			end
		end

end

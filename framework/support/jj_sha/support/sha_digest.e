note
	description: "[
		Base class defining the various SHA (Secure Hash Algorithms message digests.
		A message digest, or simply digest, is the result calculated by running a
		SHA on a string message.  It consists of from five to eight, 32- or 64-bit
		words, (depending on the algorithm) formatted as a string.
		
		This class defines eight NATURAL words used by `calculate' in the SHA-x 
		classes as working variables to compute the hash.  Descendents define the
		initial hash values and effect `as_hex_string'.
		
		See FIPS Pub 180-4, Mar 2012.
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"


deferred class
	SHA_DIGEST

inherit

	HASHABLE

feature -- Access

	word_0: like word_type
			-- The zero-th working variable (i.e. first word).
	word_1: like word_type
	word_2: like word_type
	word_3: like word_type
	word_4: like word_type
	word_5: like word_type
	word_6: like word_type
	word_7: like word_type
			-- The 8th working variable; the 8th word of the calculation

	frozen as_string: STRING_8
			-- The `as_hex_string' converted to lower case as described
			-- in FIPS PUB 180-4 (Mar 2012)
		do
			Result := as_hex_string.as_lower
		end

	as_hex_string: STRING_8
			-- The words of Current as hexidecimal strings
			-- a space between each word.
		deferred
		end

	hash_code: INTEGER
			-- Produced from the hash-code of the string representation of Current
		do
			Result := as_hex_string.hash_code
		end

feature -- Element change

	initialize
			-- Set to initial values
		deferred
		end

	wipe_out
			-- Set all words to zero
		do
			word_0 := word_0.zero
			word_1 := word_0.zero
			word_2 := word_0.zero
			word_3 := word_0.zero
			word_4 := word_0.zero
			word_5 := word_0.zero
			word_6 := word_0.zero
			word_7 := word_0.zero
		ensure
			word_0_is_zero: word_0 ~ word_0.Zero
			word_1_is_zero: word_1 ~ word_0.Zero
			word_2_is_zero: word_2 ~ word_0.Zero
			word_3_is_zero: word_3 ~ word_0.Zero
			word_4_is_zero: word_4 ~ word_0.Zero
			word_5_is_zero: word_5 ~ word_0.zero
			word_6_is_zero: word_6 ~ word_0.zero
			word_7_is_zero: word_7 ~ word_0.zero
		end

	set_five (w0, w1, w2, w3, w4: like word_type)
			-- Assign correspoding values to the first five words (for SHA-1).
		do
			word_0 := w0
			word_1 := w1
			word_2 := w2
			word_3 := w3
			word_4 := w4
		end

	set_all (w0, w1, w2, w3, w4, w5, w6, w7: like word_type)
			-- Assign correspoding values to all eight words.
		do
			word_0 := w0
			word_1 := w1
			word_2 := w2
			word_3 := w3
			word_4 := w4
			word_5 := w5
			word_6 := w6
			word_7 := w7
		end

feature {NONE} -- Anchors

	word_type: NATURAL_32
			-- Anchor for type used by the SHA calculations; 32 or 64 bits.
			-- Not to be called; just used to anchor types.
			-- Declared as a feature to avoid adding an attribute.
		require else
			not_callable: False
		do
			check
				do_not_call: False then
					-- Because gives no info; simply used as anchor.
			end
		end

end

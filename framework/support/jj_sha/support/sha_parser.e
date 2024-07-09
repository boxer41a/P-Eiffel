note
	description: "[
		Base class for the parser classes which are used to preprocess and pad
		messages before calculation of a `digest' in the SHA (Secure Hash Algorithm)
		classes (e.g. SHA_1_GENERATOR and SHA_512_GENERATOR).

		This class implements `pad', which adds a one and rounds off to a word
		boundary, and `parse', which places the message bytes into blocks as
		words in preparation for `calculate'.

		See FIPS Pub 108-4 (Mar 2012)
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SHA_PARSER

inherit

	SHA
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize Current
		do
			Precursor
			create blocks.make (5)
		end

feature {SHA_PARSER} -- Basic operations

	pad
			-- Add a one (really a byte containing a one in the high order bit
			-- followed by seven zero's) after the last bit in `message'.
		local
			n: NATURAL_8
		do
				-- Add the one as the left-most nibble in a byte (i.e. 0x80 or 0b10000000)
			n := 0x80
			message.extend (n)
				-- Round off the "word" with zeros
			from
			until (message.count \\ bytes_per_word) = 0
			loop
				message.extend (n.zero)
			end
			is_padded := true
		end

	parse
			-- Parse the `message' into "blocks" and "words", placing the words into
			-- the  `blocks' list and adding the length (in bits) as the last two words.
			-- See FIBs Pub 180-4 (Mar 2012).
		local
			fbc: INTEGER				-- full block count
			bc, wc, i: INTEGER
			rem: INTEGER
			w: like word_type
			b: detachable like block_type
		do
			fbc := message.count // bytes_per_word // 16
				-- Build up the full blocks (each has 16 words)
			from bc := 1
			until bc > fbc
			loop
				b := new_block
				blocks.extend (b)
				from i := 1
				until i > 16
				loop
					wc := wc + 1
					w := i_th_word (wc)
					b.put (w, i - 1)
					i := i + 1
				end
				bc := bc + 1
			end
				-- How many words are left in the `message'?
			rem := words_per_message - wc
			check
				only_partial_block_left: rem <= 15
					-- because complete blocks were read above
			end
				-- Now build one last block, placing any remaining words into it
			if rem > 0 then
				b := new_block
				blocks.extend (b)
				from i := 1
				until i > rem
				loop
					w := i_th_word (wc + i)
						-- Reminder: a `block' is zero-based
					b.put (w, i - 1)
					i := i + 1
				end
			end
				-- If there is room, place the `length' in the last two words
				-- of this block, else place the `length' in the last two words
				-- of a new block.  Reminder: a `new_block' is zero-based.
			if rem = 0 or rem = 15 then
				b := new_block
				blocks.extend (b)
			end
			check attached b as otb then
				otb.put (length.w1, 14)
				otb.put (length.w2, 15)
			end
			is_parsed := true
		end

	words_per_message: INTEGER
			-- The number of words in the padded `message'
		require
			is_padded: is_padded
			correct_word_boundaries: message.count \\ bytes_per_word = 0
		do
			Result := message.count // bytes_per_word
		end

	i_th_word (a_index: INTEGER): like word_type
		require
			is_padded: is_padded
			correct_word_boundaries: message.count \\ bytes_per_word = 0
			index_big_enough: a_index >= 1
			index_small_enough: a_index <= words_per_message
		deferred
		end

feature {NONE} -- Implementation (message parsing)

	blocks: ARRAYED_LIST [like block_type]
			-- An array of blocks, holding the parsed message

	new_block: like block_type
			-- Create a new block containing 16 words.
			-- A word (i.e. of word_type) contain 32 bits for SHA-1,
			-- SHA-224, & SHA-25 giving 512-bit blocks; a word contains
			-- 64 bits for SHA-384, SHA-512, SHA-512/224, and SHA-512/256
			-- giveing 1024-bit blocks.
			-- FIPS Pub 180-4 (Mar 2012) page 14.
		local
			n: like word_type
		do
				-- We need to get hold of a word so we can get `zero';
				-- the value for `n' does not matter.
			n := word_zero
			create Result.make_filled (word_zero, 0, 15)
		end

feature {NONE} -- Anchors

	block_type: ARRAY [like word_type]
			-- The type of the N blocks (512-bits or 1024-bits), each made
			-- of 16 [32-bit or 64-bit] words
			-- Anchor for type used by the SHA calculations.
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

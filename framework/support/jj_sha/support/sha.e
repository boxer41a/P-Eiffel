note
	description: "[
		Class implementing the SHA_1 functions only using NATURAL_32.

		Use `set_with_string or `set_with_filename' to set the text from which
		an SHA digest is to be calculated.  Call `digest' to get the result 
		of the calculation which is performed on the first call to `digest'; 
		subsequent calls look up the previously calculated value.  Calling
		either set feature resets the calculation flags causing the direst
		to be recalculated on the next call to `digest'.

		See FIPS Pub 180-4 (Mar 2012).
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SHA

inherit

	ANY
		redefine
			default_create,
			out
		end

feature {NONE} -- Initialization

	default_create
		do
			create message.make (256)
			message_origin := ""
			out_count := Default_out_count
			set_length_imp
		end

feature -- Initialization

	set_with_string (a_string: STRING_GENERAL)
			-- Initialize Current from `a_string', breaking the string into bytes.
		local
			i: INTEGER
			c: NATURAL_32
		do
			default_create
			message_origin := a_string
			message.wipe_out
			if a_string.is_string_32 then
				from i := 1
				until i > a_string.count
				loop
					c := a_string.item (i).code.as_natural_32
					message.extend (c.bit_and (0xF000).bit_shift_right (24).as_natural_8)
					message.extend (c.bit_and (0x0F00).bit_shift_right (16).as_natural_8)
					message.extend (c.bit_and (0x00F0).bit_shift_right (8).as_natural_8)
					message.extend (c.bit_and (0x000F).bit_shift_right (0).as_natural_8)
					i := i + 1
				end
			elseif a_string.is_string_8 then
				from i := 1
				until i > a_string.count
				loop
					message.extend (a_string.item (i).code.as_natural_8)
					i := i + 1
				end
			else
				check
					should_not_happen: false then
						-- because there are only the two string types
				end
			end
			is_from_file := false
			is_padded := false
			is_parsed := false
			is_calculated := false
			set_length_imp
		end

	set_with_filename (a_filename: STRING_GENERAL)
			-- Initialize from the file named `a_filename'
		require
			filename_not_empty: not a_filename.is_empty
			filename_not_blank: not a_filename.is_whitespace
			file_exists: (create {RAW_FILE}.make_with_name (a_filename)).exists
		local
			f: RAW_FILE
			p: MANAGED_POINTER
			i: INTEGER
		do
			default_create
			message_origin := a_filename
			create f.make_open_read_write (a_filename)
			create p.make (f.count)
			f.read_to_managed_pointer (p, 0, f.count)
			from i := 0
			until i > p.count - 1
			loop
				message.extend (p.read_natural_8 (i))
				i := i + 1
			end
			is_from_file := true
			is_padded := false
			is_parsed := false
			is_calculated := false
			set_length_imp
		end

feature -- Access

	frozen digest: attached like digest_imp
			-- The result of the computation
			-- Reset when `message' is changed
		do
			if not is_calculated then
				calculate
				is_calculated := true
			end
			check attached digest_imp as d then
				Result := d
			end
		end

	message: SHA_MESSAGE
			-- The list of bytes making up Current; an ARRAY [NATURAL_8]

	out_count: INTEGER_32
			-- The limit set for number of bytes shown by `out'

	Default_out_count: INTEGER_32 = 50
			-- The default number of bytes shown by `out'

	out: STRING_8
			-- New string containing terse printable representation
			-- of current object.
		local
			n: INTEGER
		do
			check attached message_origin as m then
				if is_from_file then
					Result := ""
					from
						n := 1
						message.start
					until message.after or n > out_count
					loop
						Result.append (message.item.to_hex_string)
						message.forth
						n := n + 1
					end
				else
					Result := m.head (out_count).out
				end
			end
		end

feature -- Element change

	set_out_count (a_value: like out_count)
			-- Change `out_count'
		do
			out_count := a_value
		end

feature -- Status report

	is_from_file: BOOLEAN
			-- Was Current initialized by a call to `set_with_filename'?
			-- If this is true, the string given by `out' will be formated as
			-- individual bytes in hexidecimal.

	is_padded: BOOLEAN
			-- Has the message been padded with a "one", zero's, and `length'?

	is_parsed: BOOLEAN
			-- Has the message been parsed into its corresponding `blocks'?

	is_calculated: BOOLEAN
			-- Has the `digest' been calculated?

feature -- Basic operations

	frozen calculate
			-- Calculate and make result available in the `digest'
		require
			not_calculated: not is_calculated
		do
			if not is_padded then
				pad
			end
			if not is_parsed then
				parse
			end
			calculate_imp
			is_calculated := true
		end

feature {NONE} -- Basic operations

	pad
			-- Add a one (really a byte containing a one in the high order bit
			-- followed by seven zero's) after the last bit in `message'.
		require
			not_padded: not is_padded
		deferred
		ensure
			is_padded: is_padded
		end

	parse
			-- Parse the message into "blocks" usable by the calculations.
		require
			not_parsed: not is_parsed
			is_padded: is_padded
			correct_word_boundaries: message.count \\ bytes_per_word = 0
		deferred
		ensure
			is_parsed: is_parsed
		end

	calculate_imp
			-- Calculations specific to the particular SHA type
		require
			is_padded: is_padded
			is_parsed: is_parsed
			not_calculated: not is_calculated
		deferred
		end

feature {SHA} -- Implementation

	message_origin: detachable STRING_GENERAL
			-- Store the string or filename from which Current was built
			-- to simplify output (otherwize would have to convert bytes
			-- to characters.

	length: TUPLE [w1: like word_type; w2: like word_type]
			-- The length (in bits) of the original message expressed in two words
		do
			check attached length_imp as len then
				Result := len
			end
		end

	byte_count: INTEGER
			-- The number of bytes in `message'
		do
			Result := message.count
		end

	length_imp: detachable like length
			-- Implementation of `length' to delay creation

	set_length_imp
			-- Calculate the length in bits of the `message' and place in `length_imp'
		deferred
		end

	bits_per_word: INTEGER = 32
			-- The number of bits in the `word_type'

	bytes_per_word: INTEGER = 4
			-- The number of bytes in the `word_type' (4 for 32/8)

feature {NONE} -- Anchors

	word_zero: like word_type
			-- To obtain a number of the correct type

	word_type: NATURAL_32
			-- Anchor for type used by the SHA calculations; 32 or 64 bits.
			-- Not to be called; just used to anchor types.
			-- Declared as a feature to avoid adding an attribute.
			-- This should be an ancestor of the NATURAL_xx types, but there is
			-- no such class.
		require
			not_callable: False
		do
			check
				do_not_call: False then
					-- Because gives no info; simply used as anchor.
			end
		end

	digest_imp: detachable SHA_DIGEST
			-- Allow dynamic programming in `digest'
		deferred
		end

--	block_type: ARRAY [like word_type]
--			-- The type of the N blocks (512-bits or 1024-bits), each made
--			-- of 16 [32-bit or 64-bit] words
--			-- Anchor for type used by the SHA calculations.
--			-- Not to be called; just used to anchor types.
--			-- Declared as a feature to avoid adding an attribute.
--		require
--			not_callable: False
--		do
--			check
--				do_not_call: False then
--					-- Because gives no info; simply used as anchor.
--			end
--		end

end

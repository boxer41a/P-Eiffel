note
	description: "[
		Class needed to give a concrete type to the geneic of SHA_PARSER, so
		`set_length_imp' and `i_th_word' will work correctly.  Otherwise, the
		features could not convert the bytes to the correct types, because
		prior to this class the `word_type' is JJ_NATURAL.
		
		See FIPS Pub 108-4 (Mar 2012)
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SHA_PARSER_32_BIT

inherit

	SHA_PARSER

feature -- Access

feature {NONE} -- Implementation (message parsing)

	set_length_imp
			-- Record the number of bits into `length_imp'; called after initialization.
		do
			length_imp := [word_zero, (message.count * 8).as_natural_32]
		end

	i_th_word (a_index: INTEGER): like word_type
			-- The `a_index'th word of the `message'
		local
			i: INTEGER
			b: NATURAL_8
			w: NATURAL_32
		do
			from i := 1
			until i > bytes_per_word
			loop
				b := message.i_th (((a_index - 1) * bytes_per_word) + i)
				w := word_zero + b
				Result := Result + w
				if i < bytes_per_word then
					Result := Result.bit_shift_left (8)
				end
				i := i + 1
			end
		end

end

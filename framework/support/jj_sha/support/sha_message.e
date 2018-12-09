note
	description: "[
		The byte sequence representing the message used to calculate
		SHA (Secure Hash Algorithm) digests for 32- or 64-bit hashes.

		See FIPS Pub 108-4 (Mar 2012)
		]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SHA_MESSAGE

inherit

	ARRAYED_LIST [NATURAL_8]

create
	make

feature {NONE} -- Initialization


end

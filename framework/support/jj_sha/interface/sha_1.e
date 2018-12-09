note
	description: "[
		Calculates the SHA-1 multi-bit `digest' for a string message.

		Use `set_with_string or `set_with_filename' to set the text for which
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

class
	SHA_1

inherit

	SHA_FUNCTIONS_1
		redefine
			default_create
		end

create
	default_create,
	set_with_string,
	set_with_filename

feature {NONE} -- Initialization

	default_create
			-- Initialize Current, creating the arrays
		do
			Precursor
			create digest_imp
		end

feature {NONE} -- Anchors

	digest_imp: detachable SHA_DIGEST_1
			-- Implementation of `digest'

end

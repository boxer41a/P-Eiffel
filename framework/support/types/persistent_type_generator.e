note
	description: "[
		SHA_GENERATOR used to produce a PERSISTENT_TYPE encoding
	]"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	PERSISTENT_TYPE_GENERATOR

inherit

	SHA_1
		redefine
			digest_imp
		end

feature {NONE} -- Anchors

	digest_imp: detachable PERSISTENT_TYPE
			-- Implementation of `digest'

end

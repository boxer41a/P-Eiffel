note
	description: "[
		Eiffel tests that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	SHA_TESTS

inherit

	EQA_TEST_SET
		redefine
			on_prepare
		end

feature -- Initialization

	on_prepare
		do
			create sha_1
			parser := sha_1
			test_name := "not set yet"
		end

feature {NONE} -- Implementation

	test_name: STRING_8
			-- The particular test being done

	parser: SHA_FUNCTIONS_COMMON
			-- Polymorphic holder for the particular version being tested

	sha_1: SHA_1

feature -- Basic operations

	print_line
			-- Draw a seperating line across the page
		do
			print ("-------------------------------------------------------- %N")
		end

	test (a_expected: STRING_8)
			-- Test if the `parser' produces `a_expected' digest
		local
			s: STRING_8
			d: STRING_8
		do
			s := parser.generating_type + "." + test_name
			d := parser.digest.as_string
			print (s + "%N")
			print ("%T expected = " + a_expected + "%N")
			print ("%T   actual = " + d + "%N")
			assert (s, d ~ a_expected)
		end

feature -- Usage demo and test

--	demo_test
--			-- Demonstrate usage of interface classes
--		local
--			sha_1: SHA_1
--			sha_512: SHA_512
--			d_1: SHA_DIGEST_1
--			d_512: SHA_DIGEST_512
--			m: STRING_8			-- The message
--			e, e2: STRING_8		-- Expected result
--		do
--				-- Example classes and two ways to use an SHA_xxx class
--			m := "abc"
--			create sha_1.set_with_string (m)
--			create sha_512
--			sha_512.set_with_string (m)
--				-- Calculate and print the SHA hash tags
--			d_1 := sha_1.digest
--			d_512 := sha_512.digest
--			print ("{SHA_TESTS}.demo_test %N")
--			print ("SHA-1 value:    " + d_1.as_string + "%N")
--			print ("SHA-512 value:  " + d_512.as_string + "%N")
--				-- Might as well test the results
--			e :=  "a9993e36 4706816a ba3e2571 7850c26c 9cd0d89d"
--			e2 := "ddaf35a193617aba cc417349ae204131 12e6fa4e89a97ea2 0a9eeee64b55d39a " +
--					"2192992a274fc1a8 36ba3c23a3feebbd 454d4423643ce80e 2a9ac94fa54ca49f"
--			assert ("Demo_test one", d_1.as_string ~ e)
--			assert ("Demo_test e2", d_512.as_string ~ e2)
--		end

feature -- Test routines (SHA-1)

	test_sha_1
			-- Test {SHA_1_ENCODER} as per FIPS PUB 180-2 (Aug 2002)
			-- Appendix A, pp 25-27
		do
			parser := sha_1
				-- One block
			test_name := "sha-1: single block"
			parser.set_with_string ("abc")
			test ("a9993e36 4706816a ba3e2571 7850c26c 9cd0d89d")
				-- Multi-block (55 char => partial block with lenth in second block)
			test_name := "sha-1: multi-block (56 chars)"
			parser.set_with_string ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
			test ("84983e44 1c3bd26e baae4aa1 f95129e5 e54670f1")
				-- Multi-block (62 char => one full block and length in second
				-- Checked with website "onlinemd5.com"
			test_name := "sha-1: multi-block (62 chars)"
			parser.set_with_string ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq123456")
			test ("9d9d6d43 639baf54 bc62d95e 9804ca4c 03c82163")
				-- Long message
			test_name := "sha-1: one million a's"
--			parser.set_with_string (create {STRING_8}.make_filled ('a', 1_000_000))
--			test ("34aa973c d4c4daa4 f61eeb2b dbad2731 6534016f")
			print_line
		end

end



describe("strip_encap_quotes", function()
	local lib = require "resty.waf.translate"
	local s   = lib.strip_encap_quotes

	it("strips quotes from a single-quoted string", function()
		assert.is.same(s("'foo'"), "foo")
	end)

	it("strips quotes from a double-quoted string", function()
		assert.is.same(s('"foo"'), "foo")
	end)

	it("leaves an unquoted string as-is", function()
		assert.is.same(s("foo"), "foo")
	end)

	it("does not strip left-unbalanced quotes", function()
		assert.is.same(s("'foo"), "'foo")
	end)

	it("does not strip right-unbalanced quotes", function()
		assert.is.same(s("foo'"), "foo'")
	end)

	it("does not strip left-mismatched quotes", function()
		assert.is.same(s([['foo"]]), [['foo"]])
	end)

	it("does not strip right-mismatched quotes", function()
		assert.is.same(s([["foo']]), [["foo']])
	end)

	it("only strips one set of quotes", function()
		assert.is.same(s([[""foo""]]), [["foo"]])
	end)

end)

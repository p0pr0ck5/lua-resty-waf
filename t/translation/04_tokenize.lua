describe("tokenize", function()
	local lib = require "resty.waf.translate"
	local t = lib.tokenize

	it("takes a single token", function()
		assert.are.same(t('foo'), {'foo'})
	end)

	it("takes two tokens", function()
		assert.are.same(t('foo bar'), {'foo', 'bar'})
	end)

	it("takes a single quote-wrapped token", function()
		assert.are.same(t('"foo"'), {'foo'})
	end)

	it("takes two quote-wrapped tokens", function()
		assert.are.same(t('"foo" "bar"'), {'foo', 'bar'})
	end)

	it("takes two tokens, first quote-wrapped", function()
		assert.are.same(t('"foo" bar'), {'foo', 'bar'})
	end)

	it("takes two tokens, second quote-wrapped", function()
		assert.are.same(t('foo "bar"'), {'foo', 'bar'})
	end)

	it("takes a quote-wrapped token with a single escaped quote", function()
		assert.are.same(t([["foo \"bar"]]), {[[foo "bar]]})
	end)

	it("takes a quote-wrapped token with two escaped quotes", function()
		assert.are.same(t([["foo \"bar\""]]), {[[foo "bar"]]})
	end)

	it("takes a quote-wrapped token with a single escaped quote, " ..
		"then an unquoted token", function()
		assert.are.same(t([["foo \"" bar]]), {[[foo "]], [[bar]]})
	end)

	it("takes an unquoted token, then a quote-wrapped token " ..
		"with a single escaped quote", function()
		assert.are.same(t([[foo "bar \""]]), {[[foo]], [[bar "]]})
	end)

	it("takes four tokens, the last of which is quote-wrapped", function()
		assert.are.same(t([[foo bar baz "bat"]]), {
			[[foo]],
			[[bar]],
			[[baz]],
			[[bat]],
		})
	end)

	it("takes four tokens, the last of which is quote-wrapped and " ..
		"escaped with single quotes", function()
		assert.are.same(t([[foo bar baz "bat,qux:'frob foo'"]]), {
			[[foo]],
			[[bar]],
			[[baz]],
			[[bat,qux:'frob foo']],
		})
	end)

	it("takes four tokens, two of which are quote-wrapped, and one with " ..
		"escaped quotes", function()
		assert.are.same(t([[foo bar "baz \"qux\"" "bat"]]), {
			[[foo]],
			[[bar]],
			[[baz "qux"]],
			[[bat]],
		})
	end)

end)


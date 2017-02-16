describe("parse_operator", function()
	local lib = require "resty.waf.translate"
	local p   = lib.parse_operator

	it("has a default operator", function()
		assert.is.same(p('foo'), {
			operator = 'rx',
			pattern  = 'foo'
		})
	end)

	it("parses an explicitly defined operator", function()
		assert.is.same(p('@rx foo'), {
			operator = 'rx',
			pattern  = 'foo'
		})
	end)

	it("parses an explicitly defined (non default) operator", function()
		assert.is.same(p('@streq foo'), {
			operator = 'streq',
			pattern  = 'foo'
		})
	end)

	it("parses a numeric pattern", function()
		assert.is.same(p('@eq 5'), {
			operator = 'eq',
			pattern  = '5'
		})
	end)

	it("parses a negative operator", function()
		assert.is.same(p('!@rx foo'), {
			operator = 'rx',
			pattern  = 'foo',
			negated  = '!'
		})
	end)

	it("parses an operator with no pattern", function()
		assert.is.same(p('@detectSQLi'), {
			operator = 'detectSQLi',
			pattern  = ''
		})
	end)

	it("parses a negative operator with no pattern", function()
		assert.is.same(p('!@detectSQLi'), {
			operator = 'detectSQLi',
			pattern  = '',
			negated  = '!'
		})
	end)

	it("parses negation with the implicit operator", function()
		assert.is.same(p('!foo'), {
			operator = 'rx',
			pattern  = 'foo',
			negated  = '!'
		})
	end)

	it("parses negation with a proceeding space char", function()
		assert.is.same(p('! foo'), {
			operator = 'rx',
			pattern  = ' foo',
			negated  = '!'
		})
	end)

	it("parses negation with a proceeding space char and an incorrect "..
		"operator assignment", function()
		assert.is.same(p('! @rx foo'), {
			operator = 'rx',
			pattern  = ' @rx foo',
			negated  = '!'
		})
	end)

	it("parses an operator with no pattern, and space following negation",
		function()
		assert.is.same(p('! @detectSQLi'), {
			operator = 'rx',
			pattern  = ' @detectSQLi',
			negated  = '!'
		})
	end)

	it("errors when encountering a pattern that does not match its regex",
		function()
		pending("need to figure out mocking ngx.re")

		assert.has.error(function() p('foo') end)
	end)
end)

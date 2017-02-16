describe("translate_vars", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_vars

	local translation
	before_each(function()
		translation = {}
	end)

	it("translates a var in the lookup table", function()
		local rule = {
			vars = {{
				variable = 'REQUEST_METHOD',
				specific = '',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'METHOD' }
		})
	end)

	it("translates two var in the lookup table", function()
		local rule = {
			vars = {
				{
					variable = 'REQUEST_METHOD',
					specific = '',
				},
				{
					variable = 'TIME',
					specific = '',
				},
			}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'METHOD' },
			{ type = 'TIME' },
		})
	end)

	it("translates a var in the lookup table with a parse helper", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'REQUEST_ARGS', parse = { 'values', true } }
		})
	end)

	it("translates a var in the lookup table with specific element", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = 'foo',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'REQUEST_ARGS', parse = { 'specific', 'foo' } }
		})
	end)

	it("errors when given a conflicting specific element", function()
		local rule = {
			vars = {{
				variable = 'RESPONSE_CONTENT_LENGTH',
				specific = 'foo',
			}}
		}

		assert.has.error(function() t(rule, translation) end)
	end)

	it("translates a storage var (uppercasing the specific element)", function()
		local rule = {
			vars = {{
				variable = 'IP',
				specific = 'foo',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'IP', parse = { 'specific', 'FOO' }, storage = true }
		})
	end)

	it("translates a var with a length modifier", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
				modifier = '&'
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'REQUEST_ARGS', parse = { 'values', true }, length = true }
		})
	end)

	it("translates a var with a specific element & length modifier", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = 'foo',
				modifier = '&'
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{
				type = 'REQUEST_ARGS',
				parse = { 'specific', 'foo' },
				length = true
			}
		})
	end)

	it("translates a var with a specific regex value", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '/foo/',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{ type = 'REQUEST_ARGS', parse = { 'regex', 'foo' } }
		})
	end)

	it("translates a var with an ignored value", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
				modifier = '!',
				ignore   = { 'foo' }
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{
				type   = 'REQUEST_ARGS',
				parse  = { 'values', true },
				ignore = { { 'ignore', 'foo' } },
			}
		})
	end)

	it("translates a var with multiple ignored values", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
				modifier = '!',
				ignore   = { 'foo', 'bar' }
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{
				type   = 'REQUEST_ARGS',
				parse  = { 'values', true },
				ignore = { { 'ignore', 'foo' }, { 'ignore', 'bar' } },
			}
		})
	end)

	it("translates a var with a regex ignored value", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
				modifier = '!',
				ignore   = { '/foo/' }
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{
				type   = 'REQUEST_ARGS',
				parse  = { 'values', true },
				ignore = { { 'regex', 'foo' } },
			}
		})
	end)

	it("translates a var with regex and specific ignored values", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '',
				modifier = '!',
				ignore   = { '/foo/', 'bar' }
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars, {
			{
				type   = 'REQUEST_ARGS',
				parse  = { 'values', true },
				ignore = { { 'regex', 'foo' }, { 'ignore', 'bar' } },
			}
		})
	end)

	it("removes the encapsulating slashes in a regex element", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = '/foo/',
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars[1].parse[2], 'foo')
	end)

	it("removes the encapsulating slashes/quotes in a regex element", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = "'/foo/'",
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars[1].parse[2], 'foo')
	end)

	it("does not remove a slash when the slash is not a wrapper", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = "/fo/o/",
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars[1].parse[2], 'fo/o')
	end)

	it("does not remove a quote when the slash is not a wrapper", function()
		local rule = {
			vars = {{
				variable = 'ARGS',
				specific = "/fo'o/",
			}}
		}

		t(rule, translation)

		assert.is.same(translation.vars[1].parse[2], "fo'o")
	end)

	it("errors when given an invalid element", function()
		local rule = {
			vars = {{
				variable = 'foo',
				specific = '',
			}}
		}

		assert.has.error(function() t(rule, translation) end)
	end)

	it("errors when given one invalid element in a list", function()
		local rule = {
			vars = {
				{
					variable = 'foo',
					specific = '',
				},
				{
					variable = 'ARGS',
					specific = '',
				},
			}
		}

		assert.has.error(function() t(rule, translation) end)
	end)

	it("does not error on failure when force is true", function()
		local rule = {
			vars = {
				{
					variable = 'ARGS',
					specific = '',
				},
				{
					variable = 'foo',
					specific = '',
				},
			}
		}

		assert.has.no_errors(function() t(rule, translation, true) end)
		assert.is.same(translation.vars, {
			{ type = 'REQUEST_ARGS', parse = { 'values', true } }
		})
	end)

	it("results in empty translation when forced with no valid vars", function()
		local rule = {
			vars = {
				{
					variable = 'foo',
					specific = '',
				},
			}
		}

		assert.has.no_errors(function() t(rule, translation, true) end)
		assert.is.same(translation.vars, {})
	end)
end)

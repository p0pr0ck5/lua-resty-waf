describe("translate_operator", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_operator

	local translation
	before_each(function()
		translation = {}
	end)

	it("translates an operator", function()
		local rule = {
			operator = {
				operator = 'rx',
				pattern  = 'foo'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, { operator = 'REFIND', pattern = 'foo' })
	end)

	it("errors on an invalid operator", function()
		local rule = {
			operator = {
				operator = 'x',
				pattern  = 'foo'
			}
		}

		assert.has.errors(function() t(rule, translation) end)
		assert.is.same(translation, {})
	end)

	it("translates an operator that modifies the pattern", function()
		local rule = {
			operator = {
				operator = 'containsWord',
				pattern  = 'foo'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			operator = 'REFIND',
			pattern  = [[\bfoo\b]],
			opts = {
				parsepattern = true
			}
		})
	end)

	it("translates an operator with the negated flag", function()
		local rule = {
			operator = {
				operator = 'rx',
				pattern  = 'foo',
				negated  = '!'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			operator   = 'REFIND',
			pattern    = 'foo',
			op_negated = true,
		})
	end)

	it("casts a numeric pattern to a number type", function()
		local rule = {
			operator = {
				operator = 'gt',
				pattern  = '5'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is_number(translation.pattern)
		assert.is.same(translation.pattern, 5)
	end)

	it("casts a numeric pattern to a number type", function()
		local rule = {
			operator = {
				operator = 'gt',
				pattern  = '0.2'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is_number(translation.pattern)
		assert.is.same(translation.pattern, 0.2)
	end)

	it("splits the PM operator by space", function()
		local rule = {
			operator = {
				operator = 'pm',
				pattern  = 'foo bar    baz	bat'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			operator   = 'PM',
			pattern    = { 'foo', 'bar', 'baz', 'bat' },
		})
	end)

	it("splits the ipMatch operator by comma", function()
		local rule = {
			operator = {
				operator = 'ipMatch',
				pattern  = '1.2.3.4,5.6.7.8,10.10.10.0/24'
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			operator   = 'CIDR_MATCH',
			pattern    = { '1.2.3.4', '5.6.7.8', '10.10.10.0/24' },
		})
	end)

	for op, _ in pairs(lib.expand_operators) do
		it("automatically expands the operator " .. op, function()
			local rule = {
				operator = {
					operator = op,
					pattern  = 'foo'
				}
			}

			local s = spy.on(lib, 'translate_macro')

			assert.has.no_errors(function() t(rule, translation) end)
			assert.is.True(translation.opts.parsepattern)
			assert.spy(s).was.called(1)
		end)
	end

	it("reads a data file from a given path", function()
		local rule = {
			operator = {
				operator = 'ipMatchFromFile',
				pattern  = 'ips.txt'
			}
		}

		local opts = { path = require("lfs").currentdir() .. '/t/data' }

		assert.has.no_errors(function() t(rule, translation, opts.path) end)
		assert.is.same(translation, {
			operator   = 'CIDR_MATCH',
			pattern    = { '1.2.3.4', '5.6.7.8', '10.10.10.0/24' },
		})

	end)

	it("errors reading data file from an invalid path", function()
		local rule = {
			operator = {
				operator = 'ipMatchFromFile',
				pattern  = 'ips.txt'
			}
		}

		local opts = { path = require("lfs").currentdir() .. '/t/dne' }

		assert.has.errors(function() t(rule, translation, opts.path) end)
	end)

	it("errors reading data file from an undefined path", function()
		local rule = {
			operator = {
				operator = 'ipMatchFromFile',
				pattern  = 'ips.txt'
			}
		}

		assert.has.errors(function() t(rule, translation) end)
	end)
end)

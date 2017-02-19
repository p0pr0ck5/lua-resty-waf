describe("translate_chain", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_chain

	lib.translate_vars = function(rule, translation)
		translation.vars = {}

		for i = 1, #rule.vars do
			translation.vars[i] = rule.vars[i]
		end
	end
	lib.translate_operator = function(rule, translation, path)
		translation.operator = rule.operator
	end
	lib.translate_actions = function(rule, translation)
		for i = 1, #rule.actions do
			local action = rule.actions[i]
			translation[action.action] = action.value
		end
	end

	it("translates a single SecRule in a chain", function()
		local chain = {
			{
				actions = {
					{ action = 'action', value = 'DENY'   },
					{ action = 'id',     value = 12345    },
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { baz = 'bat' } }
			}
		}

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.is.same(t(chain), {
			{
				actions = {
					disrupt = 'DENY'
				},
				id       = 12345,
				phase    = 'access',
				operator = 'rx',
				vars     = { { baz = 'bat' } }
			}
		})
		assert.spy(spy_v).was.called(1)
		assert.spy(spy_o).was.called(1)
		assert.spy(spy_a).was.called(1)
	end)

	it("translates a single SecAction in a chain", function()
		local chain = {
			{
				actions = {
					{ action = 'action', value = 'DENY'   },
					{ action = 'id',     value = 12345    },
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecAction',
			}
		}

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.is.same(t(chain), {
			{
				actions = {
					disrupt = 'DENY'
				},
				id       = 12345,
				phase    = 'access',
				vars     = { unconditional = true }
			}
		})
		assert.spy(spy_v).was.not_called()
		assert.spy(spy_o).was.not_called()
		assert.spy(spy_a).was.called(1)
	end)

	it("translates a single SecMarker in a chain", function()
		local chain = {
			{
				actions = {
					{ action = 'mark' },
				},
				directive = 'SecMarker',
			}
		}

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.is.same(t(chain), {
			{
				actions = {
					disrupt = 'DENY'
				},
				id         = 'mark',
				op_negated = true,
				vars       = { unconditional = true }
			}
		})
		assert.spy(spy_v).was.not_called()
		assert.spy(spy_o).was.not_called()
		assert.spy(spy_a).was.called(1)
	end)

	it("translates two SecRule entries in a chain", function()
		local chain = {
			{
				actions = {
					{ action = 'action', value = 'DENY'   },
					{ action = 'id',     value = 12345    },
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { foo = 'bar' } }
			},
			{
				actions = {
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { baz = 'bat' } }
			}
		}

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.is.same(t(chain), {
			{
				actions = {
					disrupt = 'CHAIN'
				},
				id       = 12345,
				phase    = 'access',
				operator = 'rx',
				vars     = { { foo = 'bar' } }
			},
			{
				actions = {
					disrupt = 'DENY'
				},
				id       = 12345,
				phase    = 'access',
				operator = 'rx',
				vars     = { { baz = 'bat' } }
			}
		})
		assert.spy(spy_v).was.called(2)
		assert.spy(spy_o).was.called(2)
		assert.spy(spy_a).was.called(2)
	end)

	it("moves the skip action of a chain to the chain end", function()
		local chain = {
			{
				actions = {
					{ action = 'action', value = 'DENY'   },
					{ action = 'id',     value = 12345    },
					{ action = 'phase',  value = 'access' },
					{ action = 'skip',   value = 1        },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { foo = 'bar' } }
			},
			{
				actions = {
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { baz = 'bat' } }
			}
		}

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.is.same(t(chain), {
			{
				actions = {
					disrupt = 'CHAIN'
				},
				id       = 12345,
				phase    = 'access',
				operator = 'rx',
				vars     = { { foo = 'bar' } }
			},
			{
				actions = {
					disrupt = 'DENY'
				},
				id       = 12345,
				phase    = 'access',
				operator = 'rx',
				skip     = 1,
				vars     = { { baz = 'bat' } }
			}
		})
		assert.spy(spy_v).was.called(2)
		assert.spy(spy_o).was.called(2)
		assert.spy(spy_a).was.called(2)
	end)

	it("bubbles up an error in translation", function()
		local chain = {
			{
				actions = {
					{ action = 'action', value = 'DENY'   },
					{ action = 'id',     value = 12345    },
					{ action = 'phase',  value = 'access' },
				},
				directive = 'SecRule',
				operator  = 'rx',
				vars      = { { baz = 'bat' } }
			}
		}

		lib.translate_vars = function() error("nope") end

		local spy_v = spy.on(lib, 'translate_vars')
		local spy_o = spy.on(lib, 'translate_operator')
		local spy_a = spy.on(lib, 'translate_actions')

		assert.has_error(function() t(chain) end)
		assert.spy(spy_v).was.called(1)
		assert.spy(spy_o).was.called(0)
		assert.spy(spy_a).was.called(0)
	end)

end)

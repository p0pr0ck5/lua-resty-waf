describe("translate_actions", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_actions

	local translation
	before_each(function()
		translation = {}
	end)

	for k, v in pairs(lib.action_lookup) do
		it("translates " .. k, function()
			local rule = {
				actions = { { action = k } }
			}

			assert.has.no_errors(function() t(rule, translation) end)
			assert.is.same(translation, { action = v })
		end)
	end

	for k, v in pairs(lib.direct_translation_actions) do
		it("translates " .. k, function()
			local rule = {
				actions = { { action = k, value = 'foo' } }
			}

			assert.has.no_errors(function() t(rule, translation) end)
			assert.is.same(translation[k], 'foo')
		end)
	end

	it("translates chain without altering the translation table", function()
		local rule = {
			actions = { { action = 'chain' } }
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {})
	end)

	it("translates expirevar with an integer expire", function()
		local rule = {
			actions = {{
				action = 'expirevar',
				value  = 'foo.bar=60'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'expirevar',
					data   = {
						col  = 'FOO',
						key  = 'BAR',
						time = 60
					}
				}}
			}
		})
	end)

	it("translates expirevar with a decimal expire", function()
		local rule = {
			actions = {{
				action = 'expirevar',
				value  = 'foo.bar=.2'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'expirevar',
					data   = {
						col  = 'FOO',
						key  = 'BAR',
						time = .2
					}
				}}
			}
		})
	end)

	it("translates expirevar with a macro'd expire", function()
		local rule = {
			actions = {{
				action = 'expirevar',
				value  = 'foo.bar=baz'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'expirevar',
					data   = {
						col  = 'FOO',
						key  = 'BAR',
						time = 'baz'
					}
				}}
			}
		})
		assert.spy(s).was.called(1)
		assert.spy(s).was.called.with('baz')
	end)

	it("translates initcol", function()
		local rule = {
			actions = {{
				action = 'initcol',
				value  = 'ip=foo'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'initcol',
					data   = {
						col   = 'IP',
						value = 'foo',
					}
				}}
			}
		})
		assert.spy(s).was.called(1)
		assert.spy(s).was.called.with('foo')
	end)

	local should_macro = { 'logdata', 'msg', 'tag' }
	for i = 1, #should_macro do
		local action = should_macro[i]
		it("translates " .. action .. ", calling translate_macro", function()
			local rule = {
				actions = {{
					action = action,
					value  = 'foo'
				}}
			}

			local s = spy.on(lib, 'translate_macro')

			assert.has.no_errors(function() t(rule, translation) end)
			assert.spy(s).was.called(1)
		end)
	end

	local log_actions = { log = true, auditlog = true,
		nolog = false, noauditlog = false }
	for action, bool in pairs(log_actions) do
		it("translates " .. action, function()
			translation.opts = {} -- this is done in translate_chain

			local rule = {
				actions = {{
					action = action,
				}}
			}

			assert.has.no_errors(function() t(rule, translation) end)
			assert.is.same(translation.opts.log, log_actions[action])
		end)
	end


	it("translates setvar with a string value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo=bar'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
						value = 'bar'
					}
				}}
			}
		})
		assert.is.string(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.called(1)
	end)

	it("translates setvar with an integer value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo=60'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
						value = 60
					}
				}}
			}
		})
		assert.is.number(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.not_called()
	end)

	it("translates setvar with a decimal value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo=0.2'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
						value = 0.2
					}
				}}
			}
		})
		assert.is.number(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.not_called()
	end)

	it("translates setvar with an incrementing integer value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo=+1'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
						value = 1,
						inc   = true
					}
				}}
			}
		})
		assert.is.number(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.not_called()
	end)

	it("translates setvar with an incrementing decimal value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo=+0.2'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
						value = 0.2,
						inc   = true
					}
				}}
			}
		})
		assert.is.number(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.not_called()
	end)

	it("translates setvar with a key containing a dot", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo.bar=baz'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'setvar',
					data   = {
						col   = 'IP',
						key   = 'FOO.BAR',
						value = 'baz'
					}
				}}
			}
		})
		assert.is.string(translation.actions.nondisrupt[1].data.value)
		assert.spy(s).was.called(1)
	end)

	it("translates setvar deleting a value", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = '!IP.foo'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'deletevar',
					data   = {
						col   = 'IP',
						key   = 'FOO',
					}
				}}
			}
		})
		assert.spy(s).was.not_called()
	end)

	it("errors on strict set/delete confusion", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo'
			}}
		}

		assert.has.errors(function() t(rule, translation) end)
	end)

	it("warns on set/delete confusion", function()
		local rule = {
			actions = {{
				action = 'setvar',
				value  = 'IP.foo'
			}}
		}

		local opts = { loose = true }

		assert.has.no_errors(function() t(rule, translation, opts) end)
		assert.is.same(translation, {})
	end)

	it("translates status", function()
		local rule = {
			actions = {{
				action = 'status',
				value  = '500'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'status',
					data   = 500
				}}
			}
		})
	end)

	it("translates pause", function()
		local rule = {
			actions = {{
				action = 'pause',
				value  = '5000'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'sleep',
					data   = 5
				}}
			}
		})
	end)

	it("translates pause with decimal value", function()
		local rule = {
			actions = {{
				action = 'pause',
				value  = '125'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'sleep',
					data   = 0.125
				}}
			}
		})
	end)

	it("translates pause at minimal timer size", function()
		local rule = {
			actions = {{
				action = 'pause',
				value  = 1
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {
			actions = {
				nondisrupt = {{
					action = 'sleep',
					data   = 0.001
				}}
			}
		})
	end)

	it("translates t:none", function()
		local rule = {
			actions = {{
				action = 't',
				value  = 'none'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, {})
	end)

	it("translates a valid transform", function()
		local rule = {
			actions = {{
				action = 't',
				value  = 'length'
			}}
		}

		translation.opts = { transform = {} }

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, { opts = { transform = { 'length' } }})
	end)

	it("errors when translating an invalid transform when not loose", function()
		local rule = {
			actions = {{
				action = 't',
				value  = 'foo'
			}}
		}

		translation.opts = { transform = {} }

		assert.has.errors(function() t(rule, translation) end)
	end)

	it("warns when translating an invalid transform when not loose", function()
		local rule = {
			actions = {{
				action = 't',
				value  = 'foo'
			}}
		}

		local opts = { loose = true }
		translation.opts = { transform = {} }

		assert.has.no_errors(function() t(rule, translation, opts) end)
		assert.is.same(translation, { opts = { transform = {} } })
	end)

	it("does not continue on transform failure when not loose", function()
		local rule = {
			actions = {
				{
					action = 't',
					value  = 'foo'
				},
				{
					action = 't',
					value  = 'length'
				},
			}
		}

		translation.opts = { transform = {} }

		assert.has.errors(function() t(rule, translation) end)
		assert.is.same(translation, { opts = { transform = {}},
			actions = { nondisrupt = {}}})
	end)

	it("continues translating on transform failure when not loose", function()
		local rule = {
			actions = {
				{
					action = 't',
					value  = 'foo'
				},
				{
					action = 't',
					value  = 'length'
				},
			}
		}

		local opts = { loose = true }
		translation.opts = { transform = {} }

		assert.has.no_errors(function() t(rule, translation, opts) end)
		assert.is.same(translation, { opts = { transform = { 'length' } } })
	end)

	it("appends one tag", function()
		local rule = {
			actions = {{
				action = 'tag',
				value  = 'foo'
			}}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, { tag = { 'foo' } })
		assert.spy(s).was.called(1)
	end)

	it("appends two tags", function()
		local rule = {
			actions = {
				{
					action = 'tag',
					value  = 'foo'
				},
				{
					action = 'tag',
					value  = 'bar'
				},
			}
		}

		local s = spy.on(lib, 'translate_macro')

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, { tag = { 'foo', 'bar' } })
		assert.spy(s).was.called(2)
	end)

	it("retranslates the operator when capture is set", function()
		local rule = {
			actions = { { action = 'capture' } }
		}

		translation = { operator = 'REFIND' }

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation, { operator = 'REGEX' })
	end)

	it("errors when capture is set and the operator is not REFIND", function()
		local rule = {
			actions = { { action = 'capture' } }
		}

		translation = { operator = 'foo' }

		assert.has.errors(function() t(rule, translation) end)
	end)

	it("translates ctl:ruleRemoveById", function()
		local rule = {
			actions = {{
				action = 'ctl',
				value  = 'ruleRemoveById=12345'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation.actions.nondisrupt[1], {
			action = 'rule_remove_id',
			data   = 12345,
		})
	end)

	it("translates ctl:ruleRemoveByMsg", function()
		local rule = {
			actions = {{
				action = 'ctl',
				value  = 'ruleRemoveByMsg=foo'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation.exceptions, {
			'foo'
		})
		assert.is.same(translation.actions.nondisrupt[1], {
			action = 'rule_remove_by_meta',
			data   = true,
		})
	end)

	it("translates ctl:ruleRemoveByTag", function()
		local rule = {
			actions = {{
				action = 'ctl',
				value  = 'ruleRemoveByTag=bar'
			}}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation.exceptions, {
			'bar'
		})
		assert.is.same(translation.actions.nondisrupt[1], {
			action = 'rule_remove_by_meta',
			data   = true,
		})
	end)

	it("translates ctl ruleRemove* actions", function()
		local rule = {
			actions = {
				{
					action = 'ctl',
					value  = 'ruleRemoveByTag=foo'
				},
				{
					action = 'ctl',
					value  = 'ruleRemoveByTag=bar'
				},
			}
		}

		assert.has.no_errors(function() t(rule, translation) end)
		assert.is.same(translation.exceptions, { 'foo', 'bar' })
		assert.equals(#translation.actions.nondisrupt, 1)
	end)

	it("errors on invalid ctl", function()
		local rule = {
			actions = {{
				action = 'ctl',
				value  = 'ruleRemoveByFoo=bar'
			}}
		}

		assert.has.errors(function() t(rule, translation) end)
	end)

end)

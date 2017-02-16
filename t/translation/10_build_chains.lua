describe("build_chains", function()
	local lib = require "resty.waf.translate"
	local b   = lib.build_chains

	it("builds a single chain from a single rule", function()
		local rules = {
			{
				actions = { { action = 'foo' } },
				things  = { rule1 }
			}
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'foo' } },
					things  = { rule1 }
				}
			}
		})
	end)

	it("builds two chains from two individual rules", function()
		local rules = {
			{
				actions = { { action = 'foo' } },
				things  = { rule1 }
			},
			{
				actions = { { action = 'bar' } },
				things  = { rule2 }
			},
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'foo' } },
					things  = { rule1 }
				},
			},
			{
				{
					actions = { { action = 'bar' } },
					things  = { rule2 }
				},
			}
		})
	end)

	it("builds one chain from two rules", function()
		local rules = {
			{
				actions = { { action = 'chain' } },
				things  = { rule1 }
			},
			{
				actions = { { action = 'bar' } },
				things  = { rule2 }
			},
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'chain' } },
					things  = { rule1 }
				},
				{
					actions = { { action = 'bar' } },
					things  = { rule2 }
				},
			}
		})
	end)

	it("builds one chain from two rules and a separate " ..
		"chain from a third rule", function()
		local rules = {
			{
				actions = { { action = 'chain' } },
				things  = { rule1 }
			},
			{
				actions = { { action = 'bar' } },
				things  = { rule2 }
			},
			{
				actions = { { action = 'baz' } },
				things  = { rule3 }
			},
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'chain' } },
					things  = { rule1 }
				},
				{
					actions = { { action = 'bar' } },
					things  = { rule2 }
				},
			},
			{
				{
					actions = { { action = 'baz' } },
					things  = { rule3 }
				}
			}
		})
	end)

	it("builds one chain from three rules", function()
		local rules = {
			{
				actions = { { action = 'chain' } },
				things  = { rule1 }
			},
			{
				actions = { { action = 'chain' } },
				things  = { rule2 }
			},
			{
				actions = { { action = 'foo' } },
				things  = { rule3 }
			},
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'chain' } },
					things  = { rule1 }
				},
				{
					actions = { { action = 'chain' } },
					things  = { rule2 }
				},
				{
					actions = { { action = 'foo' } },
					things  = { rule3 }
				}
			}
		})
	end)

	it("builds two chains from four rules", function()
		local rules = {
			{
				actions = { { action = 'chain' } },
				things  = { rule1 }
			},
			{
				actions = { { action = 'foo' } },
				things  = { rule2 }
			},
			{
				actions = { { action = 'chain' } },
				things  = { rule3 }
			},
			{
				actions = { { action = 'bar' } },
				things  = { rule4 }
			},
		}

		assert.is.same(b(rules), {
			{
				{
					actions = { { action = 'chain' } },
					things  = { rule1 }
				},
				{
					actions = { { action = 'foo' } },
					things  = { rule2 }
				},
			},
			{
				{
					actions = { { action = 'chain' } },
					things  = { rule3 }
				},
				{
					actions = { { action = 'bar' } },
					things  = { rule4 }
				},
			}
		})
	end)

end)

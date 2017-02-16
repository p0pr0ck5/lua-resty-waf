describe("translate_chains", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_chains

	it("builds the skeleton chain hashref when given an empty chain list",
		function()
		local chains, err

		assert.has.no_errors(function() chains, err = t({}) end)
		assert.are.same(chains, {
			access        = {},
			header_filter = {},
			body_filter   = {},
		})
		assert.is.equals(err, nil)
	end)

	it("translates a single chain with a single rule", function()
		local chains, err

		local c = {{
			{
				id    = '12345',
				foo   = 'bar',
				phase = 'access',
			}
		}}

		local s = spy.on(lib, 'figure_phase')
		lib.translate_chain = function(chain) return chain end

		assert.has.no_errors(function() chains, err = t(c) end)
		assert.are.same(chains, {
			access = {
				{
					id    = '12345',
					foo   = 'bar',
				}
			},
			header_filter = {},
			body_filter   = {},
		})
		assert.is.equals(err, nil)
		assert.spy(s).was.called(1)
	end)

	it("translates a single chain with two rules", function()
		local chains, err

		local c = {
			{
				{
					id    = '12345',
					foo   = 'bar',
					phase = 'access',
				},
				{
					id    = '12346',
					foo   = 'bar',
					phase = 'access',
				},
			}
		}

		local s = spy.on(lib, 'figure_phase')
		lib.translate_chain = function(chain) return chain end

		assert.has.no_errors(function() chains, err = t(c) end)
		assert.are.same(chains, {
			access = {
				{
					id    = '12345',
					foo   = 'bar',
				},
				{
					id    = '12346',
					foo   = 'bar',
					phase = 'access'
				}
			},
			header_filter = {},
			body_filter   = {},
		})
		assert.is.equals(err, nil)
		assert.spy(s).was.called(1)
	end)

	it("translates two chains, one with two rules and one with one", function()
		local chains, err

		local c = {
			{
				{
					id    = '12345',
					foo   = 'bar',
					phase = 'access',
				},
				{
					id    = '12346',
					foo   = 'bar',
					phase = 'access',
				},
			},
			{
				{
					id    = '12347',
					foo   = 'baz',
					phase = 'access',
				},
			}
		}

		local s = spy.on(lib, 'figure_phase')
		lib.translate_chain = function(chain) return chain end

		assert.has.no_errors(function() chains, err = t(c) end)
		assert.are.same(chains, {
			access = {
				{
					id    = '12345',
					foo   = 'bar',
				},
				{
					id    = '12346',
					foo   = 'bar',
					phase = 'access'
				},
				{
					id    = '12347',
					foo   = 'baz',
				}
			},
			header_filter = {},
			body_filter   = {},
		})
		assert.is.equals(err, nil)
		assert.spy(s).was.called(2)
	end)

	it("catches and returns an error on translation failure", function()
			local chains, err

			local c = {{
				{
					id       = '12345',
					foo      = 'bar',
					phase    = 'access',
					original = 'orig',
				}
			}}

			local s = spy.on(lib, 'figure_phase')
			lib.translate_chain = function(chain) error("nope!", 2) end

			assert.has.no_errors(function() chains, err = t(c) end)
			assert.are.same(chains, {
				access        = {},
				header_filter = {},
				body_filter   = {},
			})
			assert.are.same(err[1].orig, { 'orig' })
			assert.is_true(not not ngx.re.match(err[1].err, [[nope!]]))
			assert.spy(s).was.called(0)
	end)

	it("translates one chain and fails on error for a separate chain",
		function()
		local chains, err

		local c = {
			{
				{
					id       = '12345',
					foo      = 'bar',
					phase    = 'access',
					original = 'orig12345'
				},
				{
					id       = '12346',
					foo      = 'bar',
					phase    = 'access',
					original = 'orig12346'
				},
			},
			{
				{
					id    = '12347',
					foo   = 'baz',
					phase = 'access',
				},
			}
		}

		local s = spy.on(lib, 'figure_phase')
		lib.translate_chain = function(chain)
			if chain[1].id == '12345' then
				error("meganope")
			else
				return chain
			end
		end

		assert.has.no_errors(function() chains, err = t(c) end)
		assert.are.same(chains, {
			access = {
				{
					id    = '12347',
					foo   = 'baz',
				}
			},
			header_filter = {},
			body_filter   = {},
		})
		assert.are.same(err[1].orig, { 'orig12345', 'orig12346' })
		assert.is_true(not not ngx.re.match(err[1].err, [[meganope]]))
		assert.spy(s).was.called(1)
	end)

end)

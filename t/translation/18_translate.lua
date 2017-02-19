describe("translate", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate

	local chains, errs
	before_each(function()
		chains = {}
		errs   = nil
	end)

	it("single valid rule with no errors", function()
		local raw = {
			[[SecRule ARGS "foo" "id:12345,phase:2,deny,msg:'dummy msg'"]]
		}

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
	end)

	it("single invalid rule with errors", function()
		local raw = {
			[[SecRule DNE "foo" "id:12345,phase:2,deny,msg:'dummy msg'"]]
		}

		assert.has.no_errors(function() chains, errs = t(raw) end)

		assert.is_not_nil(errs)
	end)

	it("forces translation of a single valid rule with errors", function()
		local raw = {
			[[SecRule ARGS|DNE "foo" "id:12345,phase:2,deny,msg:'dummy msg'"]]
		}

		local opts = { force = true }

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
		assert.is.same(#chains.access[1].vars, 1)
	end)

	it("single valid rule with invalid action", function()
		local raw = {
			[[SecRule ARGS "foo" "id:12345,phase:2,deny,msg:'dummy msg',foo"]]
		}

		assert.has.no_errors(function() chains, errs = t(raw) end)

		assert.is_not_nil(errs)
	end)

	it("loose single valid rule with invalid action", function()
		local raw = {
			[[SecRule ARGS "foo" "id:12345,phase:2,deny,msg:'dummy msg',foo"]]
		}

		local opts = { loose = true }

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
	end)

	it("single valid rule with data file pattern", function()
		local raw = {
			[[SecRule REMOTE_ADDR "@ipMatchFromFile ips.txt" ]] ..
				[[ "id:12345,phase:2,deny,msg:'dummy msg'"]]
		}

		local opts = { path = require("lfs").currentdir() .. '/t/data' }

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
		assert.is.same(chains.access[1].pattern, {
			'1.2.3.4', '5.6.7.8', '10.10.10.0/24'
		})
	end)

	it("single invalid rule with data file pattern", function()
		local raw = {
			[[SecRule REMOTE_ADDR "@ipMatchFromFile ips.txt" ]] ..
				[[ "id:12345,phase:2,deny,msg:'dummy msg'"]]
		}

		local opts = { path = require("lfs").currentdir() .. '/t/dne' }

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_not_nil(errs)
		assert.is.same(#chains.access, 0)
	end)

	it("multiple rules in the same phase", function()
		local raw = {
			[[SecRule ARGS "foo" "id:12345,phase:2,deny,msg:'dummy msg'"]],
			[[SecRule ARGS "foo" "id:12346,phase:2,deny,msg:'dummy msg'"]]
		}

		local funcs = { 'clean_input', 'tokenize', 'parse_tokens',
			'build_chains', 'translate_chains' }
		local s = {}
		for i = 1, #funcs do
			local func = funcs[i]
			s[func] = spy.on(lib, func)
		end

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
		assert.is.same(#chains.access, 2)
		for i = 1, #funcs do
			local func = funcs[i]
			assert.spy(s[func]).was.called()
		end
	end)

	it("multiple rules in different phases", function()
		local raw = {
			[[SecRule ARGS "foo" "id:12345,phase:2,deny,msg:'dummy msg'"]],
			[[SecRule ARGS "foo" "id:12346,phase:3,deny,msg:'dummy msg'"]]
		}

		local funcs = { 'clean_input', 'tokenize', 'parse_tokens',
			'build_chains', 'translate_chains' }
		local s = {}
		for i = 1, #funcs do
			local func = funcs[i]
			s[func] = spy.on(lib, func)
		end

		assert.has.no_errors(function() chains, errs = t(raw, opts) end)

		assert.is_nil(errs)
		assert.is.same(#chains.access, 1)
		assert.is.same(#chains.header_filter, 1)
		for i = 1, #funcs do
			local func = funcs[i]
			assert.spy(s[func]).was.called()
		end
	end)

end)

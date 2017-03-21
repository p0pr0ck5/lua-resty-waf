describe("figure_phase", function()
	local lib = require "resty.waf.translate"
	local f   = lib.figure_phase

	for i = 1, #lib.phase_lookup do
		local p = lib.phase_lookup[i]

		it("translates a phase determined from phase key " .. p, function()
			assert.is.same(f({{phase = i}}), lib.phase_lookup[i])
		end)

		it("translates a phase determined from phase key " .. p ..
			" using only the first rule", function()
			assert.is.same(f({{phase = i}, {phase = 2}}), lib.phase_lookup[i])
		end)

	end

	do
		local phase_names = {
			request  = 'access',
			response = 'body_filter',
			logging  = 'log'
		}

		for k, v in pairs(phase_names) do
			it("translates a phase determined from phase key " .. k, function()
				assert.is.same(f({{phase = k}}), lib.phase_lookup[k])
				assert.is.same(f({{phase = k}}), v)
			end)

			it("translates a phase determined from phase key " .. k ..
				" using only the first rule", function()
				assert.is.same(f({{phase = k}, {phase = 2}}), lib.phase_lookup[k])
				assert.is.same(f({{phase = k}, {phase = 2}}), v)
			end)
		end
	end

	it("translates a phase determined from implicit default", function()
		assert.is.same(f({{}}), 'access')
	end)

	it("removes the phase key from the translation", function()
		local translation = {
			{
				phase = 1,
				foo = 'bar'
			}
		}

		f(translation)
		assert.is_nil(translation.phase)
	end)
end)

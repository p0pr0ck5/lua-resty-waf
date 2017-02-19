describe("figure_phase", function()
	local lib = require "resty.waf.translate"
	local f   = lib.figure_phase

	for i = 1, #lib.phase_lookup do
		local p = lib.phase_lookup[i]

		it("translates a phase determined from phase key " .. p, function()
			assert.is.same(f({{phase = i}}), lib.phase_lookup[i])
		end)

	end

	for i = 1, #lib.phase_lookup do
		local p = lib.phase_lookup[i]

		it("translates a phase determined from phase key " .. p ..
			" using only the first rule", function()
			assert.is.same(f({{phase = i}, {phase = 2}}), lib.phase_lookup[i])
		end)

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

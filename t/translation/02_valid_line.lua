describe("valid_line", function()
	local lib = require "resty.waf.translate"
	local v   = lib.valid_line

	it("starts with known directives", function()
		assert.is_true(v('SecRule '))
		assert.is_true(v('SecAction '))
		assert.is_true(v('SecDefaultAction '))
		assert.is_true(v('SecMarker '))
	end)

	it("starts with unsupported directives", function()
		assert.is_false(v('SecRuleScript'))	
	end)

	it("starts with unknown directives", function()
		assert.is_false(v('SecFoo '))

		local r = require "resty.waf.random"
		assert.is_false(v(r.random_bytes(8)))
	end)
end)

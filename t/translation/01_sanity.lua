describe("module", function()
	it("loads without errors", function()
		-- dont print warnings
		ngx.log = function() end

		assert.has_no.errors(function() require "resty.waf.translate" end)
	end)
end)

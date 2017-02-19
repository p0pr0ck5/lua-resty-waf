describe("translate_macro", function()
	local lib = require "resty.waf.translate"
	local t   = lib.translate_macro

	it("does not modify a string without a marker", function()
		assert.is.same(t('foo'), 'foo')
	end)

	it("does not modify a string wrapped in a marker", function()
		assert.is.same(t('%{foo}'), '%{foo}')
	end)

	it("translates a string containing a var", function()
		assert.is.same(t('%{REQUEST_METHOD}'), '%{METHOD}')
	end)

	it("does not modify a var string without a marker", function()
		assert.is.same(t('REQUEST_METHOD'), 'REQUEST_METHOD')
	end)

	it("translates a string containing a var and a specific", function()
		assert.is.same(t('%{ARGS.foo}'), '%{REQUEST_ARGS.foo}')
	end)

	it("translates a string containing a var and an implicit specific",
		function()
		assert.is.same(t('%{RESPONSE_CONTENT_TYPE}'),
			'%{RESPONSE_HEADERS.Content-Type}')
	end)

	it("translates a string containing two marked vars", function()
		assert.is.same(t('%{REQUEST_METHOD} - %{RESPONSE_STATUS}'),
			'%{METHOD} - %{STATUS}')
	end)

	it("translates a string containing two marked vars " ..
		"one of which is not a valid var", function()
		assert.is.same(t('%{REQUEST_METHOD} - %{foo}'),
			'%{METHOD} - %{foo}')
	end)

	it("translates a string containing two marked vars " ..
		"one of which has a specific element", function()
		assert.is.same(t('%{ARGS.foo} - %{RESPONSE_STATUS}'),
			'%{REQUEST_ARGS.foo} - %{STATUS}')
	end)

	it("does not modify a string wrapped in a malformed marker (1/3)",
		function()
		assert.is.same(t('{foo}'), '{foo}')
	end)

	it("does not modify a string wrapped in a malformed marker (2/3)",
		function()
		assert.is.same(t('%{foo'), '%{foo')
	end)

	it("does not modify a string wrapped in a malformed marker (3/3)",
		function()
		assert.is.same(t('%{foo { bar}'), '%{foo { bar}')
	end)

	it("uc's the collection name as part of translation", function()
		assert.is.same(t('%{args.foo}'), '%{REQUEST_ARGS.foo}')
	end)

	it("does not uc the collection name as part of missed lookup", function()
		assert.is.same(t('%{foo.bar}'), '%{foo.bar}')
	end)

	it("uc's the collection name and element as part of translation " ..
		"of storage collections", function()
		assert.is.same(t('%{ip.foo}'), '%{IP.FOO}')
	end)

end)

describe("parse_vars", function()
	local lib = require "resty.waf.translate"
	local p   = lib.parse_vars

	it("parses a var", function()
		assert.is.same(p('ARGS'), {{ variable = 'ARGS' }})
	end)

	it("parses a var with a specific element", function()
		assert.is.same(p('ARGS:foo'), {{ variable = 'ARGS', specific = 'foo' }})
	end)

	it("ignores an element within a var", function()
		assert.is.same(p('ARGS|!ARGS:foo'), {{
			variable = 'ARGS',
			modifier = '!',
			ignore   = { 'foo' },
		}})
	end)

	it("ignores an element within a var via regex", function()
		assert.is.same(p('ARGS|!ARGS:/__foo/'), {{
			variable = 'ARGS',
			modifier = '!',
			ignore   = { '/__foo/' },
		}})
	end)

	it("parses a var with a length modifier", function()
		assert.is.same(p('&ARGS'), {{ variable = 'ARGS', modifier = '&' }})
	end)

	it("parses a var with a specific element and alength modifier", function()
		assert.is.same(p('&ARGS:foo'), {{
			variable = 'ARGS',
			modifier = '&',
			specific = 'foo'
		}})
	end)

	it("parses a var with a specific element containing a colo", function()
		assert.is.same(p('ARGS:foo:bar'), {{
			variable = 'ARGS',
			specific = 'foo:bar'
		}})
	end)

	it("parses two vars", function()
		assert.is.same(p('ARGS|ARGS_NAMES'), {
			{ variable = 'ARGS' },
			{ variable = 'ARGS_NAMES' }
		})
	end)

	it("parses two vars, one with a specific element", function()
		assert.is.same(p('ARGS:foo|ARGS_NAMES'), {
			{ variable = 'ARGS', specific = 'foo' },
			{ variable = 'ARGS_NAMES' }
		})
	end)

	it("parses two vars with specific elements", function()
		assert.is.same(p('ARGS:foo|ARGS_NAMES:bar'), {
			{ variable = 'ARGS', specific = 'foo' },
			{ variable = 'ARGS_NAMES', specific = 'bar' }
		})
	end)

	it("parses two vars, one with a specific element and " ..
		"length modifier", function()
		assert.is.same(p('&ARGS:foo|ARGS_NAMES'), {
			{ variable = 'ARGS', specific = 'foo', modifier = '&' },
			{ variable = 'ARGS_NAMES' }
		})
	end)

	it("parses two vars, one with a specific element and the other with a " ..
		"length modifier", function()
		assert.is.same(p('ARGS:foo|&ARGS_NAMES'), {
			{ variable = 'ARGS', specific = 'foo' },
			{ variable = 'ARGS_NAMES', modifier = '&' }
		})
	end)

	it("parses a var with a regex element", function()
		assert.is.same(p('ARGS:/foo/'), {{
			variable = 'ARGS', specific = '/foo/'
		}})
	end)

	it("parses a var with a regex element containing a quote", function()
		assert.is.same(p("ARGS:/fo'o/"), {{
			variable = 'ARGS', specific = "/fo'o/"
		}})
	end)

	it("parses a var with a quote-wrapped regex element", function()
		assert.is.same(p("ARGS:'/foo/'"), {{
			variable = 'ARGS', specific = "'/foo/'"
		}})
	end)

	it("parses a var with a quote-wrapped regex element " ..
		"containing a single quote", function()
		assert.is.same(p("ARGS:'/fo'o/'"), {{
			variable = 'ARGS', specific = "'/fo'o/'"
		}})
	end)

	it("parses a var with a regex element containing a slash", function()
		assert.is.same(p("ARGS:/fo/o/"), {{
			variable = 'ARGS', specific = "/fo/o/"
		}})
	end)

	it("parses a var with a quote-wrapped regex element " ..
		"containing a slash", function()
		assert.is.same(p("ARGS:'/fo/o/'"), {{
			variable = 'ARGS', specific = "'/fo/o/'"
		}})
	end)

	it("parses a var with a regex element containing a pipe", function()
		assert.is.same(p('ARGS:/foo|bar/'), {{
			variable = 'ARGS', specific = '/foo|bar/'
		}})
	end)

	it("parses a var with a quote-wrapped regex element " ..
		"containing a pipe", function()
		assert.is.same(p("ARGS:'/foo|bar/'"), {{
			variable = 'ARGS', specific = "'/foo|bar/'"
		}})
	end)

	it("parses two vars, one with a regex element", function()
		assert.is.same(p('ARGS:/foo/|ARGS_NAMES'), {
			{ variable = 'ARGS', specific = '/foo/' },
			{ variable = 'ARGS_NAMES' },
		})
	end)

	it("parses two vars, one with a quote-wrapped regex element", function()
		assert.is.same(p("ARGS:'/foo/'|ARGS_NAMES"), {
			{ variable = 'ARGS', specific = "'/foo/'" },
			{ variable = 'ARGS_NAMES' },
		})
	end)

	it("parses two vars, one with a quote-wrapped regex element " ..
		"containing a pipe", function()
		assert.is.same(p("ARGS:'/foo|bar/'|ARGS_NAMES"), {
			{ variable = 'ARGS', specific = "'/foo|bar/'" },
			{ variable = 'ARGS_NAMES' },
		})
	end)

	it("parses a real-life CRSv2 example", function()
		assert.is.same(
			p("REQUEST_HEADERS:'/(Content-Length|Transfer-Encoding)/'"), {{
				variable = 'REQUEST_HEADERS',
				specific = "'/(Content-Length|Transfer-Encoding)/'"
			}}
		)
	end)

	it("errors when trying to ignore an unseen var", function()
		assert.has_error(function() p('!ARGS:foo') end)
	end)

	it("errors when trying to ignore an unmatched var", function()
		assert.has_error(function() p('ARGS|!ARGS_GET:foo') end)
	end)
end)

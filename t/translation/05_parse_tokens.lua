local secrule   = 'SecRule'
local secaction = 'SecAction'
local args      = 'ARGS'
local operator  = 'foo'
local actions   = "block,id:12345,msg:'hello world'"

describe("parse_token", function()
	local lib = require "resty.waf.translate"
	local p   = lib.parse_tokens

	it("lives ok with four tokens", function()
		stub(lib, 'parse_vars')
		stub(lib, 'parse_operator')
		stub(lib, 'parse_actions')

		assert.has_no_errors(function()
			p({secrule, args, operator, actions})
		end)
		assert.stub(lib.parse_vars).was.called(1)
		assert.stub(lib.parse_operator).was.called(1)
		assert.stub(lib.parse_actions).was.called(1)
	end)

	it("lives ok with two tokens", function()
		stub(lib, 'parse_vars')
		stub(lib, 'parse_operator')
		stub(lib, 'parse_actions')

		assert.has_no_errors(function() p({secaction, actions}) end)
		assert.stub(lib.parse_vars).was.not_called()
		assert.stub(lib.parse_operator).was.not_called()
		assert.stub(lib.parse_actions).was.called(1)
	end)

	it("dies with four tokens and SecAction", function()
		assert.has_error(function()
			p({secaction, args, operator, actions})
		end)
	end)

	it("properly forms an entry from SecRule", function()
		stub(lib, 'parse_vars')
		stub(lib, 'parse_operator')
		stub(lib, 'parse_actions')

		local entry = p({secrule, args, operator, actions})

		assert.is.same(entry.original,
			"SecRule ARGS foo block,id:12345,msg:'hello world'")
		assert.is.same(entry.directive, 'SecRule')
		assert.stub(lib.parse_vars).was.called_with("ARGS")
		assert.stub(lib.parse_operator).was.called_with("foo")
		assert.stub(lib.parse_actions).was.
			called_with("block,id:12345,msg:'hello world'")
	end)

	it("properly forms an entry from SecRule with no actions", function()
		stub(lib, 'parse_vars')
		stub(lib, 'parse_operator')
		stub(lib, 'parse_actions')

		local entry = p({secrule, args, operator})

		assert.is.same(entry.original, "SecRule ARGS foo")
		assert.is.same(entry.directive, 'SecRule')
		assert.stub(lib.parse_vars).was.called_with("ARGS")
		assert.stub(lib.parse_operator).was.called_with("foo")
		assert.stub(lib.parse_actions).was.not_called()
	end)

	it("properly forms an entry from SecAction", function()
		stub(lib, 'parse_vars')
		stub(lib, 'parse_operator')
		stub(lib, 'parse_actions')

		local entry = p({secaction, actions})

		assert.is.same(entry.original,
			"SecAction block,id:12345,msg:'hello world'")
		assert.is.same(entry.directive, 'SecAction')
		assert.stub(lib.parse_actions).was.
			called_with("block,id:12345,msg:'hello world'")
	end)
end)

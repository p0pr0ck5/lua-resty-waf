local basic             = [[SecRule ARGS "foo" "id:12345,pass"]]
local trim_left         = [[  SecRule ARGS "foo" "id:12345,pass"]]
local trim_right        = [[SecRule ARGS "foo" "id:12345,pass"	]]
local trim_both         = [[  SecRule ARGS "foo" "id:12345,pass"  ]]
local ignore_comment    = [[#SecRule ARGS "foo" "id:12345,pass"]]
local invalid_directive = [[Secrule ARGS "foo" "id:12345,pass"]]
local multi_line        = {
[[SecRule      \]],
[[	ARGS       \]],
[[	"foo"      \]],
[[	"id:12345,pass"]]
}
local multi_line_action = {
[[SecRule              \]],
[[	ARGS               \]],
[[	"foo"              \]],
[[	"id:12345,         \]],
[[	phase:1,           \]],
[[	block,             \]],
[[	setvar:tx.foo=bar, \]],
[[	expirevar:tx.foo=60"]]
}

describe("clean_input", function()

	local lib = require "resty.waf.translate"
	local c   = lib.clean_input

	it("takes a basic line", function()
		assert.are.same(c({basic}), {'SecRule ARGS "foo" "id:12345,pass"'})
	end)

	it("takes a line to trim left", function()
		assert.are.same(c({trim_left}), {'SecRule ARGS "foo" "id:12345,pass"'})
	end)

	it("takes a line to trim right", function()
		assert.are.same(c({trim_right}), {'SecRule ARGS "foo" "id:12345,pass"'})
	end)

	it("takes a line to trim left and right", function()
		assert.are.same(c({trim_both}), {'SecRule ARGS "foo" "id:12345,pass"'})
	end)

	it("takes a commented-out line", function()
		assert.are.same(c({ignore_comment}), {})
	end)

	it("takes a line with an invalid directive", function()
		assert.are.same(c({invalid_directive}), {})
	end)

	it("takes a multi-line string", function()
		assert.are.same(c(multi_line), {'SecRule ARGS "foo" "id:12345,pass"'})
	end)

	it("takes multiple elements", function()
		local input = { basic }
		for i = 1, #multi_line do
			input[i + 1] = multi_line[i]
		end
		assert.are.same(c(input), {
			'SecRule ARGS "foo" "id:12345,pass"',
			'SecRule ARGS "foo" "id:12345,pass"'
		})
	end)

	it("takes multiple elements with a comment", function()
		local input = { basic, ignore_comment }
		for i = 1, #multi_line do
			input[i + 2] = multi_line[i]
		end
		assert.are.same(c(input), {
			'SecRule ARGS "foo" "id:12345,pass"',
			'SecRule ARGS "foo" "id:12345,pass"'
		})
	end)

	it("takes a mutli-line action directive", function()
		assert.are.same(c(multi_line_action), {
			'SecRule ARGS "foo" "id:12345, phase:1, block, setvar:tx.foo=bar, expirevar:tx.foo=60"'
		})
	end)
end)

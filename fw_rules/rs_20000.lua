local rs_20000 = {}

local _rules = {
	{
		id = 20001,
		var = {
			type = "REQUEST_LINE",
			opts = nil,
			pattern = [=[^(?i:(?:[a-z]{3,10}\s+(?:\w{3,7}?://[\w\-\./]*(?::\d+)?)?/[^?#]*(?:\?[^#\s]*)?(?:#[\S]*)?|connect (?:\d{1,3}\.){3}\d{1,3}\.?(?::\d+)?|options \*)\s+[\w\./]+|get /[^?#]*(?:\?[^#\s]*)?(?:#[\S]*)?)$]=],
			operator = "NOT_REGEX",
		},
		opts = {},
		action = "LOG",
		description = "Proper HTTP request per RFC 2616"
	},
	{
		id = 20002,
		var = {
			type = "HEADERS",
			opts = { specific = "content-length" },
			pattern = [=[^[\d]+$]=],
			operator = "NOT_REGEX",
		},
		opts = {},
		action = "LOG",
		description = "Content-Length header must be a numeric value"
	},
	{
		id = 20003,
		var = {
			type = "METHOD",
			opts = nil,
			pattern = [=[^(?:GET|HEAD)$]=],
			operator = "REGEX"
		},
		opts = { nolog = true },
		action = "CHAIN",
		description = "GET/HEAD request with a body"
	},
	{
		id = 20004,
		var = {
			type = "HEADERS",
			opts = { specific = "content-length" },
			pattern = "0",
			operator = "NOT_EQUALS"
		},
		opts = { chainend = true, chainchild = true },
		action = "DENY",
		description = "GET/HEAD request with a body"
	},
	{
		id = 20005,
		var = {
			type = "METHOD",
			opts = nil,
			pattern = "POST",
			operator = "EQUALS"
		},
		opts = {},
		action = "CHAIN",
		description = "POST request does not have a Content-Length Header"
	},
	{
		id = 20006,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "content-length",
			operator = "NOT_EXISTS"
		},
		opts = { chainend = true, chainchild = true },
		action = "LOG",
		description = "POST request does not have a Content-Length Header"
	},
	{
		id = 20007,
		var = {
			type = "HEADERS",
			opts = { specific = "content-encoding" },
			pattern = "Identity",
			operator = "EQUALS"
		},
		opts = {},
		action = "LOG",
		description = "Identity should not be used in Content-Encoding, only in Accept-Encoding"
	},
	{
		id = 20008,
		var = {
			type = "HEADERS",
			opts = { specific = "expect" },
			pattern = [=[100-continue]=],
			operator = "REGEX"
		},
		opts = {},
		action = "CHAIN",
		description = "Expect header sent in non-HTTP/1.1 request"
	},
	{
		id = 20009,
		var = {
			type = "HTTP_VERSION",
			opts = nil,
			pattern = 1.1,
			operator = "NOT_EQUALS"
		},
		opts = { chainend = true, chainchild = true },
		action = "LOG",
		description = "Expect header sent in non-HTTP/1.1 request"
	},
	{
		id = 20010,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "pragma",
			operator = "EXISTS"
		},
		opts = {},
		action = "CHAIN",
	},
	{
		id = 20011,
		var = {
			type = "HEADERS",
			opts = { specific = "pragma" },
			pattern = "no-cache",
			operator = "EQUALS"
		},
		opts = { chainchild = true },
		action = "CHAIN"
	},
	{
		id = 20012,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "cache-control",
			operator = "NOT_EXISTS"
		},
		opts = { chainchild = true },
		action = "CHAIN"
	},
	{
		id = 20013,
		var = {
			type = "HTTP_VERSION",
			opts = nil,
			pattern = 1.1,
			operator = "NOT_EQUALS"
		},
		opts = { chainend = true, chainchild = true },
		action = "LOG",
		description = "HTTP/1.1 request sent with a Pragma:no-cache header, but no corresponding Cache-Control header"
	},
	{
		id = 20014,
		var = {
			type = "HEADERS",
			opts = { specific = "range" },
			pattern = [=[^bytes=0-]=],
			operator = "REGEX"
		},
		opts = {},
		action = "LOG",
		description = "Request sent with abnormal Range header"
	},
	{
		id = 20015,
		var = {
			type = "HEADERS",
			opts = { specific = "range" },
			pattern = [=[^bytes=(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,]=],
			operator = "REGEX"
		},
		opts = {},
		action = "LOG",
		description = "Excessive number of byte range fields within one request"
	},
	{
		id = 20016,
		var = {
			type = "HEADERS",
			opts = { specific = "request-range" },
			pattern = [=[^bytes=(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,]=],
			operator = "REGEX"
		},
		opts = {},
		action = "LOG",
		description = "Excessive number of byte range fields within one request"
	},
	{
		id = 20017,
		var = {
			type = "HEADERS",
			opts = { specific = "connection" },
			pattern = [=[\b(keep-alive|close),\s?(keep-alive|close)\b]=],
			operator = "REGEX"
		},
		opts = {},
		action = "LOG",
		description = "Duplicate/broken connection header"
	}
}

function rs_20000.rules()
	return _rules
end

return rs_20000

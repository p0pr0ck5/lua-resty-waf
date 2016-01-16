-- HTTP Protocol Violations

local _M = {}

_M.version = "0.5.2"

_M.rules = {
	access = {
		{
			id = 20001,
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
			id = 20002,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "content-length" },
				pattern = "0",
				operator = "NOT_EQUALS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "GET/HEAD request with a body"
		},
		{
			id = 20003,
			var = {
				type = "METHOD",
				opts = nil,
				pattern = "POST",
				operator = "EQUALS"
			},
			opts = { nolog = true },
			action = "CHAIN",
			description = "POST request does not have a Content-Length Header"
		},
		{
			id = 20004,
			var = {
				type = "REQUEST_HEADER_NAMES",
				opts = nil,
				pattern = "content-length",
				operator = "NOT_EXISTS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "POST request does not have a Content-Length Header"
		},
		{
			id = 20005,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "content-encoding" },
				pattern = "identity",
				operator = "EQUALS"
			},
			opts = { score = 2, transform = 'lowercase' },
			action = "SCORE",
			description = "Identity should not be used in Content-Encoding, only in Accept-Encoding"
		},
		{
			id = 20006,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "expect" },
				pattern = [=[100-continue]=],
				operator = "REGEX"
			},
			opts = { nolog = true },
			action = "CHAIN",
			description = "Expect header sent in non-HTTP/1.1 request"
		},
		{
			id = 20007,
			var = {
				type = "HTTP_VERSION",
				opts = nil,
				pattern = 1.1,
				operator = "NOT_EQUALS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Expect header sent in non-HTTP/1.1 request"
		},
		{
			id = 20008,
			var = {
				type = "REQUEST_HEADER_NAMES",
				opts = nil,
				pattern = "pragma",
				operator = "EXISTS"
			},
			opts = { nolog = true },
			action = "CHAIN",
		},
		{
			id = 20009,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "pragma" },
				pattern = "no-cache",
				operator = "EQUALS"
			},
			opts = { transform = 'lowercase', nolog = true },
			action = "CHAIN"
		},
		{
			id = 20010,
			var = {
				type = "REQUEST_HEADER_NAMES",
				opts = nil,
				pattern = "cache-control",
				operator = "NOT_EXISTS"
			},
			opts = { nolog = true },
			action = "CHAIN"
		},
		{
			id = 20011,
			var = {
				type = "HTTP_VERSION",
				opts = nil,
				pattern = "1.1",
				operator = "NOT_EQUALS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "HTTP/1.1 request sent with a Pragma:no-cache header, but no corresponding Cache-Control header"
		},
		{
			id = 20012,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "range" },
				pattern = [=[^bytes=0-]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Request sent with abnormal Range header"
		},
		{
			id = 20013,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "range" },
				pattern = [=[^bytes=(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Excessive number of byte range fields within one request"
		},
		{
			id = 20014,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "request-range" },
				pattern = [=[^bytes=(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Excessive number of byte range fields within one request"
		},
		{
			id = 20015,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "connection" },
				pattern = [=[\b(keep-alive|close),\s?(keep-alive|close)\b]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Duplicate/broken connection header"
		}
	}
}

return _M

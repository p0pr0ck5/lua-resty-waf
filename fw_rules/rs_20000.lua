local rs_20000 = {}

local _rules = {
	{
		id = "20001",
		vars = { 
			{ 
				type = "REQUEST_LINE", 
				opts = { { nil } },
				pattern = [=[!^(?i:(?:[a-z]{3,10}\s+(?:\w{3,7}?://[\w\-\./]*(?::\d+)?)?/[^?#]*(?:\?[^#\s]*)?(?:#[\S]*)?|connect (?:\d{1,3}\.){3}\d{1,3}\.?(?::\d+)?|options \*)\s+[\w\./]+|get /[^?#]*(?:\?[^#\s]*)?(?:#[\S]*)?)$]=],
				operator = "REGEX",
			},
		},
		action = "LOG",
		description = "Proper HTTP request per RFC 2616"
	},
	{
		id = "20002",
		vars = { 
			{
				type = "HEADERS",
				opts = { { specific = "Content-Length" } },
				pattern = [=[^[^\d]+$]=],
				operator = "REGEX",
			},
		},
		action = "LOG",
		description = "Content-Length header must be a numeric value"
	},
	{
		id = "20003",
		vars = {
			{
				type = "METHOD",
				opts = { { nil } },
				pattern = [=[^(?:GET|HEAD)$]=],
				operator = "REGEX",
			},
			{
				type = "HEADERS",
				opts = { { specific = "Content-Length" } },
				pattern = "0",
				operator = "NOT_EQUALS"
			},
		},
		action = "LOG",
		description = "GET and HEAD requests should not have a body"
	},
	{
		id = "20004",
		vars = {
			{
				type = "METHOD",
				opts = { { nil } },
				pattern = "POST",
				operator = "EQUALS",
			},
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Content-Length",
				operator = "NOT_EXISTS"
			},
		},
		action = "LOG",
		description = "POST requests should always have a Content-Length header associated with the body"
	},
	{
		id = "20005",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Content-Encoding" } },
				pattern = [=[^Identity$]=],
				operator = "REGEX"
			},
		},
		action = "LOG",
		description = "Identity should not be used in Content-Encoding, only in Accept-Encoding"
	},
	{
		id = "20006",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Expect" } },
				pattern = [=[100-continue]=],
				operator = "REGEX"
			},
			{
				type = "HTTP_VERSION",
				opts = { { nil } },
				pattern = 1.1,
				operator = "NOT_EQUALS"
			}
		},
		action = "LOG",
		description = "Expect header is an HTTP/1.1 feature"
	},
	{
		id = "20007",
		vars = {
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Pragma",
				operator = "EXISTS"
			},
			{
				type = "HEADERS",
				opts = { { specific = "Pragma" } },
				pattern = "no-cache",
				operator = "EQUALS"
			},
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Cache-Control",
				operator = "NOT_EXISTS"
			},
			{
				type = "HTTP_VERSION",
				opts = { { nil } },
				pattern = 1.1,
				operator = "EQUALS"
			}
		},
		action = "LOG",
		description = "HTTP/1.1 Requests with Pragma header must have a corresponding Control-Cache header"
	},
	{
		id = "20008",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Range" } },
				pattern = [=[^bytes=0-]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Normal browsers don't send Range headers starting with 0"
	},
	{
		id = "20009",
		vars = {
			{
				type = { "HEADERS", "HEADERS" },
				opts = { { specific = "Range" }, { specific = "Request-Range" } },
				pattern = [=[^bytes=(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,\s?(\d+)?\-(\d+)?\,]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Excessive number of byte range fields within one request"
	},
	{
		id = "20010",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Connection" } },
				pattern = [=[\b(keep-alive|close),\s?(keep-alive|close)\b]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Automated/broken clients often have duplicate or conflicting headers"
	},
	{
		id = "20011",
		vars = {
			{
				type = { "URI", "REQUEST_BODY" },
				opts = { { nil }, { all = true } },
				pattern = [=[\%u[fF]{2}[0-9a-fA-F]{2}]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Disallow use of full-width unicode"
	}
}

function rs_20000.rules()
	return _rules
end

return rs_20000

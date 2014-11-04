local rs_21000 = {}

local _rules = {
	{
		id = "21001",
		vars = {
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Host",
				operator = "NOT_EXISTS"
			}
		},
		action = "LOG",
		description = "No valid Host header"
	},
	{
		id = "21002",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Host" } },
				pattern = [=[^$]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Host header has no value"
	},
	{
		id = "21003",
		vars = {
			{
				type = "METHOD",
				opts = { { nil } },
				pattern = "OPTIONS",
				operator = "NOT_EQUALS"
			},
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Accept",
				operator = "NOT_EXISTS"
			}
		},
		action = "LOG",
		description = "No valid Accept header"
	},
	{   
        id = "21004",
        vars = { 
            {   
                type = "METHOD",
                opts = { { nil } },
                pattern = "OPTIONS",
                operator = "NOT_EQUALS"
            },  
            {   
                type = "HEADERS",
                opts = { { specific = "Accept" } },
                pattern = [=[^$]=],
                operator = "REGEX"
            }   
        },  
        action = "LOG",
        description = "Accept header has no value"
    },
	{
        id = "21005",
        vars = {
            {
                type = "HEADER_NAMES",
                opts = { { nil } },
                pattern = "User-Agent",
                operator = "NOT_EXISTS"
            }
        },
        action = "LOG",
        description = "No valid User-Agent header"
    },
    {
        id = "21006",
        vars = {
            {
                type = "HEADERS",
                opts = { { specific = "User-Agent" } },
                pattern = [=[^$]=],
                operator = "REGEX"
            }
        },
        action = "LOG",
        description = "User-Agent header has no value"
    },
	{
		id = "21007",
		vars = {
			{
				type = "HEADER_NAMES",
				opts = { { nil } },
				pattern = "Content-Type",
				operator = "NOT_EXISTS"
			},
			{
				type = "HEADERS",
				opts = { { specific = "Content-Length" } },
				pattern = [=[!^0$]=],
				operator = "FALSE" -- need to implement negated regex
			}
		},
		action = "LOG",
		description = "Request contains content, but missing Content-Type header"
	},
	{
		id = "21008",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "Host" } },
				pattern = [=[^[\d.:]+$]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Host header contained an IP address"
	}
}

function rs_21000.rules()
	return _rules
end

return rs_21000

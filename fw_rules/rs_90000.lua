local rs = {}

local _rules = {
	{
		id = 90001,
		vars = {
			{
				type = { "HEADERS" },
				opts = { { specific = "User-Agent" } },
				pattern = "FreeWAF Dummy",
				operator = "EQUALS"
			}
		},
		action = "DENY",
		description = "Dummy FreeWAF signature"
	},
	{
		id = "90002",
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = [=[(?:(?:(?:id(?:_(?:dsa(?:.old)?|rsa(?:.old)?)|entify)|key(?:.priv)?$|[dr]sa)))]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "SSH key scan (https://isc.sans.edu/forums/diary/Gimme+your+keys+/18231)" 
	},
	{
		id = "90003",
		vars = {
			{
				type = { "METHOD" },
				opts = { { nil } },
				pattern = "HEAD",
				operator = "EQUALS"
			},
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = "/checknfurl123",
				operator = "EQUALS"
			}
		},
		action = "DENY",
		description = "SSH key scan signature (https://isc.sans.edu/forums/diary/Gimme+your+keys+/18231)"
	},
	{
		id = "90004",
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = [=[/((?:tim)?thumb|img)\.php]=],
				operator = "REGEX"
			},
			{
				type = { "URI_ARGS" },
				opts = { { keys = true } },
				pattern = "webshot",
				operator = "EXISTS"
			},
			{
				type = { "URI_ARGS" },
				opts = { { specific = "src" } },
				pattern = [=[\$\(.*\)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Timthumb zero-day (http://seclists.org/fulldisclosure/2014/Jun/117)"
	},
	{
		id = "90005",
		vars = {
			{
				type = "URI",
				opts = { { nil } },
				pattern = "/index.php",
				operator = "EQUALS"
			},
			{
				type = "REQUEST_ARGS",
				opts = { { specific = 'cat' } },
				pattern = [=[.?[0-9]+.UNION.SELECT]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "WP SQL injection"
	},
	{
		id = "90006",
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = "/wp-comments-post.php",
				operator = "EQUALS"
			},
			{
				type = { "METHOD" },
				opts = { { nil } },
				pattern = "POST",
				operator = "EQUALS"
			},
			{
				type = { "REQUEST_BODY" },
				opts = { { all = true } },
				pattern = [=[%3C.*mfunc.*%3E]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "WP Super Cache PHP injection"
	},
	{
		id = 90007,
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = "/xmlrpc.php",
				operator = "EQUALS"
			},
			{
				type = { "HEADERS" },
				opts = { { specific = "User-Agent" } },
				pattern = [=[WinHttp\.WinHttpRequest\.5]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Brute force botnet affecting Wordpress domains"
	},
	{
		id = 90008,
		vars = {
			{
				type = { "HEADERS" },
				opts = { { specific = "User-Agent" } },
				pattern = [=[Mozilla/5\.0 \(compatible; Zollard; Linux\)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Known *Coin miner worm (https://isc.sans.edu/forums/diary/Multi+Platform+Coin+Miner+Attacking+Routers+on+Port+32764/18353)"
	},
	{
		id = 90009,
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = "/wp-login.php",
				operator = "EQUALS"
			},
			{
				type = { "URI_ARGS" },
				opts = { { specific = "registration" } },
				pattern = "disabled",
				operator = "EQUALS"
			}
		},
		action = "LOG",
		description = "Client attempted to register a Wordpress user, but user registration is disabled."
	},
	{
		id = 900010,
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = "/wp-login.php",
				operator = "EQUALS"
			},
			{
				type = { "METHOD" },
				opts = { { nil } },
				pattern = "POST",
				operator = "EQUALS"
			},
			{
				type = { "HEADER_NAMES" },
				opts = { { nil } },
				pattern = "Referer",
				operator = "NOT_EXISTS"
			}
		},
		action = "DENY",
		description = "Wordpress login attempted with no Referer"
	},
	{
		id = 90011,
		vars = {
			{
				type = { "URI" },
				opts = { { } },
				pattern = "/wp-admin/admin-ajax.php",
				operator = "EQUALS"
			},
			{
				type = { "URI_ARGS" },
				opts = { { specific = "action" } },
				pattern = "revslider_show_image",
				operator = "EQUALS"
			},
			{
				type = { "URI_ARGS" },
				opts = { { specific = "img" } },
				pattern = [=[^\.\./wp-*|\.php$]=],
				operator = "REGEX"
			}
		},
		description = "Slider Revolution WordPress Plugin LFI Vulnerability",
		action = "DENY"
	},
	{
		id = 90012,
		vars = {
			{
				type = { "REQUEST_ARGS" },
				opts = { { all = true } },
				pattern = [=[^\(\)]=],
				operator = "REGEX"
			}
		},
		description = "Bash environmental variable injection (CVE-2014-6271)",
		action = "DENY"
	}
}

function rs.rules()
	return _rules
end

return rs

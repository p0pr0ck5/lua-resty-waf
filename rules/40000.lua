-- Generic Attacks

local _M = {}

_M.version = "0.5.2"

_M.rules = {
	access = {
		{
			id = 40001,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:(?:[\;\|\`]\W*?\bcc|\b(wget|curl))\b|\/cc(?:[\'\"\|\;\`\-\s]|$))]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "OS Command Injection detected"
		},
		{
			id = 40002,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[[^\w\r\n]{4,}]=],
				operator = "REGEX",
			},
			opts = { score = 4, transform = 'uri_decode' },
			action = "SCORE",
			description = "Repetative non-word characters anomaly detected"
		},
		{
			id = 40003,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[\bcf(?:usion_(?:d(?:bconnections_flush|ecrypt)|set(?:tings_refresh|odbcini)|getodbc(?:dsn|ini)|verifymail|encrypt)|_(?:(?:iscoldfusiondatasourc|getdatasourceusernam)e|setdatasource(?:password|username))|newinternal(?:adminsecurit|registr)y|admin_registry_(?:delete|set)|internaldebug|execute)\b]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "Coldfusion injection detected"
		},
		{
			id = 40004,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\((?:\W*?(?:objectc(?:ategory|lass)|homedirectory|[gu]idnumber|cn)\b\W*?=|[^\w\x80-\xFF]*?[\!\&\|][^\w\x80-\xFF]*?\()|\)[^\w\x80-\xFF]*?\([^\w\x80-\xFF]*?[\!\&\|])]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "LDAP Injection detected"
		},
		{
			id = 40005,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[<!--\W*?#\W*?(?:e(?:cho|xec)|printenv|include|cmd)]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "SSI injection detected"
		},
		{
			id = 40006,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[http:\/\/[\w\.]+?\/.*?\.pdf\b[^\x0d\x0a]*#]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "UPDF XSS"
		},
		{
			id = 40007,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[[\n\r]\s*\b(?:to|b?cc)\b\s*:.*?\@]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "E-mail injection",
		},
		{
			id = 40008,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "content-length" },
				pattern = [=[,]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "HTTP Request Smuggling"
		},
		{
			id = 40009,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "transfer-encoding" },
				pattern = [=[,]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "HTTP Request Smuggling"
		},
		{
			id = 40010,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[[\n\r](?:content-(type|length)|set-cookie|location):]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "HTTP Response Splitting"
		},
		{
			id = 40011,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\bhttp\/(?:0\.9|1\.[01])|<(?:html|meta)\b)]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "HTTP Response Splitting"
	    },
		{
			id = 40012,
	        var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[^(?:ht|f)tps?:\/\/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "Remote File Inclusion - URL in request argument"
		},
		{
			id = 40013,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:(\binclude\s*\([^)]*|mosConfig_absolute_path|_CONF\[path\]|_SERVER\[DOCUMENT_ROOT\]|GALLERY_BASEDIR|path\[docroot\]|appserv_root|config\[root_dir\])=(ht|f)tps?:\/\/)]=],
				operator = "REGEX"
			},
			opts = { score = 4, transform = 'uri_decode' },
			action = "SCORE",
			description = "Remote File Inclusion - PHP include() function"
		},
		{
			id = 40014,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[^(?:ft|htt)ps?(.*?)\?+$]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "Remote File Inclusion - RFI data ends with question mark"
		},
		{
			id = 40015,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\.cookie\b.*?;\W*?(?:expires|domain)\W*?=|\bhttp-equiv\W+set-cookie\b)]=],
				operator = "REGEX",
			},
			opts = { score = 4, transform = 'uri_decode' },
			action = "SCORE",
			description = "Session fixation attack detected"
		},
		{
			id = 40016,
			var = {
					type = "REQUEST_ARGS",
					opts = { key = "all" },
					pattern = [=[(?:\b(?:\.(?:ht(?:access|passwd|group)|www_?acl)|global\.asa|httpd\.conf|boot\.ini)\b|\/etc\/)]=],
					operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "System file access attempt"
		},
		{
			id = 40017,
			var = {
					type = "REQUEST_ARGS",
					opts = { key = "all" },
					pattern = [=[\b(?:(?:n(?:map|et|c)|w(?:guest|sh)|telnet|rcmd|ftp)\.exe\b|cmd(?:(?:32)?\.exe\b|\b\W*?\/c))]=],
					operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "System command access attempt"
		},
		{
			id = 40018,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\b(?:(?:n(?:et(?:\b\W+?\blocalgroup|\.exe)|(?:map|c)\.exe)|t(?:racer(?:oute|t)|elnet\.exe|clsh8?|ftp)|(?:w(?:guest|sh)|rcmd|ftp)\.exe|echo\b\W*?\by+)\b|c(?:md(?:(?:\.exe|32)\b|\b\W*?\/c)|d(?:\b\W*?[\\/]|\W*?\.\.)|hmod.{0,40}?\+.{0,3}x))|[\;\|\`]\W*?\b(?:(?:c(?:h(?:grp|mod|own|sh)|md|pp)|p(?:asswd|ython|erl|ing|s)|n(?:asm|map|c)|f(?:inger|tp)|(?:kil|mai)l|(?:xte)?rm|ls(?:of)?|telnet|uname|echo|id)\b|g(?:\+\+|cc\b)))]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "System command injection attempt"
		},
		{
			id = 40019,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[<\?(?!xml)]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "PHP Injection"
		},
		{
			id = 40020,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\b(?:f(?:tp_(?:nb_)?f?(?:ge|pu)t|get(?:s?s|c)|scanf|write|open|read)|gz(?:(?:encod|writ)e|compress|open|read)|s(?:ession_start|candir)|read(?:(?:gz)?file|dir)|move_uploaded_file|(?:proc_|bz)open|call_user_func)|\$_(?:(?:pos|ge)t|session))\b]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "PHP Injection"
		},
		{
			id = 40021,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:(?:(?:(?:a(?:llow_url_includ|uto_prepend_fil)e|s(?:uhosin.simulation|afe_mode)|disable_functions|open_basedir)=|php://input)))]=],
				operator = "REGEX"
			},
			opts = { score = 4, transform = 'uri_decode' },
			action = "SCORE",
			description = "PHP Injection"
		},
		{
			id = 40022,
			var = {
				type = "REQUEST_ARGS",
				opts = { key = "all" },
				pattern = [=[(?:\x5c|(?:%(?:2(?:5(?:2f|5c)|%46|f)|c(?:0%(?:9v|af)|1%1c)|u(?:221[56]|002f)|%32(?:%46|F)|e0%80%af|1u|5c)|\/))(?:%(?:2(?:(?:52)?e|%45)|(?:e0%8|c)0%ae|u(?:002e|2024)|%32(?:%45|E))|\.){2}(?:\x5c|(?:%(?:2(?:5(?:2f|5c)|%46|f)|c(?:0%(?:9v|af)|1%1c)|u(?:221[56]|002f)|%32(?:%46|F)|e0%80%af|1u|5c)|\/))]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "Directory traversal (volatile match)"
		},
		{
			id = 40023,
			var = {
				type = "URI",
				opts = nil,
				pattern = [=[%00+$]=],
				operator = "REGEX"
			},
			opts = { score = 4 },
			action = "SCORE",
			description = "Null byte at end of URI"
		},
	}
}

return _M

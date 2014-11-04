local rs_40000 = {}

local _rules = {
	{
		id = "40001",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[(?:(?:[\;\|\`]\W*?\bcc|\b(wget|curl))\b|\/cc(?:[\'\"\|\;\`\-\s]|$))]=],
				operator = "REGEX",
			}
		},
		action = "DENY",
		description = "OS Command Injection detected"
	},
	{
		id = "40002",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[[^\w\r\n]{4,}]=],
				operator = "REGEX",
			}
		},
		action = "DENY",
		description = "Repetative non-word characters anomaly detected"
	},
	{
		id = "40003",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[\bcf(?:usion_(?:d(?:bconnections_flush|ecrypt)|set(?:tings_refresh|odbcini)|getodbc(?:dsn|ini)|verifymail|encrypt)|_(?:(?:iscoldfusiondatasourc|getdatasourceusernam)e|setdatasource(?:password|username))|newinternal(?:adminsecurit|registr)y|admin_registry_(?:delete|set)|internaldebug|execute)\b]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Coldfusion injection detected"
	},
	{
		id = "40004",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[(?:\((?:\W*?(?:objectc(?:ategory|lass)|homedirectory|[gu]idnumber|cn)\b\W*?=|[^\w\x80-\xFF]*?[\!\&\|][^\w\x80-\xFF]*?\()|\)[^\w\x80-\xFF]*?\([^\w\x80-\xFF]*?[\!\&\|])]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "LDAP Injection detected"
	},
	{
		id = "40005",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[<!--\W*?#\W*?(?:e(?:cho|xec)|printenv|include|cmd)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "SSI injection detected"
	},
	{
		id = "40006",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[http:\/\/[\w\.]+?\/.*?\.pdf\b[^\x0d\x0a]*#]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "UPDF XSS"
	},
	{
		id = "40007",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[[\n\r]\s*\b(?:to|b?cc)\b\s*:.*?\@]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "E-mail injection",
	},
	{
		id = "40008",
		vars = {
			{
				type = { "HEADERS", "HEADERS" },
				opts = { { specific = "Content-Length" }, { specific = "Transfer-Encoding" } },
				pattern = [=[,]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "HTTP Request Smuggling"
	},
	{
		id = "40009",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[[\n\r](?:content-(type|length)|set-cookie|location):]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "HTTP Response Splitting"
	},
	{   
        id = "40010",
        vars = { 
            {   
                type = "REQUEST_ARGS",
                opts = { { all = true } },
                pattern = [=[(?:\bhttp\/(?:0\.9|1\.[01])|<(?:html|meta)\b)]=],
                operator = "REGEX"
            }   
        },  
        action = "DENY",
        description = "HTTP Response Splitting"
    },
	{
        id = "40011",
        vars = {
            {
                type = "REQUEST_ARGS",
                opts = { { all = true } },
                pattern = [=[^(?:ht|f)tps?:\/\/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})]=],
                operator = "REGEX"
            }
        },
        action = "DENY",
        description = "Remote File Inclusion - URL in request argument"
    },
	{
		id = "40012",
		vars = {
			{
				type = { "URI_ARGS", "REQUEST_BODY" },
				opts = { { all = true }, { all = true } },
				pattern = [=[(?:(\binclude\s*\([^)]*|mosConfig_absolute_path|_CONF\[path\]|_SERVER\[DOCUMENT_ROOT\]|GALLERY_BASEDIR|path\[docroot\]|appserv_root|config\[root_dir\])=(ht|f)tps?:\/\/)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Remote File Inclusion - PHP include() function"
	},
	{
		id = "40013",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[^(?:ft|htt)ps?(.*?)\?+$]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Remote File Inclusion - RFI data ends with question mark"
	},
	{
		id = "40014",
		vars = {
			{
				type = "REQUST_ARGS",
				opts = { { all = true  } },
				pattern = [=[(?:\.cookie\b.*?;\W*?(?:expires|domain)\W*?=|\bhttp-equiv\W+set-cookie\b)]=],
				operator = "REGEX",
			}
		},
		action = "DENY",
		description = "Session fixation attack detected"
	},
	{
		id = "40015",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { V } },
				pattern = [=[(?:\b(?:\.(?:ht(?:access|passwd|group)|www_?acl)|global\.asa|httpd\.conf|boot\.ini)\b|\/etc\/)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "System file access attempt"
	},
	{
		id = "40016",
		vars = {
			{
				type = "REQEST_ARGS",
				opts = { { all = true } },
				pattern = [=[\b(?:(?:n(?:map|et|c)|w(?:guest|sh)|telnet|rcmd|ftp)\.exe\b|cmd(?:(?:32)?\.exe\b|\b\W*?\/c))]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "System command access attempt"
	},
	{
		id = "40017",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[(?:\b(?:(?:n(?:et(?:\b\W+?\blocalgroup|\.exe)|(?:map|c)\.exe)|t(?:racer(?:oute|t)|elnet\.exe|clsh8?|ftp)|(?:w(?:guest|sh)|rcmd|ftp)\.exe|echo\b\W*?\by+)\b|c(?:md(?:(?:\.exe|32)\b|\b\W*?\/c)|d(?:\b\W*?[\\/]|\W*?\.\.)|hmod.{0,40}?\+.{0,3}x))|[\;\|\`]\W*?\b(?:(?:c(?:h(?:grp|mod|own|sh)|md|pp)|p(?:asswd|ython|erl|ing|s)|n(?:asm|map|c)|f(?:inger|tp)|(?:kil|mai)l|(?:xte)?rm|ls(?:of)?|telnet|uname|echo|id)\b|g(?:\+\+|cc\b)))]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "System command injection attempt"
	},
	{
		id = "40018",
		vars = {
			{
				type = "REQUEST_HEADERS",
				opts = { { nil } },
				pattern = [=[<\?(?!xml)]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "PHP Injection"
	},
	{
		id = "40019",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[(?:\b(?:f(?:tp_(?:nb_)?f?(?:ge|pu)t|get(?:s?s|c)|scanf|write|open|read)|gz(?:(?:encod|writ)e|compress|open|read)|s(?:ession_start|candir)|read(?:(?:gz)?file|dir)|move_uploaded_file|(?:proc_|bz)open|call_user_func)|\$_(?:(?:pos|ge)t|session))\b]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "PHP Injection"
	},
	{
		id = "40020",
		vars = {
			{
				type = "REQUEST_ARGS",
				opts = { { all = true } },
				pattern = [=[(?:(?:(?:(?:a(?:llow_url_includ|uto_prepend_fil)e|s(?:uhosin.simulation|afe_mode)|disable_functions|open_basedir)=|php://input)))]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "PHP Injection"
	},
	{
		id = "40021",
		vars = {
			{
				type = { "URI", "REQUEST_BODY", "HEADERS" },
				opts = { { nil }, { all = true }, { ignore = "Referer" } },
				pattern = [=[(?:\x5c|(?:%(?:2(?:5(?:2f|5c)|%46|f)|c(?:0%(?:9v|af)|1%1c)|u(?:221[56]|002f)|%32(?:%46|F)|e0%80%af|1u|5c)|\/))(?:%(?:2(?:(?:52)?e|%45)|(?:e0%8|c)0%ae|u(?:002e|2024)|%32(?:%45|E))|\.){2}(?:\x5c|(?:%(?:2(?:5(?:2f|5c)|%46|f)|c(?:0%(?:9v|af)|1%1c)|u(?:221[56]|002f)|%32(?:%46|F)|e0%80%af|1u|5c)|\/))]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Directory traversal (volatile match)"
	},
	{
		id = "40022",
		vars = {
			{
				type = { "URI" },
				opts = { { nil } },
				pattern = [=[%00+$]=],
				operator = "REGEX"
			}
		},
		action = "DENY",
		description = "Null byte at end of URI"
	},
}



function rs_40000.rules()
	return _rules
end

return rs_40000

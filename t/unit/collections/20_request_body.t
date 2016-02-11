use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_BODY collections variable (GET request, no body)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(tostring(collections.REQUEST_BODY))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- error_log
Request has no content type, ignoring the body
--- no_error_log
[error]

=== TEST 2: REQUEST_BODY collections variable type (GET request, no body)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- error_log
Request has no content type, ignoring the body
--- no_error_log
[error]

=== TEST 3: REQUEST_BODY collections variable (POST request, no content type)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(tostring(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
foo=bar
--- error_code: 200
--- response_body
nil
--- error_log
Request has no content type, ignoring the body
--- no_error_log
[error]

=== TEST 4: REQUEST_BODY collections variable type (POST request, no content type)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
foo=bar
--- error_code: 200
--- response_body
nil
--- error_log
Request has no content type, ignoring the body
--- no_error_log
[error]

=== TEST 5: REQUEST_BODY collections variable (POST request, application/x-www-form-urlencoded)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections  = ngx.ctx.collections
			local request_body = collections.REQUEST_BODY

			for k, v in pairs(request_body) do
				ngx.say(k .. ": " .. v)
			end
		';
	}
--- request
POST /t
foo=bar
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
foo: bar
--- no_error_log
[error]
Request has no content type, ignoring the body

=== TEST 6: REQUEST_BODY collections variable type (POST request, application/x-www-form-urlencoded)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
foo=bar
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
table
--- no_error_log
[error]
Request has no content type, ignoring the body

=== TEST 7: REQUEST_BODY collections variable (POST request, application/x-www-form-urlencoded, too large)
--- config
	location /t {
		client_body_buffer_size 1k;

		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(tostring(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
foo=Lorem%20ipsum%20dolor%20sit%20amet,%20consectetur%20adipiscing%20elit.%20Etiam%20tincidunt%20dapibus%20metus,%20in%20blandit%20est%20blandit%20et.%20Morbi%20finibus%20nisl%20id%20arcu%20tincidunt,%20at%20sodales%20neque%20pulvinar.%20Nam%20malesuada%20hendrerit%20scelerisque.%20Quisque%20ut%20diam%20at%20nisl%20finibus%20sollicitudin%20et%20a%20lacus.%20Vestibulum%20accumsan%20dui%20sit%20amet%20tristique%20posuere.%20Nam%20velit%20sapien,%20luctus%20ut%20odio%20non,%20elementum%20tempor%20velit.%20Sed%20lobortis%20elementum%20metus%20non%20iaculis.%20Nam%20vel%20gravida%20justo.%20Donec%20pellentesque%20eleifend%20quam%20et%20suscipit.%20Mauris%20ac%20purus%20et%20mauris%20consequat%20dignissim.%20Donec%20rutrum%20congue%20lorem,%20nec%20faucibus%20velit%20pharetra%20a.%20Proin%20semper%20lorem%20in%20lorem%20rhoncus%20sagittis.%20Nulla%20quis%20lorem%20a%20enim%20mattis%20semper.%20Nunc%20sagittis,%20odio%20eu%20luctus%20condimentum,%20magna%20mauris%20posuere%20ipsum,%20et%20fermentum%20mi%20arcu%20ut%20leo.%20Etiam%20sit%20amet%20tempus%20purus.%20Vestibulum%20urna%20risus,%20posuere%20vel%20bibendum%20vitae,%20gravida%20id%20massa.In%20tincidunt%20lectus%20sodales%20orci%20tempus%20commodo.%20Cum%20sociis%20natoque%20penatibus%20et%20magnis%20dis%20parturient%20montes,%20nascetur%20ridiculus%20mus.%20Morbi%20feugiat%20felis%20diam,%20vel%20pellentesque%20augue%20condimentum%20sagittis.%20Vivamus%20feugiat%20nisi%20ornare,%20dignissim%20ex%20at,%20ullamcorper%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20purus%20justo,%20malesuada%20vel%20fermentum%20id,%20auctor%20condimentum%20lacus.%20Integer%20et%20lorem%20eget%20magna%20bibendum%20aliquam%20nec%20a%20diam.%20Morbi%20volutpat%20mauris%20non%20dictum%20dignissim.%20Nullam%20convallis,%20felis%20et%20sagittis%20pellentesque,%20ex%20eros%20tempor%20tortor,%20vitae%20sagittis%20mauris%20est%20ac%20quam.%20Aliquam%20faucibus%20gravida%20mauris%20ac%20luctus.%20Curabitur%20sagittis%20placerat%20sem,%20eget%20lacinia%20enim.%20Fusce%20quis%20molestie%20risus,%20id%20euismod%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20interdum%20nisl%20metus,%20sit%20amet%20fermentum%20arcu%20venenatis%20ac.Nullam%20placerat,%20quam%20eu%20aliquam%20porttitor,%20ex%20ante%20semper%20velit,%20ac%20gravida%20arcu%20purus%20sit%20amet%20justo.%20Nullam%20molestie%20rutrum%20tortor,%20id%20feugiat%20odio%20gravida%20vitae.%20Vivamus%20lobortis%20massa%20vel%20turpis%20gravida,%20sit%20amet%20pretium%20augue%20dignissim.%20Sed%20ultricies%20nisi%20in%20nisi%20faucibus,%20sed%20commodo%20lacus%20elementum.%20Integer%20convallis%20interdum%20orci%20eu%20maximus.%20Vestibulum%20dictum%20euismod%20massa.%20Aenean%20orci%20massa,%20laoreet%20at%20nisi%20consequat,%20efficitur%20efficitur%20justo.%20Curabitur%20lobortis%20pulvinar%20mauris%20ac%20pulvinar.%20Sed%20nisi%20mi,%20congue%20id%20nulla%20in,%20sodales%20interdum%20sem.%20Duis%20sit%20amet%20accumsan%20libero.%20Pellentesque%20sapien%20nulla,%20mollis%20rutrum%20finibus%20eu,%20lobortis%20sed%20velit.%20Pellentesque%20sem%20risus,%20tempor%20ut%20scelerisque%20sed,%20tempus%20et%20nulla.%20Pellentesque%20a%20viverra%20lacus,%20nec%20imperdiet%20mauris.%20Suspendisse%20lobortis,%20sem%20fermentum%20sollicitudin%20aliquam,%20ligula%20diam%20elementum%20sapien,%20in%20congue%20nunc%20sapien%20ut%20erat.Duis%20eget%20enim%20in%20tellus%20rhoncus%20ornare%20sit%20amet%20sit%20amet%20arcu.%20Vestibulum%20in%20sapien%20eu%20nibh%20ornare%20suscipit.%20Sed%20et%20maximus%20erat,%20sed%20sollicitudin%20sem.%20Quisque%20in%20convallis%20metus,%20eget%20congue%20dui.%20Etiam%20urna%20lectus,%20euismod%20vitae%20est%20id,%20sollicitudin%20commodo%20felis.%20Duis%20commodo%20arcu%20ex,%20a%20fringilla%20dolor%20tristique%20id.%20Donec%20cursus%20dolor%20at%20quam%20posuere,%20in%20dictum%20arcu%20volutpat.%20Nullam%20tincidunt%20vehicula%20neque.%20Pellentesque%20a%20lacus%20pellentesque,%20elementum%20felis%20sed,%20aliquam%20est.%20Nunc%20commodo%20massa%20in%20sapien%20euismod%20imperdiet.Proin%20dignissim%20velit%20eu%20ex%20aliquet,%20id%20lacinia%20mi%20condimentum.%20Mauris%20eu%20urna%20eget%20ante%20vulputate%20scelerisque.%20Donec%20in%20porttitor%20nisl.%20Mauris%20semper,%20nunc%20mattis%20blandit%20convallis,%20risus%20libero%20tristique%20dui,%20nec%20interdum%20nisi%20erat%20et%20turpis.%20Nunc%20sed%20interdum%20orci,%20ut%20tincidunt%20neque.%20Nunc%20bibendum%20et%20eros%20eu%20iaculis.%20Nunc%20accumsan%20ac%20libero%20eu%20malesuada.%20Nulla%20laoreet%20sodales%20ligula,%20sit%20amet%20semper%20enim%20blandit%20et.%20Aenean%20pulvinar%20urna%20varius%20tortor%20rutrum,%20a%20venenatis%20tellus%20fringilla.%20Nullam%20a%20nunc%20in%20nunc%20condimentum%20pellentesque%20eu%20sit%20amet%20felis.%20Fusce%20facilisis%20efficitur%20felis%20sit%20amet%20pulvinar.%20Morbi%20eget%20nunc%20justo.%20Aenean%20et%20nisl%20odio.%20Nulla%20facilisi.%20Nam%20mattis%20mi%20eget%20metus%20aliquet,%20ut%20viverra%20nulla%20fringilla.%20Cras%20aliquam%20urna%20ipsum,%20feugiat%20molestie%20ante%20sagittis%20in.
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
nil
--- error_log
Request body size larger than client_body_buffer_size, ignoring request body
--- no_error_log
[error]

=== TEST 8: REQUEST_BODY collections variable type (POST request, application/x-www-form-urlencoded, too large)
--- config
	location /t {
		client_body_buffer_size 1k;

		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
foo=Lorem%20ipsum%20dolor%20sit%20amet,%20consectetur%20adipiscing%20elit.%20Etiam%20tincidunt%20dapibus%20metus,%20in%20blandit%20est%20blandit%20et.%20Morbi%20finibus%20nisl%20id%20arcu%20tincidunt,%20at%20sodales%20neque%20pulvinar.%20Nam%20malesuada%20hendrerit%20scelerisque.%20Quisque%20ut%20diam%20at%20nisl%20finibus%20sollicitudin%20et%20a%20lacus.%20Vestibulum%20accumsan%20dui%20sit%20amet%20tristique%20posuere.%20Nam%20velit%20sapien,%20luctus%20ut%20odio%20non,%20elementum%20tempor%20velit.%20Sed%20lobortis%20elementum%20metus%20non%20iaculis.%20Nam%20vel%20gravida%20justo.%20Donec%20pellentesque%20eleifend%20quam%20et%20suscipit.%20Mauris%20ac%20purus%20et%20mauris%20consequat%20dignissim.%20Donec%20rutrum%20congue%20lorem,%20nec%20faucibus%20velit%20pharetra%20a.%20Proin%20semper%20lorem%20in%20lorem%20rhoncus%20sagittis.%20Nulla%20quis%20lorem%20a%20enim%20mattis%20semper.%20Nunc%20sagittis,%20odio%20eu%20luctus%20condimentum,%20magna%20mauris%20posuere%20ipsum,%20et%20fermentum%20mi%20arcu%20ut%20leo.%20Etiam%20sit%20amet%20tempus%20purus.%20Vestibulum%20urna%20risus,%20posuere%20vel%20bibendum%20vitae,%20gravida%20id%20massa.In%20tincidunt%20lectus%20sodales%20orci%20tempus%20commodo.%20Cum%20sociis%20natoque%20penatibus%20et%20magnis%20dis%20parturient%20montes,%20nascetur%20ridiculus%20mus.%20Morbi%20feugiat%20felis%20diam,%20vel%20pellentesque%20augue%20condimentum%20sagittis.%20Vivamus%20feugiat%20nisi%20ornare,%20dignissim%20ex%20at,%20ullamcorper%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20purus%20justo,%20malesuada%20vel%20fermentum%20id,%20auctor%20condimentum%20lacus.%20Integer%20et%20lorem%20eget%20magna%20bibendum%20aliquam%20nec%20a%20diam.%20Morbi%20volutpat%20mauris%20non%20dictum%20dignissim.%20Nullam%20convallis,%20felis%20et%20sagittis%20pellentesque,%20ex%20eros%20tempor%20tortor,%20vitae%20sagittis%20mauris%20est%20ac%20quam.%20Aliquam%20faucibus%20gravida%20mauris%20ac%20luctus.%20Curabitur%20sagittis%20placerat%20sem,%20eget%20lacinia%20enim.%20Fusce%20quis%20molestie%20risus,%20id%20euismod%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20interdum%20nisl%20metus,%20sit%20amet%20fermentum%20arcu%20venenatis%20ac.Nullam%20placerat,%20quam%20eu%20aliquam%20porttitor,%20ex%20ante%20semper%20velit,%20ac%20gravida%20arcu%20purus%20sit%20amet%20justo.%20Nullam%20molestie%20rutrum%20tortor,%20id%20feugiat%20odio%20gravida%20vitae.%20Vivamus%20lobortis%20massa%20vel%20turpis%20gravida,%20sit%20amet%20pretium%20augue%20dignissim.%20Sed%20ultricies%20nisi%20in%20nisi%20faucibus,%20sed%20commodo%20lacus%20elementum.%20Integer%20convallis%20interdum%20orci%20eu%20maximus.%20Vestibulum%20dictum%20euismod%20massa.%20Aenean%20orci%20massa,%20laoreet%20at%20nisi%20consequat,%20efficitur%20efficitur%20justo.%20Curabitur%20lobortis%20pulvinar%20mauris%20ac%20pulvinar.%20Sed%20nisi%20mi,%20congue%20id%20nulla%20in,%20sodales%20interdum%20sem.%20Duis%20sit%20amet%20accumsan%20libero.%20Pellentesque%20sapien%20nulla,%20mollis%20rutrum%20finibus%20eu,%20lobortis%20sed%20velit.%20Pellentesque%20sem%20risus,%20tempor%20ut%20scelerisque%20sed,%20tempus%20et%20nulla.%20Pellentesque%20a%20viverra%20lacus,%20nec%20imperdiet%20mauris.%20Suspendisse%20lobortis,%20sem%20fermentum%20sollicitudin%20aliquam,%20ligula%20diam%20elementum%20sapien,%20in%20congue%20nunc%20sapien%20ut%20erat.Duis%20eget%20enim%20in%20tellus%20rhoncus%20ornare%20sit%20amet%20sit%20amet%20arcu.%20Vestibulum%20in%20sapien%20eu%20nibh%20ornare%20suscipit.%20Sed%20et%20maximus%20erat,%20sed%20sollicitudin%20sem.%20Quisque%20in%20convallis%20metus,%20eget%20congue%20dui.%20Etiam%20urna%20lectus,%20euismod%20vitae%20est%20id,%20sollicitudin%20commodo%20felis.%20Duis%20commodo%20arcu%20ex,%20a%20fringilla%20dolor%20tristique%20id.%20Donec%20cursus%20dolor%20at%20quam%20posuere,%20in%20dictum%20arcu%20volutpat.%20Nullam%20tincidunt%20vehicula%20neque.%20Pellentesque%20a%20lacus%20pellentesque,%20elementum%20felis%20sed,%20aliquam%20est.%20Nunc%20commodo%20massa%20in%20sapien%20euismod%20imperdiet.Proin%20dignissim%20velit%20eu%20ex%20aliquet,%20id%20lacinia%20mi%20condimentum.%20Mauris%20eu%20urna%20eget%20ante%20vulputate%20scelerisque.%20Donec%20in%20porttitor%20nisl.%20Mauris%20semper,%20nunc%20mattis%20blandit%20convallis,%20risus%20libero%20tristique%20dui,%20nec%20interdum%20nisi%20erat%20et%20turpis.%20Nunc%20sed%20interdum%20orci,%20ut%20tincidunt%20neque.%20Nunc%20bibendum%20et%20eros%20eu%20iaculis.%20Nunc%20accumsan%20ac%20libero%20eu%20malesuada.%20Nulla%20laoreet%20sodales%20ligula,%20sit%20amet%20semper%20enim%20blandit%20et.%20Aenean%20pulvinar%20urna%20varius%20tortor%20rutrum,%20a%20venenatis%20tellus%20fringilla.%20Nullam%20a%20nunc%20in%20nunc%20condimentum%20pellentesque%20eu%20sit%20amet%20felis.%20Fusce%20facilisis%20efficitur%20felis%20sit%20amet%20pulvinar.%20Morbi%20eget%20nunc%20justo.%20Aenean%20et%20nisl%20odio.%20Nulla%20facilisi.%20Nam%20mattis%20mi%20eget%20metus%20aliquet,%20ut%20viverra%20nulla%20fringilla.%20Cras%20aliquam%20urna%20ipsum,%20feugiat%20molestie%20ante%20sagittis%20in.
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
nil
--- error_log
Request body size larger than client_body_buffer_size, ignoring request body
--- no_error_log
[error]

=== TEST 9: REQUEST_BODY collections variable (POST request, text/json)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("allowed_content_types", "text/json")
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_BODY)
		';
	}
--- request
POST /t
{"foo":"bar","qux":{"quux":"corge","grault":"garply"},"baz":["bat","bam","biff"]}
--- more_headers
Content-Type: text/json
--- error_code: 200
--- response_body
{"foo":"bar","qux":{"quux":"corge","grault":"garply"},"baz":["bat","bam","biff"]}
--- no_error_log
[error]
Request has no content type, ignoring the body

=== TEST 10: REQUEST_BODY collections variable type (POST request, text/json)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("allowed_content_types", "text/json")
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
{"foo":"bar","qux":{"quux":"corge","grault":"garply"},"baz":["bat","bam","biff"]}
--- more_headers
Content-Type: text/json
--- error_code: 200
--- response_body
string
--- no_error_log
[error]
Request has no content type, ignoring the body

=== TEST 11: REQUEST_BODY collections variable (POST request, text/json, too large)
--- config
	location /t {
		client_body_buffer_size 1k;

		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("allowed_content_types", "text/json")
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(tostring(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
{"foo"="Lorem%20ipsum%20dolor%20sit%20amet,%20consectetur%20adipiscing%20elit.%20Etiam%20tincidunt%20dapibus%20metus,%20in%20blandit%20est%20blandit%20et.%20Morbi%20finibus%20nisl%20id%20arcu%20tincidunt,%20at%20sodales%20neque%20pulvinar.%20Nam%20malesuada%20hendrerit%20scelerisque.%20Quisque%20ut%20diam%20at%20nisl%20finibus%20sollicitudin%20et%20a%20lacus.%20Vestibulum%20accumsan%20dui%20sit%20amet%20tristique%20posuere.%20Nam%20velit%20sapien,%20luctus%20ut%20odio%20non,%20elementum%20tempor%20velit.%20Sed%20lobortis%20elementum%20metus%20non%20iaculis.%20Nam%20vel%20gravida%20justo.%20Donec%20pellentesque%20eleifend%20quam%20et%20suscipit.%20Mauris%20ac%20purus%20et%20mauris%20consequat%20dignissim.%20Donec%20rutrum%20congue%20lorem,%20nec%20faucibus%20velit%20pharetra%20a.%20Proin%20semper%20lorem%20in%20lorem%20rhoncus%20sagittis.%20Nulla%20quis%20lorem%20a%20enim%20mattis%20semper.%20Nunc%20sagittis,%20odio%20eu%20luctus%20condimentum,%20magna%20mauris%20posuere%20ipsum,%20et%20fermentum%20mi%20arcu%20ut%20leo.%20Etiam%20sit%20amet%20tempus%20purus.%20Vestibulum%20urna%20risus,%20posuere%20vel%20bibendum%20vitae,%20gravida%20id%20massa.In%20tincidunt%20lectus%20sodales%20orci%20tempus%20commodo.%20Cum%20sociis%20natoque%20penatibus%20et%20magnis%20dis%20parturient%20montes,%20nascetur%20ridiculus%20mus.%20Morbi%20feugiat%20felis%20diam,%20vel%20pellentesque%20augue%20condimentum%20sagittis.%20Vivamus%20feugiat%20nisi%20ornare,%20dignissim%20ex%20at,%20ullamcorper%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20purus%20justo,%20malesuada%20vel%20fermentum%20id,%20auctor%20condimentum%20lacus.%20Integer%20et%20lorem%20eget%20magna%20bibendum%20aliquam%20nec%20a%20diam.%20Morbi%20volutpat%20mauris%20non%20dictum%20dignissim.%20Nullam%20convallis,%20felis%20et%20sagittis%20pellentesque,%20ex%20eros%20tempor%20tortor,%20vitae%20sagittis%20mauris%20est%20ac%20quam.%20Aliquam%20faucibus%20gravida%20mauris%20ac%20luctus.%20Curabitur%20sagittis%20placerat%20sem,%20eget%20lacinia%20enim.%20Fusce%20quis%20molestie%20risus,%20id%20euismod%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20interdum%20nisl%20metus,%20sit%20amet%20fermentum%20arcu%20venenatis%20ac.Nullam%20placerat,%20quam%20eu%20aliquam%20porttitor,%20ex%20ante%20semper%20velit,%20ac%20gravida%20arcu%20purus%20sit%20amet%20justo.%20Nullam%20molestie%20rutrum%20tortor,%20id%20feugiat%20odio%20gravida%20vitae.%20Vivamus%20lobortis%20massa%20vel%20turpis%20gravida,%20sit%20amet%20pretium%20augue%20dignissim.%20Sed%20ultricies%20nisi%20in%20nisi%20faucibus,%20sed%20commodo%20lacus%20elementum.%20Integer%20convallis%20interdum%20orci%20eu%20maximus.%20Vestibulum%20dictum%20euismod%20massa.%20Aenean%20orci%20massa,%20laoreet%20at%20nisi%20consequat,%20efficitur%20efficitur%20justo.%20Curabitur%20lobortis%20pulvinar%20mauris%20ac%20pulvinar.%20Sed%20nisi%20mi,%20congue%20id%20nulla%20in,%20sodales%20interdum%20sem.%20Duis%20sit%20amet%20accumsan%20libero.%20Pellentesque%20sapien%20nulla,%20mollis%20rutrum%20finibus%20eu,%20lobortis%20sed%20velit.%20Pellentesque%20sem%20risus,%20tempor%20ut%20scelerisque%20sed,%20tempus%20et%20nulla.%20Pellentesque%20a%20viverra%20lacus,%20nec%20imperdiet%20mauris.%20Suspendisse%20lobortis,%20sem%20fermentum%20sollicitudin%20aliquam,%20ligula%20diam%20elementum%20sapien,%20in%20congue%20nunc%20sapien%20ut%20erat.Duis%20eget%20enim%20in%20tellus%20rhoncus%20ornare%20sit%20amet%20sit%20amet%20arcu.%20Vestibulum%20in%20sapien%20eu%20nibh%20ornare%20suscipit.%20Sed%20et%20maximus%20erat,%20sed%20sollicitudin%20sem.%20Quisque%20in%20convallis%20metus,%20eget%20congue%20dui.%20Etiam%20urna%20lectus,%20euismod%20vitae%20est%20id,%20sollicitudin%20commodo%20felis.%20Duis%20commodo%20arcu%20ex,%20a%20fringilla%20dolor%20tristique%20id.%20Donec%20cursus%20dolor%20at%20quam%20posuere,%20in%20dictum%20arcu%20volutpat.%20Nullam%20tincidunt%20vehicula%20neque.%20Pellentesque%20a%20lacus%20pellentesque,%20elementum%20felis%20sed,%20aliquam%20est.%20Nunc%20commodo%20massa%20in%20sapien%20euismod%20imperdiet.Proin%20dignissim%20velit%20eu%20ex%20aliquet,%20id%20lacinia%20mi%20condimentum.%20Mauris%20eu%20urna%20eget%20ante%20vulputate%20scelerisque.%20Donec%20in%20porttitor%20nisl.%20Mauris%20semper,%20nunc%20mattis%20blandit%20convallis,%20risus%20libero%20tristique%20dui,%20nec%20interdum%20nisi%20erat%20et%20turpis.%20Nunc%20sed%20interdum%20orci,%20ut%20tincidunt%20neque.%20Nunc%20bibendum%20et%20eros%20eu%20iaculis.%20Nunc%20accumsan%20ac%20libero%20eu%20malesuada.%20Nulla%20laoreet%20sodales%20ligula,%20sit%20amet%20semper%20enim%20blandit%20et.%20Aenean%20pulvinar%20urna%20varius%20tortor%20rutrum,%20a%20venenatis%20tellus%20fringilla.%20Nullam%20a%20nunc%20in%20nunc%20condimentum%20pellentesque%20eu%20sit%20amet%20felis.%20Fusce%20facilisis%20efficitur%20felis%20sit%20amet%20pulvinar.%20Morbi%20eget%20nunc%20justo.%20Aenean%20et%20nisl%20odio.%20Nulla%20facilisi.%20Nam%20mattis%20mi%20eget%20metus%20aliquet,%20ut%20viverra%20nulla%20fringilla.%20Cras%20aliquam%20urna%20ipsum,%20feugiat%20molestie%20ante%20sagittis%20in."}
--- more_headers
Content-Type: text/json
--- error_code: 200
--- response_body
nil
--- error_log
Request body size larger than client_body_buffer_size, ignoring request body
--- no_error_log
[error]

=== TEST 12: REQUEST_BODY collections variable type (POST request, text/json, too large)
--- config
	location /t {
		client_body_buffer_size 1k;

		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("allowed_content_types", "text/json")
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BODY))
		';
	}
--- request
POST /t
{"foo"="Lorem%20ipsum%20dolor%20sit%20amet,%20consectetur%20adipiscing%20elit.%20Etiam%20tincidunt%20dapibus%20metus,%20in%20blandit%20est%20blandit%20et.%20Morbi%20finibus%20nisl%20id%20arcu%20tincidunt,%20at%20sodales%20neque%20pulvinar.%20Nam%20malesuada%20hendrerit%20scelerisque.%20Quisque%20ut%20diam%20at%20nisl%20finibus%20sollicitudin%20et%20a%20lacus.%20Vestibulum%20accumsan%20dui%20sit%20amet%20tristique%20posuere.%20Nam%20velit%20sapien,%20luctus%20ut%20odio%20non,%20elementum%20tempor%20velit.%20Sed%20lobortis%20elementum%20metus%20non%20iaculis.%20Nam%20vel%20gravida%20justo.%20Donec%20pellentesque%20eleifend%20quam%20et%20suscipit.%20Mauris%20ac%20purus%20et%20mauris%20consequat%20dignissim.%20Donec%20rutrum%20congue%20lorem,%20nec%20faucibus%20velit%20pharetra%20a.%20Proin%20semper%20lorem%20in%20lorem%20rhoncus%20sagittis.%20Nulla%20quis%20lorem%20a%20enim%20mattis%20semper.%20Nunc%20sagittis,%20odio%20eu%20luctus%20condimentum,%20magna%20mauris%20posuere%20ipsum,%20et%20fermentum%20mi%20arcu%20ut%20leo.%20Etiam%20sit%20amet%20tempus%20purus.%20Vestibulum%20urna%20risus,%20posuere%20vel%20bibendum%20vitae,%20gravida%20id%20massa.In%20tincidunt%20lectus%20sodales%20orci%20tempus%20commodo.%20Cum%20sociis%20natoque%20penatibus%20et%20magnis%20dis%20parturient%20montes,%20nascetur%20ridiculus%20mus.%20Morbi%20feugiat%20felis%20diam,%20vel%20pellentesque%20augue%20condimentum%20sagittis.%20Vivamus%20feugiat%20nisi%20ornare,%20dignissim%20ex%20at,%20ullamcorper%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20purus%20justo,%20malesuada%20vel%20fermentum%20id,%20auctor%20condimentum%20lacus.%20Integer%20et%20lorem%20eget%20magna%20bibendum%20aliquam%20nec%20a%20diam.%20Morbi%20volutpat%20mauris%20non%20dictum%20dignissim.%20Nullam%20convallis,%20felis%20et%20sagittis%20pellentesque,%20ex%20eros%20tempor%20tortor,%20vitae%20sagittis%20mauris%20est%20ac%20quam.%20Aliquam%20faucibus%20gravida%20mauris%20ac%20luctus.%20Curabitur%20sagittis%20placerat%20sem,%20eget%20lacinia%20enim.%20Fusce%20quis%20molestie%20risus,%20id%20euismod%20massa.%20Vestibulum%20ante%20ipsum%20primis%20in%20faucibus%20orci%20luctus%20et%20ultrices%20posuere%20cubilia%20Curae%20Morbi%20interdum%20nisl%20metus,%20sit%20amet%20fermentum%20arcu%20venenatis%20ac.Nullam%20placerat,%20quam%20eu%20aliquam%20porttitor,%20ex%20ante%20semper%20velit,%20ac%20gravida%20arcu%20purus%20sit%20amet%20justo.%20Nullam%20molestie%20rutrum%20tortor,%20id%20feugiat%20odio%20gravida%20vitae.%20Vivamus%20lobortis%20massa%20vel%20turpis%20gravida,%20sit%20amet%20pretium%20augue%20dignissim.%20Sed%20ultricies%20nisi%20in%20nisi%20faucibus,%20sed%20commodo%20lacus%20elementum.%20Integer%20convallis%20interdum%20orci%20eu%20maximus.%20Vestibulum%20dictum%20euismod%20massa.%20Aenean%20orci%20massa,%20laoreet%20at%20nisi%20consequat,%20efficitur%20efficitur%20justo.%20Curabitur%20lobortis%20pulvinar%20mauris%20ac%20pulvinar.%20Sed%20nisi%20mi,%20congue%20id%20nulla%20in,%20sodales%20interdum%20sem.%20Duis%20sit%20amet%20accumsan%20libero.%20Pellentesque%20sapien%20nulla,%20mollis%20rutrum%20finibus%20eu,%20lobortis%20sed%20velit.%20Pellentesque%20sem%20risus,%20tempor%20ut%20scelerisque%20sed,%20tempus%20et%20nulla.%20Pellentesque%20a%20viverra%20lacus,%20nec%20imperdiet%20mauris.%20Suspendisse%20lobortis,%20sem%20fermentum%20sollicitudin%20aliquam,%20ligula%20diam%20elementum%20sapien,%20in%20congue%20nunc%20sapien%20ut%20erat.Duis%20eget%20enim%20in%20tellus%20rhoncus%20ornare%20sit%20amet%20sit%20amet%20arcu.%20Vestibulum%20in%20sapien%20eu%20nibh%20ornare%20suscipit.%20Sed%20et%20maximus%20erat,%20sed%20sollicitudin%20sem.%20Quisque%20in%20convallis%20metus,%20eget%20congue%20dui.%20Etiam%20urna%20lectus,%20euismod%20vitae%20est%20id,%20sollicitudin%20commodo%20felis.%20Duis%20commodo%20arcu%20ex,%20a%20fringilla%20dolor%20tristique%20id.%20Donec%20cursus%20dolor%20at%20quam%20posuere,%20in%20dictum%20arcu%20volutpat.%20Nullam%20tincidunt%20vehicula%20neque.%20Pellentesque%20a%20lacus%20pellentesque,%20elementum%20felis%20sed,%20aliquam%20est.%20Nunc%20commodo%20massa%20in%20sapien%20euismod%20imperdiet.Proin%20dignissim%20velit%20eu%20ex%20aliquet,%20id%20lacinia%20mi%20condimentum.%20Mauris%20eu%20urna%20eget%20ante%20vulputate%20scelerisque.%20Donec%20in%20porttitor%20nisl.%20Mauris%20semper,%20nunc%20mattis%20blandit%20convallis,%20risus%20libero%20tristique%20dui,%20nec%20interdum%20nisi%20erat%20et%20turpis.%20Nunc%20sed%20interdum%20orci,%20ut%20tincidunt%20neque.%20Nunc%20bibendum%20et%20eros%20eu%20iaculis.%20Nunc%20accumsan%20ac%20libero%20eu%20malesuada.%20Nulla%20laoreet%20sodales%20ligula,%20sit%20amet%20semper%20enim%20blandit%20et.%20Aenean%20pulvinar%20urna%20varius%20tortor%20rutrum,%20a%20venenatis%20tellus%20fringilla.%20Nullam%20a%20nunc%20in%20nunc%20condimentum%20pellentesque%20eu%20sit%20amet%20felis.%20Fusce%20facilisis%20efficitur%20felis%20sit%20amet%20pulvinar.%20Morbi%20eget%20nunc%20justo.%20Aenean%20et%20nisl%20odio.%20Nulla%20facilisi.%20Nam%20mattis%20mi%20eget%20metus%20aliquet,%20ut%20viverra%20nulla%20fringilla.%20Cras%20aliquam%20urna%20ipsum,%20feugiat%20molestie%20ante%20sagittis%20in."}
--- more_headers
Content-Type: text/json
--- error_code: 200
--- response_body
nil
--- error_log
Request body size larger than client_body_buffer_size, ignoring request body
--- no_error_log
[error]


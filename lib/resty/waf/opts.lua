local _M = {}

local ngx_INFO = ngx.INFO
local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN

_M.version = "0.8"

_M.defaults = {
	_add_ruleset                 = {},
	_add_ruleset_string          = {},
	_allow_unknown_content_types = false,
	_allowed_content_types       = {},
	_debug                       = false,
	_debug_log_level             = ngx_INFO,
	_deny_status                 = ngx_HTTP_FORBIDDEN,
	_event_log_altered_only      = true,
	_event_log_buffer_size       = 4096,
	_event_log_level             = ngx_INFO,
	_event_log_ngx_vars          = {},
	_event_log_periodic_flush    = nil,
	_event_log_request_arguments = false,
	_event_log_request_body      = false,
	_event_log_request_headers   = false,
	_event_log_ssl               = false,
	_event_log_ssl_sni_host      = '',
	_event_log_ssl_verify        = false,
	_event_log_socket_proto      = 'udp',
	_event_log_target            = 'error',
	_event_log_target_host       = '',
	_event_log_target_path       = '',
	_event_log_target_port       = '',
	_event_log_verbosity         = 1,
	_hook_actions                = {},
	_ignore_rule                 = {},
	_ignore_ruleset              = {},
	_mode                        = 'SIMULATE',
	_nameservers                 = {},
	_pcre_flags                  = 'oij',
	_process_multipart_body      = true,
	_req_tid_header              = false,
	_res_body_max_size           = (1024 * 1024),
	_res_body_mime_types         = { ["text/plain"] = true, ["text/html"] = true },
	_res_tid_header              = false,
	_score_threshold             = 5,
	_storage_backend             = 'dict',
	_storage_keepalive           = true,
	_storage_keepalive_pool_size = 100,
	_storage_keepalive_timeout   = 10000,
	_storage_memcached_host      = '127.0.0.1',
	_storage_memcached_port      = 11211,
	_storage_redis_host          = '127.0.0.1',
	_storage_redis_port          = 6379,
	_storage_zone                = nil,
}

return _M

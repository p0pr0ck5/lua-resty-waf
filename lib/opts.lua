local _M = {}

_M.version = "0.7.0"

_M.defaults = {
	_mode                        = "SIMULATE",
	_add_ruleset                 = {},
	_ignore_ruleset              = {},
	_ignore_rule                 = {},
	_allowed_content_types       = {},
	_allow_unknown_content_types = false,
	_debug                       = false,
	_debug_log_level             = ngx.INFO,
	_event_log_level             = ngx.INFO,
	_event_log_verbosity         = 1,
	_event_log_request_arguments = false,
	_event_log_request_headers   = false,
	_event_log_request_body      = false,
	_event_log_ngx_vars          = {},
	_event_log_target            = 'error',
	_event_log_target_host       = '',
	_event_log_target_port       = '',
	_event_log_target_path       = '',
	_event_log_socket_proto      = 'udp',
	_event_log_buffer_size       = 4096,
	_event_log_periodic_flush    = nil,
	_event_log_altered_only      = true,
	_res_body_max_size           = (1024 * 1024),
	_res_body_mime_types         = { ["text/plain"] = true, ["text/html"] = true },
	_process_multipart_body      = true,
	_req_tid_header              = false,
	_res_tid_header              = false,
	_pcre_flags                  = 'oij',
	_score_threshold             = 5,
	_storage_zone                = nil,
}

return _M

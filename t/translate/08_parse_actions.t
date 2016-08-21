use Test::More;

use lib 'tools';
use Modsec2LRW qw(parse_actions);

is_deeply(
	parse_actions('foo'),
	[
		{
			action => 'foo',
		}
	],
	'single standalone action'
);

is_deeply(
	parse_actions('foo, bar'),
	[
		{
			action => 'foo',
		},
		{
			action => 'bar',
		}
	],
	'two standalone actions'
);

is_deeply(
	parse_actions('foo:1'),
	[
		{
			action => 'foo',
			value  => 1,
		}
	],
	'single action expressing a value'
);

is_deeply(
	parse_actions("foo:'bar'"),
	[
		{
			action => 'foo',
			value  => 'bar',
		}
	],
	'single action expressing a quoted value'
);

is_deeply(
	parse_actions("foo:'bar,baz'"),
	[
		{
			action => 'foo',
			value  => 'bar,baz',
		}
	],
	'single action expressing a quoted value with comma'
);

is_deeply(
	parse_actions("foo:'bar:baz'"),
	[
		{
			action => 'foo',
			value  => 'bar:baz',
		}
	],
	'single action expressing a quoted value with colon'
);

is_deeply(
	parse_actions("foo:1,bar"),
	[
		{
			action => 'foo',
			value  => '1',
		},
		{
			action => 'bar',
		}
	],
	'two actions, one expressing a value'
);

is_deeply(
	parse_actions("foo:'baz',bar"),
	[
		{
			action => 'foo',
			value  => 'baz',
		},
		{
			action => 'bar',
		}
	],
	'two actions, one expressing a quoted value'
);

is_deeply(
	parse_actions("foo:'baz,bat',bar"),
	[
		{
			action => 'foo',
			value  => 'baz,bat',
		},
		{
			action => 'bar',
		}
	],
	'two actions, one expressing a quoted value with comma'
);

is_deeply(
	parse_actions("foo:'baz:bat',bar"),
	[
		{
			action => 'foo',
			value  => 'baz:bat',
		},
		{
			action => 'bar',
		}
	],
	'two actions, one expressing a quoted value with colon'
);

is_deeply(
	parse_actions(q(phase:2,rev:'2',ver:'OWASP_CRS/2.2.9',maturity:'8',accuracy:'8',id:'981231',t:none,t:urlDecodeUni,block,msg:'SQL Comment Sequence Detected.',severity:'2',capture,logdata:'Matched Data: %{TX.0} found within %{MATCHED_VAR_NAME}: %{MATCHED_VAR}',tag:'OWASP_CRS/WEB_ATTACK/SQL_INJECTION',tag:'WASCTC/WASC-19',tag:'OWASP_TOP_10/A1',tag:'OWASP_AppSensor/CIE1',tag:'PCI/6.5.2',setvar:tx.anomaly_score=+%{tx.critical_anomaly_score},setvar:tx.sql_injection_score=+1,setvar:'tx.msg=%{rule.msg}',setvar:tx.%{rule.id}-OWASP_CRS/WEB_ATTACK/SQL_INJECTION-%{matched_var_name}=%{tx.0})),
	[
		{
			action => 'phase',
			value  => 2,
		},
		{
			action => 'rev',
			value  => '2',
		},
		{
			action => 'ver',
			value  => 'OWASP_CRS/2.2.9',
		},
		{
			action => 'maturity',
			value  => '8'
		},
		{
			action => 'accuracy',
			value  => '8',
		},
		{
			action => 'id',
			value  => '981231',
		},
		{
			action => 't',
			value  => 'none',
		},
		{
			action => 't',
			value  => 'urlDecodeUni',
		},
		{
			action => 'block',
		},
		{
			action => 'msg',
			value  => 'SQL Comment Sequence Detected.',
		},
		{
			action => 'severity',
			value  => '2',
		},
		{
			action => 'capture',
		},
		{
			action => 'logdata',
			value  => 'Matched Data: %{TX.0} found within %{MATCHED_VAR_NAME}: %{MATCHED_VAR}',
		},
		{
			action => 'tag',
			value  => 'OWASP_CRS/WEB_ATTACK/SQL_INJECTION',
		},
		{
			action => 'tag',
			value  => 'WASCTC/WASC-19',
		},
		{
			action => 'tag',
			value  => 'OWASP_TOP_10/A1',
		},
		{
			action => 'tag',
			value  => 'OWASP_AppSensor/CIE1',
		},
		{
			action => 'tag',
			value  => 'PCI/6.5.2',
		},
		{
			action => 'setvar',
			value  => 'tx.anomaly_score=+%{tx.critical_anomaly_score}'
		},
		{
			action => 'setvar',
			value  => 'tx.sql_injection_score=+1',
		},
		{
			action => 'setvar',
			value  => 'tx.msg=%{rule.msg}'
		},
		{
			action => 'setvar',
			value  => 'tx.%{rule.id}-OWASP_CRS/WEB_ATTACK/SQL_INJECTION-%{matched_var_name}=%{tx.0}',
		},
	],
	'real life example from CRSv2'
);

done_testing;

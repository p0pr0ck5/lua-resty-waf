use Test::More;

use lib 'tools';
use Modsec2LRW qw(figure_phase);

is(
	figure_phase({
		phase => 1,
	}),
	'access',
	'phase determined from phase key (phase 1)'
);

is(
	figure_phase({
		phase => 2,
	}),
	'access',
	'phase determined from phase key (phase 2)'
);

is(
	figure_phase({
		phase => 3,
	}),
	'header_filter',
	'phase determined from phase key (phase 3)'
);

is(
	figure_phase({
		phase => 4,
	}),
	'body_filter',
	'phase determined from phase key (phase 4)'
);

is(
	figure_phase({
		phase => 5,
	}),
	'log',
	'phase determined from phase key (phase 5)'
);

is(
	figure_phase({
		foo => 'bar',
	}),
	'access',
	'phase determined from implicit default'
);

is(
	figure_phase(
		{
			phase => 1,
		},
		{
			phase => 3,
		}
	),
	'access',
	'phase determined only from first element'
);

done_testing;

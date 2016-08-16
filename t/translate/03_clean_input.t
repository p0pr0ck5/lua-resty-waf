use Test::More;

use lib 'tools';
use Modsec2LRW qw(clean_input);

my $basic             = q/SecRule ARGS "foo" "id:12345,pass"/;
my $trim_left         = q/	SecRule ARGS "foo" "id:12345,pass"/;
my $trim_right        = q/SecRule ARGS "foo" "id:12345,pass"	/;
my $trim_both         = q/	SecRule ARGS "foo" "id:12345,pass"	/;
my $ignore_comment    = q/#SecRule ARGS "foo" "id:12345,pass"/;
my $invalid_directive = q/Secrule ARGS "foo" "id:12345,pass"/;
my $multi_line        = q/
SecRule \
	ARGS \
	"foo" \
	"id:12345,pass"
/;
my $multi_line_action = q/
SecRule                 \
	ARGS                \
	"foo"               \
	"id:12345,          \
	phase:1,            \
	block,              \
	setvar:tx.foo=bar,  \
	expirevar:tx.foo=60"
/;

{
	open my $stdin, '<', \ $basic;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'basic'
	);
}

{
	open my $stdin, '<', \ $trim_left;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim left'
	);
}

{
	open my $stdin, '<', \ $trim_right;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim right'
	);
}

{
	open my $stdin, '<', \ $trim_both;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim both'
	);
}

{
	open my $stdin, '<', \ $ignore_comment;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[],
		'comment'
	);
}

{
	open my $stdin, '<', \ $invalid_directive;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[],
		'invalid_directive'
	);
}

{
	open my $stdin, '<', \ $multi_line;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'multi line'
	);
}

{
	my $data = "$basic\n$multi_line\n";
	open my $stdin, '<', \ $data;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[
			q/SecRule ARGS "foo" "id:12345,pass"/,
			q/SecRule ARGS "foo" "id:12345,pass"/,
		],
		'multiple elements'
	);
}

{
	my $data = "$basic\n$comment\n$multi_line";
	open my $stdin, '<', \ $data;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[
			q/SecRule ARGS "foo" "id:12345,pass"/,
			q/SecRule ARGS "foo" "id:12345,pass"/,
		],
		'multi line with comment'
	);
}

{
	open my $stdin, '<', \ $multi_line_action;
	local *STDIN = $stdin;
	my @out = clean_input(*STDIN);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345, phase:1, block, setvar:tx.foo=bar, expirevar:tx.foo=60"/ ],
		'multi line action, each line is joined with a space'
	);
}

done_testing;

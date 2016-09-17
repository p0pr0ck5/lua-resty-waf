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
	my @in  = ($basic);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'basic'
	);
}

{
	my @in  = ($trim_left);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim left'
	);
}

{
	my @in  = ($trim_right);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim right'
	);
}

{
	my @in  = ($trim_both);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'trim both'
	);
}

{
	my @in  = ($ignore_comment);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[],
		'comment'
	);
}

{
	my @in  = ($invalid_directive);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[],
		'invalid_directive'
	);
}

{
	my @in  = (split /\n/, $multi_line);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345,pass"/ ],
		'multi line'
	);
}

{
	my @in  = ($basic, split /\n/, $multi_line);
	my @out = clean_input(@in);
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
	my @in  = ($basic, $comment, split /\n/, $multi_line);
	my @out = clean_input(@in);
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
	my @in  = (split /\n/, $multi_line_action);
	my @out = clean_input(@in);
	is_deeply(
		\@out,
		[ q/SecRule ARGS "foo" "id:12345, phase:1, block, setvar:tx.foo=bar, expirevar:tx.foo=60"/ ],
		'multi line action, each line is joined with a space'
	);
}

done_testing;

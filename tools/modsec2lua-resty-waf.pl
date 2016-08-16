#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling no_ignore_case);
use JSON;

use lib 'tools';
use Modsec2LRW qw(:translate);

sub usage {
	print <<"_EOF";
Usage $0 < <data> [hqspP]
Translate ModSecurity configs to lua-resty-waf rulesets, reading from standard input and writing to standard output.

  -h|--help      Print this help
  -q|--quiet     Be quite when translating (do not print imcompatible chains)
  -s|--silent    Be silent when translating (do not print any information apart from translated rules)
  -p|--path      Provide an optional path to search for *FromFile data files. If not given, the current dir will be used
  -P|--pretty    Pretty-print translated rulesets
  -f|--force     Do not die on failed collection translations

_EOF
	exit 1;
}


sub main {
	my ($path, $quiet, $silent, $pretty, $force);

	GetOptions(
		'q|quiet'  => \$quiet,
		's|silent' => \$silent,
		'p|path=s' => \$path,
		'P|pretty' => \$pretty,
		'f|force'  => \$force,
		'h|help'   => sub { usage(); },
	) or usage();

	# silent implies quiet
	$quiet = 1 if $silent;

	# ModSecurity ruleset parsing
	# clean the input and build an array of tokens
	my @parsed_lines = map { parse_tokens(tokenize($_)) } clean_input(*STDIN);

	# ModSecurity knows where it lives in a chain
	# via pointer arithmetic and internal state handling
	# we need to be a little more obvious about chain
	# definitions for the purposes of translation
	my @modsec_chains = build_chains(@parsed_lines);

	# do the actual translation
	my $lua_resty_waf_chains = translate_chains({
		chains => \@modsec_chains,
		path   => $path,
		quiet  => $quiet,
		silent => $silent,
		force  => $force,
	});

	printf "%s\n",
		to_json(
			$lua_resty_waf_chains,
			{
				pretty    => $pretty ? 1 : 0,
				canonical => 1,
			}
		);
}

main();

#!/usr/bin/perl

use strict;
use warnings;

use Clone qw(clone);
use Getopt::Long qw(:config bundling no_ignore_case);
use JSON;
use List::MoreUtils qw(any none);
use Try::Tiny;

my @valid_directives = qw(SecRule SecAction SecDefaultAction SecMarker);

my $valid_vars = {
	ARGS                    => { type => 'REQUEST_ARGS', parse => { values => 1 } },
	ARGS_GET                => { type => 'URI_ARGS', parse => { values => 1 } },
	ARGS_GET_NAMES          => { type => 'URI_ARGS', parse => { keys => 1 } },
	ARGS_NAMES              => { type => 'REQUEST_ARGS', parse => { keys => 1 } },
	ARGS_POST               => { type => 'REQUEST_BODY', parse => { values => 1 } },
	ARGS_POST_NAMES         => { type => 'REQUEST_BODY', parse => { keys => 1 } },
	MATCHED_VAR             => { type => 'MATCHED_VAR' },
	MATCHED_VARS            => { type => 'MATCHED_VARS' },
	MATCHED_VAR_NAME        => { type => 'MATCHED_VAR_NAME' },
	MATCHED_VAR_NAMES       => { type => 'MATCHED_VAR_NAMES' },
	QUERY_STRING            => { type => 'QUERY_STRING' },
	REMOTE_ADDR             => { type => 'REMOTE_ADDR' },
	REQUEST_BASENAME        => { type => 'REQUEST_BASENAME' },
	REQUEST_BODY            => { type => 'REQUEST_BODY' },
	REQUEST_COOKIES         => { type => 'COOKIES', parse => { values => 1 } },
	REQUEST_COOKIES_NAMES   => { type => 'COOKIES', parse => { keys => 1 } },
	REQUEST_FILENAME        => { type => 'URI' },
	REQUEST_HEADERS         => { type => 'REQUEST_HEADERS', parse => { values => 1 } },
	REQUEST_HEADERS_NAMES   => { type => 'REQUEST_HEADERS', parse => { keys => 1 } },
	REQUEST_LINE            => { type => 'REQUEST_LINE' },
	REQUEST_METHOD          => { type => 'METHOD' },
	REQUEST_PROTOCOL        => { type => 'PROTOCOL' },
	REQUEST_URI             => { type => 'REQUEST_URI' },
	RESPONSE_BODY           => { type => 'RESPONSE_BODY' },
	RESPONSE_CONTENT_LENGTH => { type => 'RESPONSE_HEADERS', parse => { specific => 'Content-Length' } },
	RESPONSE_CONTENT_TYPE   => { type => 'RESPONSE_HEADERS', parse => { specific => 'Content-Type' } },
	RESPONSE_HEADERS        => { type => 'RESPONSE_HEADERS', parse => { values => 1 } },
	RESPONSE_HEADERS_NAMES  => { type => 'RESPONSE_HEADERS', parse => { keys => 1 } },
	RESPONSE_PROTOCOL       => { type => 'PROTOCOL' },
	RESPONSE_STATUS         => { type => 'STATUS' },
	SERVER_NAME             => { type => 'REQUEST_HEADERS', parse => { specific => 'Host' } },
	TIME                    => { type => 'TIME' },
	TIME_DAY                => { type => 'TIME_DAY' },
	TIME_EPOCH              => { type => 'TIME_EPOCH' },
	TIME_HOUR               => { type => 'TIME_HOUR' },
	TIME_MIN                => { type => 'TIME_MIN' },
	TIME_MON                => { type => 'TIME_MON' },
	TIME_SEC                => { type => 'TIME_SEC' },
	TIME_YEAR               => { type => 'TIME_YEAR' },
	TX                      => { type => 'TX', storage => 1 },
	IP                      => { type => 'IP', storage => 1 },
};

my $valid_operators = {
	beginsWith       => sub { my $pattern = shift; return('REGEX', "^$pattern"); },
	contains         => 'STR_CONTAINS',
	containsWord     => sub { my $pattern = shift; return('REGEX', "\b$pattern\b"); },
	detectSQLi       => 'DETECT_SQLI',
	detectXSS        => 'DETECT_XSS',
	endsWith         => sub { my $pattern = shift; return('REGEX', "$pattern\$"); },
	eq               => 'EQUALS',
	ge               => 'GREATER_EQ',
	gt               => 'GREATER',
	ipMatch          => 'CIDR_MATCH',
	ipMatchF         => 'CIDR_MATCH',
	ipMatchFromFile  => 'CIDR_MATCH',
	le               => 'LESS_EQ',
	lt               => 'LESS',
	pm               => 'PM',
	pmf              => 'PM',
	pmFromFile       => 'PM',
	rbl              => 'RBL_LOOKUP',
	rx               => 'REGEX',
	streq            => 'EQUALS',
	strmatch         => 'STR_MATCH',
	within           => 'STR_EXISTS',
};

my $valid_transforms = {
	base64decode       => 'base64_decode',
	base64decodeext    => 'base64_decode',
	base64encode       => 'base64_encode',
	cmdline            => 'cmd_line',
	compresswhitespace => 'compress_whitespace',
	hexdecode          => 'hex_decode',
	hexencode          => 'hex_encode',
	htmlentitydecode   => 'html_decode',
	length             => 'length',
	lowercase          => 'lowercase',
	md5                => 'md5',
	normalisepath      => 'normalise_path',
	removewhitespace   => 'remove_whitespace',
	removecomments     => 'remove_comments',
	removecommentschar => 'remove_comments_char',
	replacecomments    => 'replace_comments',
	sha1               => 'sha1',
	sqlhexdecode       => 'sql_hex_decode',
	trim               => 'trim',
	trimleft           => 'trim_left',
	trimright          => 'trim_right',
	urldecode          => 'uri_decode',
	urldecodeuni       => 'uri_decode',
};

my $action_lookup = {
	allow => 'ACCEPT',
	block => 'DENY',
	deny  => 'DENY',
	pass  => 'IGNORE'
};

my $phase_lookup = {
	1 => 'access',
	2 => 'access',
	3 => 'header_filter',
	4 => 'body_filter',
	5 => 'body_filter', # lua-resty-waf doesnt have a proper logging phase
};

my $op_sep_lookup = {
	PM         => '\s+',
	CIDR_MATCH => ',',
};

my $defaults = {
	action => 'DENY',
	phase  => 'access',
};

my @auto_expand_operators = qw(beginsWith contains endsWith streq within);

my @alters_pattern_operators = qw(beginsWith containsWord endsWith);

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

sub valid_line {
	my ($line) = @_;

	# the directive must be the first element in the line
	# so if this does not match our whitelist we can't process it
	return any { $line =~ m/^$_ / } @valid_directives;
}

sub clean_input {
	my ($fh) = @_;

	my (@lines, @line_buf);

	while (my $line = <$fh>) {
		chomp $line;

		# ignore comments and blank lines
		next if $line =~ m/^\s*$/;
		next if $line =~ m/^\s*#/;

		# trim whitespace
		$line =~ s/^\s*|\s*$//;

		# merge multi-line directives
		# ex.
		#
		# SecRule \
		#   ARGS \
		#   "foo" \
		#   "t:none, \
		#   block, \
		#   phase:1, \
		#   setvar:tx.foo=bar, \
		#   expirevar:tx.foo=60"
		#
		# strip the multi-line ecape and surrounding whitespace
		if ($line =~ s/\s*\\\s*$//) {
			push @line_buf, $line;
		} else {
			# either the end of a multi line directive or a standalone line
			# push the buffer to the return array and clear the buffer
			push @line_buf, $line;

			my $final_line = join ' ', @line_buf;

			push @lines, $final_line if valid_line($final_line);
			@line_buf = ();
		}
	}

	return @lines;
}

# take a line and return an array of tokens representing various rule parts
sub tokenize {
	my ($line) = @_;

	my @tokens;

	# so... this sucks
	# we have to make a few assumptions about our line
	# - tokens are whitespace separated
	# - tokens must be quoted with " if they contain spaces
	# - " chars within quoted tokens must be escaped with \
	my $re_quoted   = qr/^"((?:[^"\\]+|\\.)*)"/;
	my $re_unquoted = qr/([^\s]+)/;

	# walk the given string and grab the next token
	# which may be either quoted or unquoted
	# from there, push the token to our list of fields
	# and strip it from the input line
	while ($line =~ $re_quoted || $line =~ $re_unquoted) {
		my $token = $1;
		push @tokens, $token;
		$line =~ s/"?\Q$token\E"?//;
		$line =~ s/^\s*//;
	}

	return @tokens;
}

# take an array of rule parts and return a hashref of parsed tokens
sub parse_tokens {
	my (@tokens) = @_;

	my ($entry, $directive, $vars, $operator, $opts);
	$entry = {};

	# save this for later debugging / warning
	$entry->{original}  = join ' ', @tokens;

	$directive = shift @tokens;
	if ($directive eq 'SecRule') {
		$vars     = shift @tokens;
		$operator = shift @tokens;
	}
	$opts = shift @tokens;

	die "Uh oh! We shouldn't have any fields left but we still have @tokens\n" if @tokens;

	$entry->{directive} = $directive;
	$entry->{vars}      = parse_vars($vars) if $vars;
	$entry->{operator}  = parse_operator($operator) if $operator;
	$entry->{opts}      = parse_options($opts) if $opts;

	return $entry;
}

sub parse_vars {
	my ($raw_var) = @_;

	my @vars = split '\|', $raw_var;

	my @parsed_vars;

	for my $var (@vars) {
		# variables may take a few forms
		# ! and & are optional metacharacters (mutually exclusive)
		# an optional ':foo' element may also exist
		my ($var, @rest) = split ':', $var;

		my $specific = join ':', @rest;
		my $modifier;

		my $parsed = {};

		# if we see a modifier, strip it from the var
		# and populate its own field
		if ($var =~ m/^[&!]/) {
			$modifier = substr $var, 0, 1, '';
			$parsed->{modifier} = $modifier;
		}

		$parsed->{variable} = $var;
		$parsed->{specific} = $specific;

		push @parsed_vars, $parsed;
	}

	return \@parsed_vars;
}

sub parse_operator {
	my ($raw_operator) = @_;

	# operators may be defined by the @ symbol
	# if one isnt' defined, 'rx' is the default
	# everything following in this token is the pattern
	#
	# using a regex here makes the parser a little more flexible
	# we could split on space, but that breaks if the operator
	# is not single space separated from the pattern, and splitting
	# on \s+ isn't possible because that could break the pattern
	# when joining back together
	#
	# note that some operators (i'm looking at you, libinjection wrapper)
	# do not require a pattern, so we need to account for such cases
	my ($negated, $operator, $pattern) = $raw_operator =~ m/^\s*(?:(\!)?\@([a-zA-Z]+)\s*)?(.*)$/;
	$operator ||= 'rx';

	my $parsed = {};

	$parsed->{negated}  = $negated if $negated;
	$parsed->{operator} = $operator;
	$parsed->{pattern}  = $pattern;

	return $parsed;
}

sub parse_options {
	my ($raw_options) = @_;

	my (@tokens, @parsed_options, @opt_buf, $sentinal);
	my @split_options = split ',', $raw_options;

	# options may take one of a few forms
	# standalone: deny
	# express a value: phase:1
	# express a quoted value: msg:'foo bar'
	#
	# because the quoted value in something like msg or logdata
	# may have commas, we cant simply split on comma
	# so we need to loop through and piece together tokens
	while (@split_options) {
		# take a chunk and add it the buffer array
		# once we know we've reached the end of an
		# option, we'll put the buffer elements
		# back together and add it to the final array
		my $chunk = shift @split_options;
		push @opt_buf, $chunk;

		# we're done chaining together chunks if:
		#
		# - we didnt have the potential to split
		#   meaning that the chunk didnt have a : or '
		#   and that the first member of the buffer
		#   did contain a '
		#
		# OR
		#
		# - we could have split but we know we're done
		# (we know this if the last member of the chunk is a ')
		$sentinal = 1 if (($chunk !~ m/'/ || $chunk !~ m/:/)
			&& ! (scalar @opt_buf > 1 && $opt_buf[0] =~ m/'/))
			|| $chunk =~ m/'$/;

		if ($sentinal) {
			push @tokens, join ',', @opt_buf;
			@opt_buf  = ();
			$sentinal = 0;
		}
	}

	# great, now that we have proper tokens
	# we can split any potential key value pairs
	# and add them to the final array
	for my $token (@tokens) {
		my ($opt, @value) = split /:/, $token;

		# trim whitespace (this is necessary for multi-line rules)
		$opt =~ s/^\s*|\s*$//;

		my $parsed = {};

		$parsed->{opt}   = $opt;
		$parsed->{value} = strip_encap_quotes(join ':', @value) if @value;

		push @parsed_options, $parsed;
	}

	return \@parsed_options;
}

# strip encapsulating single or double quotes from a string
sub strip_encap_quotes {
	my ($line) = @_;

	$line =~ s/^(['"])(.*)\1$/$2/;

	return $line;
}

# take an array of rule hashrefs and return an array of chain hashrefs
sub build_chains {
	my (@rules) = @_;

	my (@chain, @chains);

	for my $rule (@rules) {
		push @chain, $rule;

		# figure if this rule is part of a chain
		next if grep { $_ eq 'chain' } map { $_->{opt} } @{$rule->{opts}};

		# if the chain opt isnt set, we're either a standalone rule
		# or at the end of a chain; either way, push this chain
		# to our array of chains and empty the current chain buffer
		push @chains, [ @chain ];
		@chain = ();
	}

	return @chains;
}

# take an array of ModSecurity chain hashrefs and return a hashref of lua-resty-waf rule hashrefs (including appropriate phases)
sub translate_chains {
	my ($args) = @_;
	my @chains = @{$args->{chains}};
	my $quiet  = $args->{quiet};
	my $silent = $args->{silent};
	my $force  = $args->{force};
	my $path   = $args->{path};

	my $lua_resty_waf_chains = {
		access        => [],
		header_filter => [],
		body_filter   => [],
	};

	for my $chain (@chains) {
		try {
			my @translation = translate_chain({
				chain  => $chain,
				silent => $silent,
				force  => $force,
				path   => $path,
			});

			my $phase = figure_phase(@translation);

			push @{$lua_resty_waf_chains->{$phase}}, @translation;
		} catch {
			warn "$_" if !$silent;
			warn join ("\n", map { $_->{original} } @{$chain} ) . "\n\n" if !$quiet;
		};
	}

	return $lua_resty_waf_chains;
}

# take an array of hashrefs representing modsec rules and return an array of
# hashrefs representing lua-resty-waf rules. if the translation cannot be performed
# due to an imcompatability, die with the incompatible elements
sub translate_chain {
	my ($args) = @_;
	my @chain  = @{$args->{chain}};
	my $silent = $args->{silent};
	my $force  = $args->{force};
	my $path   = $args->{path};

	my (@lua_resty_waf_chain, $chain_id, $chain_opt, $ctr);

	my @end_opts = qw(action skip skip_after);

	for my $rule (@chain) {
		my $translation = {};

		if ($rule->{directive} eq 'SecRule') {
			translate_vars($rule, $translation, $force);
			translate_operator($rule, $translation, $path);
		} elsif ($rule->{directive} =~ m/Sec(?:Action|Marker)/) {
			push @{$translation->{vars}}, { unconditional => 1 };

			# SecMarker is a rule that never matches
			# with its only option representing its ID
			if ($rule->{directive} eq 'SecMarker') {
				$translation->{op_negated} = 1;
				my $marker = pop @{$rule->{opts}};
				$translation->{id} = $marker->{opt};
			}
		}

		translate_options($rule, $translation, $silent);

		# assign the same ID to each rule in the chain
		# it is guaranteed that the first rule in a
		# ModSecurity chain must have a valid, unique ID
		# lua-resty-waf only requires that each rule has an ID,
		# not that each rule's ID must be unique
		$chain_id = $translation->{id} if $translation->{id};
		$translation->{id} = $chain_id if ! $translation->{id};

		# these opts exist in the chain starter in ModSecurity
		# but they belong in the final rule in lua-resty-waf
		for my $opt (@end_opts) {
			$chain_opt->{$opt} = delete $translation->{$opt} if $translation->{$opt};
		}

		# if we've reached the end of the chain, assign our values that
		# had to be pushed from the chain starter, or assign the default
		# if the chain starter didn't specify. otherwise, we're at the start
		# or middle of a chain, so the only thing we know to do is set the CHAIN action
		if (++$ctr == scalar @chain) {
			for my $opt (@end_opts) {
				if ($chain_opt->{$opt}) {
					$translation->{$opt} = $chain_opt->{$opt};
				} elsif ($defaults->{$opt}) {
					$translation->{$opt} = $defaults->{$opt};
				}
			}
		} else {
			$translation->{action} = 'CHAIN';
		}

		push @lua_resty_waf_chain, $translation;
	}

	return @lua_resty_waf_chain;
}

sub translate_vars {
	my ($rule, $translation, $force) = @_;

	# maintain a 1-1 translation of modsec vars to lua-resty-waf vars
	# this necessitates that a lua-resty-waf rule vars key is an array
	for my $var (@{$rule->{vars}}) {
		my $original_var = $var->{variable};
		my $lookup_var   = clone($valid_vars->{$original_var});

		die "Cannot translate variable $original_var" if !$lookup_var && !$force;
		next if !$lookup_var;

		die "Cannot have a specific attribute when the lookup table already provided one"
			if ($var->{specific} && $lookup_var->{parse}->{specific});

		my $translated_var = $lookup_var;
		my $modifier       = $var->{modifier};
		my $specific       = $var->{specific};

		if (defined $modifier && $modifier eq '!') {
			$translated_var->{parse}->{ignore} = $specific;
			delete $translated_var->{parse}->{values};
		} elsif (length $specific) {
			$translated_var->{parse}->{specific} = $specific;
			delete $translated_var->{parse}->{values};
		}

		if (defined $modifier && $modifier eq '&') {
			$translated_var->{length} = 1;
		}

		push @{$translation->{vars}}, $translated_var;
	}

	return;
}

sub translate_operator {
	my ($rule, $translation, $path) = @_;

	my $original_operator   = $rule->{operator}->{operator};
	my $translated_operator = $valid_operators->{$original_operator};

	die "Cannot translate operator $original_operator"
		if !$translated_operator;

	# in some cases its easier to have our translation alter the pattern
	# rather than create separate-but-mostly equal operators
	# in these cases the lookup table gives us a function we can use
	# to get both the operator and the altered pattern
	if (any { $_ eq $original_operator } @alters_pattern_operators) {
		my ($operator, $pattern) = $translated_operator->($rule->{operator}->{pattern});
		$translation->{operator} = $operator;
		$translation->{pattern}  = $pattern;
	} else {
		$translation->{operator} = $translated_operator;
		$translation->{pattern}  = $rule->{operator}->{pattern};
	}

	$translation->{op_negated} = 1 if $rule->{operator}->{negated};

	# force int
	$translation->{pattern} += 0 if $translation->{pattern} =~ m/^\d+$/;

	# this operator reads from a file.
	# read the file and build the pattern table
	# n.b. this regex is very simple, we rely on the
	# fact that no other support operators end with the
	# letter 'f' in order to support this. thanks SpiderLabs.
	# see https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual#pmf
	# and https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual#ipmatchf
	if ($rule->{operator}->{operator} =~ m/[fF]$|FromFile$/) {
		my @buffer;
		my $pattern_file = $rule->{operator}->{pattern};

		$path ||= '.'; # if a path wasn't given, check in the current dir

		open my $fh, '<', "$path/$pattern_file" or die $!;

		# read the FromFile target and build out the pattern based on its contents
		while (my $line = <$fh>) {
			chomp $line;

			# ignore comments and blank lines
			next if $line =~ m/^\s*$/;
			next if $line =~ m/^\s*#/;

			push @buffer, $line;
		}

		close $fh;

		$translation->{pattern} = [ @buffer ];
		return;
	}

	# some operators that behave on split patterns need to be adjusted
	# as lua-resty-waf will expect the pattern as a table
	if (my $special_op = $op_sep_lookup->{$translated_operator}) {
		my @pattern = split /$special_op/, $rule->{operator}->{pattern};
		$translation->{pattern} = \@pattern;
	}

	# automatically expand the rule pattern for certain operators
	if (any { $_ eq $original_operator } @auto_expand_operators) {
		$translation->{opts}->{parsepattern} = 1;
		$translation->{pattern} = translate_macro($translation->{pattern});
	}

	return;
}

sub translate_options {
	my ($rule, $translation, $silent) = @_;

	for my $opt (@{$rule->{opts}}) {
		my $key   = $opt->{opt};
		my $value = $opt->{value};

		# easier to do this than a lookup table
		if (grep { $_ eq $key } qw(allow block deny pass)) {
			$translation->{action} = uc $action_lookup->{$key};
		} elsif ($key eq 'expirevar') {
			my ($var, $time)           = split /=/, $value;
			my ($collection, $element) = split /\./, $var;

			# dont cast as an int if this is a macro
			$time = $time =~ m/^\d+$/ ? $time * 1 : translate_macro($time);

			push @{$translation->{opts}->{expirevar}},
				{ col => $collection, key => $element, time => $time };
		} elsif ($key eq 'id') {
			$translation->{id} = $value;
		} elsif ($key eq 'initcol') {
			my ($col, $val) = split /=/, $value;

			$translation->{opts}->{initcol}->{uc $col} = $val;
		} elsif ($key eq 'logdata') {
			$translation->{logdata} = translate_macro($value);
		} elsif ($key eq 'msg') {
			$translation->{msg} = $value;
		} elsif ($key =~ m/^no(?:audit)?log$/) {
			$translation->{opts}->{nolog} = 1;
		} elsif ($key =~ m/^(?:audit)?log$/) {
			delete $translation->{opts}->{nolog};
		} elsif ($key eq 'phase') {
			$translation->{phase} = $value; # this will be deleted after we figure where the chain will live
		} elsif ($key eq 'skip') {
			$translation->{skip} = $value;
		} elsif ($key eq 'skipAfter') {
			$translation->{skip_after} = $value;
		} elsif ($key eq 'setvar') {
			my ($var, $val)            = split /=/, $value;
			my ($collection, @elements) = split /\./, $var;

			my $element = join '.', @elements;

			# no $val, perhaps a delete?
			if (! defined $val) {
				if ($var =~ m/^\!/) {
					substr $collection, 0, 1, '';

					my $deletevar = { col => $collection, key => $element };
					push @{$translation->{opts}->{deletevar}}, $deletevar;
				} else {
					warn "No assignment in setvar, but not a delete?\n";
				}
				next;
			}

			my $setvar = { col => $collection, key => $element };

			if ($val =~ m/^\+/) {
				substr $val, 0, 1, '';
				$setvar->{inc} = 1;
			}

			$setvar->{value}  = $val;

			push @{$translation->{opts}->{setvar}}, $setvar;
		} elsif ($key eq 't') {
			next if $value eq 'none';

			my $transform = $valid_transforms->{lc $value};

			if (!$transform) {
				warn "Cannot perform transform $value" if !$silent;
				next;
			}

			push @{$translation->{opts}->{transform}}, $transform;
		}
	}

	return;
}

sub figure_phase {
	my ($translation) = @_; # grab only the first element

	# phase must be defined in the first rule of the chain
	my $phase = delete $translation->{phase};

	return $phase && defined $phase_lookup->{$phase} ? $phase_lookup->{$phase} : $defaults->{phase};
}

# because we don't maintain a strict 1-1 mapping of collection names
# we need to fudge the contents of macros. note this is not actually
# performing the expansion (that happens at runtime by the rule engine),
# we're merely updating the string to accomodate lua-resty-waf's lookup table
sub translate_macro {
	my ($string) = @_;

	# grab each macro and replace it with its lookup equivalent
	for my $macro ($string =~ m/%{([^}]+)}/g) {
		my ($key, $specific) = split /\./, $macro;
		my $replacement;

		if (my $lookup = clone($valid_vars->{$key})) {
			$replacement = $lookup->{type};

			$replacement .= ".$lookup->{parse}->{specific}" if $lookup->{parse}->{specific};

			$replacement .= ".$specific" if $specific;
		} else {
			$replacement = $macro;
		}

		$replacement = "%{$replacement}";

		$string =~ s/\Q%{$macro}\E/$replacement/g;
	};

	return $string;
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
	my @parsed_lines  = map { parse_tokens(tokenize($_)) } clean_input(*STDIN);

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

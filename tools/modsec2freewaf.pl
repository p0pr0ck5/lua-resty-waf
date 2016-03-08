#!/usr/bin/perl

use strict;
use warnings;

use Clone qw(clone);
use JSON;
use List::MoreUtils qw(none);
use Try::Tiny;

my @valid_directives = qw(SecRule SecAction SecDefaultAction);

my $valid_vars = {
	ARGS                    => { type => 'REQUEST_ARGS', parse => { values => 1 } },
	ARGS_GET                => { type => 'URI_ARGS', parse => { values => 1 } },
	ARGS_GET_NAMES          => { type => 'URI_ARGS', parse => { keys => 1 } },
	ARGS_NAMES              => { type => 'REQUEST_ARGS', parse => { keys => 1 } },
	ARGS_POST               => { type => 'REQUEST_BODY', parse => { values => 1 } },
	ARGS_POST_NAMES         => { type => 'REQUEST_BODY', parse => { keys => 1 } },
	REMOTE_ADDR             => { type => 'IP' },
	REQUEST_COOKIES         => { type => 'COOKIES', parse => { values => 1 } },
	REQUEST_COOKIES_NAMES   => { type => 'COOKIES', parse => { keys => 1 } },
	REQUEST_FILENAME        => { type => 'URI' },
	REQUEST_HEADERS         => { type => 'REQUEST_HEADERS', parse => { values => 1 } },
	REQUEST_HEADERS_NAMES   => { type => 'REQUEST_HEADERS', parse => { keys => 1 } },
	REQUEST_METHOD          => { type => 'METHOD' },
	REQUEST_URI             => { type => 'URI' },
	RESPONSE_BODY           => { type => 'RESPONSE_BODY' },
	RESPONSE_CONTENT_LENGTH => { type => 'RESPONSE_HEADERS', parse => { specific => 'Content-Length' } },
	RESPONSE_CONTENT_TYPE   => { type => 'RESPONSE_HEADERS', parse => { specific => 'Content-Type' } },
	RESPONSE_HEADERS        => { type => 'RESPONSE_HEADERS', parse => { values => 1 } },
	RESPONSE_HEADERS_NAMES  => { type => 'RESPONSE_HEADERS', parse => { keys => 1 } },
	RESPONSE_STATUS         => { type => 'STATUS' },
	SERVER_NAME             => { type => 'REQUEST_HEADERS', parse => { specific => 'Host' } },
	TX                      => { type => 'TX' },
};

my $valid_operators = {
	contains => 'CONTAINS',
	eq       => 'EQUALS',
	gt       => 'GREATER',
	ipMatch  => "CIDR_MATCH",
	pm       => "PM",
	rx       => 'REGEX',
	streq    => "EQUALS",
	within   => "EXISTS",
};

my $valid_transforms = {
	base64Decode       => 'base64_decode',
	base64DecodeExt    => 'base64_decode',
	base64Encode       => 'base64_encode',
	compressWhitespace => 'compress_whitespace',
	htmlEntityDecode   => 'html_decode',
	lowercase          => 'lowercase',
	removeWhitespace   => 'remove_whitespace',
	replaceComments    => 'replace_comments',
	removeComments     => 'remove_comments',
	urlDecode          => 'uri_decode',
};

my $action_lookup = {
	allow => 'ALLOW',
	block => 'DENY',
	deny  => 'DENY',
	pass  => 'IGNORE'
};

my $phase_lookup = {
	1 => 'access',
	2 => 'access',
	3 => 'header_filter',
	4 => 'body_filter',
	5 => 'body_filter', # FreeWAF doesnt have a proper logging phase
};

my $defaults = {
	action => 'DENY',
	phase  => 'access',
};

sub usage {
	# run the damn thing
	exit 1;
}

sub valid_line {
	my ($line) = @_;

	# the directive must be the first element in the line
	# so if this does not match our whitelist we can't process it
	return if none { $line =~ m/^$_ / } @valid_directives;

	return 1;
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
		if ($line =~ m/\s*\\\s*$/) {
			# strip the multi-line ecape and surrounding whitespace
			$line =~ s/\s*\\\s*$//;

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
	my $re_quoted   = qr/^"(.*?(?<!\\))"/;
	my $re_unquoted = qr/([^ ]+)/;

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

	die "Uh oh! We shouldn't have any fields left but we still have @tokens\n"
		if @tokens;

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
		$parsed->{specific} = $specific if $specific;

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
	$raw_operator =~ m/^\s*(?:(\!)?\@([a-zA-Z]+)\s+)?(.*)$/;

	my ($negated, $operator, $pattern) = $raw_operator =~ m/^\s*(?:(\!)?\@([a-zA-Z]+)\s+)?(.*)$/;
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
		$sentinal = 1 if (($chunk !~ m/'/ || $chunk !~ m/:/) &&
			! (scalar @opt_buf > 1 && $opt_buf[0] =~ m/'/)) ||
			$chunk =~ m/'$/;

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

# take an array of ModSecurity chain hashrefs and return a hashref of FreeWAF rule hashrefs (including appropriate phases)
sub translate_chains {
	my (@chains) = @_;

	my $freewaf_chains = {
		access        => [],
		header_filter => [],
		body_filter   => [],
	};

	for my $chain (@chains) {
		my @rules = @{$chain};

		try {
			my @translation = translate_chain(@rules);
			my $phase       = figure_phase(@translation);

			push @{$freewaf_chains->{$phase}}, [ @translation ];
		} catch {
			warn sprintf "%s\n%s\n",
				join ("\n", map { $_->{original} } @rules),
				$_;
		};
	}

	return $freewaf_chains;
}

# take an array of hashrefs representing modsec rules and return an array of
# hashrefs representing FreeWAF rules. if the translation cannot be performed
# due to an imcompatability, die with the incompatible elements
sub translate_chain {
	my (@chain) = @_;

	my (@freewaf_chain, $chain_action, $ctr);
	#$ctr = 0;

	for my $rule (@chain) {
		my $translation = {};

		translate_vars($rule, $translation);
		translate_operator($rule, $translation);
		translate_options($rule, $translation);

		# grab the action if it was set
		$chain_action = $action_lookup->{$translation->{action}}
			if $translation->{action};

		# if we're the last (or only) rule in the chain,
		# set our action as the chain action
		# otherwise, our action is CHAIN (which is a no-op)
		$translation->{action} = (++$ctr == scalar @chain) ?
			$chain_action ? $chain_action : $defaults->{action} :
			'CHAIN';

		push @freewaf_chain, $translation;
	}

	return @freewaf_chain;
}

sub translate_vars {
	my ($rule, $translation) = @_;

	# maintain a 1-1 translation of modsec vars to FreeWAF vars
	# this necessitates that a FreeWAF rule vars key is an array
	for my $var (@{$rule->{vars}}) {
		my $original_var = $var->{variable};
		my $lookup_var   = clone($valid_vars->{$original_var});

		die "Cannot translate variable $original_var"
			if !$lookup_var;

		die "Cannot have a specific attribute when the lookup table already provided one"
			if ($var->{specific} && $lookup_var->{parse}->{specific});

		my $translated_var = $lookup_var;
		my $modifier       = $var->{modifier};
		my $specific       = $var->{specific};

		if (defined $modifier && $modifier eq '!') {
			$translated_var->{parse}->{ignore} = $specific;
		} elsif ($specific) {
			$translated_var->{parse}->{specific} = $specific;
			delete $translated_var->{parse}->{values};
		}

		if (defined $modifier && $modifier eq '&') {
			$translated_var->{parse}->{length} = 1;
		}

		push @{$translation->{vars}}, $translated_var;
	}

	return;
}

sub translate_operator {
	my ($rule, $translation) = @_;

	my $original_operator   = $rule->{operator}->{operator};
	my $translated_operator = $valid_operators->{$original_operator};

	die "Cannot translate operator $original_operator"
		if !$translated_operator;

	$translation->{operator} = $translated_operator;
	$translation->{negated}  = $rule->{operator}->{negated} if $rule->{operator}->{negated};
	$translation->{pattern}  = $rule->{operator}->{pattern};

	# hack for lua-aho-corasick which needs the pattern as a table
	if ($translated_operator eq 'PM') {
		my @pattern = split /\s+/, $rule->{operator}->{pattern};
		$translation->{pattern} = \@pattern;
	}

	return;
}

sub translate_options {
	my ($rule, $translation) = @_;

	for my $opt (@{$rule->{opts}}) {
		my $key   = $opt->{opt};
		my $value = $opt->{value};

		# easier to do this than a lookup table
		if (grep { $_ eq $key } qw(allow block deny pass)) {
			$translation->{action} = $key;
		} elsif ($key eq 'id') {
			$translation->{id} = $value;
		} elsif ($key eq 'msg') {
			$translation->{description} = $value;
		} elsif ($key eq 'noauditlog') {
			$translation->{opts}->{nolog} = 1;
		} elsif ($key eq 'phase') {
			$translation->{phase} = $value; # this will be deleted after we figure where the chain will live
		} elsif ($key eq 'skip') {
			$translation->{action} = 'SKIP';
			$translation->{opts}->{skip} = $value;
		} elsif ($key eq 't') {
			next if $value eq 'none';

			my $transform = $valid_transforms->{$value};

			if (!$transform) {
				warn "Cannot perform transform $value";
				next;
			}

			push @{$translation->{opts}->{transform}}, $transform;
		}
	}

	return;
}

sub figure_phase {
	my (@translation) = @_;

	# phase must be defined in the first rule of the chain
	my $phase = $translation[0]->{phase};
	delete $translation[0]->{phase};

	return $phase ? $phase_lookup->{$phase} : $defaults->{phase};
}

sub main {
	my $fh = *STDIN;

	my @cleaned_lines  = clean_input($fh);
	my @parsed_lines   = map { parse_tokens(tokenize($_)) } @cleaned_lines;
	my @modsec_chains  = build_chains(@parsed_lines);
	my $freewaf_chains = translate_chains(@modsec_chains);

	print to_json($freewaf_chains, { pretty => 1 });
}

main();

use v6;

use Test;
my $test;

plan $test;


use XML::SAX;
BEGIN { $test += 1 }
ok 1, 'ok';

my @parsed;
class XML::SAX::Test is XML::SAX {
	method start_elem($elem) {
		@parsed.push(['start_elem', $elem]);
	}
	method end_elem($elem) {
		@parsed.push(['end_elem', $elem]);
	}
	method content($elem) {
		@parsed.push(['content', $elem]);
	}
}

{
	BEGIN { $test += 1 }
	my $xml = XML::SAX.new;
	isa_ok $xml, 'XML::SAX';
}

my $xml = XML::SAX::Test.new;
BEGIN { $test += 1 }
isa_ok $xml, 'XML::SAX::Test', 'XML::SAX::Test constructor';

#----------------

{
	BEGIN { $test += 8 }
	reset_all();
	$xml.parse('<chapter>');
	is @parsed.elems, 1, 'one element';
	is @parsed[0][0], 'start_elem', 'start_elem';
	is @parsed[0][1], 'chapter', 'chapter';
	#ok @parsed ~~ ['chapter'], 'parsed chapter';
	#note @parsed.perl;
	#note ;

	{
		$xml.done;
		CATCH {
			default {
				is $_, 'Still in stack: chapter', 'exception still in stack';
			}
		}
	}

	is $xml.string, '', 'string is empty';
	is $xml.stack[0], 'chapter', 'stack is chapter';

	$xml.reset;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
}

#----------------

{
	BEGIN { $test += 3 }
	#@parsed = ();
	reset_all();
	$xml.parse('<chapter>');
	$xml.parse('</chapter>');
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
	my @expected = (
		['start_elem', 'chapter'],
		['end_elem', 'chapter'],
	);
	cmp_deep(@parsed, @expected, "<chapter></chapter>");
}

#----------------

{
	BEGIN { $test += 1 }
	reset_all();
	my $exception;
	{
		$xml.parse('</chapter>');
		CATCH {
			default {
				$exception = $_;
			}
		}
	}
	is $exception, "End element 'chapter' reached while stack was empty", 'exception on single </chapter>';
}
#----------------

{
	BEGIN { $test += 3 }
	reset_all();
	my $exception;

	my $str = '<chapter><page></page></chapter>';
	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
	my @expected = (
		['start_elem', 'chapter'],
		['start_elem', 'page'],
		['end_elem', 'page'],
		['end_elem', 'chapter'],
	);
	cmp_deep(@parsed, @expected, $str);
}

#----------------

{
	BEGIN { $test += 1 }
	reset_all();
	my $exception;

	my $str = '<chapter><page></chapter>';
	{
		$xml.parse($str);
		CATCH {
			default {
				$exception = $_;
			}
		}
	}
	is $exception, "End element 'chapter' reached while in 'page' element", $str;
}

#----------------

{
	BEGIN { $test += 1 }
	reset_all();
	my $exception;

	my $str = '<chapter><page></page></page></chapter>';

	{
		$xml.parse($str);
		CATCH {
			default {
				$exception = $_;
			}
		}
	}
	is $exception, "End element 'page' reached while in 'chapter' element", $str;
}


#----------------

{
	BEGIN { $test += 6 }
	reset_all();

	my $str = '<chapter id="12" name="perl"  ></chapter>';
	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
	my @expected = (
		['start_elem', 'chapter'],
		['end_elem', 'chapter'],
	);
	cmp_deep(@parsed, @expected, $str);
	my $attr = @parsed[0][1].attributes;
	is $attr.elems, 2, "2 attributes";
	is $attr<id>, 12, 'id=12';
	is $attr<name>, 'perl', 'name=perl';
}

#----------------

{
	BEGIN { $test += 3 }
	reset_all();

	my $str = '<chapter> before <para>this is the text</para> after </chapter>';
	diag $str;
	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';

	my @expected = (
		['start_elem', 'chapter'],
		['content',    'chapter', ' before '],
		['start_elem', 'para'],
		['content',    'para', 'this is the text'],
		['end_elem',   'para'],
		['content',    'chapter', ' before ', 'para', ' after '],
		['end_elem',   'chapter'],
	);
	cmp_deep(@parsed, @expected, $str);
	#is @parsed[5][1].content[1].get_content, 'this is the text', 'content of para element';
}

# note "Ex: $exception";
# TODO:
#   parse data given in a file

{
	BEGIN { $test += 3 }
	reset_all();
	my $str = "<a>\n <b></b></a>";
	diag $str;

	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
	is @parsed.elems, 4, '4 elems';
}

{
	BEGIN { $test += 3 }
	reset_all();
	my $str = "<c><a><b></b> </a></c>";
	diag $str;

	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';
	is @parsed.elems, 6, '6 elems';
}

{
	BEGIN { $test += 5 }
	reset_all();
	my $str = qq{<a><b id="23" /></a>};
	diag $str;

	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';
	is $xml.stack.elems, 0, 'stack is empty';

	my @expected = (
		['start_elem', 'a'],
		['start_elem', 'b'],
		['end_elem',   'b'],
		['end_elem',   'a'],
	);
	cmp_deep(@parsed, @expected, $str);

	my $attr = @parsed[1][1].attributes;
	is $attr.elems, 1, "1 attributes";
	is $attr<id>, 23, 'id=23';
}

{
	BEGIN { $test += 2 }
	reset_all();
	my $str = qq{<a> apple <!-- <b id="23" /> --> banana </a>};
	diag $str;

	$xml.parse($str);
	$xml.done;
	is $xml.string, '', 'string is empty';

	my @expected = (
		['start_elem', 'a'],
		['content',    'a', ' apple '],
		['content',    'a', ' apple ', ' banana '],
		['end_elem',   'a'],
	);
	cmp_deep(@parsed, @expected, $str);
}

#{
#	BEGIN { $test += 2 }
#	reset_all();
#	my $str = qq{<p>before <ul><li>item1 <a href="htt://url1">link1</a> text <a href="htt://url2">link2</a> end1</li>};
#	$str   ~= qq{<li><a href="http://url3">link3</a> middle <a href="http://url4">link4</a></li>\n  </ul> after</p>};
#	$xml.parse($str);
#	$xml.done;
#	is $xml.string, '', 'string is empty';
#	my @expected = (
#		['start_elem', 'p'],
#		['content',    'p', 'before '],
#		['start_elem', 'ul'],
#
#		['start_elem', 'li'],
#		['content',    'li', 'item1 '],
#		['start_elem', 'a'], # attribute?
#		['content',    'a', 'link1'],
#		['end_elem',   'a'],
#		['content',    'li', ' text '],
#		['start_elem', 'a'], # attribute?
#		['content',    'a', 'link2 '],
#		['end_elem',   'a'],
#		['content',    'li', ' end1'],
#		['end_elem',   'li'],
#
#		['start_elem', 'li'],
#		['content',    'li', ''],
#		['start_elem', 'a'], # attribute?
#		['content',    'a', 'link3'],
#		['end_elem',   'a'],
#		['content',    'li', ' middle '],
#		['start_elem', 'a'], # attribute?
#		['content',    'a', 'link4 '],
#		['end_elem',   'a'],
#		['content',    'li', ''],
#		['end_elem',   'li'],
#
#		['end_elem',   'ul'],
#		['content',    'p', ' after'],
#		['end_elem',   'p'],
#	);
#	cmp_deep(@parsed, @expected, $str);
#}

{
	BEGIN { $test += 1 }
	reset_all();
	diag 't/files/a.xml';

	XML::SAX::Test.new.parse_file('t/files/a.xml');
	my @expected = (
		['start_elem', 'chapter'                     ],
		['content',    'chapter', " before \n"       ],
		['start_elem', 'para'                        ],
		['content',    'para',   "this is the text\n"],
		['end_elem',   'para'                        ],
		['content',    'chapter', " before \n", 'para', "\n  after\n  "],
		['end_elem',   'chapter'                     ],
	);

	cmp_deep(@parsed, @expected);

	#is @parsed[5][1].content[1].get_content, "this is the text\n", 'content of para element';
}

sub cmp_deep(@real, @expected, $name = '') {

	my $err = '';
	for 0 .. @expected.elems-1 -> $i {
		for 0 .. 1 -> $j {
			if @real[$i][$j] ne @expected[$i][$j] {
				ok 0, $name;
				diag "In row $i column $j.\n  Expected: '{@expected[$i][$j]}'\n  Received: '{@real[$i][$j]}'";
				return False;
			}
		}
		for 2 .. @expected[$i].elems-1 -> $j {
			if @real[$i][1].content[$j-2] ne @expected[$i][$j] {
				ok 0, $name;
				diag "In row $i content $j.\n  Expected: '{@expected[$i][$j]}'\n  Received: '{@real[$i][1].content[$j-2]}'";
				return False;
			}
		}
	}

	if @real.elems != @expected.elems {
		ok 0, $name;
		diag "Number of elements don't match. expected {@expected.elems} received {@real.elems}";
		return False;
	}

	ok 1, $name;
	return True;
}



sub reset_all() {
	@parsed = ();
	$xml.reset;
}
# <a href="http://url">link</a> after-link

# vim: ft=perl6


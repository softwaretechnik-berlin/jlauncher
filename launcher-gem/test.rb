require 'optimist'

parser = Optimist::Parser.new


# parser.ignore_invalid_options = true
parser.stop_on_unknown
parser.version "test 1.2.3 (c) 2008 William Morgan"
parser.banner <<-EOS
Test is an awesome program that does something very, very important.

Usage:
.. test [options] <filenames>+
where [options] are:
EOS
parser.opt :ignore, "Ignore incorrect values"
parser.opt :file, "Extra data filename to read in, with a very long option description like this one", :type => String
parser.opt :volume, "Volume level", :default => 3.0
parser.opt :iters, "Number of iterations", :default => 5
opts = parser.parse(ARGV)

puts opts

puts "Hello"
puts parser.leftovers

Optimist::die :volume, "must be non-negative" if opts[:volume] < 0
Optimist::die :file, "must exist" unless File.exist?(opts[:file]) if opts[:file]



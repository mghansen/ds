###
#
# DSP - dScript Parser
# author: mghansen@gmail.com
#
###

require_relative 'ds_parser'

# Main ============================================================

def dspMain

	if ARGV.size < 1
		puts "Usage: dsp <filename>"
		return
	end
	
	parser = Parser.new
	parser.loadFile("#{ARGV[0]}")
	parser.tokenize()
	parser.parseAll()
	
end

dspMain

=begin
TODO:
	Unary operators ++ --
	Assignment operators += -= etc.
	Arrays and other containers
	break/continue
	constructor params
=end

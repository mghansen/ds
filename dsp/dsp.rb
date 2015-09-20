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
	Arrays and other containers
	new Class
	constructor params
	Nil
	return should be a reserved word but not part of parsing
	break and continue as function calls?
=end

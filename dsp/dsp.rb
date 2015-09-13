###
#
# DSP - dScript Parser
# author: mghansen@gmail.com
#
###

require_relative 'ds_parser'

# Main ============================================================

def dspMain
	
	parser = Parser.new
	parser.loadFile("test.ds")
	parser.tokenizeLines
	parser.showTokens()	
	
end

dspMain

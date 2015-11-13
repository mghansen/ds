###
#
# DSI - dScript Interpreter
# author: mghansen@gmail.com
#
###

require_relative 'ds_loader'
require_relative 'ds_contexts'
require_relative 'ds_instructions'

# Main ============================================================

def dsiMain

	if ARGV.size < 1
		puts "Usage: dsi <filename>"
		return
	end
	
	loader = Loader.new()
	loader.loadFile("#{ARGV[0]}")
	puts "==================================== LOAD COMPLETE ===================================="
	
	context = loader.getGlobalContext
	context.run

end

dsiMain

=begin
TODO:
	Classes
	Class function calls and member variables need to be parsed properly
	[] operators?
	Arrays
	Enums
	Qualified names (for classes)
	Command line parameters (after arrays)
=end
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
	
	context = loader.getGlobalContext
	context.run

end

dsiMain

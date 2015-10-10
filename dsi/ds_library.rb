require_relative "ds_contexts"
require_relative "ds_instructions"

$logForLibrary = true

def logLib text
	puts ("L " + text) if $logForLibrary
end

$libraryFunctions = ["return", "break", "contine", "print" ]

class LibraryCall

	def initialize(name, params)
		logLib "LibraryCall.initialize \"#{name}\""
		@name = name
		@params = params
		@params.each { |p| logLib "  PARAM: #{p.to_s}" }
	end
	
	def getReturnValue
		@returnValue
	end

	def invoke(state)
		case @name
		when "return"
			logLib "LibraryCall handling 'return'"
			if @params.size > 0
				logLib "LibraryCall returning a value"
				state.setReturnValue(@params[0])
				# TODO: Early return
			end
		when "break"
			# TODO: break out of loop (set flag in the state)
		when "continue"
			# TODO: continue to next iteration of loop (set flag in the state)
		when "print"
			s = ""
			@params.each { |p| s << p.to_s }
			# TODO: escape sequences
			puts s
		else
			logLib "not recognized"
		end
	end

end
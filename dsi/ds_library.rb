require_relative "ds_contexts"
require_relative "ds_instructions"

$logForLibrary = true

def logLib text
	puts ("L " + text) if $logForLibrary
end

$libraryFunctions = ["return", "break", "continue", "print" ]

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
			end
			state.returnFlag = true
		when "break"
			logLib "LibraryCall handling 'break'"
			state.setBreak(true)
		when "continue"
			logLib "LibraryCall handling 'continue'"
			state.setContinue(true)
		when "print"
			s = ""
			@params.each { |p| s << p.to_s }
			# TODO: escape sequences
			puts "===> " << s
		else
			logLib "not recognized"
		end
	end

end
# DSObject ####################################################################################################

class DSNode

	def initialize()
		@references = 1
	end
	
	def addref()
		@references += 1
	end
	
	def release()
		@references -= 1
	end
	
	def parse(parserState)
		cur = parserState.currentIndex
		parserState.consume(1)
		object = nil
		return object
	end
	
	def translate()
	end

end

# DSStatement ####################################################################################################

class DSAlphaNumeric < DSNode
	def initialize()
		super()
	end
	
	def parse(parserState)
		# static, generate object and advance index
	end
end

# DSStatement ####################################################################################################

class DSStatement < DSNode
	def initialize()
		super
	end

	def release()
		# Notify instance objects
		super
	end
	
end

# DSDeclaration ####################################################################################################

class DSDeclaration < DSStatement
	def initialize()
		super()
	end
end

# DSUse ####################################################################################################

class DSUse < DSDeclaration
	def initialize()
		super(:use)
	end
end

# DSAssignment ####################################################################################################

class DSAssignment < DSStatement
	def initialize()
		super()
	end
end

# DSFunctionCall ####################################################################################################

class DSFunctionCall < DSStatement
	def initialize()
		super()
	end
end

# DSControl ####################################################################################################

class DSControl < DSStatement
	def initialize()
		super()
	end
end

# DSComment ####################################################################################################

class DSComment < DSStatement
	def initialize()
		super()
	end
end

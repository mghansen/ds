# DsiContext ####################################################################################################

class DsiContext
end

class DsiItem < DsiContext
end

class DsiGlobalContext < DsiContext
	# Allowed in the global context are use, variable declaration, enum declaration, class declaration, function declaration
	def initialize
		@uses = Array.new
		@vars = Array.new
		@enums = Array.new
		@classes = Array.new
		@functions = Array.new
	end
end

class DsiClassContext < DsiContext
	def initialize(name, baseClass)
		@name = name
		@baseClass = baseClass
		@vars = Array.new
		@functionContexts = Array.new
	end
	
	def addVar(name)
		@vars.push(name)
	end
	
	def addFunction(functionContext)
		@functionContexts.push(functionContext)
	end
end

class DsiFunctionContext < DsiContext
	def initialize
		@vars = Array.new
		@instructions = Array.new
	end
end

# DsiEnum ####################################################################################################

class DsiUse < DsiItem
	def initialize(filename)
		@filename = filename
	end
end


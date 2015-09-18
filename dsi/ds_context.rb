require 'set'

# DsiContext ####################################################################################################

class DsiContext
	def initialize
		@valid = true
	end
	
	def isValid
		@valid
	end
	
	def invalidate
		@valid = false
	end
end

# DsiGlobalContext ####################################################################################################

class DsiGlobalContext < DsiContext
	# Allowed in the global context are use, variable declaration, enum declaration, class declaration, function declaration
	def initialize
		@uses = Set.new
		@vars = Set.new
		@enums = Array.new
		@classes = Array.new
		@functionContexts = Array.new
	end
	
	def getClassContexts
		@classes
	end
	
	def getFunctionContexts
		@functionContexts
	end

	def addUse(name)
		@uses.add(name)
	end
	
	def addVar(name)
		@vars.add(name)
	end
	
	def addEnum(name, values)
		enum = DsiEnum.new(name, values)
		@enums.each do |e|
			if e.getName.eql?(name)
				return
			end
		end
		@enums.add(enum)
	end
	
	def addClass(classContext)
		@classes.each do |c|
			if c.getName.eql?(classContext.getName)
				return
			end
		end
		@classes.push(classContext)
	end

	def addFunction(functionContext)
		@functionContexts.each do |f|
			if f.getName.eql?(functionContext.getName)
				return
			end
		end
		@functionContexts.push(functionContext)
	end
end

# DsiClassContext ####################################################################################################

class DsiClassContext < DsiContext
	def initialize(name, baseClass)
		@name = name
		@baseClass = baseClass
		@vars = Set.new
		@functionContexts = Array.new
	end
	
	def getName
		@name
	end
	
	def addVar(name)
		@vars.add(name)
	end
	
	def addFunction(functionContext)
		# TODO: Qualify incoming names (classname.functionname)
		@functionContexts.each do |f|
			if f.getName.eql?(functionContext.getName)
				return
			end
		end
		@functionContexts.push(functionContext)
	end
end	

# DsiFunctionContext ####################################################################################################

class DsiFunctionContext < DsiContext
	def initialize(name, params)
		@name = name
		@params = params # names, not expressions
		@vars = Set.new
		@instructions = nil	
	end

	def getName
		@name
	end
	
	def addVar(var)
		@vars.add(var)
	end
	
	def setInstructions(instructions)
		@instructions = instructions
	end
end

# DsiItem ####################################################################################################

class DsiItem < DsiContext
end

class DsiEnum < DsiItem
	def initialize(name, values)
		@name = name
		@value = values
	end
	
	def getName
		@name
	end
	
	def getValues
		@values
	end
		
end

# DsiInstruction ####################################################################################################

class DsiInstruction
	def initialize
	end
end

class DsiControl < DsiInstruction
end

class DsiAction < DsiInstruction
	def initialize
	end
	def evaluate(state)
		nil
	end
	
end

class DsiAssignment < DsiAction
	def initizlize(lValue, operator, rValue)
		@lValue = lValue
		@operator = operator
		@rValue = rValue
	end
	def evaluate(state)
		rValue = @rValue.evaluate
		# Find the variable in lValue and make the assignment
	end
end

class DsiFunctionCall < DsiAction
	def initialize(name, params)
		@name = name
		@params = params # expressions, not names
	end
	def evaluate(state)
		# Set up internal state of the function, including named params
		# Loop through instructions
	end
end

class DsiOperation < DsiAction
	def initizlize(lValue, operator, rValue)
		@lValue = lValue
		@operator = operator
		@rValue = rValue
	end
	def evaluate(state)
		lValue = @lValue.evaluate
		rValue = @rValue.evaluate
		# Switch on operator
	end
def





class DsiVariable
	# This is more of a runtime object and shouldn't go here with the contexts
	# number, string, bool, enum, object, function, or Nil
end

# Expression can be:
#	Value: (Number, String, Bool, Enum, Nil)
#	Variable: (Value + Object, Function)
#	Function calls (not built-in)
#	Operation

	
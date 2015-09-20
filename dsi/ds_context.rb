require 'set'

$verboseContext = true

def debugContext text
	puts text if $verboseContext
end

# DsiContext ####################################################################################################

class DsiContext
	def initialize(name)
		debugContext "DsiContext #{name}"
		@valid = true
		@name = name
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
		debugContext "DsiGlobalContext"
		super("0_GLOBAL_CONTEXT")
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
	def initialize(name, baseClass, vars, functionContexts)
		debugContext "DsiClassContext #{name} #{baseClass}"
		super(name)
		@baseClass = baseClass
		@vars = vars
		@functionContexts = functionContexts
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
	def initialize(name, paramNames, vars, instructions)
		debugContext "DsiFunctionContext #{name}"
		super(name) # TODO: Scope
		@paramNames = paramNames
		@vars = vars
		@instructions = instructions
	end

	def getName
		@name
	end
	
	def setInstructions(instructions)
		@instructions = instructions
	end
end

# DsiInstruction ####################################################################################################

class DsiInstruction
	def initialize
		debugContext "DsiInstruction"
	end
	def evaluate(state)
		nil
	end
end

class DsiUse < DsiInstruction
	def initialize(filename)
		debugContext "DsiUse #{filename}"
		super()
		filename = @filename
	end
end

class DsiAssignment < DsiInstruction
	def initizlize(lValue, operator, rValue)
		debugContext "DsiAssignment #{lValue} #{operator}"
		super()
		@lValue = lValue
		@operator = operator
		@rValue = rValue
	end
	def evaluate(state)
		rValue = @rValue.evaluate
		# Find the variable in lValue and make the assignment
	end
end

# TODO: Control instructions

class DsiIf < DsiInstruction
	def initialize(conditions)
		debugContext "DsiIf"
		super()
		@conditions = conditions
	end
end

class DsiCondition < DsiInstruction
	def initialize(conditionType, expression, statemets)
		debugContext "DsiCondition #{conditionType}"
		super()
		@conditionType = conditionType
		@expression = expression
		@statements = statements
	end
end

class DsiForIn < DsiInstruction
	def initialize(variant, set, statements)
		debugContext "DsiForIn #{variant} in #{set}"
		super()
		@variant = variant
		@set = set
		@statements = statements
	end
end

class DsiForFrom < DsiInstruction
	def initialize(variant, startExpression, endExpression, statements)
		debugContext "DsiForFrom #{variant}"
		super()
		@variant = variant
		@startExpression = startExpression
		@endExpression = endExpression
		@statements = statement
	end
end

class DsiWhile < DsiInstruction
	def initialize(expression, statements)
		debugContext "DsiWhile"
		super()
		@expression = expression
		@statements = statements
	end
end

class DsiDo
	def initialize(statements, expression)
		debugContext "DsiDo"
		super()
		@statements = statements
		@expression = expression
	end
end

class DsiSwitch
	def initialize(expression, cases)
		debugContext "DsiSwitch"
		super()
		@expression = expression
		@cases = cases
	end
end
	
class DsiCase
	def initialize(expression, statements)
		debugContext "DsiCase"
		super()
		@expression = expression
		@statements = statements
	end
end

# DsiExpression ####################################################################################################

class DsiExpression < DsiInstruction
	def initialize
		debugContext "DsiExpression"
		super
	end
	def evaluate(state)
	end
end

class DsiOperation < DsiExpression
	def initialize(leftExpression, operator, rightExpression)
		debugContext "DsiOperation #{operator}"
		super()
		@leftExpression = leftExpression
		@operator = operator
		@rightExpression = rightExpression
	end
end

class DsiFunctionCall < DsiExpression
	def initialize(name, paramExpressions)
		debugContext "DsiFunctionCall #{name}"
		super()
		@name = name
		@paramExpressions = paramExpressions
	end
	def evaluate(state)
		# Set up internal state of the function, including named params
		# Loop through instructions
	end
end

class DsiValue < DsiExpression
	# Can be number, string, bool, enum, functionCall, array, or var
	# Part of state
	def initialize(value)
		debugContext "DsiValue"
		super()
		@value = value
	end
end	

class DsiNumberValue < DsiValue
	def initialize(value)
		debugContext "DsiNumberValue #{value}"
		super
	end
end

class DsiStringValue < DsiValue
	def initialize(value)
		debugContext "DsiStringValue #{value}"
		super
	end
end

class DsiBoolValue < DsiValue
	def initialize(value)
		debugContext "DsiBoolValue #{value}"
		super
	end
end

class DsiEnumValue < DsiValue
	def initialize(value)
		debugContext "DsiEnumValue #{value}"
		super
	end
end

class DsiFunctionReferenceValue < DsiValue
	# ~function pointer
	def initialize(value)
		debugContext "DsiFunctionReferenceValue"
		super
	end
end

class DsiArray < DsiValue
	def initialize(value)
		debugContext "DsiArray"
		super
	end
end

# DsiContextVariable ####################################################################################################

class DsiContextVariable
	def initialize(name, value)
		debugContext "DsiContextVariable #{name}"
		@name = name
		@value = value
	end
end

class DsiContextVariableList
	def initialize(constants, variables)
		debugContext "DsiContextVariableList"
		@constants = constants
		@variables = variables
	end
end

class DsiVariable < DsiExpression
	def initialize(name)
		debugContext "DsiVariable #{name}"
		super()
		@name = name
	end
	def getName
		@name
	end
end

class DsiConstantVariable < DsiVariable
	# Value is loaded from constant each time the context loads
	def initialize(name, value)
		debugContext "DsiConstantVariable #{name}"
		super(name)
		@value = value
	end
	def getValue
		@value
	end
end


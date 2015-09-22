$verboseRuntime = true

def debugRuntime text
	puts text if $verboseRuntime
end

# DsiInstruction ####################################################################################################

class DsiInstruction
	def initialize
		debugRuntime "DsiInstruction"
	end
	def evaluate(state)
		nil
	end
end

# Instructions ####################################################################################################

class DsiAssignment < DsiInstruction
	def initialize(lValue, operator, rValue)
		debugRuntime "DsiAssignment #{lValue} #{operator}"	
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

# Control Instructions ####################################################################################################

class DsiIf < DsiInstruction
	def initialize(conditions)
		debugRuntime "DsiIf"
		super()
		@conditions = conditions
	end
end

class DsiCondition < DsiInstruction
	def initialize(conditionType, expression, statemets)
		debugRuntime "DsiCondition #{conditionType}"
		super()
		@conditionType = conditionType
		@expression = expression
		@statements = statements
	end
end

class DsiForIn < DsiInstruction
	def initialize(variant, set, statements)
		debugRuntime "DsiForIn #{variant} in #{set}"
		super()
		@variant = variant
		@set = set
		@statements = statements
	end
end

class DsiForFrom < DsiInstruction
	def initialize(variant, startExpression, endExpression, statements)
		debugRuntime "DsiForFrom #{variant}"
		super()
		@variant = variant
		@startExpression = startExpression
		@endExpression = endExpression
		@statements = statement
	end
end

class DsiWhile < DsiInstruction
	def initialize(expression, statements)
		debugRuntime "DsiWhile"
		super()
		@expression = expression
		@statements = statements
	end
end

class DsiDo < DsiInstruction
	def initialize(statements, expression)
		debugRuntime "DsiDo"
		super()
		@statements = statements
		@expression = expression
	end
end

class DsiSwitch < DsiInstruction
	def initialize(expression, cases)
		debugRuntime "DsiSwitch"
		super()
		@expression = expression
		@cases = cases
	end
end
	
class DsiCase
	def initialize(expression, statements)
		debugRuntime "DsiCase"
		super()
		@expression = expression
		@statements = statements
	end
end

# DsiExpression ####################################################################################################

class DsiExpression < DsiInstruction
	def initialize
		debugRuntime "DsiExpression"
		super()
	end
	def evaluate(state)
	end
end

class DsiOperation < DsiExpression
	def initialize(leftExpression, operator, rightExpression)
		debugRuntime "DsiOperation #{operator}"
		super()
		@leftExpression = leftExpression
		@operator = operator
		@rightExpression = rightExpression
	end
end

class DsiFunctionCall < DsiExpression
	def initialize(name, paramExpressions)
		debugRuntime "DsiFunctionCall #{name}"
		super()
		@name = name
		@paramExpressions = paramExpressions
	end
	def evaluate(state)
		# Set up internal state of the function, including named params
		# Loop through instructions
	end
end

# DsiValue (runtime objects) ####################################################################################################

class DsiValue < DsiExpression
	# Can be number, string, bool, enum, functionCall, array, or var
	# Part of state
	def initialize(value)
		debugRuntime "DsiValue"
		super()
		@value = value
	end
end	

class DsiNumberValue < DsiValue
	def initialize(value)
		debugRuntime "DsiNumberValue #{value}"
		super
	end
end

class DsiStringValue < DsiValue
	def initialize(value)
		debugRuntime "DsiStringValue #{value}"
		super
	end
end

class DsiBoolValue < DsiValue
	def initialize(value)
		debugRuntime "DsiBoolValue #{value}"
		super
	end
end

class DsiEnumValue < DsiValue
	def initialize(value)
		debugRuntime "DsiEnumValue #{value}"
		super
	end
end

class DsiFunctionReferenceValue < DsiValue
	# ~function pointer
	def initialize(value)
		debugRuntime "DsiFunctionReferenceValue"
		super
	end
end

# TODO: Array is a reserved class
#class DsiArray < DsiValue
#	def initialize(value)
#		debugRuntime "DsiArray"
#		super
#	end
#end

class DsiClassValue < DsiValue
	def initialize(value)
		debugRuntime "DsiClassValue"
	end
end

class DsiVariable < DsiExpression
	def initialize(name, value = nil)
		debugRuntime "DsiVariable #{name}"
		super()
		@name = name
		@value = value
	end
	def getName
		@name
	end
	def getValue
		@value
	end
end

class DsiConstantVariable < DsiVariable
	# Value is loaded from constant each time the template loads
	def initialize(name, value)
		debugRuntime "DsiConstantVariable #{name}"
		super(name, value)
	end
end

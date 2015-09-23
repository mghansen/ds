#require_relative "ds_contexts"
require_relative "ds_templates"

$verboseInstructions = true

def debugInstructions text
	puts text if $verboseInstructions
end

# DsiInstruction ####################################################################################################

class DsiInstruction
	def initialize
		debugInstructions "DsiInstruction"
	end
	def evaluate(state)
	end
end

# Instructions ####################################################################################################

class DsiAssignment < DsiInstruction
	def initialize(lValue, operator, rValue)
		debugInstructions "DsiAssignment #{lValue} #{operator}"	
		super()
		@lValue = lValue
		@operator = operator # "=", "+=", "-=", "*=", "/="
		@rValue = rValue
	end
	def evaluate(state)
		debugInstructions "DsiAssignment.evaluate #{@lValue} #{@operator}"
		ret = nil
		# Find the variable in lValue and make the assignment
		lValue = state.getVariable(@lValue)
		
		if not lValue == nil
			debugInstructions "DsiAssignment.evaluate #{lValue.getName}"
			rValue = @rValue.evaluate(state)

			case @operator
			when "="
				lValue.setValue(rValue)
			when "+="
			when "-="
			when "*="
			when "/="
			else
			end

		end
		debugInstructions "DsiAssignment.evaluate end"
	end
end

# Control Instructions ####################################################################################################

class DsiIf < DsiInstruction
	def initialize(conditions)
		debugInstructions "DsiIf"
		super()
		@conditions = conditions
	end
end

class DsiCondition < DsiInstruction
	def initialize(conditionType, expression, statemets)
		debugInstructions "DsiCondition #{conditionType}"
		super()
		@conditionType = conditionType
		@expression = expression
		@statements = statements
	end
end

class DsiForIn < DsiInstruction
	def initialize(variant, set, statements)
		debugInstructions "DsiForIn #{variant} in #{set}"
		super()
		@variant = variant
		@set = set
		@statements = statements
	end
end

class DsiForFrom < DsiInstruction
	def initialize(variant, startExpression, endExpression, statements)
		debugInstructions "DsiForFrom #{variant}"
		super()
		@variant = variant
		@startExpression = startExpression
		@endExpression = endExpression
		@statements = statement
	end
end

class DsiWhile < DsiInstruction
	def initialize(expression, statements)
		debugInstructions "DsiWhile"
		super()
		@expression = expression
		@statements = statements
	end
end

class DsiDo < DsiInstruction
	def initialize(statements, expression)
		debugInstructions "DsiDo"
		super()
		@statements = statements
		@expression = expression
	end
end

class DsiSwitch < DsiInstruction
	def initialize(expression, cases)
		debugInstructions "DsiSwitch"
		super()
		@expression = expression
		@cases = cases
	end
end
	
class DsiCase
	def initialize(expression, statements)
		debugInstructions "DsiCase"
		super()
		@expression = expression
		@statements = statements
	end
end

# DsiExpression ####################################################################################################

class DsiExpression < DsiInstruction
	def initialize
		debugInstructions "DsiExpression"
		super()
	end
end

class DsiOperation < DsiExpression
	def initialize(leftExpression, operator, rightExpression)
		debugInstructions "DsiOperation #{operator}"
		super()
		@leftExpression = leftExpression
		@operator = operator
		@rightExpression = rightExpression
	end
end

class DsiFunctionCall < DsiExpression
	def initialize(name, paramExpressions)
		debugInstructions "DsiFunctionCall #{name}"
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

# TODO: Reference count (for garbage collection)

class DsiValue < DsiExpression
	# Can be number, string, bool, enum, functionCall, array, or var
	# Part of state
	def initialize(value)
		debugInstructions "DsiValue"
		super()
		@value = value
	end
	def getValue
		@value
	end
end	

class DsiNumberValue < DsiValue
	def initialize(value)
		debugInstructions "DsiNumberValue #{value}"
		super
	end
end

class DsiStringValue < DsiValue
	def initialize(value)
		debugInstructions "DsiStringValue #{value}"
		super
	end
end

class DsiBoolValue < DsiValue
	def initialize(value)
		debugInstructions "DsiBoolValue #{value}"
		super
	end
end

class DsiEnumValue < DsiValue
	def initialize(value)
		debugInstructions "DsiEnumValue #{value}"
		super
	end
end

class DsiFunctionReferenceValue < DsiValue
	# ~function pointer
	def initialize(value)
		debugInstructions "DsiFunctionReferenceValue"
		super
	end
end

# TODO: Array is a reserved class
#class DsiArray < DsiValue
#	def initialize(value)
#		debugInstructions "DsiArray"
#		super
#	end
#end

class DsiClassValue < DsiValue
	def initialize(value)
		debugInstructions "DsiClassValue"
	end
end

class DsiVariable < DsiExpression
	def initialize(name, value = nil)
		debugInstructions "DsiVariable #{name}"
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
		debugInstructions "DsiConstantVariable #{name}"
		super(name, value)
	end
end

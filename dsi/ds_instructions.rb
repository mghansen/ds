require_relative "ds_contexts"

$logForInstructions = true

def logInstructions text
	puts ("I " + text) if $logForInstructions
end

# DsiInstruction ####################################################################################################

class DsiInstruction
	def initialize
		logInstructions "DsiInstruction"
	end
	def evaluate(state)
		logInstructions "DsiInstruction.evaluate"
	end
end

# Instructions ####################################################################################################

class DsiAssignment < DsiInstruction
	def initialize(lValue, operator, rValue)
		logInstructions "DsiAssignment.initialize #{lValue} #{operator}"	
		super()
		@lValue = lValue
		@operator = operator # "=", "+=", "-=", "*=", "/="
		@rValue = rValue
		logInstructions "DsiAssignment.initialize rValue #{@rValue.to_s}"	
	end
	def evaluate(state)
		logInstructions "DsiAssignment.evaluate #{@lValue} #{@operator}"
		ret = nil
		# Find the variable in lValue and make the assignment
		lValue = state.getVariable(@lValue)
		
		if not lValue == nil
			logInstructions "DsiAssignment.evaluate #{lValue.getName}"
			logInstructions @rValue.to_s
			rValue = @rValue.evaluate(state)
			logInstructions "DsiAssignment.evaluate rValue #{rValue.getValue}"

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
		logInstructions "DsiAssignment.evaluate end"
	end
end

# Control Instructions ####################################################################################################

class DsiIf < DsiInstruction
	def initialize(conditions)
		logInstructions "DsiIf"
		super()
		@conditions = conditions
	end
end

class DsiCondition < DsiInstruction
	def initialize(conditionType, expression, statemets)
		logInstructions "DsiCondition #{conditionType}"
		super()
		@conditionType = conditionType
		@expression = expression
		@statements = statements
	end
end

class DsiForIn < DsiInstruction
	def initialize(variant, set, statements)
		logInstructions "DsiForIn #{variant} in #{set}"
		super()
		@variant = variant
		@set = set
		@statements = statements
	end
end

class DsiForFrom < DsiInstruction
	def initialize(variant, startExpression, endExpression, statements)
		logInstructions "DsiForFrom #{variant}"
		super()
		@variant = variant
		@startExpression = startExpression
		@endExpression = endExpression
		@statements = statement
	end
end

class DsiWhile < DsiInstruction
	def initialize(expression, statements)
		logInstructions "DsiWhile"
		super()
		@expression = expression
		@statements = statements
	end
end

class DsiDo < DsiInstruction
	def initialize(statements, expression)
		logInstructions "DsiDo"
		super()
		@statements = statements
		@expression = expression
	end
end

class DsiSwitch < DsiInstruction
	def initialize(expression, cases)
		logInstructions "DsiSwitch"
		super()
		@expression = expression
		@cases = cases
	end
end
	
class DsiCase
	def initialize(expression, statements)
		logInstructions "DsiCase"
		super()
		@expression = expression
		@statements = statements
	end
end

# DsiExpression ####################################################################################################

class DsiExpression < DsiInstruction
	def initialize
		logInstructions "DsiExpression"
		super()
	end
	def evaluate(state)
		logInstructions "DsiFunctionCall.evauate"
		super
	end
end

class DsiOperation < DsiExpression
	def initialize(leftExpression, operator, rightExpression)
		logInstructions "DsiOperation #{operator}"
		super()
		@leftExpression = leftExpression
		@operator = operator
		@rightExpression = rightExpression
	end
	def evaluate(state)
		logInstructions "DsiFunctionCall.evauate"
		super
	end
end

class DsiFunctionCall < DsiExpression
	def initialize(name, paramExpressions)
		logInstructions "DsiFunctionCall #{name}"
		super()
		@name = name
		@paramExpressions = paramExpressions
	end
	def evaluate(state)
		logInstructions "DsiFunctionCall.evauate"
		# Set up internal state of the function, including named params
		# Loop through instructions
		super
	end
end

# DsiValue (runtime objects) ####################################################################################################

# TODO: Reference count (for garbage collection)

class DsiValue < DsiExpression
	# Can be number, string, bool, enum, functionCall, array, or var
	# Part of state
	def initialize(value)
		logInstructions "DsiValue"
		super()
		@value = value
	end
	def getValue
		@value
	end
	def to_s
		@value.to_s
	end
	def evaluate(state)
		logInstructions "DsiValue.evaluate #{@value}"
		DsiValue.new(@value)
	end
	def to_s
		"#{@value.to_s}"
	end
end	

class DsiNumberValue < DsiValue
	def initialize(value)
		logInstructions "DsiNumberValue #{value}"
		super
	end
	def evaluate(state)
		logInstructions "DsiNumberValue.evaluate #{@value}"
		super
	end
	def to_s
		"#{@value.to_s}"
	end
end

class DsiStringValue < DsiValue
	def initialize(value)
		logInstructions "DsiStringValue #{value}"
		super
	end
	def evaluate(state)
		logInstructions "DsiStringValue.evaluate #{@value}"
		super
	end
	def to_s
		"'#{@value.to_s}'"
	end
end

class DsiBoolValue < DsiValue
	def initialize(value)
		logInstructions "DsiBoolValue #{value}"
		super
	end
	def evaluate(state)
		logInstructions "DsiBoolValue.evaluate #{@value}"
		super
	end
	def to_s
		@value ? "TRUE" : "FALSE"
	end
end

class DsiEnumValue < DsiValue
	def initialize(value)
		logInstructions "DsiEnumValue #{value}"
		super
	end
	def evaluate(state)
		logInstructions "DsiEnumValue.evaluate #{@value}"
		super
	end
end

class DsiFunctionReferenceValue < DsiValue
	# ~function pointer
	def initialize(value)
		logInstructions "DsiFunctionReferenceValue"
		super
	end
end

# TODO: Array is a reserved class
#class DsiArray < DsiValue
#	def initialize(value)
#		logInstructions "DsiArray"
#		super
#	end
#end

class DsiClassValue < DsiValue
	def initialize(value)
		logInstructions "DsiClassValue"
	end
	def evaluate(state)
		logInstructions "DsiClassValue.evaluate #{@value}"
		super
	end
end

# Variables exist in the state
class DsiVariable < DsiExpression
	def initialize(name, value = nil)
		logInstructions "DsiVariable #{name}"
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
	def setValue(v)
		@value = v
	end
	def evaluate(state)
		@value
	end
end

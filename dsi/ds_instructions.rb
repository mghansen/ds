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
			when "+=" # TODO: The parser or the loader should reformat the expression so that assignment only deals with '='
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
	def evaluate(state)
		logInstructions "DsiIf.evaluate"
		@conditions.each do |c|
			logInstructions "DsiIf.evaluate calling evaluate for condition"
			managed = c.evaluate(state)
			if managed
				logInstructions "DsiIf.evaluate condition managed"
				break
			end
		end
	end
end

class DsiCondition < DsiInstruction
	def initialize(conditionType, expression, statements)
		logInstructions "DsiCondition #{conditionType}, #{statements.size} statements"
		super()
		@conditionType = conditionType
		@expression = expression
		@statements = statements
	end
	def evaluate(state)
		logInstructions "DsiCondition.EVALUATE"
		managed = false
		resultValue = @expression.evaluate(state)
		puts resultValue.to_s
		if resultValue.isTrue
			@statements.each do |s|
				s.evaluate(state)
			end
			managed = true
		end
		return managed
	end
end

class DsiForIn < DsiInstruction
	def initialize(variant, set, statements)
		logInstructions "DsiForIn #{variant} in #{set} (NOT IMPLEMENTED)"
		super()
		@variant = variant
		@set = set
		@statements = statements
	end
	def evaluate(state)
		logInstructions "DsiForIn.EVALUATE"
		state.addVariable(@variant)
		# TODO: Arrays
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
	def evaluate(state)
		logInstructions "DsiForFrom.EVALUATE"
		state.addVariable(@variant)
		variant = state.getVariable(@variant)
		variant.setValue(@startExpression.evaluate(state))
		while @endExpression.evaluate(state).isTrue do
			@statements.evaluate(state)
			# Implementor is responsible to iterate the variant
		end
	end
end

class DsiWhile < DsiInstruction
	def initialize(expression, statements)
		logInstructions "DsiWhile"
		super()
		@expression = expression
		@statements = statements
	end
	def evaluate(state)
		logInstructions "DsiWhile.EVALUATE"
		while @endExpression.evaluate(state).isTrue do
			@statements.evaluate(state)
		end
	end
end

class DsiDo < DsiInstruction
	def initialize(statements, expression)
		logInstructions "DsiDo"
		super()
		@statements = statements
		@expression = expression
	end
	def evaluate(state)
		logInstructions "DsiWhile.EVALUATE"
		loop do
			@statements.evaluate(state)
			if not @endExpression.evaluate(state).isTrue
				break
			end
		end
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
		logInstructions "DsiOperation.evauate #{@operator}"
		leftValue = @leftExpression.evaluate(state)
		rightValue = @rightExpression.evaluate(state)
		#DspOperation.@@logicalOperators = [ "+", "-", "*", "/", "." ]
		#DspOperation.@@arithmeticOperators = [ "!", "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
		returnValue = nil
		logInstructions "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&7"
		puts leftValue.to_s
		puts rightValue.to_s
		if leftValue.is_a?(DsiNumberValue) and rightValue.is_a?(DsiNumberValue)
			l = leftValue.getValue
			r = rightValue.getValue
			logInstructions "DsiOperation.evauate arithmetic #{l.to_s} #{@operator} #{r.to_s}"
			case @operator
			when "+"
				returnValue = DsiNumberValue.new(l + r)
			when "-"
				returnValue = DsiNumberValue.new(l - r)
			when "*"
				returnValue = DsiNumberValue.new(l * r)
			when "/"
				returnValue = DsiNumberValue.new(l / r)
			when "!="
				returnValue = DsiBoolValue.new(l != r)
			when "<"
				returnValue = DsiBoolValue.new(l < r)
			when "<="
				returnValue = DsiBoolValue.new(l <= r)
			when "=="
				returnValue = DsiBoolValue.new(l == r)
			when ">"
				returnValue = DsiBoolValue.new(l > r)
			when ">="
				returnValue = DsiBoolValue.new(l >= r)
			end
		elsif (leftValue.is_a?(DsiBoolValue) and rightValue_is_a?(DsiBoolValue)) or
				(leftValue.is_a?(DsiNumberValue) and rightValue_is_a?(DsiBoolValue)) or
				(leftValue.is_a?(DsiBoolValue) and rightValue_is_a?(DsiNumberValue))
			l = leftValue.is_a?(DsiBoolValue) ? leftValue.getValue : (leftValue.getValue != 0 ? true : false)
			r = rightValue.is_a?(DsiBoolValue) ? rightValue.getValue : (rightValue.getValue != 0 ? true : false)
			logInstructions "DsiOperation.evauate boolean #{l.to_s} #{@operator} #{r.to_s}"
			case @operator
				when "+", "||"
					returnValue = DsiBoolValue.new(l || r)
				when "*", "&&"
					returnValue = DsiBoolValue.new(l && r)
				when "^"
					returnValue = DsiBoolValue.new(l ^ r)
			end
			# TODO: Not?
		elsif (leftValue.is_a?(DsiStringValue) or rightValue.is_a?(DsiStringValue))
			logInstructions "DsiOperation.evauate string '#{l.to_s}' #{@operator} '#{r.to_s}'"
			case @operator
			when "+"
				l = leftValue.to_s
				r = rightValue.to_s
				returnValue = DsiStringValue(l + r)
			end
		else
			logInstructions "DsiOperation.evaluate invalid use of operator."
		end
		logInstructions "DsiOperation.evauate done"
		returnValue
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
	def isTrue
		return true
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
	def isTrue
		if @value != 0
			ret = true
		else
			ret = false
		end
		#logInstructions "DsiNumberValue.isTrue #{@value} #{ret.to_s}"
		ret
	end
	def evaluate(state)
		logInstructions "DsiNumberValue.evaluate #{@value}"
		DsiNumberValue.new(@value)
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
	def isTrue
		return true if @value.size > 0
		return false
	end
	def evaluate(state)
		logInstructions "DsiStringValue.evaluate #{@value}"
		DsiStringValue.new(@value)
	end
	def to_s
		"#{@value.to_s}="
	end
end

class DsiBoolValue < DsiValue
	def initialize(value)
		logInstructions "DsiBoolValue #{value}"
		super
	end
	def isTrue
		if @value
			ret = true
		else
			ret = false
		end
		#logInstructions "DsiBoolValue.isTrue #{ret.to_s}"
		ret
	end
	def evaluate(state)
		logInstructions "DsiBoolValue.evaluate #{@value}"
		DsiBoolValue.new(@value)
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
		returnValue = nil
		var = state.getVariable(@name)
		if var != nil
			returnValue = var.getValue
		end
		returnValue
	end
end

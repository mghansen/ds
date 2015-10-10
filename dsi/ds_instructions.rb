require_relative "ds_contexts"
require_relative "ds_library"

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
			logInstructions "(raw rValue) " << @rValue.to_s
			rValue = @rValue.evaluate(state)
			logInstructions "DsiAssignment.evaluate rValue #{rValue.to_s}"

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
		#puts resultValue.to_s
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
	def initialize(variantName, set, statements)
		logInstructions "DsiForIn #{variantName} in #{set} (NOT IMPLEMENTED)"
		super()
		@variantName = variantName
		@set = set
		@statements = statements
	end
	def evaluate(state)
		logInstructions "DsiForIn.EVALUATE"
		state.addVariable(@variantName)
		# TODO: Arrays
	end
end

class DsiForFrom < DsiInstruction
	def initialize(variantName, startExpression, endExpression, stepExpression, excludeLastItem, statements)
		logInstructions "DsiForFrom #{variantName}"
		super()
		@variantName = variantName
		@startExpression = startExpression
		@endExpression = endExpression
		@stepExpression = stepExpression
		@excludeLastItem = excludeLastItem
		@statements = statements
	end
	def evaluate(state)
		logInstructions "DsiForFrom.EVALUATE"
		startValue = @startExpression.evaluate(state)
		endValue = @endExpression.evaluate(state)
		if @stepExpression == nil
			stepValue = DsiNumberValue.new(1)
		else
			stepValue = DsiNumberValue.new(@stepExpression.evaluate(state))
		end
		state.addVariableByName(@variantName)
		variant = state.getVariable(@variantName)
		variant.setValue(@startExpression.evaluate(state))
		
		if @excludeLastItem
			# for from to
			while variant.getValue.neq?(endValue) do
				@statements.each { |s| s.evaluate(state) }
				variant.setValue variant.getValue.add(stepValue)
			end
		else
			# for from through
			@statements.each { |s| s.evaluate(state) }
			while variant.getValue.neq?(endValue) do
				variant.setValue variant.getValue.add(stepValue)
				@statements.each { |s| s.evaluate(state) }
			end
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
		while @expression.evaluate(state).isTrue do
			@statements.each { |s| s.evaluate(state) }
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
			@statements.each { |s| s.evaluate(state) }
			if not @expression.evaluate(state).isTrue
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
	def evaluate(state)
		controlValue = @expression.evaluate(state)
		@cases.each do |c|
			if c.matches(controlValue, state)
				c.evaluate(state)
			end
		end
	end
end
	
class DsiCase
	def initialize(expression, statements)
		logInstructions "DsiCase"
		super()
		@expression = expression
		@statements = statements
	end
	def matches(controlValue, state)
		caseValue = @expression.evaluate(state)
		if caseValue.eq?(controlValue)
			return true
		else
			return false
		end
	end
	def evaluate(state)
		@statements.each { |s| s.evaluate(state) }
	end
end

# DsiExpression ####################################################################################################

class DsiExpression < DsiInstruction
	def initialize
		logInstructions "DsiExpression"
		super()
	end
	def evaluate(state)
		logInstructions "DsiExpression.evauate"
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
		if @leftExpression != nil
			leftValue = @leftExpression.evaluate(state)
			logInstructions "DsiOperation.evauate leftValue #{leftValue.to_s}"
		else
			leftValue = nil
		end
		rightValue = @rightExpression.evaluate(state)
		logInstructions "DsiOperation.evauate rightValue #{rightValue.to_s}"
		
		#DspOperation.@@arithmeticOperators = [ "+", "-", "*", "/", "." ]
		#DspOperation.@@logicalOperators = [ "!", "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
		returnValue = nil
		#puts leftValue.to_s
		#puts rightValue.to_s
		if leftValue == nil
			logInstructions "DsiOperation.evauate unary operator"
			r = rightValue.getValue
			case @operator
			when "!"
				if rightValue.is_a?(DsiBoolValue)
					returnValue = DsiBoolValue.new(r == false)
				elsif rightValue.is_a?(DsiNumberValue)
					returnValue = DsiNumberValue.new(r == 0 ? 1 : 0)
				end
			end
		elsif leftValue.is_a?(DsiNumberValue) and rightValue.is_a?(DsiNumberValue)
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
				(leftValue.is_a?(DsiNumberValue) and rightValue.is_a?(DsiBoolValue)) or
				(leftValue.is_a?(DsiBoolValue) and rightValue.is_a?(DsiNumberValue))
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
				returnValue = DsiStringValue.new(l + r)
			when "=="
				returnValue = DsiBoolValue.new(l.eql?(r))
			when "!="
				returnValue = DsiBoolValue.new(l.eql?(r) == false)
			end
		else
			logInstructions "DsiOperation.evaluate invalid use of operator."
			#puts leftValue.to_s
			#puts rightValue.to_s
		end
		logInstructions "DsiOperation.evauate done"
		return returnValue
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
		logInstructions "DsiFunctionCall.evauate #{@name}"
		if state.isLibraryFunction(@name)
			logInstructions "DsiFunctionCall.evauate LIBRARY FUNCTION #{@name}"
			returnValue = evaluateLibraryFunction(state)
		else
			# Find the context for the target function and check parameters
			functionContext = state.getFunctionContext(@name)
			if functionContext != nil and functionContext.getParamNames.size == @paramExpressions.size
				newState = functionContext.makeFunctionState(state.getParentState)
				# Set up internal state of the function, including named params
				numExpressions = @paramExpressions.size
				for i in 0 .. numExpressions - 1
					newValue = @paramExpressions[i].evaluate(state)
					newVariable = DsiVariable.new(functionContext.getParamNames[i], newValue)
					newState.addVariable(newVariable)
				end
			end
			returnValue = functionContext.invoke(newState)
		end
		puts "EVALUATE RETURN VALUE #{returnValue.to_s}"
		return returnValue
	end
	
	def evaluateLibraryFunction(state)
		logInstructions "DsiFunctionCall.evauate #{@name}"
		params = Array.new
		@paramExpressions.each do |p|
			newValue = p.evaluate(state)
			params.push(newValue)
		end
		libraryCall = LibraryCall.new(@name, params)
		libraryCall.invoke(state)
		returnValue = libraryCall.getReturnValue
		puts "RETURN VALUE #{returnValue.to_s}"
		return returnValue
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
	def compare(otherValue)
		return -1 # like strcmp
	end
	def eq?(otherValue)
		return true if compare(otherValue) == 0
		return false
	end
	def neq?(otherValue)
		#puts "NEQ L:#{getValue} R:#{otherValue.getValue}"
		return false if compare(otherValue) == 0
		return true
	end
	def lt?(otherValue)
		return true if compare(otherValue) < 0
		return false
	end
	def gt?(otherValue)
		return true if compare(otherValue) > 0
		return false
	end
	def lteq?(otherValue)
		return true if compare(otherValue) <= 0
		return false
	end
	def gteq?(otherValue)
		return true if compare(otherValue) >= 0
		return false
	end
	def add(otherValue)
		return @value
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
	def compare(otherValue)
		compareValue = 0
		if otherValue.is_a?(DsiNumberValue)
			compareValue = otherValue.getValue
		elsif otherValue.is_a?(DsiStringValue)
			if otherValue.getValue.include? '.'
				compareValue = otherValue.getValue.to_f
			else
				compareValue = otherValue.getValue.to_i
			end
		end
		if getValue == compareValue
			return 0
		elsif getValue < compareValue
			return -1
		elsif getValue > compareValue
			return 1
		end
	end
	def add(otherValue)
		ret = getValue
		if otherValue.is_a?(DsiNumberValue)
			ret = DsiNumberValue.new(getValue + otherValue.getValue)
		elsif otherValue.is_a?(DsiStringValue)
			ret = DsiStringValue.new("#{getValue.to_s}#{otherValue.getValue}")
		end
		return ret
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
	def compare(otherValue)
		compareValue = ""
		if otherValue.is_a?(DsiStringValue)
			compareValue = otherValue.getValue
		elsif otherValue.is_a?(DsiNumberValue)
			compareValue = "#{otherValue.getValue.to_s}"
		end
		return getValue <=> compareValue
	end
	def add(otherValue)
		if otherValue.is_a?(DsiStringValue)
			ret = DsiStringValue.new("#{getValue}#{otherValue.getValue}")
		else
			ret = DsiStringValue.new("#{getValue}#{otherValue.getValue.to_s}")
		end
		return ret
	end
	def to_s
		"#{@value.to_s}"
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
	def compare(otherValue)
		if otherValue.is_a?(DsiBoolValue) and getValue == otherValue.getValue
			return 0
		else
			return - 1
		end
	end
	def _and(otherValue)
		if otherValue.is_a?(DsiBoolValue) and getValue and otherValue.getValue
			return true
		else
			return false
		end
	end
	def _or(otherValue)
		if otherValue.is_a?(DsiBoolValue) and (getValue or otherValue.getValue)
			return true
		else
			return false
		end
	end
	def _xor(otherValue)
		if otherValue.is_a?(DsiBoolValue) and
				((getValue and not otherValue.getValue) or (otherValue.getValue and not getValue))
			return true
		else
			return false
		end
	end
	def _not
		return false if getValue
		return true
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

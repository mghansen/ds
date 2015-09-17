# TODO: 
#  Array
#  new Class
#  constructors and destructors?
#  What is nil?

$verboseElements = FALSE
$indentationLevel = 2

def dbgElements text
	puts text if $verboseElements
end

def dbgElementsTokens(text, tokens)
	if $verboseElements
		if tokens == nil or tokens.size == 0
			puts "#{text} []"
		else
			puts "#{text} [ #{tokens[0]} #{tokens[1]} #{tokens[2]} #{tokens[3]} #{tokens[4]} ]"
		end
	end
end

def prefix(indent)
	s = ""
	#s << "<#{indent}>"
	i = indent * $indentationLevel
	while i > 0
		s << " "
		i = i - 1
	end
	s
end

# DSObject ####################################################################################################

class DSObject
	@@keywords = [ 
		"use", "new", "array", "of", "enum", "end", "class", "from", "func", "true", "false", "return", 
		"break", "continue", "if", "else", "elsif", "for", "in", "do", "from", "to", "while", "switch", "case" ]
		
	def initialize
		@id = ""
		@consumed = 1
		@valid = true
		consume 1 # Advance 1 character by default
	end
	
	def consume tokensConsumed
		@consumed = tokensConsumed
	end
	
	def getConsumed
		@consumed
	end
	
	def invalidate
		@valid = false
	end
	
	def isValid
		@valid
	end
	
	def self.parse tokens 
		dbgElements "Default DSObject parse"
		invalid()
	end
	
	def evaluate
	end
	
	def self.invalid
		ret = DSObject.new
		ret.invalidate
		ret
	end
	
	def to_s
		"X"
	end
	
	def format(indent)
		to_s
	end
	
	def endl(indent)
		""
	end
	
	def self.isName(name)
		#puts "\"#{name}\" IS NAME? #{ret ? "TRUE" : "FALSE"}"
		#/^[a-zA-Z][a-zA-Z0-9]*$/ =~ name
		/^[_a-zA-Z][_a-zA-Z0-9]*$/ =~ name
	end
	
	def self.isQName(name)
		#/^([a-zA-Z])([a-zA-Z0-9\.])*([a-zA-Z0-9])$/ =~ name
		#/(^([a-zA-Z])([a-zA-Z0-9\.])*([a-zA-Z0-9])$)|^([a-zA-Z])$/ =~ name
		/(^([_a-zA-Z])([_a-zA-Z0-9\.])*[_a-zA-Z0-9]$)|^([_a-zA-Z])$/ =~ name
	end
	
	
	def self.isNumber(number)
		/^\-?\d+(\.\d+)?$/ =~ number
	end
		
end

# DSDocument ####################################################################################################

class DSDocument < DSObject
	def initialize(name, statements)
		super()
		@name = name
		@statements = statements
	end
	def self.parse tokens
		super
	end
end

# Names ####################################################################################################

class DSName < DSObject
	def initialize (name)
		dbgElements "DSName.initialize " + name
		super()
		@name = name
		consume 1
		dbgElements "DSName.initialize DONE"
	end
	def self.parse tokens
		dbgElementsTokens "DSName.parse", tokens
		element = DSObject.isName(tokens[0]) ? DSName.new(tokens[0]) : invalid()
		element
	end
	def to_s
		@name
	end
	def format(indent)
		@name
	end
		
	
end

class DSVarName < DSName
	def initialize (name)
		dbgElements "DSVarName.initialize " + name
		super
		@name = name
	end
	def self.parse tokens
		dbgElementsTokens "DSVarName.parse", tokens
		element = DSObject.isQName(tokens[0]) ? DSVarName.new(tokens[0]) : invalid()
		element
	end
	def to_s
		@name
	end
	def format(indent)
		"#{prefix(indent)}#{to_s}\n"
	end
end

# DSStatement ####################################################################################################

class DSStatement < DSObject
	def initialize
		super
	end
	def self.parse tokens	
		dbgElementsTokens "DSStatement.parse", tokens
		
		if tokens[0].eql?("use")
			element = DSUse.parse(tokens)
		elsif ["enum", "class", "func", "var" ].include?(tokens[0])
			element = DSDeclaration.parse(tokens)
		elsif ["if", "for", "while", "do", "switch" ].include?(tokens[0])
			element = DSControl.parse tokens
		elsif [ "=", "+=", "-=", "*=", "/=" ].include?(tokens[1]) and DSObject.isQName(tokens[0])
			element = DSAssignment.parse(tokens)
		else
			element = DSExpression.parse(tokens)
		end
		element
	end
	
	def to_s
		"X"
	end
end

# DSBlock ####################################################################################################

class DSBlock < DSObject
	def initialize(statements, finalizingToken)
		super()
		@statements = statements
		@finalizingToken = finalizingToken
		consumed = 0
		@statements.each { |s| consumed += s.getConsumed() }
		consume consumed + 1 # + 1 is for finalizing token ("end")
		# puts "BLOCK CONSUMED #{getConsumed()} >>> #{to_s}"
	end
	
	def self.parse(tokens, finalizingTokens)
		#puts "DSBlock #{tokens.size} tokens"
		dbgElementsTokens "DSBlock.parse", tokens
		statements = Array.new
		finalizingToken = ""
		i = 0
		if tokens != nil and tokens.size > 0
			while i < tokens.size() do
				# Don't include finalizing token here. The caller will look for it (to support else cases)
				if(finalizingTokens.include?(tokens[i]))
					finalizingToken = tokens[i]
					break
				else
					statement = DSStatement.parse(tokens[i..-1])
					statements.push(statement)
					i += statement.getConsumed()
				end
			end
			element = DSBlock.new(statements, finalizingToken)
		else
			element = invalid()
		end
		element
	end
	def to_s
		blockText = ""
		@statements.each { |statement| blockText << statement.to_s << "\n" }
		blockText
	end
	def format(indent)
		s = ""
		@statements.each { |statement| s << "#{statement.format(indent)}"}
		#s << "#{prefix(indent)}#{@finalizingToken}\n"
		s
	end
end

# DSUse ####################################################################################################

class DSUse < DSStatement
	def initialize (filename)
		super()
		@filename = filename
		consume 2
	end
	def self.parse tokens
		dbgElementsTokens "DSUse.parse", tokens
		if tokens[0].eql? "use" and tokens.size > 1
			element = DSUse.new(tokens[1])
		end
		element
	end
	def to_s
		"USE #{@filename}"
	end
	def format(indent)
		"USE #{prefix(indent)}#{@filename}\n"
	end
end

# DSAssignment ####################################################################################################

class DSAssignment < DSStatement
	def initialize(lValue, operation, rValue)
		super()
		@lValue = lValue
		@operation = operation
		@rValue = rValue
		consume (2 + @rValue.getConsumed)
	end
	def self.parse tokens
		dbgElementsTokens "DSAssignment.parse", tokens
		rValue = DSExpression.parse(tokens[2..-1])
		if rValue.isValid
			element = DSAssignment.new(tokens[0], tokens[1], rValue)
		else
			element = invalid()
		end
		element
	end
	def to_s
		"#{@lValue} #{@operation} #{@rValue}"
	end
	def format(indent)
		s = "#{prefix(indent)}ASSIGN #{@lValue} #{@operation}\n"
		s << @rValue.format(indent + 1)
		s << "#{prefix(indent)}END ASSIGN\n"
		s
	end
end

# DSDeclaration ####################################################################################################

class DSDeclaration < DSStatement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSDeclaration.parse", tokens
		element = invalid()
		if tokens[0].eql?("enum") and DSObject.isName(tokens[1]) and DSObject.isName(tokens[2])
			element = DSEnumDeclaration.parse(tokens)
		elsif tokens[0].eql?("class") and DSObject.isName(tokens[1]) and DSObject.isName(tokens[2]) # tokens[2] might be "from"
			element = DSClassDeclaration.parse(tokens)
		elsif tokens[0].eql?("func") and DSObject.isName(tokens[1]) and tokens[2].eql?("(")
			element = DSFunctionDeclaration.parse(tokens)
		elsif tokens[0].eql?("var") and DSObject.isName(tokens[1])
			element = DSVariableDeclaration.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

# DSVariableDeclaration ####################################################################################################

class DSVariableDeclaration < DSDeclaration
	def initialize(name)
		@name = name
		consume 2
	end
	def self.parse tokens
		dbgElementsTokens "DSDeclaration.parse", tokens
		if tokens[0].eql?("var") and DSObject.isName(tokens[1])
			element = DSVariableDeclaration.new(tokens[1])
		else
			element = invalid()
		end
		element
	end
	def to_s
		"var #{@name}"
	end
	def format(indent)
		"#{prefix(indent)}VAR #{@name}\n"
	end
end

# DSEnumDeclaration ####################################################################################################

class DSEnumDeclaration < DSDeclaration
	def initialize(name, values)
		super()
		@name = name
		@values = values
		consume (2 + (@values.size * 2))
	end

	def self.parse tokens
		dbgElementsTokens "DSEnumDeclaration.parse", tokens
		if tokens[0].eql?("enum") and DSObject.isName(tokens[1])
			name = tokens[1]
			values = Array.new
			consumed = 1
			first = true
			valid = true
			while not tokens[consumed].eql?("end") do
				if (first or tokens[consumed].eql?(","))
					if DSObject.isName(tokens[consumed + 1])
						values.push(tokens[consumed + 1])
						consumed += 2
					else
						valid = false
						break;
					end
				end
				first = false
			end
			if(valid)
				element = DSEnumDeclaration.new(name, values)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end

	def format(indent)
		s = ""
		s << "#{prefix(indent)}ENUM #{@name}\n"
		@values.each { |v| s << "#{prefix(indent + 1)}#{v}\n" }
		s << "#{prefix(indent)}"
		s
	end
	def format(indent)
		s = ""
		s << "#{prefix(indent)}ENUM #{@name}\n"
		@values.each { |v| s << "#{prefix(indent + 1)}#{v}\n" }
		s << "#{prefix(indent)}END ENUM\n"
		s
	end
end

# DSClassDeclaration ####################################################################################################

class DSClassDeclaration < DSDeclaration
	def initialize(name, baseClass, block)
		super()
		@name = name
		@baseClass = baseClass
		@block = block
		consume (2 + (@baseClass.size > 0 ? 2 : 0) + @block.getConsumed)
	end
	def self.parse tokens
		dbgElements "DSClassDeclaration.parse"
		if tokens[0].eql?("class") and DSObject.isName(tokens[1])
			name = tokens[1]
			consumed = 2
			if tokens[consumed].eql?("from") and DSObject.isName(tokens[consumed + 1])
				from = tokens[consumed + 1]
				consumed += 2
			else
				from = ""
			end
			block = DSBlock.parse(tokens[consumed..-1], [ "end" ])
			if block.isValid
				element = DSClassDeclaration.new(name, from, block)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		"class #{@name}#{@baseClass.size > 0 ? " from #{@baseClass}" : ""}\n#{@block.to_s}"
	end
	def format(indent)
		s = "#{prefix(indent)}CLASS #{@name}#{@baseClass.size > 0 ? " FROM #{@baseClass}" : ""}\n"
		s << "#{@block.format(indent + 1)}"
		s << "#{prefix(indent)}END CLASS\n"
	end
end

# DSFunctionDeclaration ####################################################################################################

class DSFunctionDeclaration < DSDeclaration
	
	def initialize(name, params, block)
		super()
		@name = name
		@params = params
		@block = block
		consume 3 + (params.size > 0 ? params.size * 2 : 1) + block.getConsumed()
	end
	
	def self.parse tokens
		dbgElementsTokens "DSFunctionDeclaration.parse", tokens
		if(tokens[0].eql?("func") and DSObject.isName(tokens[1]) and tokens[2].eql?("("))
			name = tokens[1]
			params = Array.new
			consumed = 3

			if tokens[consumed].eql?(")")
				consumed += 1
				# puts "NO PARAMS consumed=#{consumed}"
			else
				# dbgElementsTokens "DSFunctionDeclaration.parse params start", tokens[consumed..-1]
				while not tokens[consumed - 1].eql?(")") do
					# dbgElementsTokens "DSFunctionDeclaration.parse params", tokens[consumed..-1]
					if DSObject.isName(tokens[consumed]) and ([ ",", ")" ].include?(tokens[consumed + 1]))
						params.push(tokens[consumed])
						# puts "PARAMETER #{tokens[consumed]}"
						consumed += 2
					else
						puts "DSFunctionDeclaration.parse error reading parameters"
						break
					end
				end
				# puts "END LOOP consumed=#{consumed}"
			end

			# dbgElementsTokens "DSFunctionDeclaration.parse starting block", tokens[consumed..-1]
			block = DSBlock.parse(tokens[consumed..-1], [ "end" ])
			if block.isValid
				element = DSFunctionDeclaration.new(name, params, block)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	
	def to_s
		s = "func #{@name} ("
		first = true
		@params.each do |p| 
			if first
				s << "#{p}"
				first = false
			else
				s << ", #{p}"
			end
		end
		s << ")\n"
		s << "#{@block.to_s}"
		s << "end"
		s
	end
	def format(indent)
		s = "#{prefix(indent)}FUNCTION #{@name}\n"
		s << "#{prefix(indent + 1)}PARAMS:\n"
		if @params.size == 0 
			s << "#{prefix(indent + 2)}none\n"
		else
			@params.each { |p| s << "#{prefix(indent + 2)}#{p}\n" }
		end
		s << "#{prefix(indent + 1)}BODY:\n"
		s << "#{@block.format(indent + 2)}"
		s << "#{prefix(indent)}END FUNCTION\n"
		s
	end
end

# DSExpression ####################################################################################################

class DSExpression < DSStatement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSExpression.parse", tokens
		
		if tokens[0].eql?("(")
			# dbgElements "EXPRESSION GROUPED EXPRESSION"
			element = DSExpression.parse(tokens[1..-1])
			if tokens[element.getConsumed + 1].eql?(")")
				element.consume(element.getConsumed + 2)
			else
				element = invalid()
			end
		elsif DSObject.isNumber(tokens[0])
			# dbgElements "EXPRESSION NUMBER"
			element = DSNumber.parse(tokens)
		elsif /^\"/ =~ tokens[0]
			# dbgElements "EXPRESSION STRING"
			element = DSString.parse(tokens)	
		elsif /^true|false$/ =~ tokens[0]
			# dbgElements "EXPRESSION BOOL"
			element = DSBool.parse(tokens)
		elsif tokens[0].eql?("nil")
			dbgElements "NIL"
		elsif [ "return", "break", "continue" ].include?(tokens[0])
			# dbgElements "BUILT IN FUNCTION CALL"
			element = DSBuiltInFunction.parse(tokens)
		elsif DSObject.isQName(tokens[0]) and not @@keywords.include?(tokens[0])
			if tokens[1].eql?("(")
				# dbgElements "EXPRESSION FUNCTION CALL"
				element = DSFunctionCall.parse(tokens)
			else
	 			dbgElements "EXPRESSION VARIABLE NAME"
				element = DSVarName.parse(tokens)
			end
		else
			# dbgElements "EXPRESSION OTHER"
			element = invalid()
		end
		
		if element.isValid and DSOperation.isOperator(tokens[element.getConsumed])
			# dbgElements "EXPRESSION OPERATION"
			element = DSOperation.parse(tokens, element)
		end
		element
	end
end

# DSConstant ####################################################################################################

class DSConstant < DSExpression
	def initialize
		super
	end
	def self.parse tokens
		super
	end
	def format(indent)
		super
	end
end

class DSNumber < DSConstant
	def initialize(value)
		super()
		if value.include? '.'
			@value = value.to_f
		else
			@value = value.to_i
		end
		consume 1
	end
	def self.parse tokens
		dbgElements "DSNumber.parse"
		element = DSNumber.new(tokens[0])
		element
	end
	def to_s
		@value.to_s
	end
	def format(indent)
		"#{prefix(indent)}#{@value.to_s}\n"
	end
end

class DSString < DSConstant
	def initialize(value)
		super()
		@value = value
		consume 1
	end
	def self.parse tokens
		element = DSString.new(tokens[0])
		element
	end
	def to_s
		@value
	end
	def format(indent)
		"#{prefix(indent)}#{@value.to_s}\n"
	end
end

class DSBool < DSConstant
	def initialize(value)
		super()
		@value = value
		consume 1
	end
	def self.parse tokens
		element = DSBool.new(tokens[0].eql?("true"))
	end
	def to_s
		@value ? "[true]" : "[false]"
	end
	def format(indent)
		"#{prefix(indent)}#{@value.to_s}\n"
	end
end

# DSOperation ####################################################################################################

class DSOperation < DSExpression
	@@logicalOperators = [ "+", "-", "*", "/", "." ]
	@@arithmeticOperators = [ "!", "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
	
	def initialize(firstExpression, operator, secondExpression)
		super()
		@firstExpression = firstExpression
		@operator = operator
		@secondExpression = secondExpression
		consume @firstExpression.getConsumed + 1 + @secondExpression.getConsumed
	end
	
	def self.parse(tokens, firstExpression)
		dbgElementsTokens "DSOperation.parse", tokens
		operator = tokens[firstExpression.getConsumed]
		if DSOperation.isOperator(operator)
			secondExpression = DSExpression.parse(tokens[(firstExpression.getConsumed + 1)..-1])
			if secondExpression.isValid
				element = DSOperation.new(firstExpression, operator, secondExpression)
			else
				element = invalid()
			end
		else
			element = invalid()
			# element = firstExpression # ?
		end
		element
	end
	
	def self.isOperator(token)
		@@logicalOperators.include?(token) or @@arithmeticOperators.include?(token)
	end
	
	def to_s
		s = "(#{@firstExpression.to_s} #{@operator} #{@secondExpression.to_s})"
		s
	end
	def format(indent)
		s = "#{prefix(indent)}OPERATION\n"
		s << @firstExpression.format(indent + 1)
		s << "#{prefix(indent)}#{@operator}\n"
		s << @secondExpression.format(indent + 1)
		s << "#{prefix(indent)}END OPERATION\n"
		s
	end
	
end 

# DSFunctionCall ####################################################################################################

class DSFunctionCall < DSExpression
	def initialize(name, tokens)
		# dbgElements "DSFunctionCall.initialize"
		super()
		@name = name
		consumed = 2
		first = true
		@params = Array.new

		i = consumed
		while i < tokens.size do
			if tokens[i].eql?(")")
				consumed += 1
				break
			elsif tokens[i].eql?(",")
				consumed += 1
				i += 1
			else
				param = DSExpression.parse(tokens[i..-1])
				@params.push(param) if param.isValid
				consumed += param.getConsumed()
				i += param.getConsumed()
			end				
		end
		consume consumed
	end
	def self.parse tokens
		dbgElementsTokens "DSFunctionCall.parse", tokens
		if [ "return", "break", "continue" ].include?(tokens[0])
			element = DSBuiltInFunction(tokens)
		elsif not DSObject.isQName(tokens[0]) or @@keywords.include?(tokens[0]) or not tokens[1].eql?("(")
			element = invalid()
		else
			element = DSFunctionCall.new(tokens[0], tokens)
		end
		element
	end
	def to_s
		s = "#{@name}("
		first = true
		@params.each do |p|
			s << ", " if not first
			first = false
			s << p.to_s
		end
		s << ")"
		s
	end
	def format(indent)
		"#{prefix(indent)}CALL #{to_s}\n"
	end
	
end

# DSBuiltInFunction ####################################################################################################

class DSBuiltInFunction < DSExpression
	def initialize(name, expression)
		super()
		@name = name
		@expression = expression
		consumed = 1
		if @name.eql?("return")#if expression == nil
			consumed = consumed + @expression.getConsumed
		end
		consume consumed
	end
	def self.parse tokens
		dbgElementsTokens "DSBuiltInFunction.parse", tokens
		if [ "return", "break", "continue" ].include?(tokens[0])
			if tokens[0].eql?("return")
				expression = DSExpression.parse(tokens[1..-1])
				if expression.isValid
					element = DSBuiltInFunction.new(tokens[0], expression)
				else
					element = invalid()
				end
			else
				element = DSBuiltInFunction.new(tokens[0], nil)
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		if @name.eql?("return")
			"#{@name} #{@name.eql?("return") ? "#{expression.to_s}" : ""}"
		else
			"#{@name}"
		end
	end
	def format(indent)
		"#{prefix(indent)}CALL #{@name}\n#{@name.eql?("return") ? @expression.format(indent + 1) : ""}"
	end
end

# DSControl ####################################################################################################

class DSControl < DSStatement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSControl.parse", tokens
		if tokens[0].eql?("if")
			element = DSIf.parse(tokens)
		elsif tokens[0].eql?("for") and DSObject.isName(tokens[1])
			element = DSFor.parse(tokens)
		elsif tokens[0].eql?("while") and tokens[1].eql?("(")
			element = DSWhile.parse(tokens)
		elsif tokens[0].eql?("do")
			element = DSDo.parse(tokens)
		elsif tokens[0].eql?("switch")
			element = DSSwitch.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

# DSIf ####################################################################################################

class DSIf < DSControl
	def initialize(conditions)
		super()
		@conditions = conditions
		consumed = 0
		@conditions.each { |c| consumed += c.getConsumed }
		consumed += 1 # end
		consume consumed
	end
	def self.parse tokens
		dbgElementsTokens "DSIf.parse", tokens
		conditions = Array.new
		if tokens[0].eql?("if") and tokens[1].eql?("(")
			consumed = 0
			seenIf = false
			seenElse = false
			
			begin
				type = tokens[consumed]
				if type.eql?("if")
					break if seenIf
					seenIf = true
				elsif type.eql?("else")
					break if seenElse
					seenElse = true
				end
			
				condition = DSCondition.parse tokens[consumed..-1]
				if condition.isValid
					conditions.push(condition)
					consumed += condition.getConsumed
				end
				
				if tokens[consumed].eql?("end")
					break
				end
				
			end while(condition.isValid)
			
			if conditions.size > 0 and tokens[consumed].eql?("end")
				element = DSIf.new(conditions)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		s = ""
		@conditions.each { |c| s << c.to_s }
		s << "end"
		s
	end
	def format(indent)
		s = "#{prefix(indent)}IF\n"
		@conditions.each do |c| 
			s << " #{c.format(indent)}"
		end
		s << "#{prefix(indent)}END IF\n"
		s
	end
end

# DSCondition ####################################################################################################

class DSCondition < DSObject
	def initialize(conditionType, expression, block)
		super()
		@conditionType = conditionType
		@expression = expression
		@block = block
		# consumed size does not include the elsif/else/end at the end of the block
		if @conditionType.eql?("else")
			consume (1 + (@block.getConsumed - 1))
		else
			consume (2 + @expression.getConsumed + 1 + (@block.getConsumed - 1))
		end
		# puts "CONDITION CONSUMED #{getConsumed()} >>> #{to_s}"
	end
	def getConditionType
		@conditionType
	end
	def self.parse tokens
		dbgElementsTokens "DSCondition.parse", tokens
		isElse = tokens[0].eql?("else")
		if (["if", "elsif"].include?(tokens[0]) and tokens[1].eql?("(")) or isElse
			if isElse
				expression = DSExpression.parse( ["true" ] )
				block = DSBlock.parse(tokens[1..-1], ["end"])
				if block.isValid
					element = DSCondition.new(tokens[0], expression, block)
				else
					element = invalid()
				end
			else
				consumed = 2
				expression = DSExpression.parse(tokens[consumed..-1])
				if expression.isValid and tokens[consumed + expression.getConsumed].eql?(")")
					consumed += expression.getConsumed + 1
					block = DSBlock.parse(tokens[consumed..-1], ["elsif", "else", "end"])
					if block.isValid
						element = DSCondition.new(tokens[0], expression, block)
					else
						element = invalid()
					end
				else
					element = invalid()
				end
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		"#{@conditionType} (#{@expression.to_s})\n#{@block.to_s}"
	end	
	def format(indent)
		s = "#{prefix(indent)}#{@conditionType}\n"
		s << "#{@block.format(indent + 1)}"
		s
	end	
end

# DSFor ####################################################################################################

class DSFor < DSControl
	def initialize(variant, block)
		super()
		@variant = variant
		@block = block
		# consume in child class
	end
	def self.parse tokens
		dbgElementsTokens "DSFor.parse", tokens
		if tokens[0].eql?("for") and DSObject.isName(tokens[1])
			if tokens[2].eql?("in") and DSObject.isQName(tokens[3])
				element = DSForIn.parse(tokens)
			elsif tokens[2].eql?("from")
				element = DSForFrom.parse(tokens)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
end

# DSForIn ####################################################################################################

class DSForIn < DSFor
	def initialize(variant, set, block)
		super(variant, block)
		@set = set
		consume 4 + block.getConsumed()
	end
	def self.parse tokens
		dbgElementsTokens "DSForIn.parse", tokens
		variant = tokens[1]
		set = tokens[3]
		block = DSBlock.parse(tokens[4..-1], [ "end" ])
		if block.isValid
			element = DSForIn.new(variant, set, block)
		else
			element = invalid()
		end
		element
	end
	def to_s
		s = "for |#{@variant}| in #{@set}\n#{@block}"
	end
	def format(indent)
		s = "#{prefix(indent)}FOR #{@variant} IN #{@set}\n"
		s << @block.format(indent + 1)
		s = "#{prefix(indent)}END FOR IN\n"
		s
	end
end

# DSForFrom ####################################################################################################

class DSForFrom < DSFor
	def initialize(variant, startExpression, endExpression, block)
		super(variant, block)
		@startExpression = startExpression
		@endExpression = endExpression
		consume 3 + startExpression.getConsumed() + 1 + endExpression.getConsumed() + block.getConsumed()
	end
	def self.parse tokens
		dbgElementsTokens "DSForFrom.parse", tokens
		variant = tokens[1]
		consumed = 3
		startExpression = DSExpression.parse(tokens[consumed..-1])
		if startExpression.isValid and tokens[consumed + startExpression.getConsumed].eql?("to")
			consumed += startExpression.getConsumed + 1
			endExpression = DSExpression.parse(tokens[consumed..-1])
			if endExpression.isValid
				consumed += endExpression.getConsumed
				block = DSBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid
					element = DSForFrom.new(variant, startExpression, endExpression, block)
				else
					element = invalid()
				end
			else
				element = invalid()
			end
		else
			element = invalid()
		end
	end
	def to_s
		"for |#{@variant}| from #{@startExpression} to #{@endExpression}\n#{@block}"
	end
	def format(indent)
		s = "#{prefix(indent)}FOR #{@variant}\n"
		s << "#{prefix(indent + 1)}FROM\n#{@startExpression.format(indent + 2)}"
		s << "#{prefix(indent + 1)}TO\n#{@endExpression.format(indent + 2)}"
		s << "#{prefix(indent + 1)}BODY\n"
		s << @block.format(indent + 2)
		s << "#{prefix(indent)}END FOR FROM\n"
		s
	end
end

# DSWhile ####################################################################################################

class DSWhile < DSControl
	def initialize(expression, block)
		super()
		@expression = expression
		@block = block
		consume 2 + expression.getConsumed + 1 + block.getConsumed
	end
	def self.parse tokens
		dbgElementsTokens "DSWhile.parse", tokens
		if tokens[0].eql?("while") and tokens[1].eql?("(")
			consumed = 2
			expression = DSExpression.parse(tokens[2..-1])
			if expression.isValid and tokens[2 + expression.getConsumed()].eql?(")")
				consumed += expression.getConsumed + 1
				block = DSBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid()
					element = DSWhile.new(expression, block)				
				else
					element = invalid()
				end
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		"while(#{@expression.to_s})\n#{@block.to_s}\nend"
	end
	def format(indent)
		s = "#{prefix(indent)}WHILE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s
	end
end

# DSDo ####################################################################################################

class DSDo < DSControl
	def initialize(block, expression)
		super()
		@block = block
		@expression = expression
		consume 1 + block.getConsumed + 1 + expression.getConsumed + 1
	end
	def self.parse tokens
		dbgElementsTokens "DSDo.parse", tokens
		if tokens[0].eql?("do")
			consumed = 1
			block = DSBlock.parse(tokens[consumed..-1], [ "while" ])
			if block.isValid and tokens[consumed + block.getConsumed].eql?("(")
				consumed += block.getConsumed + 1
				expression = DSExpression.parse(tokens[consumed..-1])
				if expression.isValid
					element = DSDo.new(block, expression)
				else
					element = invalid()
				end
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		"do\n#{block.to_s}\nwhile(#{expression.to_s})"
	end
	def format(indent)
		s = "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s << "#{prefix(indent)}WHILE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}END DO WHILE\n"
	end
end

# DSSwitch ####################################################################################################


class DSSwitch < DSControl
	def initialize(expression, cases)
		super()
		@expression = expression
		@cases = cases
		consumed = 2 + expression.getConsumed + 1
		cases.each { |c| consumed += c.getConsumed }
		consumed += 1
		consume consumed
	end
	def self.parse tokens
		dbgElementsTokens "DSSwitch.parse", tokens
		if tokens[0].eql?("switch") and tokens[1].eql?("(")
			consumed = 2
			expression = DSExpression.parse(tokens[consumed..-1])
			if expression.isValid and tokens[consumed + expression.getConsumed].eql?(")")
				consumed += expression.getConsumed + 1
				cases = Array.new
				begin
					dscase = DSCase.parse(tokens[consumed..-1])
					if dscase.isValid
						cases.push(dscase)
						consumed += dscase.getConsumed
					else
						break
					end
				end while dscase.isValid and not tokens[consumed].eql?("end")
				if cases.size > 0 #and tokens[consumed].eql?("end")
					element = DSSwitch.new(expression, cases)
				else
					element = invalid()
				end
			else
				element = invalid
			end
		else
			element = invalid()
		end
		element
	end
	def to_s
		s = "switch(#{expression.to_s})\n"
		cases.each { |c| s << c.to_s << "\n" }
		s << "end"
		s
	end
	def format(indent)
		s = "#{prefix(indent)}SWITCH\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		@cases.each { |c| s << c.format(indent + 1) }
		s << "#{prefix(indent)}END SWITCH\n"
		s
	end
end

# DSCase ####################################################################################################

class DSCase < DSObject
	def initialize(expression, block, isDefault)
		super()
		@expression = expression
		@block = block
		consume 1 + (isDefault ? 1 : 2 + expression.getConsumed) + block.getConsumed
	end
	def self.parse tokens
		dbgElementsTokens "DSCase.parse", tokens
		if tokens[0].eql?("case")
			isDefault = false
			element = nil
			consumed = 1
			if tokens[1].eql?("default")
				isDefault = true
				consumed += 1
				expression = DSExpression.parse( [ "true" ] )
			elsif tokens[1].eql?("(")
				consumed += 1
				expression = DSExpression.parse(tokens[consumed..-1])
				if expression.isValid and tokens[consumed + expression.getConsumed].eql?(")")
					consumed += expression.getConsumed + 1
				else
					expression = nil
				end
			end
			if expression != nil
				block = DSBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid
					element = DSCase.new(expression, block, isDefault)
				else
					a=5/0
					element = invalid()
				end
			else
				a=5/0
				element = invalid()
			end
		else
			a=5/0
			element = invalid()
		end
		element
	end
	def to_s
		"case#{isDefault ? " default" : "(#{@expression.to_s})"}\n#{@block.to_s}\nend"
	end
	def format(indent)
		s = "#{prefix(indent)}CASE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s << "#{prefix(indent)}END CASE\n"
	end
end


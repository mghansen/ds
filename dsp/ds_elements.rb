$indentationLevel = 4

$logForElements = false

def logElements text
	puts ("E " + text) if $logForElements
end

def logElementsTokens(text, tokens)
	if $logForElements
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

# DspObject ####################################################################################################

class DspObject
	@@keywords = [ 
		"use", "new", "array", "of", "enum", "end", "class", "from", "step", "func", "true", "false", 
		"if", "else", "elsif", "for", "in", "do", "from", "to", "through", "while", "switch", "case" ]
	@@libraryFunctions = [ "return", "break", "continue" ]
		
	def initialize
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
		logElements "Default DspObject parse"
		invalid()
	end
	
	def evaluate
	end
	
	def self.invalid
		ret = DspObject.new
		ret.invalidate
		ret
	end
	
	#def to_s
	#	"X"
	#end
	
	def format(indent)
		"#{prefix(indent)}X\n"
	end
	
	def self.isName(name)
		/^[_a-zA-Z][_a-zA-Z0-9]*$/ =~ name
	end
	
	def self.isQName(name)
		/(^([_a-zA-Z])([_a-zA-Z0-9\.])*[_a-zA-Z0-9]$)|^([_a-zA-Z])$/ =~ name
	end
	
	def self.isNumber(number)
		/^\-?\d+(\.\d+)?$/ =~ number
	end
		
end

# DspDocument ####################################################################################################

class DspDocument < DspObject
	def initialize(name, statements)
		super()
		@name = name
		@statements = statements
	end
	
	def getName
		@name
	end
	
	def getStatements
		@statements
	end
	
	def self.parse tokens, filename
		logElementsTokens "DspDocument.parse", tokens
		statements = Array.new
		consumed = 0
		while (consumed < tokens.size - 1) do
			element = DspStatement.parse(tokens[consumed..-1])
			if element == nil
				logElementsTokens "DspDocument.parse", tokens
				return
			elsif !element.isValid
				logElementsTokens "DspDocument.parse", tokens
				return
			else
				statements.push(element)
				consumed += element.getConsumed
			end
		end
		document = DspDocument.new(filename, statements)
		document
	end
	
	def format(indent)
		output = ""
		output << "DOCUMENT \"#{@name}\"\n"
		@statements.each { |s| output << s.format(indent + 1) }
		output << "\n"
		output
	end
end

# Names ####################################################################################################

class DspName < DspObject
	def initialize (name)
		#logElements "DspName.initialize " + name
		super()
		@name = name
		consume 1
	end
	def getName
		@name
	end
	def self.parse tokens
		logElementsTokens "DspName.parse", tokens
		element = DspObject.isName(tokens[0]) ? DspName.new(tokens[0]) : invalid()
		element
	end
	def format(indent)
		@name
	end
		
	
end

class DspQName < DspName
	def initialize (name)
		#logElements "DspQName.initialize " + name
		super
		@name = name
	end
	def getName
		@name
	end
	def self.parse tokens
		logElementsTokens "DspQName.parse", tokens
		element = DspObject.isQName(tokens[0]) ? DspQName.new(tokens[0]) : invalid()
		element
	end
	def format(indent)
		"#{prefix(indent)}#{@name}\n"
	end
end

# DspStatement ####################################################################################################

class DspStatement < DspObject
	def initialize
		super
	end
	def self.parse tokens	
		logElementsTokens "DspStatement.parse", tokens
		
		if tokens[0].eql?("use")
			element = DspUse.parse(tokens)
		elsif ["enum", "class", "func", "var" ].include?(tokens[0])
			element = DspDeclaration.parse(tokens)
		elsif ["if", "for", "while", "do", "switch" ].include?(tokens[0])
			element = DspControl.parse tokens
		elsif [ "=", "+=", "-=", "*=", "/=" ].include?(tokens[1]) and DspObject.isQName(tokens[0])
			element = DspAssignment.parse(tokens)
		else
			element = DspExpression.parse(tokens)
		end
		element
	end
end

# DspBlock ####################################################################################################

class DspBlock < DspObject
	def initialize(statements, finalizingToken)
		super()
		@statements = statements
		@finalizingToken = finalizingToken
		consumed = 0
		@statements.each { |s| consumed += s.getConsumed() }
		consume consumed + 1 # + 1 is for finalizing token ("end")
	end
	
	def getStatements
		@statements
	end
	
	def self.parse(tokens, finalizingTokens)
		#logElements "DspBlock #{tokens.size} tokens"
		logElementsTokens "DspBlock.parse", tokens
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
					statement = DspStatement.parse(tokens[i..-1])
					statements.push(statement)
					i += statement.getConsumed()
				end
			end
			element = DspBlock.new(statements, finalizingToken)
		else
			element = invalid()
		end
		element
	end
	
	def format(indent)
		s = ""
		@statements.each { |statement| s << "#{statement.format(indent)}"}
		#s << "#{prefix(indent)}#{@finalizingToken}\n"
		s
	end
end

# DspUse ####################################################################################################

class DspUse < DspStatement
	def initialize (filename)
		super()
		@filename = filename
		consume 2
	end
	def getFilename
		@filename
	end
	def self.parse tokens
		logElementsTokens "DspUse.parse", tokens
		if tokens[0].eql? "use" and tokens.size > 1
			element = DspUse.new(tokens[1])
		end
		element
	end
	def format(indent)
		"#{prefix(indent)}USE #{@filename}\n"
	end
end

# DspAssignment ####################################################################################################

class DspAssignment < DspStatement
	def initialize(lValue, operator, rValue)
		super()
		@lValue = lValue
		@operator = operator
		@rValue = rValue
		consume (2 + @rValue.getConsumed)
	end
	def getLValue
		@lValue
	end
	def getOperator
		@operator
	end
	def getRValue
		@rValue
	end
	def self.parse tokens
		logElementsTokens "DspAssignment.parse", tokens
		rValue = DspExpression.parse(tokens[2..-1])
		if rValue.isValid
			element = DspAssignment.new(tokens[0], tokens[1], rValue)
		else
			element = invalid()
		end
		element
	end
	def format(indent)
		s = "#{prefix(indent)}ASSIGN #{@lValue} #{@operator}\n"
		s << @rValue.format(indent + 1)
		s << "#{prefix(indent)}END ASSIGN\n"
		s
	end
end

# DspDeclaration ####################################################################################################

class DspDeclaration < DspStatement
	def initialize
		super
	end
	def self.parse tokens
		logElementsTokens "DspDeclaration.parse", tokens
		element = invalid()
		if tokens[0].eql?("enum") and DspObject.isName(tokens[1]) and DspObject.isName(tokens[2])
			element = DspEnumDeclaration.parse(tokens)
		elsif tokens[0].eql?("class") and DspObject.isName(tokens[1]) and DspObject.isName(tokens[2]) # tokens[2] might be "from"
			element = DspClassDeclaration.parse(tokens)
		elsif tokens[0].eql?("func") and DspObject.isName(tokens[1]) and tokens[2].eql?("(")
			element = DspFunctionDeclaration.parse(tokens)
		elsif tokens[0].eql?("var") and DspObject.isName(tokens[1])
			element = DspVariableDeclaration.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

# DspVariableDeclaration ####################################################################################################

class DspVariableDeclaration < DspDeclaration
	def initialize(name)
		@name = name
		consume 2
	end
	def getName
		@name
	end
	def self.parse tokens
		logElementsTokens "DspDeclaration.parse", tokens
		if tokens[0].eql?("var") and DspObject.isName(tokens[1])
			element = DspVariableDeclaration.new(tokens[1])
		else
			element = invalid()
		end
		element
	end
	def format(indent)
		"#{prefix(indent)}VAR #{@name}\n"
	end
end

# DspEnumDeclaration ####################################################################################################

class DspEnumDeclaration < DspDeclaration
	def initialize(name, values)
		super()
		@name = name
		@values = values
		consume (2 + (@values.size * 2))
	end
	
	def getName
		@name
	end
	def getValues
		@values
	end

	def self.parse tokens
		logElementsTokens "DspEnumDeclaration.parse", tokens
		if tokens[0].eql?("enum") and DspObject.isName(tokens[1])
			name = tokens[1]
			values = Array.new
			consumed = 1
			first = true
			valid = true
			while not tokens[consumed].eql?("end") do
				if (first or tokens[consumed].eql?(","))
					if DspObject.isName(tokens[consumed + 1])
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
				element = DspEnumDeclaration.new(name, values)
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

# DspClassDeclaration ####################################################################################################

class DspClassDeclaration < DspDeclaration
	def initialize(name, baseClass, block)
		super()
		@name = name
		@baseClass = baseClass
		@block = block
		consume (2 + (@baseClass.size > 0 ? 2 : 0) + @block.getConsumed)
	end
	
	def getName
		@name
	end
	def getBaseClass
		@baseClass
	end
	def getStatements
		@block.getStatements
	end
	
	def self.parse tokens
		logElements "DspClassDeclaration.parse"
		if tokens[0].eql?("class") and DspObject.isName(tokens[1])
			name = tokens[1]
			consumed = 2
			if tokens[consumed].eql?("from") and DspObject.isName(tokens[consumed + 1])
				from = tokens[consumed + 1]
				consumed += 2
			else
				from = ""
			end
			block = DspBlock.parse(tokens[consumed..-1], [ "end" ])
			if block.isValid
				element = DspClassDeclaration.new(name, from, block)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
	def format(indent)
		s = "#{prefix(indent)}CLASS #{@name}#{@baseClass.size > 0 ? " FROM #{@baseClass}" : ""}\n"
		s << "#{@block.format(indent + 1)}"
		s << "#{prefix(indent)}END CLASS\n"
	end
end

# DspFunctionDeclaration ####################################################################################################

class DspFunctionDeclaration < DspDeclaration
	
	def initialize(name, params, block)
		super()
		@name = name
		@params = params
		@block = block
		consume 3 + (params.size > 0 ? params.size * 2 : 1) + block.getConsumed()
	end
	
	def getName
		@name
	end
	
	def getParams
		@params
	end
	
	def getStatements
		@block.getStatements
	end
	
	def self.parse tokens
		logElementsTokens "DspFunctionDeclaration.parse", tokens
		if(tokens[0].eql?("func") and DspObject.isName(tokens[1]) and tokens[2].eql?("("))
			name = tokens[1]
			params = Array.new
			consumed = 3

			if tokens[consumed].eql?(")")
				consumed += 1
				# logElements "NO PARAMS consumed=#{consumed}"
			else
				# logElementsTokens "DspFunctionDeclaration.parse params start", tokens[consumed..-1]
				while not tokens[consumed - 1].eql?(")") do
					# logElementsTokens "DspFunctionDeclaration.parse params", tokens[consumed..-1]
					if DspObject.isName(tokens[consumed]) and ([ ",", ")" ].include?(tokens[consumed + 1]))
						params.push(tokens[consumed])
						# logElements "PARAMETER #{tokens[consumed]}"
						consumed += 2
					else
						logElements "DspFunctionDeclaration.parse error reading parameters"
						break
					end
				end
				# logElements "END LOOP consumed=#{consumed}"
			end

			# logElementsTokens "DspFunctionDeclaration.parse starting block", tokens[consumed..-1]
			block = DspBlock.parse(tokens[consumed..-1], [ "end" ])
			if block.isValid
				element = DspFunctionDeclaration.new(name, params, block)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
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

# DspExpression ####################################################################################################

class DspExpression < DspStatement
	def initialize
		super
	end
	def self.parse tokens
		logElementsTokens "DspExpression.parse", tokens
		
		if tokens[0].eql?("(")
			# logElements "EXPRESSION GROUPED EXPRESSION"
			element = DspExpression.parse(tokens[1..-1])
			if tokens[element.getConsumed + 1].eql?(")")
				element.consume(element.getConsumed + 2)
			else
				element = invalid()
			end
		elsif tokens[0].eql?("!")
			logElements "UNARY OPERATOR"
			element = DspOperation.parse(tokens, nil)
		elsif DspObject.isNumber(tokens[0])
			logElements "EXPRESSION NUMBER"
			element = DspNumber.parse(tokens)
		elsif /^\"/ =~ tokens[0]
			# logElements "EXPRESSION STRING"
			element = DspString.parse(tokens)	
		elsif /^true|false$/ =~ tokens[0]
			# logElements "EXPRESSION BOOL"
			element = DspBool.parse(tokens)
		elsif tokens[0].eql?("nil")
			logElements "NIL"
			# TODO: Concept of nil
		elsif DspObject.isQName(tokens[0]) and not @@keywords.include?(tokens[0])
			if tokens[1].eql?("(")
				# logElements "EXPRESSION FUNCTION CALL"
				element = DspFunctionCall.parse(tokens)
			else
	 			# logElements "EXPRESSION VARIABLE NAME"
				element = DspQName.parse(tokens)
			end
		else
			# logElements "EXPRESSION OTHER"
			element = invalid()
		end
		
		if element.isValid and DspOperation.isOperator(tokens[element.getConsumed])
			# logElements "EXPRESSION OPERATION"
			element = DspOperation.parse(tokens, element)
		end
		
		element
	end
end

# DspConstant ####################################################################################################

class DspConstant < DspExpression
	def initialize
		super
		@value = nil
	end
	def getValue
		@value
	end
	def self.parse tokens
		super
	end
	def format(indent)
		super
	end
end

class DspNumber < DspConstant
	def initialize(value)
		super()
		if value.include? '.'
			@value = value.to_f
		else
			@value = value.to_i
		end
		logElements "DspNumber.init value=#{@value}"
		consume 1
	end
	def self.makeDspNumberFromValue(value)
		logElements "DspNumber.makeDspNumberFromValue value=#{value}"
		item = DspNumber.new("0")
		item.setValue(value)
		logElements "DspNumber.makeDspNumberFromValue newvalue=#{item.getValue}"
		item
	end
	def getValue
		@value
	end
	def setValue(value)
		@value = value
	end
	def self.parse tokens
		logElements "DspNumber.parse"
		element = DspNumber.new(tokens[0])
		element
	end
	def format(indent)
		"#{prefix(indent)}#{@value.to_s}\n"
	end
end

class DspString < DspConstant
	def initialize(value)
		super()
		@value = value
		consume 1
	end
	def self.parse tokens
		element = DspString.new(tokens[0])
		element
	end
	def format(indent)
		"#{prefix(indent)}#{@value.to_s}\n"
	end
end

class DspBool < DspConstant
	def initialize(value)
		super()
		@value = value
		consume 1
	end
	def self.parse tokens
		element = DspBool.new(tokens[0].eql?("true"))
	end
	def format(indent)
		#"#{prefix(indent)}#{@value.to_s}\n"
		"#{prefix(indent)}#{@value ? "TRUE" : "FALSE"}\n"
	end
end

# DspOperation ####################################################################################################

class DspOperation < DspExpression
	@@arithmeticOperators = [ "+", "-", "*", "/", "." ]
	@@logicalOperators = [ "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
	@@unaryOperators = [ "!" ]
	
	def initialize(firstExpression, operator, secondExpression)
		super()
		@firstExpression = firstExpression
		@operator = operator
		@secondExpression = secondExpression
		
		if @firstExpression != nil
			logElements "DspNumber.initialize first expression is valid"
			consume @firstExpression.getConsumed + 1 + @secondExpression.getConsumed
		else
			logElements "DspNumber.initialize first expression is not valid"
			consume 1 + @secondExpression.getConsumed
		end
	end
	def getFirstExpression
		@firstExpression
	end
	def getOperator
		@operator
	end
	def getSecondExpression
		@secondExpression
	end
	def self.parse(tokens, firstExpression)
		logElementsTokens "DspOperation.parse", tokens
		
		element = invalid()
		
		if @@unaryOperators.include?(tokens[0])
			logElements "DspNumber.parse unary operator"
			operator = tokens[0]
			secondExpression = DspExpression.parse(tokens[1..-1])
			if secondExpression.isValid
				logElements "DspNumber.parse second expression is valid"
				element = DspOperation.new(firstExpression, operator, secondExpression)
			end
		else
			operator = tokens[firstExpression.getConsumed]
			if DspOperation.isOperator(operator)
				secondExpression = DspExpression.parse(tokens[(firstExpression.getConsumed + 1)..-1])
				if secondExpression.isValid
					element = DspOperation.new(firstExpression, operator, secondExpression)
				end
			end
		end
		element
	end
	def self.isOperator(token)
		@@logicalOperators.include?(token) or @@arithmeticOperators.include?(token)
	end
	def format(indent)
		s = "#{prefix(indent)}OPERATION\n"
		if @firstExpression != nil
			s << @firstExpression.format(indent + 1)
		end
		s << "#{prefix(indent)}#{@operator}\n"
		s << @secondExpression.format(indent + 1)
		s << "#{prefix(indent)}END OPERATION\n"
		s
	end
	
end 

# DspFunctionCall ####################################################################################################

class DspFunctionCall < DspExpression
	def initialize(name, params)
		# logElements "DspFunctionCall.initialize"
		# TODO: Put parsing logic into parse and not in initialize at all !!!!!!!!!!!!!!!!!!!
		super()
		@name = name
		@params = params
		#logElementsTokens "FUNCTION " << name

		consumed = 2
		if @params.size == 0
			consumed += 1
		else
			@params.each { |p| consumed += p.getConsumed + 1 }
		end
		consume consumed
	end
	def getName
		@name
	end
	def getParams
		@params
	end
	def self.parse tokens
		logElementsTokens "&&& DspFunctionCall.parse", tokens
		if not DspObject.isQName(tokens[0]) or @@keywords.include?(tokens[0]) or not tokens[1].eql?("(")
			element = invalid()
		else
			logElementsTokens "&&& DspFunctionCall.parse 1", tokens
			consumed = 2
			params = Array.new
			i = consumed
			while i < tokens.size do
				logElementsTokens "DspFunctionCall.parse", tokens[i..-1]
				if tokens[i].eql?(")")
					logElementsTokens "&&& DspFunctionCall.parse 2", tokens
					consumed += 1
					break
				elsif tokens[i].eql?(",")
					consumed += 1
					i += 1
				else
					logElementsTokens "&&& DspFunctionCall.parse 4", tokens
					param = DspExpression.parse(tokens[i..-1])
					params.push(param) if param.isValid
					consumed += param.getConsumed()
					i += param.getConsumed()
				end				
			end
			element = DspFunctionCall.new(tokens[0], params)
		end
		element
	end
	def format(indent)
		s = "#{prefix(indent)}CALL #{@name}\n"
		@params.each { |p| s << p.format(indent + 1) }
		return s
	end
	
end

# DspControl ####################################################################################################

class DspControl < DspStatement
	def initialize
		super
	end
	def self.parse tokens
		logElementsTokens "DspControl.parse", tokens
		if tokens[0].eql?("if")
			element = DspIf.parse(tokens)
		elsif tokens[0].eql?("for") and DspObject.isName(tokens[1])
			element = DspFor.parse(tokens)
		elsif tokens[0].eql?("while") and tokens[1].eql?("(")
			element = DspWhile.parse(tokens)
		elsif tokens[0].eql?("do")
			element = DspDo.parse(tokens)
		elsif tokens[0].eql?("switch")
			element = DspSwitch.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

# DspIf ####################################################################################################

class DspIf < DspControl
	def initialize(conditions)
		super()
		@conditions = conditions
		consumed = 0
		@conditions.each { |c| consumed += c.getConsumed }
		consumed += 1 # end
		consume consumed
	end
	def getConditions
		@conditions
	end
	def self.parse tokens
		logElementsTokens "DspIf.parse", tokens
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
			
				condition = DspCondition.parse tokens[consumed..-1]
				if condition.isValid
					conditions.push(condition)
					consumed += condition.getConsumed
				end
				
				if tokens[consumed].eql?("end")
					break
				end
				
			end while(condition.isValid)
			
			if conditions.size > 0 and tokens[consumed].eql?("end")
				element = DspIf.new(conditions)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
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

# DspCondition ####################################################################################################

class DspCondition < DspObject
	def initialize(conditionType, expression, block)
		logElements "DspCondition.initialize"
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
	end
	def getConditionType
		@conditionType
	end
	def getExpression
		@expression
	end
	def getStatements
		@block.getStatements
	end
	def self.parse tokens
		logElementsTokens "DspCondition.parse", tokens
		isElse = tokens[0].eql?("else")
		if (["if", "elsif"].include?(tokens[0]) and tokens[1].eql?("(")) or isElse
			if isElse
				expression = DspExpression.parse( ["true" ] )
				block = DspBlock.parse(tokens[1..-1], ["end"])
				if block.isValid
					element = DspCondition.new(tokens[0], expression, block)
				else
					element = invalid()
				end
			else
				consumed = 2
				expression = DspExpression.parse(tokens[consumed..-1])
				if expression.isValid and tokens[consumed + expression.getConsumed].eql?(")")
					consumed += expression.getConsumed + 1
					block = DspBlock.parse(tokens[consumed..-1], ["elsif", "else", "end"])
					if block.isValid
						element = DspCondition.new(tokens[0], expression, block)
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
	def format(indent)
		s =  "#{prefix(indent)}#{@conditionType}\n"
		s << "#{@expression.format(indent)}"
		s << "#{@block.format(indent + 1)}"
		s
	end	
end

# DspFor ####################################################################################################

class DspFor < DspControl
	def initialize(variant, block)
		super()
		@variant = variant
		@block = block
		# consume in child class
	end
	def getVariant
		@variant
	end
	def getStatements
		@block.getStatements
	end
	def self.parse tokens
		logElementsTokens "DspFor.parse", tokens
		if tokens[0].eql?("for") and DspObject.isName(tokens[1])
			if tokens[2].eql?("in") and DspObject.isQName(tokens[3])
				element = DspForIn.parse(tokens)
			elsif tokens[2].eql?("from")
				element = DspForFrom.parse(tokens)
			else
				element = invalid()
			end
		else
			element = invalid()
		end
		element
	end
end

# DspForIn ####################################################################################################

class DspForIn < DspFor
	def initialize(variant, set, block)
		super(variant, block)
		@set = set
		consume 4 + block.getConsumed()
	end
	def getSet
		@set
	end
	def self.parse tokens
		logElementsTokens "DspForIn.parse", tokens
		variant = tokens[1]
		set = tokens[3]
		block = DspBlock.parse(tokens[4..-1], [ "end" ])
		if block.isValid
			element = DspForIn.new(variant, set, block)
		else
			element = invalid()
		end
		element
	end
	def format(indent)
		s = "#{prefix(indent)}FOR #{@variant} IN #{@set}\n"
		s << @block.format(indent + 1)
		s = "#{prefix(indent)}END FOR IN\n"
		s
	end
end

# DspForFrom ####################################################################################################

class DspForFrom < DspFor
	def initialize(variant, startExpression, endExpression, stepExpression, excludeLastItem, block)
		super(variant, block)
		@startExpression = startExpression
		@endExpression = endExpression
		@stepExpression = stepExpression
		@excludeLastItem = excludeLastItem
		toConsume = 3 + startExpression.getConsumed() + 1 + endExpression.getConsumed() + block.getConsumed()
		if @stepExpression != nil
			toConsume += 1 + @stepExpression.getConsumed
		end
		consume toConsume
	end
	def getStartExpression
		@startExpression
	end
	def getEndExpression
		@endExpression
	end
	def getStepExpression
		@stepExpression
	end
	def getExcludeLastItem
		@excludeLastItem
	end
	def self.parse tokens
		logElementsTokens "DspForFrom.parse", tokens
		variant = tokens[1]
		consumed = 3
		stepExpression = nil
		startExpression = DspExpression.parse(tokens[consumed..-1])
		if startExpression.isValid and 
				(tokens[consumed + startExpression.getConsumed].eql?("to") or
				tokens[consumed + startExpression.getConsumed].eql?("through"))
			if tokens[consumed + startExpression.getConsumed].eql?("to")
				excludeLastItem = true
			else
				excludeLastItem = false
			end
			consumed += startExpression.getConsumed + 1
			endExpression = DspExpression.parse(tokens[consumed..-1])
			if endExpression.isValid
				consumed += endExpression.getConsumed
				if tokens[consumed].eql?("step")
					consumed += 1
					stepExpression = DspExpression.parse(tokens[consumed..-1])
					if stepExpression.isValid
						consumed += stepExpression.getConsumed
					else
						# not valid step expression
					end
				end
				block = DspBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid
					element = DspForFrom.new(variant, startExpression, endExpression, stepExpression, excludeLastItem, block)
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
	def format(indent)
		s = "#{prefix(indent)}FOR #{@variant}\n"
		s << "#{prefix(indent + 1)}FROM\n#{@startExpression.format(indent + 2)}"
		s << "#{prefix(indent + 1)}#{@excludeLastItem ? "TO" : "THROUGH"}\n#{@endExpression.format(indent + 2)}"
		if @stepExpression != nil
			s << "#{prefix(indent + 1)}STEP\n#{@stepExpression.format(indent + 2)}"
		end
		s << "#{prefix(indent + 1)}BODY\n"
		s << @block.format(indent + 2)
		s << "#{prefix(indent)}END FOR FROM\n"
		s
	end
end

# DspWhile ####################################################################################################

class DspWhile < DspControl
	def initialize(expression, block)
		super()
		@expression = expression
		@block = block
		consume 2 + expression.getConsumed + 1 + block.getConsumed
	end
	def getExpression
		@expression
	end
	def getStatements
		@block.getStatements
	end
	def self.parse tokens
		logElementsTokens "DspWhile.parse", tokens
		if tokens[0].eql?("while") and tokens[1].eql?("(")
			consumed = 2
			expression = DspExpression.parse(tokens[2..-1])
			if expression.isValid and tokens[2 + expression.getConsumed()].eql?(")")
				consumed += expression.getConsumed + 1
				block = DspBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid()
					element = DspWhile.new(expression, block)				
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
	def format(indent)
		s = "#{prefix(indent)}WHILE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s
	end
end

# DspDo ####################################################################################################

class DspDo < DspControl
	def initialize(block, expression)
		super()
		@block = block
		@expression = expression
		consume 1 + block.getConsumed + 1 + expression.getConsumed + 1
	end
	def getExpression
		@expression
	end
	def getStatements
		@block.getStatements
	end
	def self.parse tokens
		logElementsTokens "DspDo.parse", tokens
		if tokens[0].eql?("do")
			consumed = 1
			block = DspBlock.parse(tokens[consumed..-1], [ "while" ])
			if block.isValid and tokens[consumed + block.getConsumed].eql?("(")
				consumed += block.getConsumed + 1
				expression = DspExpression.parse(tokens[consumed..-1])
				if expression.isValid
					element = DspDo.new(block, expression)
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
	def format(indent)
		s = "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s << "#{prefix(indent)}WHILE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}END DO WHILE\n"
	end
end

# DspSwitch ####################################################################################################


class DspSwitch < DspControl
	def initialize(expression, cases)
		super()
		@expression = expression
		@cases = cases
		consumed = 2 + expression.getConsumed + 1
		cases.each { |c| consumed += c.getConsumed }
		consumed += 1
		consume consumed
	end
	def getExpression
		@expression
	end
	def getCases
		@cases
	end
	def self.parse tokens
		logElementsTokens "DspSwitch.parse", tokens
		if tokens[0].eql?("switch") and tokens[1].eql?("(")
			consumed = 2
			expression = DspExpression.parse(tokens[consumed..-1])
			if expression.isValid and tokens[consumed + expression.getConsumed].eql?(")")
				consumed += expression.getConsumed + 1
				cases = Array.new
				begin
					dscase = DspCase.parse(tokens[consumed..-1])
					if dscase.isValid
						cases.push(dscase)
						consumed += dscase.getConsumed
					else
						break
					end
				end while dscase.isValid and not tokens[consumed].eql?("end")
				if cases.size > 0 #and tokens[consumed].eql?("end")
					element = DspSwitch.new(expression, cases)
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
	def format(indent)
		s = "#{prefix(indent)}SWITCH\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		@cases.each { |c| s << c.format(indent + 1) }
		s << "#{prefix(indent)}END SWITCH\n"
		s
	end
end

# DspCase ####################################################################################################

class DspCase < DspObject
	def initialize(expression, block, isDefault)
		super()
		@expression = expression
		@block = block
		consume 1 + (isDefault ? 1 : expression.getConsumed) + block.getConsumed
	end
	def getExpression
		@expression
	end
	def getStatements
		@block.getStatements
	end
	def self.parse tokens
		logElementsTokens "DspCase.parse", tokens
		if tokens[0].eql?("case")
			isDefault = false
			element = nil
			consumed = 1
			if tokens[1].eql?("default")
				isDefault = true
				consumed += 1
				expression = DspExpression.parse( [ "true" ] )
			else
				#consumed += 1
				expression = DspExpression.parse(tokens[consumed..-1])
				if expression.isValid
					consumed += expression.getConsumed
				else
					expression = nil
				end
			end
			if expression != nil
				block = DspBlock.parse(tokens[consumed..-1], [ "end" ])
				if block.isValid
					element = DspCase.new(expression, block, isDefault)
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
	def format(indent)
		s = "#{prefix(indent)}CASE\n"
		s << @expression.format(indent + 1)
		s << "#{prefix(indent)}DO\n"
		s << @block.format(indent + 1)
		s << "#{prefix(indent)}END CASE\n"
	end
end


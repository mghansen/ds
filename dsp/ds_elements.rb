# def consume(n) consumed += n

$verboseElements = true

def dbgElements text
	puts text if $verboseElements
end
def dbgElementsTokens(text, tokens)
	if tokens == nil or tokens.size == 0
		puts "#{text} []"
	else
		puts "#{text} [ #{tokens[0]} #{tokens[1]} #{tokens[2]} #{tokens[3]} #{tokens[4]} ]" if $verboseElements
	end
end

# DSObject ####################################################################################################

class DSObject
	@@keywords = [ 
		"use", "new", "array", "of", "enum", "end", "class", "from", "func", "true", "false", "return", 
		"if", "else", "elsif", "for", "in", "do", "from", "to", "while", "switch", "case" ]
	
	def initialize
		@id = ""
		@consumed = 1
		@valid = true
		@error = 0
		consume 1 # yes, redundant
	end
	
	def err
		if @error == 0
			return false
		else
			return true
		end
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
		puts "Default DSObject parse"
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
	
	def self.isName(name)
		/([\w&&\D])\w*/ =~ name
		#puts "\"#{name}\" IS NAME? #{ret ? "TRUE" : "FALSE"}"
	end
	
	def self.isNumber(number)
		/^\-?\d+(\.\d+)?$/ =~ number
	end
		
end

# Names ####################################################################################################

class Alphanumeric
end

class DSName < DSObject
	def initialize (name)
		@name = name
	end
	def self.parse tokens
		dbgElementsTokens "DSName.parse", tokens
		super
	end
	def to_s
		@name
	end
	
end

class VarName < DSName
	def initialize (text)
		super
	end
	def self.parse tokens
		super
	end
end

class FunctionName < DSName
	def initialize (text)
		super
	end
	def self.parse tokens
		super
	end
end

class ClassName < DSName
	def initialize (text)
		super
	end
	def self.parse tokens
		super
	end
end

class EnumName < DSName
	def initialize (text)
		super
	end
	def self.parse tokens
		super
	end
end

class FileName < DSName
	def initialize (text)
		super
	end
	def self.parse tokens
		super
	end
end

# Document ####################################################################################################

class Document < DSObject
	def initialize
		@DSUse = Array.new
		@DSStatement = Array.new
	end
	def self.parse tokens
		super
	end
end

# DSStatement ####################################################################################################

class DSStatement < DSObject
	def initialize
		super
	end
	def self.parse tokens	
		dbgElementsTokens "DSStatement.parse", tokens
		
		#DSObject.isName(tokens[0])
		#puts "ASSIGN OPERATOR" if [ "=", "+=", "-=", "*=", "/=" ].include?(tokens[1])
		#puts "YEAH, IT'S A NAME" if DSObject.isName(tokens[0])
		
		if tokens[0].eql?("use")
			dbgElements "USE"
			element = DSUse.parse(tokens)
		elsif ["enum", "class", "func" ].include?(tokens[0])
			element = DSDeclaration.parse(tokens)
		elsif ["if", "for", "while", "do", "switch" ].include?(tokens[0])
			element = DSControl.parse tokens
		elsif [ "=", "+=", "-=", "*=", "/=" ].include?(tokens[1]) and DSObject.isName(tokens[0])
			element = DSAssignment.parse(tokens)
		else
			dbgElements "EXPRESSION"
			element = DSExpression.parse(tokens)
		end
		#dbgElements "STATEMENT END"
		element
	end
	def to_s
		"X"
	end
end

# DSBlock ####################################################################################################

class DSBlock < DSObject
	def initialize statements
		super()
		@statements = statements
		consumed = 0
		statements.each { |s| consumed += s.getConsumed() }
		consume consumed + 1 # + 1 is for "end"
	end
	
	def self.parse(tokens, finalizingTokens)
		#puts "DSBlock #{tokens.size} tokens"
		dbgElementsTokens "DSBlock.parse", tokens
		statements = Array.new
		i = 0
		if tokens != nil and tokens.size > 0
			while i < tokens.size() do
				# Don't include finalizing token here. The caller will look for it (to support else cases)
				if(finalizingTokens.include?(tokens[i]))
					break
				else
					statement = DSStatement.parse(tokens[i..-1])
					statements.push(statement)
					i += statement.getConsumed()
				end
			end
			element = DSBlock.new(statements)
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
		"use #{@filename}"
	end
end

# DSAssignment ####################################################################################################

class DSAssignment < DSStatement
	def initialize(lValue, operation, tokens)
		super()
		@lValue = lValue
		@operation = operation
		@rValue = DSExpression.parse(tokens)
		consume 2 + @rValue.getConsumed()
	end
	def self.parse tokens
		dbgElementsTokens "DSAssignment.parse", tokens
		element = DSAssignment.new(tokens[0], tokens[1], tokens[2..-1])
		element
	end
	def to_s
		"#{@lValue} #{@operation} #{@rValue}"
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
			#element = DSEnumDeclaration.parse(tokens)
		elsif tokens[0].eql?("class") and DSObject.isName(tokens[1]) and DSObject.isName(tokens[2]) # tokens[2] might be "from"
			#element = DSClassDeclaration.parse(tokens)
		elsif tokens[0].eql?("func") and DSObject.isName(tokens[1]) and tokens[2].eql?("(")
			element = DSFunctionDeclaration.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

class DSEnumDeclaration < DSDeclaration
	def initialize
		super
		@enumValue = Array.new
		# numeric value?
	end
	def self.parse tokens
		dbgElementsTokens "DSEnumDeclaration.parse", tokens
		dbgElements "DSEnumDeclaration.parse"
		super
	end
end

class DSEnumValue < DSName
	def initialize
		super
	end
	def self.parse tokens
		super
	end
end

class DSClassDeclaration < DSDeclaration
	def initialize
		super
		@baseClass = ""
		@functions = Array.new
		@members = Array.new
	end
	def self.parse tokens
		dbgElements "DSClassDeclaration.parse"
		super
	end
end

# DSFunctionDeclaration ####################################################################################################

class DSFunctionDeclaration < DSDeclaration
	def initialize(name, tokens)
		#dbgElements "DSFunctionDeclaration.initialize"
		dbgElementsTokens "DSFunctionDeclaration.initialize tokens:", tokens
		
		super()
		@name = name
		@params = Array.new
		consumed = 3
		
		@params = Array.new
		#dbgElements "DSFunctionDeclaration.initialize tokens.each"
		tokens[consumed..-1].each do |t| 
			consumed += 1
			if t.eql?(")")
				#puts "PARAM END"
				break
			elsif t != ","
				#puts "PARAM NORMAL"
				@params.push(t)
				dbgElements ">>> #{t}"
			else
				# comma
			end
		end
		#dbgElements "DSFunctionDeclaration.initialize calling block has #{@params.size} parameters."
		
		dbgElements "DSFunctionDeclaration.initialize calling block, #{consumed} consumed"
		#dbgElementsTokens("DSFunctionDeclaration Tokens", tokens)
		blockTokens = tokens[consumed..-1]
		dbgElementsTokens("DSFunctionDeclaration BlockTokens", blockTokens)
		dbgElements "DSFunctionDeclaration #{blockTokens.size} tokens"

		@block = DSBlock.parse(blockTokens, [ "end" ])
		consumed += @block.getConsumed()
		consume consumed
	end
	
	def self.parse tokens
		puts "DSFunctionDeclaration #{tokens.size} tokens"
		dbgElementsTokens "DSFunctionDeclaration.parse", tokens
		if(tokens[0].eql?("func") and DSObject.isName(tokens[1]) and tokens[2].eql?("("))
			dbgElements "DSFunctionDeclaration.parse before DSFunctionDeclaration.new"
			element = DSFunctionDeclaration.new(tokens[1], tokens)#[3..-1])
			dbgElements "DSFunctionDeclaration.parse after DSFunctionDeclaration.new"
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
end

# DSExpression ####################################################################################################

class DSExpression < DSStatement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSExpression.parse", tokens
		
		if DSObject.isNumber(tokens[0])
			element = DSNumber.parse(tokens)
		elsif /^\"/ =~ tokens[0]
			element = DSString.parse(tokens)	
		elsif /^true|false$/ =~ tokens[0]
			element = DSBool.parse(tokens)
		else
			# TODO: More cases for operations, comparisons, etc.
			element = invalid()
		end
		element
	end
end

class DSConstant < DSExpression
	def initialize
		super
	end
	def self.parse tokens
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
		element = DSNumber.new(tokens[0])
		element
	end
	def to_s
		@value.to_s
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
		@value ? "true" : "false"
	end
end

class DSVariable < DSExpression
	def initialize
		@constant = nil
		super
	end
	def self.parse tokens
		super
	end
end

class DSOperation < DSExpression
	@logicalOperators = [ "+", "-", "*", "/", "." ]
	@arithmeticOperators = [ "!", "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
	def initialize
		@firstExpression = nil
		@operator = nil
		@secondExpression = nil
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSOperation.parse", tokens
		super
	end
end 

class DSControl < DSStatement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "DSControl.parse", tokens
		super
	end
end

class DSIf < DSControl
	def initialize
		super
		@conditionIf = Nil
		@conditionElse = Array.new
	end
	def self.parse tokens
		dbgElementsTokens "DSIf.parse", tokens
		super
	end
end

class DSCondition
	def initialize
		super
		@expression = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSCondition.parse", tokens
		super
	end
end

class DSFor < DSControl
	def initialize
		super
		@variant = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSFor.parse", tokens
		super
	end
end

class DSForIn < DSFor
	def initialize
		super
		@target = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSForIn.parse", tokens
		super
	end
end

class DSForFrom < DSFor
	def initialize
		super
		@first = nil
		@last = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSForFrom.parse", tokens
		super
	end
end

class DSWhile < DSControl
	def initialize
		super
		@expression = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSWhile.parse", tokens
		super
	end
end

class DSDo < DSControl
	def initialize
		super
		@block = nil
		@expression = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSDo.parse", tokens
		super
	end
end

class DSSwitch < DSControl
	def initialize
		super
		@expression = nil
		@cases = nil
	end
	def self.parse tokens
		dbgElementsTokens "DSSwitch.parse", tokens
		super
	end
end

class DSCase < DSObject
	def initialize
		super
		@expression
		@block
	end
	def self.parse tokens
		dbgElementsTokens "DSCase.parse", tokens
		super
	end
end

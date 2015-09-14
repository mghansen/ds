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
		@Use = Array.new
		@Statement = Array.new
	end
	def self.parse tokens
		super
	end
end

# Statement ####################################################################################################

class Statement < DSObject
	def initialize
		super
	end
	def self.parse tokens	
		dbgElementsTokens "Statement.parse", tokens
		if tokens[0].eql?("use")
			dbgElements "USE"
			element = Use.parse(tokens)
		elsif ["enum", "class", "func" ].include?(tokens[0])
			element = Declaration.parse(tokens)
		elsif ["if", "for", "while", "do", "switch" ].include?(tokens[0])
			element = Control.parse tokens
		elsif tokens[1] == '='
			element = Assignment.parse(tokens)
		else
			element = Expression.parse(tokens)
		end
		dbgElements "STATEMENT END"
		element
	end
	def to_s
		"X"
	end
end

# Block ####################################################################################################

class Block < DSObject
	def initialize statements
		super()
		@statements = statements
		consumed = 0
		statements.each { |s| consumed += s.getConsumed() }
		consume consumed
	end
	
	def self.parse(tokens, finalizingTokens)
		puts "Block #{tokens.size} tokens"
		dbgElementsTokens "Block.parse", tokens
		statements = Array.new
		i = 0
		if tokens != nil and tokens.size > 0
			while i < tokens.size() do
				# Don't include finalizing token here. The caller will look for it (to support else cases)
				if(finalizingTokens.include?(tokens[i]))
					break
				else
					statement = Statement.parse(tokens[i..-1])
					statements.push(statement)
					i += statement.getConsumed()
				end
			end
			element = Block.new(statements)
		else
			element = invalid()
		end
		element
	end
	def to_s
		@statements.each { |statemenet| s << statemenet.to_s << "\n" }
		s
	end
end

# Use ####################################################################################################

class Use < Statement
	def initialize (filename)
		super()
		@filename = filename
		consume 2
	end
	def self.parse tokens
		dbgElementsTokens "Use.parse", tokens
		if tokens[0].eql? "use" and tokens.size > 1
			element = Use.new(tokens[1])
		end
		element
	end
	def to_s
		"use " + @filename
	end
end

# Assignment ####################################################################################################

class Assignment < Statement
	def initialize
		super
		@lValue = ""
		@rValue = nil
	end
	def self.parse tokens
		dbgElementsTokens "Assignment.parse", tokens
		super
	end
end

# Declaration ####################################################################################################

class Declaration < Statement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "Declaration.parse", tokens
		element = invalid()
		if tokens[0].eql?("enum")
			#element = EnumDeclaration.parse(tokens)
		elsif tokens[0].eql?("class")
			#element = ClassDeclaration.parse(tokens)
		elsif tokens[0].eql?("func")
			element = FunctionDeclaration.parse(tokens)
		else
			element = invalid()
		end
		element
	end
end

class EnumDeclaration < Declaration
	def initialize
		super
		@enumValue = Array.new
		# numeric value?
	end
	def self.parse tokens
		dbgElementsTokens "EnumDeclaration.parse", tokens
		dbgElements "EnumDeclaration.parse"
		super
	end
end

class EnumValue < DSName
	def initialize
		super
	end
	def self.parse tokens
		super
	end
end

class ClassDeclaration < Declaration
	def initialize
		super
		@baseClass = ""
		@functions = Array.new
		@members = Array.new
	end
	def self.parse tokens
		dbgElements "ClassDeclaration.parse"
		super
	end
end

# FunctionDeclaration ####################################################################################################

class FunctionDeclaration < Declaration
	def initialize(name, tokens)
		dbgElements "FunctionDeclaration.initialize"
		dbgElementsTokens "FunctionDeclaration.initialize tokens:", tokens
		
		super()
		@name = name
		@params = Array.new
		consumed = 3
		
		@params = Array.new
		dbgElements "FunctionDeclaration.initialize tokens.each"
		tokens.each do |t| 
			consumed += 1
			if t.eql?(")")
				puts "PARAM END"
				break
			elsif t != ","
				puts "PARAM NORMAL"
				@params.push(t)
				puts ">>> #{t}"
			else
				puts "PARAM COMMA"
				#dbgElements "FunctionDeclaration.initialize Consuming comma"				
			end
		end
		#dbgElements "FunctionDeclaration.initialize calling block has #{@params.size} parameters."
		
		dbgElements "FunctionDeclaration.initialize calling block"
		blockTokens = tokens[consumed..-1]
		puts "FunctionDeclaration #{blockTokens.size} tokens"

		@block = Block.parse(blockTokens, [ "end" ])
		consumed += @block.getConsumed()
		consume consumed
	end
	
	def self.parse tokens
		puts "FunctionDeclaration #{tokens.size} tokens"
		dbgElementsTokens "FunctionDeclaration.parse", tokens
		puts "#{tokens.size} tokens"
		if(tokens[0].eql?("func") && tokens[2].eql?("("))
			dbgElements "FunctionDeclaration.parse before FunctionDeclaration.new"
			element = FunctionDeclaration.new(tokens[1], tokens[3..-1])
			dbgElements "FunctionDeclaration.parse after FunctionDeclaration.new"
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

# Expression ####################################################################################################

class Expression < Statement
	def initialize
		dbgElements "Expression.initialize"
		super
	end
	def self.parse tokens
		dbgElementsTokens "Expression.parse", tokens
		element = Expression.new
		element
	end
end

class Constant < Expression
	def initialize
		super
	end
	def self.parse tokens
		super
	end
end

class DSNumber < Constant
	def initialize
		super
		@value = 0
	end
	def self.parse tokens
		super
	end
end

class DSString < Constant
	def initialize
		super
		@value = ""
	end
	def self.parse tokens
		super
	end
end

class DSBool < Constant
	def initialize
		super
		@value = false
	end
	def self.parse tokens
		super
	end
end

class Variable < Expression
	def initialize
		@constant = nil
		super
	end
	def self.parse tokens
		super
	end
end

class Operation < Expression
	@logicalOperators = [ "+", "-", "*", "/", "." ]
	@arithmeticOperators = [ "!", "<", "<=", "==", ">", ">=", "&&", "||", "^" ]
	def initialize
		@firstExpression = nil
		@operator = nil
		@secondExpression = nil
		super
	end
	def self.parse tokens
		dbgElementsTokens "Operation.parse", tokens
		super
	end
end 

class Control < Statement
	def initialize
		super
	end
	def self.parse tokens
		dbgElementsTokens "Control.parse", tokens
		super
	end
end

class If < Control
	def initialize
		super
		@conditionIf = Nil
		@conditionElse = Array.new
	end
	def self.parse tokens
		dbgElementsTokens "If.parse", tokens
		super
	end
end

class Condition
	def initialize
		super
		@expression = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "Condition.parse", tokens
		super
	end
end

class For < Control
	def initialize
		super
		@variant = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "For.parse", tokens
		super
	end
end

class ForIn < For
	def initialize
		super
		@target = nil
	end
	def self.parse tokens
		dbgElementsTokens "ForIn.parse", tokens
		super
	end
end

class ForFrom < For
	def initialize
		super
		@first = nil
		@last = nil
	end
	def self.parse tokens
		dbgElementsTokens "ForFrom.parse", tokens
		super
	end
end

class While < Control
	def initialize
		super
		@expression = nil
		@block = nil
	end
	def self.parse tokens
		dbgElementsTokens "While.parse", tokens
		super
	end
end

class Do < Control
	def initialize
		super
		@block = nil
		@expression = nil
	end
	def self.parse tokens
		dbgElementsTokens "Do.parse", tokens
		super
	end
end

class Switch < Control
	def initialize
		super
		@expression = nil
		@cases = nil
	end
	def self.parse tokens
		dbgElementsTokens "Switch.parse", tokens
		super
	end
end

class Case < DSObject
	def initialize
		super
		@expression
		@block
	end
	def self.parse tokens
		dbgElementsTokens "Case.parse", tokens
		super
	end
end

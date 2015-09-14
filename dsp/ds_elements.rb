
# DSObject ####################################################################################################

class DSObject
	attr_reader :consumed
	
	@@keywords = 
			[ "use", "enum", "end", "class", "from", "func", "true", "false", "return", "if", "else", "elsif", 
				"for", "in", "do", "from", "to", "while", "switch", "case" ]
	
	def initialize
		@name = ""
		@consumed = 1
		@valid = true
		@error = 0
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
		
end



# Names ####################################################################################################

class Alphanumeric
end

class DSName < DSObject
	def initialize
		@text = ""
	end
	def setName name
		@text = name
	end
	def getName
		@text
	end
end

class VarName < DSName
	def initialize
		super
	end
end

class FunctionName < DSName
	def initialize
		super
	end
end

class ClassName < DSName
	def initialize
		super
	end
end

class EnumName < DSName
	def initialize
		super
	end
end

class FileName < DSName
	def initialize
		super
	end
end

# Document ####################################################################################################

class Document < DSObject
	def initialize
		@Use = Array.new
		@Statement = Array.new
	end
end

# Statement ####################################################################################################

class Statement < DSObject
	def initialize
		super
	end
	
	def self.parse tokens	
		if tokens[0].eql?("use")
			puts "USE"
			element = Use.parse(tokens)
		elsif ["enum", "class", "func" ].include?(tokens[0])
			puts "DECLARATION"
			element = Declaration.parse tokens
			puts "after Declaration.parse"
			consume 3
		elsif ["if", "for", "while", "do", "switch" ].include?(tokens[0])
			puts "CONTROL"
			element = Control.parse tokens
			consume 4
		elsif tokens[1] == '='
			puts "ASSIGNMENT"
			element = Assignment.parse tokens
			consume 3
		else
			puts "EXPRESSION"
			element = Expression.parse tokens
			consume 1
		end
		element
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
		if tokens[0].eql? "use" and tokens.size > 1
			element = Use.new(tokens[1])
		end
		element
	end
end

class Assignment < Statement
	def initialize
		super
		@lValue = ""
		@rValue = nil
	end
end

class Declaration < Statement
	def initialize
		super
		puts "class Declaration initialize"
	end
	def self.parse tokens
		invalid()
	end
end

class EnumDeclaration < Declaration
	def initialize
		@enumValue = Array.new
		# numeric value?
		super
	end
end

class EnumValue < DSName
	def initialize
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
end

class FunctionDeclaration < Declaration
	@params = Array.new
	@block = nil
	def initialize
		super
	end
end

class Expression < Statement
	def initialize
		super
	end
end

class Constant < Expression
	def initialize
		super
	end
end

class DSNumber < Constant
	def initialize
		super
		@value = 0
	end
end

class DSString < Constant
	def initialize
		super
		@value = ""
	end
end

class DSBool < Constant
	def initialize
		super
		@value = false
	end
end

class Variable < Expression
	def initialize
		@constant = nil
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
end 

class Control < Statement
	def initialize
		super
	end
end

class If < Control
	def initialize
		super
		@conditionIf = Nil
		@conditionElse = Array.new
	end
end

class Condition
	def initialize
		super
		@expression = nil
		@block = nil
	end
end

class For < Control
	def initialize
		super
		@variant = nil
		@block = nil
	end
end

class ForIn < For
	def initialize
		super
		@target = nil
	end
end

class ForFrom < For
	def initialize
		super
		@first = nil
		@last = nil
	end
end

class While < Control
	def initialize
		super
		@expression = nil
		@block = nil
	end
end

class Do < Control
	def initialize
		super
		@block = nil
		@expression = nil
	end
end

class Switch < Control
	def initialize
		super
		@expression = nil
		@cases = nil
	end
end

class Case < DSObject
	def initialize
		super
		@expression
		@block
	end
end

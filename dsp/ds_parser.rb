require 'forwardable'
require_relative 'ds_tokenizer'
require_relative 'ds_elements'

$verboseParser = true

def dbgParser text
	puts text if $verboseParser
end

# Parser ####################################################################################################

class Parser
	def initialize
		@tokenizer = Tokenizer.new
		@lineList = LineList.new
		@elements = Array.new
	end
	
	def loadFile(filename)
		input_file = File.new(filename, 'r')
		input_file.each_line { |line| @lineList.add(line) }
		input_file.close
	end
	
	def tokenize
		@tokenizer.tokenizeLines @lineList
		@tokenizer.showTokens
	end
	
	def parseAll
		dbgParser "PARSEALL START"
		tokenList = @tokenizer.getTokenList()
		i = 0
		while i < tokenList.getSize - 1 do
		
			tokens = tokenList.getFrom(i)
			element = Statement.parse tokens # TODO: More than one document
			if element == nil
				dbgParser "missing element, stopping... (#{tokens[0]} #{tokens[1]} #{tokens[2]} #{tokens[3]} #{tokens[4]})"
				return
			elsif !element.isValid
				dbgParser "invalid element, stopping... (#{tokens[0]} #{tokens[1]} #{tokens[2]} #{tokens[3]} #{tokens[4]})"
				return
			else
				dbgParser "> \"#{tokens[0]}...\" consumed #{element.consumed()}"
				@elements.push(element)
				i += element.consumed().to_i
			end
		end
		
	end
	
end

# LineList ####################################################################################################

class LineList

	def initialize
		@lines = Array.new
	end

	include Enumerable
	extend Forwardable
	def_delegators :@lines, :each, :<<
	
	def add(line)
		line.strip!
		@lines.push(line)
	end
	
end

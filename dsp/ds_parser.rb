require 'forwardable'
require_relative 'ds_tokenizer'
require_relative 'ds_elements'

$logForParser = false

def logParser text
	puts text if $logForParser
end

# Parser ####################################################################################################

class Parser
	def initialize
		@tokenizer = Tokenizer.new
		@lineList = LineList.new
		@document = ""
	end
	
	def loadFile(filename)
		@filename = filename
		input_file = File.new(filename, 'r')
		input_file.each_line { |line| @lineList.add(line) }
		input_file.close
	end
	
	def tokenize
		@tokenizer.tokenizeLines @lineList
		@tokenizer.combineClassNames
		@tokenizer.showTokens #if $verboseParser
	end
	
	def parseAll
		tokenList = @tokenizer.getTokenList()
		tokens = tokenList.getFrom(0)
		@document = DspDocument.parse(tokens, @input_filename)
		if @document.isValid
			indent = 0
			puts "Parsed file:"
			puts "#{@document.format(indent)}"
		else
			logParser "Document \"#{@filename}\" could not be parsed"
		end
	end
	
	def getDocument
		@document
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

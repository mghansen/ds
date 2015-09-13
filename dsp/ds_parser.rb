require 'forwardable'
require_relative 'ds_tokenizer'

# Parser ####################################################################################################

class Parser
	def initialize
		@tokenizer = Tokenizer.new
		@lineList = LineList.new
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

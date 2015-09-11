require 'forwardable'

# Parser ####################################################################################################

class Parser

	def initialize
		@lineList = LineList.new
		@tokenList = TokenList.new
		@currentIndex = 0
		@numConsumed = 0
	end
		
	def loadFile(filename)
		input_file = File.new(filename, 'r')
		input_file.each_line { |line| @lineList.add(line) }
		input_file.close
	end
	
	def tokenizeLines
		@lineList.each { |line| tokenizeLine(line) }
	end
	
	def tokenizeLine(line) 
		
		# Get array of CharDetails
		chars = Array.new
		line.split("").each do |c|
			details = CharDetails.new(c)
			chars.push(details)
		end
		# chars.each { |c| printf c.to_s }
		
		stateReady = 1
		stateInQuotes = 3
		stateInToken = 2
		state = stateReady
		token = ""
		skip = 0
		inNumber = false
		submission = ""

		chars.each_with_index do |item, index|
			#printf "#{index}: #{item.to_s}\n"
			
			if skip > 0
				skip -= 1
				next
			end

			if(index == 0)
				prev =  CharDetails.new(" ")
			else
				prev = chars[index - 1]
			end
			
			if(index < chars.size)
				after = chars[index + 1]
			else
				after = CharDetails.new(" ")
			end
			
			if state == stateReady
				if not item.isWhitespace
					combined = item.char + after.char
					if item.isQuote
						state = stateInQuotes
						token = ""
					elsif CharDetails::isDouble(combined)
						submission = combined
						skip = 1
					else
						state = stateInToken
						token = item.char
						if item.isDigit or item.char == '-' # -= already handled by isDouble
							inNumber = true
						end
					end
				end
				
			elsif state == stateInQuotes
				if item.isQuote or "\r\n".include?(item.char) # break on newline
					if(token.size > 0)
						submission = token
					end
					state = stateReady
				end
				
			elsif state == stateInToken
			
				if item.isWhitespace
					submission = token
				elsif item.isAlpha
					if prev.isAlpha or (prev.isDigit and not inNumber)
						token << item.char
					else
						submission = token
						token = item.char
					end
				elsif item.isDigit
					if not inNumber
						if prev.isAlpha or prev.isDigit
							token << item.char
						else
							submission = token
							token << item.char
						end
					else
						token << item.char
					end
				elsif item.isQuote
					submission = token
					token = ""
				elsif item.isPunctuation
					if item.char == '.' and inNumber
						token << item.char
					else
						submission = token
						token = item.char
					end
				else
						# nothing
				end
					
			end #state
			
			if submission.size
				@tokenList.add(submission)
				state = stateReady
				submission = ""
				inNumber = false
			end

		end # each
	end
	
	def getTokens()
		@tokenList
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

# TokenList ####################################################################################################

class TokenList

	def initialize
		@tokens = Array.new
	end
	
	include Enumerable
	extend Forwardable
	def_delegators :@tokens, :each, :<<
	
	def add(token)
		@tokens.push(token)
	end
	
	def to_s
		output = ""
		@tokens.each { |token| output << token + "\r\n" }
		output
	end
	
	def get(index)
		@tokens[index]
	end

end

# CharDetails ####################################################################################################

class CharDetails

	attr_reader :char, :isAlpha, :isDigit, :isWhitespace, :isPunctuation, :isQuote, :isOther

	@@alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
	@@digit = "0123456789"
	@@whitespace = " \t\n"
	@@punctuation = "()!<=>+-*/.,"
	@@doubles = [ "<<", "<=", "==", ">=", ">>", "&&", "||" ]
	
	def initialize(char)
		@char = char
		@isAlpha = @@alpha.include?(char)
		@isDigit = @@digit.include?(char)
		@isWhitespace = @@whitespace.include?(char)
		@isPunctuation = @@punctuation.include?(char)
		@isQuote = char == '"'
		@isOther = !isAlpha && !isDigit && !isWhitespace && !isPunctuation && !@isQuote
	end
	
	def to_s
		output = "-" + char if isAlpha
		output = "=" + char if isDigit
		output = "_" + char if isWhitespace
		output = "`" + char if isPunctuation
		output = "~" + char if isOther
		output
	end
	
	def self.isDouble(combined)
		@@doubles.include?(combined)
	end
		
end




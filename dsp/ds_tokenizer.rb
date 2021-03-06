require 'forwardable'

$logForLexer = false

def logLexer text
	puts text if $logForLexer
end

# Tokenizer ####################################################################################################

class Tokenizer

	@@stateNone = 0
	@@stateReady = 1
	@@stateInQuotes = 2
	@@stateInToken = 3	
	@@stateInComment = 4 
	
	def initialize
		@tokenList = TokenList.new
		@currentIndex = 0
		@inMultiLineComment = false
		@ignoreAll = false
	end
	
	def getTokenList()
		@tokenList
	end

	def getInMultiLineComment()
		@inMultiLineComment
	end

	def setInMultiLineComment(val)
		@inMultiLineComment = val
	end
	
	def tokenizeLines (linelist)
		linelist.each { |line| tokenizeLine(line) }
	end
	
	def combineClassNames
		@tokenList.combineClassNames
	end
	
	def tokenizeLine(line) 
	
		return if @ignoreAll
		logLexer "inMultiLineComment at start of function" if getInMultiLineComment()
		return if line.size == 0
		
		logLexer ":::::: #{line}"
		
		# Get array of CharDetails
		chars = Array.new
		line = line + ' '
		line.split("").each do |c|
			details = CharDetails.new(c)
			chars.push(details)
		end

		state = getInMultiLineComment() ? @@stateInComment : @@stateReady
		token = ""
		numCharsToSkip = 0
		inNumber = false
		seenDecimalPoint = false
		setOpenQuoteFlag = false
		submissions = []
		index = 0
		nextState = @@stateNone

		chars.each_with_index do |item, index|
			printf "#{'%03d' % index}:#{item.to_s}:" if $verboseTokenizer
			
			if numCharsToSkip > 0
				numCharsToSkip -= 1
				logLexer "\n"
				next
			end

			if(index == 0)
				prev = CharDetails.new(" ")
			else
				prev = chars[index - 1]
			end
			after = CharDetails.new(" ")
			if(index < chars.size - 1)
				after = chars[index + 1]
			end
			combined = "#{item.getChar()}#{after.getChar()}"

			if state == @@stateInComment
				if getInMultiLineComment()
					if CharDetails.isMultiLineCommentEnd(combined)
						logLexer "case ending multi line comment"
						setInMultiLineComment(false)
						state = @@stateReady
						numCharsToSkip = 1
					else
						logLexer "case not yet comment end"
					end
				else
					logLexer "case in comment but not multi-line"
				end
				
			elsif state == @@stateReady
				if not item.isWhitespace
					if item.isQuote
						logLexer "case starting new token and start with quotes"
						state = @@stateInQuotes
						token = ""
					elsif CharDetails.isDouble(combined)
						logLexer "case starting new token and start with double"
						submissions.push combined
						token = ""
						numCharsToSkip = 1
					else
						state = @@stateInToken
						token = item.char
						if item.isDigit or item.char.eql? '-' # -= already handled by isDouble
							logLexer "case starting new token and it's a number"
							inNumber = true
						else
							logLexer "case starting new token and it could be alpha, punctuation, or other"
						end
					end
				else
					logLexer "case whitespace"
					if token.size > 0
						submissions.push token
						token = ""
					end
				end
				
			elsif state == @@stateInQuotes
				logLexer "case already inside quotes"
				if item.isQuote or "\r\n".include?(item.char) # break on newline"
					if(token.size > 0)
						logLexer "case breaking quote on close quote or newline"
						submissions.push '"' + token + '"'
						token = ""
					else
						logLexer "case breaking quote on close quote or newline but the string was empty"
					end
					state = @@stateReady
				else
					logLexer "case inside quotes and we're still going"
					token << item.char
				end
				
			elsif state == @@stateInToken
				if item.isWhitespace
					logLexer "case this token just ended on whitespace"
					submissions.push token
					token = ""
				elsif item.isAlpha
					if prev.isAlpha or (prev.isDigit and not inNumber)
						logLexer "case alpha continuation of an alphanumeric"
						token << item.char
					else
						logLexer "case alpha breaking token after other"
						submissions.push token
						token = item.char
						nextState = @@stateInToken
					end
				elsif item.isDigit
					if not inNumber
						if prev.isAlpha or prev.isDigit
							logLexer "case digit continuation of an alphanumeric"
							token << item.char
						else
							logLexer "case digit breaking token after other"
							submissions.push token
							token = item.char
							nextState = @@stateInToken
						end
					else
						logLexer "case digit continuing a number"
						token << item.char
					end
				elsif item.isQuote
					logLexer "case open quote inside of a token"
					submissions.push token
					token = ""
					setOpenQuoteFlag = true
				elsif item.isPunctuation or item.isOther
					if item.char.eql? '.' and inNumber and not seenDecimalPoint and prev.isDigit
						logLexer "case first decimal point in number"
						token << item.char
						seenDecimalPoint = true
					elsif CharDetails.isDouble(combined)
						logLexer "case double breaks last token"
						submissions.push token
						submissions.push combined
						numCharsToSkip = 1
						token = ""						
					else
						logLexer "case other breaks last token"
						submissions.push token
						submissions.push item.char
						token = ""
					end
				else
					logLexer "case state is stateInToken but we sould never reach this case"
				end
				
			else
				logLexer "case unknown state"
			end #state
			
			submissions.each do |s|
				if s.size > 0
					if CharDetails.isSingleLineCommentStart s
						logLexer "     :case start single line comment\n"
						#printf"\n\n"
						return # no need to clear token or set state to @stateIsComment
					elsif CharDetails.isMultiLineCommentStart s
						setInMultiLineComment(true)
						logLexer "     :case start multi line comment"
						state = @@stateInComment
						numCharsToSkip = 1
					else
						puts "     >" + s if $verboseTokenizer
						if s.eql? "STOP_READING_HERE"
							@ignoreAll = true
							return
						end
						@tokenList.add(s)
						if nextState == @@stateNone
							state = @@stateReady
						else
							state = nextState
							nextState = @@stateNone
						end
					end
					inNumber = false
					seenDecimalPoint = false
				end
			end
			submissions.clear
			
			state == @@stateInQuotes if setOpenQuoteFlag
			setOpenQuoteFlag = false

		end # each
		
		logLexer "inMultiLineComment at end of function" if getInMultiLineComment()
	end
	
	def showTokens()
		#if $verboseTokenizer
			puts (@tokenList)
			printf "--------------------------------------------------------------------------------\n"
		#end
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
		@tokens.each do |t|
			#break if t.eql? "STOP"
			output << t != "%" ? "#{t}" : "%% "
			output << " "
		end
		#@tokens.each { |token| output << token + "\r\n" }
		output
	end
	
	def getFrom(index)
		@tokens[index..-1]
	end
	
	def getSize()
		@tokens.size
	end
	
	def combineClassNames
		tokens = @tokens
		newTokenList = Array.new
		i = 0
		cumulative = ""
		
		#dbgElementsTokens "TokenList.combineClassNames", tokens
		
		while i < tokens.size do
			prev = (i == 0 ? " " : tokens[i - 1])
			cur = tokens[i]
			after = ((i >= tokens.size - 1) ? " " : tokens[i + 1])
			if i == 0
				if DspObject.isName(cur)
					cumulative = cur
				else
					newTokenList.push(cur)
				end
			else
				if cur == '.'
					if cumulative.size == 0
						newTokenList.push(cur)
					else
						if DspObject.isName(after)
							cumulative << ".#{after}"
							i += 1
						else
							newTokenList.push(cumulative)
							newTokenList.push(cur)
							cumulative = ""
						end
					end
				elsif DspObject.isName(cur)
					if cumulative.size == 0
						cumulative << cur
					else
						newTokenList.push(cumulative)
						cumulative = cur
					end
				else
					if cumulative.size > 0
						newTokenList.push(cumulative)
						cumulative = ""
						newTokenList.push(cur)
					else
						newTokenList.push(cur)
					end
				end
			end
			i += 1
		end
		if(cumulative.size > 0)
			newTokenList.push(cur)
		end
		
		@tokens = newTokenList
		
		#s = ""
		#newTokenList.each { |t| s << "/#{t}/" }
		#s << "\n"
		#puts s
	end
	
end

# CharDetails ####################################################################################################

class CharDetails

	attr_reader :char, :isAlpha, :isDigit, :isWhitespace, :isPunctuation, :isQuote, :isOther

	@@alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
	@@digit = "0123456789"
	@@whitespace = " \t\r\n"
	@@punctuation = "()!<=>+-*/.,"
	@@doubles = [
		"<<", "<=", "==", ">=", ">>", "&&", "||", 
		"+=", "-=", "*=", "/=", 
		"\\\\", "\\r", "\\n", "//", "/*", "*/" ]
		
	# Currently, all comment indicators must have length 2
	@@singleLineCommentStart = [ "//" ]
	@@multiLineCommentStart = [ "/*" ]
	@@multiLineCommentEnd = [ "*/" ]
	
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
		char
	end
	
	def getChar ()
		char
	end
	
	def self.isSingleLineCommentStart(char)
		@@singleLineCommentStart.include?(char)
	end
	
	def self.isMultiLineCommentStart(char)
		@@multiLineCommentStart.include?(char)
	end

	def self.isMultiLineCommentEnd(char)
		@@multiLineCommentEnd.include?(char)
	end

	def self.isDouble(combined)
		@@doubles.include?(combined)
	end
		
end

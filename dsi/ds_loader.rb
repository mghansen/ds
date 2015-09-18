require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_context'

# Loader ####################################################################################################
#
# Creates context objects from the syntax objects in the parser

class Loader

	def initialize
		@globalContext = nil
	end
	
	def loadFile(filename)
		loadOneFile(filename)
		# TODO: Load more documents if we see the "use" directive
	end
	
	def loadOneFile(filename)
		parser = Parser.new
		parser.loadFile(filename)
		parser.tokenize
		parser.parseAll
		document = parser.getDocument
		
		loadContexts(document.getStatements)
	end

	def loadContexts(statements)
		@globalContext = loadGlobalContext(statements)
		# ...
	end

	def loadGlobalContext(statements)
		# Allowed in the global context are use, variable declaration, enum declaration, class declaration, function declaration
		context = DsiGlobalContext.new
		statements.each do |s|
			if s.is_a?(DSUse)
				name = new DsiUse(s.getFilename)
				context.addUse(name)
				
			elsif s.is_a?(DSVariableDeclaration)
				name = new DsiVar(s.getName)
				context.addVar(name)
				
			elsif s.is_a?(DSEnumDeclaration)
				name = s.getName
				values = s.getValues
				context.addEnum(name, values)
				
			elsif s.is_a?(DSClassDeclaration)
				item = loadClassContext(s)
				if item.isValid
					context.addClass(item)
				end
				
			elsif s.is_a?(DSClassDeclaration)
				item = loadFunctionContext(s)
				if item.isValid
					context.addFunction(item)
				end
			end
		end
		context
	end
	
	def loadClassContext(declaration)
		# Allowed in a class are variable declaration, function declaration
		name = declaration.getName
		baseClass = declaration.getBaseClass
		context = DsiFunctionContext.new(name, baseClass)
		
		declaration.getBlock.each do |s|
			if s.is_a?(DSVariableDeclaration)
				context.addVar(s.getName)
				
			elsif s.is_a?(DSFunctionDeclaration)
				item = loadFunctionContext(s)
				if item.isValid
					context.addFunction(item)
				end
			end
		end
		context
		
	end
	
	def loadFunctionContext(declaration)
		# Allowed in a function are variable declarations and instructions
		name = declaration.getName
		params = declaration.getParams
		context = DsiFunctionContext.new(name, params)
		
		instructions = Array.new
		# Includes actions (function calls, assignment, operations, other expressions),
		#          var declarations (which modify the context),
		#          control (if, for, while, do, switch, break, continue, return)
		
		declaration.getStatements.each do |statement|
			# parse statements into instructions
		end

		context.setInstructions(instructions)
		context
	end
	
end


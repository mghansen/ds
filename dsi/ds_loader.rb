require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_context'

# Loader ####################################################################################################

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
		context = Context.new
		statements.each do |s|
			if s.is_a>(DSUse)
				item = new DsiUse(s.getFilename)
				context.addUse(item)
				
			elsif s.is_a>(DSVariableDeclaration)
				item = new DsiVar(s.getName)
				context.addVar(item)
				
			elsif s.is_a>(DSEnumDeclaration)
				name = s.GetName
				values = s.GetValues
				item = new DsiEnum(name, values)
				context.addEnum(item)
				
			elsif s.is_a>(DSClassDeclaration)
				item = loadClassContext(s)
				context.addClass(item)
				
			elsif s.is_a>(DSClassDeclaration)
				item = loadFunctionContext(s)
				context.addFunction(item)
			end
		end
		context
	end
	
	def loadClassContext(DSClassDeclaration decl)
		# Allowed in a class are variable declaration, function declaration
		context = DsiFunctionContext.new
		context.name = decl.getName
		context.baseClass = decl.getBaseClass
		
		decl.getBlock.each do |s|
		
			if s.is_a>(DSVariableDeclaration)
				item = new DsiVar(s.getName)
				context.addVar(item)
				
			elsif s.is_a>(DSFunctionDeclaration)
				name = s.getName
				baseClass = s.getBaseClass
				statements = s.getBlock
				functionContext = new DsiFunctionContext(name, baseclass, statements)
				context.addFunction(item)
			end
		end
		context
		
	end
	
	def loadFunctionContext(globalContext, statements)
		# Allowed in a function are variable declarations and instructions
		context = context.new
		# ...
		context
	end
	
	

end

	
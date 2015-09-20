#TODO: Loader state pre-loads values

require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_context'

$verboseLoader = true

def debugLoader text
	puts text if $verboseLoader
end

# LoaderState ####################################################################################################

class LoaderState
	def initialize
		@@nextId = 1
		@variables = Array.new
		@constants = Array.new
	end
	
	def addVariable(name)
		found = false
		@variables.each do |v|
			if name.eql?(v.getName)
				found = true
				break
			end
		end
		if not found
			var = DsiVariable.new(name)
			@variables.push(var)
		end
	end
	
	def addConstant(value)
		# Value is loaded from constant each time the context loads
		# Don't bother checking for uniqueness here since the name is different for each call
		name = "0__const_#{@@nextId}"
		@@nextId += 1
		var = DsiConstantVariable.new(name, value)
		@constants.push(var)
		return name
	end
end

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
		# TODO: Move setup logic out of the context into this class
		context = DsiGlobalContext.new
		statements.each do |s|
			if s.is_a?(DSUse)
				debugLoader "Global context sees Use"
				name = new DsiUse(s.getFilename)
				context.addUse(name)
				
			elsif s.is_a?(DSVariableDeclaration)
				debugLoader "Global context sees Var"
				name = new DsiVar(s.getName) # TODO implement
				context.addVar(name)
				
			elsif s.is_a?(DSEnumDeclaration)
				debugLoader "Global context sees Enum"
				name = s.getName
				values = s.getValues
				context.addEnum(name, values)
				
			elsif s.is_a?(DSClassDeclaration)
				debugLoader "Global context sees Class"
				item = loadClassContext(s)
				if item.isValid
					context.addClass(item)
				end
				
			elsif s.is_a?(DSClassDeclaration)
				debugLoader "Global context sees Function"
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
		debugLoader "loadClassContext"
		name = declaration.getName
		baseClass = declaration.getBaseClass
		vars = Set.new
		functionContexts = Array.new
		
		declaration.getStatements.each do |s|
			debugLoader "Class context sees Var"
			if s.is_a?(DSVariableDeclaration)
				vars.push(s.getName)
				
			elsif s.is_a?(DSFunctionDeclaration)
			debugLoader "Class context sees Function"
				item = loadFunctionContext(s)
				if item.isValid
					functionContexts.addFunction(item)
				end
			end
		end
		
		context = DsiFunctionContext.new(name, baseClass)
		context
		
	end
	
	def loadFunctionContext(declaration)
		# Allowed in a function are variable declarations and instructions
		name = declaration.getName
		params = declaration.getParams
		instructions = Array.new
			# Includes actions (function calls, assignment, operations, other expressions),
			#          var declarations (which modify the context),
			#          control (if, for, while, do, switch, break, continue, return)
			
		loaderState = LoaderState.new
			
		instructions = processStatements(declaration.getStatements, loaderState)
		context = DsiFunctionContext.new(name, params, loaderState.getVars, instructions)
		context
	end

# Loader: process objects ####################################################################################################
	
	def processStatements(statements, loaderState)
		# parse statements into instructions
		newStatements = Array.new
		statements.each do |statement|
			if statement.is_a?(DSVariableDeclaration)
				loaderState.addVariable(statement.getName)
				
			elsif statement.is_a?(DSFunctionCall)
				item = processFunctionCall(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSAssignment)
				loaderState.addVariable(statement.getLValue)
				expression = processExpression(statement.getRValue, loaderState)
				item = DsiAssignment.new(statement.getLValue, statement.getOperator, expression)
				newStatements.push(item)
				
			elsif statement.is_a?(DSIf)
				item = processIf(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSForIn)
				item = processForIn(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSForFrom)
				item = processForFrom(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSWhile)
				item = processWhile(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSDo)
				item = processDo(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DSSwitch)
				item = processSwitch(statement, loaderState)
				newStatements.push(item)
				
			else
				debugLoader "Unrecognized statement"
			end
		end
		newStatements
	end
	
	def processFunctionCall(functionCall, processExpression)
		name = functionCall.getName		
		params = Array.new
		functionCall.getParams.each do |param|
			newParam = processExpression(param, processExpression)
			params.push(newParam)
		end
		item = DsiFunctionCall.new(name, params)
		item
	end
	
	def processIf(statement, loaderState)
		conditions = Array.new
		statement.getConditions.each do |c|
			condition = processCondition(c, processExpression)
			conditions.push(condition)
		end
		item = DsiIf.new(conditions)
		item
	end
	
	def processCondition(statement, loaderState)
		expression = processExpression(statement.getExpression, processExpression)
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiCondition.new(statement.getConditionType, expression, statements)
		item
	end
	
	def processForIn(statement, loaderState)
		loaderState.addVar(statement.getVariant)
		set = processSetstatement.getSet
		statements = processStatements(statement.getStatements, processExpression)
		item = DsiForIn.new(statement.getVariant, set, statements)
	end
	
	def processForFrom(statement, loaderState)
		loaderState.addVar(statement.getVariant)
		startExpression = processExpression(statement.getStartExpression, processExpression)
		endExpression = processExpression(statement.getEndExpression, processExpression)
		statements = processStatements(statement.getStatements, processExpression)
		item = DsiForFrom.new(statement.getVariant, startExpression, endExpression, statements)
		item
	end
	
	def processWhile(statement, loaderState)
		expression = processExpression(statemet.getExpression, processExpression)
		statements = processStatements(statement.getStatements, processExpression)
		item = DsiWhile.new(expresion, statements)
	end
	
	def processDo(statement, loaderState)
		statements = processStatements(statement.getStatements, processExpression)
		expression = processExpression(statemet.getExpression, processExpression)
		item = DsiDo.new(statements, expresion)
	end

	def processSwitch(statement, loaderState)
		expression = processExpression(statement.getExpression, processExpression)
		cases = Array.new
		statement.getCases.each do |c|
			caseExpression = processExpression(c.getExpression, processExpression)
			caseStatements = processStatements(c.getStatements, processExpression)
			newCase = DsiCase(caseExpression, caseStatemnts)
			cases.push(newCase)
		end
		item = DsiSwitch.new(expression, cases)
		item
	end
	
	def processExpression(expression, loaderState)

		# Expression
		if expression.is_a?(DSOperation)
			firstExpression = processExpression(expression.getFirstExpression)
			secondExpression = processExpression(expression.getSecondExpression)
			item = DsiOperation(firstExpression, expression.getOperator, secondExpression)
		
		elsif expression.is_a?(DSFunctionCall)
			item = processFunctionCall(expression)
			
		elsif expression.is_a?(DSConstant)
			if(expression.is_a?(DSNumber))
				varName = loaderState.addConstant(DsiNumberValue.new(expression.getValue))
			elsif(expression.is_a?(DSString))
				varName = loaderState.addConstant(DsiStringValue.new(expression.getValue))
			elsif(expression.is_a?(DSBool))
				varName = loaderState.addConstant(DsiBoolValue.new(expression.getValue))
			else
				varName = nil
			end
			if not varName == nil
				item = DsiVariable.new(varName)
			end
			
		elsif expression.is_a?(DSQName)
			item = DsiVariable.new(expression.name)

		else
			item = nil
		end
		
		item
	end
	
end


#		# What has expressions?
#		DSAssignment.@rValue
#		DSOperation.@firstExpression
#		DSOperation.secondExpression
#		DSCondition.@expression
#		DSForFrom.@startExpression
#		DSForFrom.@endExpression
#		DSWhile.@expression
#		DSDo.@expression
#		DSSwitch.@expression
#		DSCase.@expression
#		_return.@expression
#
#		DSFunctionCall.@params
#
#		# Types of expression
#		DSOperation
#		DSFunctionCall
#		DSNumber (end)
#		DSString (end
#		DSBool (end)

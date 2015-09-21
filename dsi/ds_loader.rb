#TODO: Loader state pre-loads values

require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_templates'
require_relative 'ds_runtime'

$verboseLoader = true

def debugLoader text
	puts text if $verboseLoader
end

# LoaderState ####################################################################################################

class LoaderState
	def initialize(stateName, parent)
		@@nextId = 1
		@variables = Array.new
		@constants = Array.new
		@parent = parent
		@stateName = stateName
	end
	
	def getVariables
		@variables
	end
	def getConstants
		@constants
	end
	
	def getNewChildState(name)
		state = LoaderState.new(name, self)
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
			var = DsiVariableName.new(name) # TODO: consistently add vars and constants
			@variables.push(var)
		end
	end
	
	def addConstant(value)
		# Value is loaded from constant each time the template loads
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
# Creates template objects from the syntax objects in the parser

class Loader

	def initialize
		@globalTemplate = nil
		@useDirectives = Array.new
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
		
		loadTemplates(document.getStatements)
	end

	def loadTemplates(statements)
		@globalTemplate = loadGlobalTemplate(statements)
		# ...
		# TODO: Load files listed with "new"
	end

	def loadGlobalTemplate(statements)
		# Allowed in the global template are use, variable declaration, enum declaration, class declaration, function declaration
		# TODO: Move setup logic out of the template into this class
		# TODO: Create state here, substates for classes and functions
		# TODO: Global assignments
		
		useDirectives = Array.new #
		vars = Array.new # Used to be Set
		enums = Array.new
		classTemplates = Array.new
		functionTemplates = Array.new
		globalState = LoaderState.new("GLOBAL", nil)

		statements.each do |s|
			if s.is_a?(DspUse)
				debugLoader "Global template sees Use"
				@useDirectives.push(name)
				
			# TODO: Separate out decl and assignment. The name confusion is crashing at runtime
			elsif s.is_a?(DspVariableDeclaration)
				debugLoader "Global template sees Var"
				found = false
				vars.each do |v|
					if v.getName.eql?(s.getName)
						found = true
						break
					end
				end
				if not found
					var = DsVariable.new(s.getName)
					vars.add(var)
				end
			
			elsif s.is_a?(DspAssignment) and s.getRValue.is_a?(DspConstant)
				debugLoader "Global template sees Assignment"
				found = false
				vars.each do |v|
					if v.getName.eql?(s.getName)
						found = true
						break
					end
				end
				if not found
					if s.is_a?(DspAssignment)
						var = DsVariable.new(s.getName)
						var.setValue(s.getValue)
					else
						var = DsVariable.new(s.getName)
					end
					vars.add(var)
				end
			
			elsif s.is_a?(DspEnumDeclaration)
				debugLoader "Global template sees Enum"
				name = s.getName
				values = s.getValues
				found = false
				enums.each do |e|
					if e.getName.eql?(name)
						found = true
						break
					end
				end
				if not fount
					enum = DsiEnum.new(name, values)
					enums.push(enum)
				end
				
			elsif s.is_a?(DspClassDeclaration)
				debugLoader "Global template sees Class"
				found = false
				classTemplates.each do |c|
					if c.getName.eql?(s.getName)
						found = true
						break
					end
				end
				if not found
					item = loadClassTemplate(s, globalState)
					if item.isValid
						classTemplates.push(item)
					end
				end
				
			elsif s.is_a?(DspFunctionDeclaration)
				debugLoader "Global template sees Function"
				found = false
				functionTemplates.each do |f|
					if f.getName.eql?(s.getName)
						found = true
						break;
					end
				end
				if not found
					item = loadFunctionTemplate(s, globalState, nil)
					if item.isValid
						functionTemplates.push(item)
					end
				end
			end
		end
		
		# Add constants and gloval vars
		
		template = DsiGlobalTemplate.new(vars, enums, classTemplates, functionTemplates)
		template
	end
	
	def loadClassTemplate(declaration, globalState)
		# Allowed in a class are variable declaration, function declaration
		debugLoader "loadClassTemplate"
		name = declaration.getName
		baseClass = declaration.getBaseClass
		vars = Array.new
		functionTemplates = Array.new
		
		classState = globalState.getNewChildState(name)
		
		declaration.getStatements.each do |s|
			debugLoader "Class template sees Var"
			if s.is_a?(DspVariableDeclaration)
				vars.push(s.getName)
				
			elsif s.is_a?(DspFunctionDeclaration)
				debugLoader "Class template sees Function"
				item = loadFunctionTemplate(s, globalState, classState)
				if item.isValid
					functionTemplates.push(item)
				end
			end
		end
		
		template = DsiClassTemplate.new(name, baseClass, vars, functionTemplates)
		template
	end
	
	def loadFunctionTemplate(declaration, globalState, classState)
		# Allowed in a function are variable declarations and instructions
		debugLoader "loadClassTemplate"
		name = declaration.getName
		params = declaration.getParams
		instructions = Array.new
			# Includes actions (function calls, assignment, operations, other expressions),
			#          var declarations (which modify the template),
			#          control (if, for, while, do, switch, break, continue, return)
			
		loaderState = LoaderState.new(name, (classState == nil) ? globalState : classState)
			
		instructions = processStatements(declaration.getStatements, loaderState)
		template = DsiFunctionTemplate.new(name, params, loaderState.getVariables, instructions)##
		if not classState == nil
			#template.setClassName(classState...
		end
		template
	end

# Loader: process objects ####################################################################################################
	
	def processStatements(statements, loaderState)
		# parse statements into instructions
		newStatements = Array.new
		statements.each do |statement|
			if statement.is_a?(DspVariableDeclaration)
				loaderState.addVariable(statement.getName)
				
			elsif statement.is_a?(DspFunctionCall)
				item = processFunctionCall(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspAssignment)
				loaderState.addVariable(statement.getLValue)
				expression = processExpression(statement.getRValue, loaderState)
				item = DsiAssignment.new(statement.getLValue, statement.getOperator, expression)
				newStatements.push(item)
				
			elsif statement.is_a?(DspIf)
				item = processIf(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspForIn)
				item = processForIn(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspForFrom)
				item = processForFrom(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspWhile)
				item = processWhile(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspDo)
				item = processDo(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspSwitch)
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
		expression = processExpression(statement.getExpression, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiCondition.new(statement.getConditionType, expression, statements)
		item
	end
	
	def processForIn(statement, loaderState)
		loaderState.addVar(statement.getVariant)
		set = processSetstatement.getSet
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiForIn.new(statement.getVariant, set, statements)
	end
	
	def processForFrom(statement, loaderState)
		loaderState.addVar(statement.getVariant)
		startExpression = processExpression(statement.getStartExpression, loaderState)
		endExpression = processExpression(statement.getEndExpression, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiForFrom.new(statement.getVariant, startExpression, endExpression, statements)
		item
	end
	
	def processWhile(statement, loaderState)
		expression = processExpression(statemet.getExpression, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiWhile.new(expresion, statements)
	end
	
	def processDo(statement, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		expression = processExpression(statemet.getExpression, loaderState)
		item = DsiDo.new(statements, expresion)
	end

	def processSwitch(statement, loaderState)
		expression = processExpression(statement.getExpression, loaderState)
		cases = Array.new
		statement.getCases.each do |c|
			caseExpression = processExpression(c.getExpression, loaderState)
			caseStatements = processStatements(c.getStatements, loaderState)
			newCase = DsiCase.new(caseExpression, caseStatements)
			cases.push(newCase)
		end
		item = DsiSwitch.new(expression, cases)
		item
	end
	
	def processExpression(expression, loaderState)

		# Expression
		if expression.is_a?(DspOperation)
			firstExpression = processExpression(expression.getFirstExpression, loaderState)
			secondExpression = processExpression(expression.getSecondExpression, loaderState)
			item = DsiOperation(firstExpression, expression.getOperator, secondExpression)
		
		elsif expression.is_a?(DspFunctionCall)
			item = processFunctionCall(expression)
			
		elsif expression.is_a?(DspConstant)
			if(expression.is_a?(DspNumber))
				varName = loaderState.addConstant(DsiNumberValue.new(expression.getValue))
			elsif(expression.is_a?(DspString))
				varName = loaderState.addConstant(DsiStringValue.new(expression.getValue))
			elsif(expression.is_a?(DspBool))
				varName = loaderState.addConstant(DsiBoolValue.new(expression.getValue))
			else
				varName = nil
			end
			if not varName == nil
				item = DsiVariableNanme.new(varName)
			end
			
		elsif expression.is_a?(DspQName)
			item = DsiVariableNanme.new(expression.getName)

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

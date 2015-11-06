#TODO: Loader state pre-loads values

require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_contexts'
require_relative 'ds_instructions'

$logForLoader = true

def logLoader text
	puts ("L " + text) if $logForLoader
end

# LoaderState ####################################################################################################

class DspVariable
	def initialize(name, value)
		@name = name
		@value = value
	end
	def getName
		@name
	end
	def getValue
		@value
	end
end

class LoaderState
	def initialize(stateName, parent)
		@@nextId = 1
		#@variableNames = Array.new
		@dsiVariables = Array.new
		#@stringTable = Array.new
		@parent = parent
		@stateName = stateName
	end
	
	def getName
		@stateName
	end
	
	def getVariables
		@dsiVariables
	end
	
	def makeNewChildState(name)
		state = LoaderState.new(name, self)
	end
	
	def self.translateDspValue(dspValue)
		logLoader "translateDspValue #{dspValue.getValue}"
		dsiValueOut = nil
		if dspValue.is_a?(DspNumber)
			logLoader "translateDspValue DspNumber #{dspValue.getValue}"
			dsiValueOut = DsiNumberValue.new(dspValue.getValue)
		elsif dspValue.is_a?(DspString)
			logLoader "translateDspValue DsiStringValue #{dspValue.getValue}"
			dsiValueOut = DsiStringValue.new(dspValue.getValue)
		elsif dspValue.is_a?(DspBool)
			logLoader "translateDspValue DsiStringValue #{dspValue.getValue}"
			dsiValueOut = DsiBoolValue.new(dspValue.getValue)
		#elsif dspValue.getValue.is_a?(DsiEnumValue)
		#	dsiValueOut = DsiEnumValue.new(dspValue.getValue)
		end
		dsiValueOut
	end
	
	def self.translateDspListToDsi(dspValues)
		dsiValues = Array.new
		dspValues.each do |v|
			dsiValues.push(translateDspValue(v))
		end
		dsiValues
	end

	def doesVariableExist?(name)
		found = false
		@dsiVariables.each do |v|
			if v.getName.eql?(name)
				found = true
				break
			end
		end
		found
	end
	
	def addEmptyVariable(name)
		logLoader "LoaderState.addEmptyVariable #{name}"
		parentHasVariable = false
		if @parent != nil and @parent.doesVariableExist?(name)
			logLoader "LoaderState.addEmptyVariable variable #{name} was found in the parent state"
			parentHasVariable = true
		end
		if not doesVariableExist?(name) and parentHasVariable == false
			@dsiVariables.push(DsiVariable.new(name, nil))
			logLoader "LoaderState.addEmptyVariable added #{name}"
		end
	end
	
	def addDspVariableIntoDsi(name, dspValue)
		logLoader "LoaderState.addDspVariableIntoDsi #{name}"
		if not doesVariableExist?(name)
			#logLoader "LoaderState.addDspVariableIntoDsi adding name #{name}"
			logLoader "LoaderState.addDspVariableIntoDsi DspValue=#{dspValue.getValue.to_s}"
			dsiValue = self.class.translateDspValue(dspValue)
			logLoader "LoaderState.addDspVariableIntoDsi DsiValue=#{dsiValue.to_s}"
			@dsiVariables.push(DsiVariable.new(name, dsiValue))#clonedValue))
			#logLoader "LoaderState.addDspVariableIntoDsi added value #{clonedValue.to_s}"
		end
	end
	
end

# Loader ####################################################################################################
#
# Creates context objects from the syntax objects in the parser

class Loader

	def initialize
		@globalContext = nil
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
		
		loadContexts(document.getStatements)
	end

	def loadContexts(statements)
		@globalContext = loadGlobalContext(statements)
		# ...
		# TODO: Load files listed with "new"
	end
	
	def getGlobalContext
		@globalContext
	end

	# --------------------------------------------------------------------------------
	
	def loadGlobalContext(statements)
		# Allowed in the global context are use, variable declaration, enum declaration, class declaration, function declaration
		# TODO: Move setup logic out of the context into this class
		# TODO: Create state here, substates for classes and functions
		# TODO: Global assignments
		
		useDirectives = Array.new #
		#variableNames = Array.new
		enums = Array.new
		classContexts = Array.new
		functionContexts = Array.new
		globalLoaderState = LoaderState.new("GLOBAL", nil)

		statements.each do |s|
			if s.is_a?(DspUse)
				#logLoader "Global context sees Use"
				@useDirectives.push(s.getFilename)
				
			# TODO: Separate out decl and assignment. The name confusion is crashing at runtime
			elsif s.is_a?(DspVariableDeclaration)
				#var = DsiVariable.new(s.getName)
				#globalLoaderState.addVariable(var) # vars.push(var)
				#globalLoaderState.addVariableName(s.getName)
				globalLoaderState.addDspVariableIntoDsi(s.getName, nil)
				
			elsif s.is_a?(DspAssignment)				
				logLoader "Global context sees Assignment"
				#globalLoaderState.addVariableName(s.getLValue)
				if s.getRValue.is_a?(DspConstant)
					logLoader "Global context Assignment constant"
					globalLoaderState.addDspVariableIntoDsi(s.getLValue, processConstant(s.getRValue))
				else
				end
				
			elsif s.is_a?(DspEnumDeclaration)
				logLoader "Global context sees Enum"
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
				logLoader "Global context sees Class"
				found = false
				classContexts.each do |c|
					if c.getName.eql?(s.getName)
						found = true
						break
					end
				end
				if not found
					item = loadClassContext(s, globalLoaderState)
					if item.isValid
						classContexts.push(item)
					end
				end
				
			elsif s.is_a?(DspFunctionDeclaration)
				logLoader "Global context sees Function"
				found = false
				functionContexts.each do |f|
					if f.getName.eql?(s.getName)
						found = true
						break;
					end
				end
				if not found
					item = loadFunctionContext(s, globalLoaderState, nil)
					if item.isValid
						functionContexts.push(item)
					end
				end
			end
		end
		
		# Add constants and global variableNames
		variables = globalLoaderState.getVariables
		context = DsiGlobalContext.new(variables, enums, classContexts, functionContexts)
		context
	end
	
	# --------------------------------------------------------------------------------

	def loadClassContext(declaration, globalLoaderState)
		# Allowed in a class are variable declaration, function declaration
		logLoader "loadClassContext"
		
		name = declaration.getName
		baseClass = declaration.getBaseClass
		variables = Array.new
		functionContexts = Array.new
		
		classState = globalLoaderState.makeNewChildState(name)
		
		declaration.getStatements.each do |s|
			logLoader "Class context sees Var"
			
			if s.is_a?(DspVariableDeclaration)
				dsiVariable = DsiVariable.new(s.getName, nil)
				variables.push(dsiVariable)
				
			elsif s.is_a?(DspAssignment)				
				logLoader "Class context sees Assignment"
				#globalLoaderState.addVariableName(s.getLValue)
				if s.getRValue.is_a?(DspConstant)
					logLoader "Global context Assignment constant"
					dsiVariable = DsiVariable.new(s.getLValue, processConstant(s.getRValue))
					variables.push(dsiVariable)
				end
				
			elsif s.is_a?(DspFunctionDeclaration)
				logLoader "Class context sees Function"
				item = loadFunctionContext(s, globalLoaderState, classState)
				if item.isValid
					functionContexts.push(item)
				end
			end
		end
		
		context = DsiClassContext.new(name, baseClass, variables, functionContexts)
		context
	end
	
	# --------------------------------------------------------------------------------

	def loadFunctionContext(declaration, globalLoaderState, classState)
		# Allowed in a function are variable declarations and instructions
		logLoader "loadFunctionContext #{declaration.getName}(#{declaration.getParams})"
		
		name = declaration.getName
		paramNames = declaration.getParams
		instructions = Array.new
			# Includes actions (function calls, assignment, operations, other expressions),
			#          var declarations (which modify the context),
			#          control (if, for, while, do, switch, break, continue, return)

		if not classState == nil
			name = "#{classState.getName()}.#{declaration.getName()}"
		end
		logLoader "loadFunctionContext with class name is #{declaration.getName}"
			
		loaderState = ((classState == nil) ? globalLoaderState : classState).makeNewChildState(name)
		instructions = processStatements(declaration.getStatements, loaderState)
		#context = DsiFunctionContext.new(name, paramNames, loaderState.getVariableNames, instructions)##
		logLoader "loadFunctionContext variables #{loaderState.getVariables.to_s}"

		context = DsiFunctionContext.new(name, paramNames, loaderState.getVariables, instructions)
		# TODO: Load variables?
		context
	end

	# Process objects --------------------------------------------------------------------------------

	def processStatements(statements, loaderState)
		logLoader "Loader.processStatements: #{statements.size} statements"
		# parse statements into instructions
		newStatements = Array.new
		statements.each do |statement|
		
			if statement.is_a?(DspVariableDeclaration)
				logLoader "Loader.processStatements declaration #{statement.getName}"
				loaderState.addDspVariableIntoDsi(statement.getName)
				
			elsif statement.is_a?(DspFunctionCall)
				logLoader "Loader.processStatements functionCall #{statement.getName}"
				item = processFunctionCall(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspAssignment)
				logLoader "Loader.processStatements assignment #{statement.getLValue} #{statement.getOperator}"
				#loaderState.addDspVariableIntoDsi(statement.getLValue, nil)
				loaderState.addEmptyVariable(statement.getLValue)
				
				rValue = nil
				if(statement.getRValue.is_a?(DspConstant))
					expression = LoaderState.translateDspValue(statement.getRValue)
				else
					expression = processExpression(statement.getRValue, loaderState)
				end
				logLoader "expression rValue #{expression.to_s}"
				#dsiRValue = LoaderState.translateDspValue(processConstant(s.getRValue))
				#globalLoaderState.addDspVariableIntoDsi(s.getLValue, dsiRValue)
				item = DsiAssignment.new(statement.getLValue, statement.getOperator, expression) # This is pushing a dps value but it should be dsi
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
				logLoader "Unrecognized statement"
			end
		end
		newStatements
	end
	
	def processFunctionCall(functionCall, loaderState)
		logLoader "$$$ processFunctionCall #{functionCall.getName}"
		name = functionCall.getName
		params = Array.new
		functionCall.getParams.each do |param|
			newParam = processExpression(param, loaderState)
			params.push(newParam)
		end
		item = DsiFunctionCall.new(name, params)
		item
	end
	
	def processIf(statement, loaderState)
		conditions = Array.new
		statement.getConditions.each do |c|
			condition = processCondition(c, loaderState)
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
		loaderState.addEmptyVariable(statement.getVariant)
		set = processSetstatement.getSet
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiForIn.new(statement.getVariant, set, statements)
	end
	
	def processForFrom(statement, loaderState)
		loaderState.addEmptyVariable(statement.getVariant)
		startExpression = processExpression(statement.getStartExpression, loaderState)
		endExpression = processExpression(statement.getEndExpression, loaderState)
		stepExpression = nil
		if statement.getStepExpression != nil
			#puts "ADDING STEP"
			stepExpression = processExpression(statement.getStepExpression, loaderState)
		end
		excludeLastItem = statement.getExcludeLastItem
		#puts "ADDING STATEMENTS"
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiForFrom.new(statement.getVariant, startExpression, endExpression, stepExpression, excludeLastItem, statements)
		item
	end
	
	def processWhile(statement, loaderState)
		expression = processExpression(statement.getExpression, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		item = DsiWhile.new(expression, statements)
	end
	
	def processDo(statement, loaderState)
		statements = processStatements(statement.getStatements, loaderState)
		expression = processExpression(statement.getExpression, loaderState)
		item = DsiDo.new(statements, expression)
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
	
	def processConstant(expression)
		#logLoader "processConstant"
		if(expression.is_a?(DspNumber))
			#logLoader "processConstant DspNumber  #{expression.getValue}"
			item = DspNumber.makeDspNumberFromValue(expression.getValue)
			#logLoader "processConstant DspNumber2 #{item.getValue}"
		elsif(expression.is_a?(DspString))
			#logLoader "processConstant DspString #{expression.getValue}"
			item = DspString.new(expression.getValue)
		elsif(expression.is_a?(DspBool))
			#logLoader "processConstant DspBool #{expression.getValue}"
			item = DspBool.new(expression.getValue)
		else
			logLoader "processConstant constant of unknown type"
		end
		item
	end
	
	def processExpression(expression, loaderState)

		# Expression
		if expression.is_a?(DspExpressionNew)
			logLoader "processExpression DspExpressionNew"
			item = DsiClassAlloc.new(expression.getClassName)
		elsif expression.is_a?(DspOperation)
			logLoader "processExpression DspOperation"
			if expression.getFirstExpression != nil
				firstExpression = processExpression(expression.getFirstExpression, loaderState)
			else
				firstExpression = nil
			end
			secondExpression = processExpression(expression.getSecondExpression, loaderState)
			item = DsiOperation.new(firstExpression, expression.getOperator, secondExpression)
		elsif expression.is_a?(DspFunctionCall)
			logLoader "processExpression DspFunctionCall"
			item = processFunctionCall(expression, loaderState)
		elsif expression.is_a?(DspConstant)
			logLoader "processExpression DspConstant"
			item = LoaderState.translateDspValue(expression)
		elsif expression.is_a?(DspQName)
			logLoader "processExpression DspQName"
			item = DsiVariable.new(expression.getName)
		else
			item = nil
		end
		item
	end
end

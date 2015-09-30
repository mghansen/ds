#TODO: Loader state pre-loads values

require_relative '../dsp/ds_parser'
require_relative '../dsp/ds_elements'
require_relative 'ds_templates'
require_relative 'ds_instructions'

$verboseLoader = true

def debugLoader text
	puts text if $verboseLoader
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
	
	def getVariables
		@dsiVariables
	end
	
	def makeNewChildState(name)
		state = LoaderState.new(name, self)
	end
	
	def self.translateDspValue(dspValue)
		debugState "translateDspValue #{dspValue.getValue}"
		dsiValueOut = nil
		if dspValue.is_a?(DspNumber)
			debugState "translateDspValue DspNumber #{dspValue.getValue}"
			dsiValueOut = DsiNumberValue.new(dspValue.getValue)
		elsif dspValue.is_a?(DspString)
			debugState "translateDspValue DsiStringValue #{dspValue.getValue}"
			dsiValueOut = DsiStringValue.new(dspValue.getValue)
		elsif dspValue.is_a?(DspBool)
			debugState "translateDspValue DsiStringValue #{dspValue.getValue}"
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
	
	def addDspVariableIntoDsi(name, dspValue)
		puts "LoaderState.addDspVariableIntoDsi #{name}"
		found = false
		@dsiVariables.each do |v|
			if v.getName.eql?(name)
				found = true
				break
			end
		end
		if not found
			#puts "LoaderState.addDspVariableIntoDsi adding name #{name}"
			puts "LoaderState.addDspVariableIntoDsi DspValue=#{dspValue.getValue.to_s}"
			dsiValue = self.class.translateDspValue(dspValue)
			puts "LoaderState.addDspVariableIntoDsi DsiValue=#{dsiValue.to_s}"
			@dsiVariables.push(DsiVariable.new(name, dsiValue))#clonedValue))
			#puts "LoaderState.addDspVariableIntoDsi added value #{clonedValue.to_s}"
		end
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
	
	def getGlobalTemplate
		@globalTemplate
	end

	def loadGlobalTemplate(statements)
		# Allowed in the global template are use, variable declaration, enum declaration, class declaration, function declaration
		# TODO: Move setup logic out of the template into this class
		# TODO: Create state here, substates for classes and functions
		# TODO: Global assignments
		
		useDirectives = Array.new #
		#variableNames = Array.new
		enums = Array.new
		classTemplates = Array.new
		functionTemplates = Array.new
		globalLoaderState = LoaderState.new("GLOBAL", nil)

		statements.each do |s|
			if s.is_a?(DspUse)
				debugLoader "Global template sees Use"
				@useDirectives.push(s.getFilename)
				
			# TODO: Separate out decl and assignment. The name confusion is crashing at runtime
			elsif s.is_a?(DspVariableDeclaration)
				#var = DsiVariable.new(s.getName)
				#globalLoaderState.addVariable(var) # vars.push(var)
				#globalLoaderState.addVariableName(s.getName)
				globalLoaderState.addDspVariableIntoDsi(s.getName, nil)
				
			elsif s.is_a?(DspAssignment)				
				debugLoader "Global template sees Assignment"
				#globalLoaderState.addVariableName(s.getLValue)
				if s.getRValue.is_a?(DspConstant)
					debugLoader "Global template Assignment constant"
					globalLoaderState.addDspVariableIntoDsi(s.getLValue, processConstant(s.getRValue))
				else
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
					item = loadClassTemplate(s, globalLoaderState)
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
					item = loadFunctionTemplate(s, globalLoaderState, nil)
					if item.isValid
						functionTemplates.push(item)
					end
				end
			end
		end
		
		# Add constants and global variableNames
		variables = globalLoaderState.getVariables
		template = DsiGlobalTemplate.new(variables, enums, classTemplates, functionTemplates)
		template
	end
	
	def loadClassTemplate(declaration, globalLoaderState)
		# Allowed in a class are variable declaration, function declaration
		debugLoader "loadClassTemplate"
		name = declaration.getName
		baseClass = declaration.getBaseClass
		variables = Array.new
		functionTemplates = Array.new
		
		classState = globalLoaderState.makeNewChildState(name)
		
		declaration.getStatements.each do |s|
			debugLoader "Class template sees Var"
			
			if s.is_a?(DspVariableDeclaration)
				dsiVariable = DsiVariable.new(s.getName, nil)
				variables.push(dsiVariable)
				
			elsif s.is_a?(DspAssignment)				
				debugLoader "Class template sees Assignment"
				#globalLoaderState.addVariableName(s.getLValue)
				if s.getRValue.is_a?(DspConstant)
					debugLoader "Global template Assignment constant"
					dsiVariable = DsiVariable.new(s.getLValue, processConstant(s.getRValue))
					variables.push(dsiVariable)
				else
				end
				
			elsif s.is_a?(DspFunctionDeclaration)
				debugLoader "Class template sees Function"
				item = loadFunctionTemplate(s, globalLoaderState, classState)
				if item.isValid
					functionTemplates.push(item)
				end
			end
		end
		
		template = DsiClassTemplate.new(name, baseClass, variableNames, functionTemplates)
		template
	end
	
	def loadFunctionTemplate(declaration, globalLoaderState, classState)
		# Allowed in a function are variable declarations and instructions
		debugLoader "loadFunctionTemplate #{declaration.getName}(#{declaration.getParams})"
		name = declaration.getName
		paramNames = declaration.getParams
		instructions = Array.new
			# Includes actions (function calls, assignment, operations, other expressions),
			#          var declarations (which modify the template),
			#          control (if, for, while, do, switch, break, continue, return)
			
		loaderState = ((classState == nil) ? globalLoaderState : classState).makeNewChildState(name)
		instructions = processStatements(declaration.getStatements, loaderState)
		#template = DsiFunctionTemplate.new(name, paramNames, loaderState.getVariableNames, instructions)##
		debugLoader "&&& loadFunctionTemplate variables #{loaderState.getVariables.to_s}"
		template = DsiFunctionTemplate.new(name, paramNames, loaderState.getVariables, instructions)
		if not classState == nil
			#template.setClassName(classState...
		end
		# TODO: Load variables?
		template
	end

# Loader: process objects ####################################################################################################

	def processStatements(statements, loaderState)
		puts "Loader.processStatements: #{statements.size} statements"
		# parse statements into instructions
		newStatements = Array.new
		statements.each do |statement|
		
			if statement.is_a?(DspVariableDeclaration)
				puts "Loader.processStatements declaration #{statement.getName}"
				loaderState.addDspVariableIntoDsi(statement.getName)
				
			elsif statement.is_a?(DspFunctionCall)
				puts "Loader.processStatements functionCall #{statement.getName}"
				item = processFunctionCall(statement, loaderState)
				newStatements.push(item)
				
			elsif statement.is_a?(DspAssignment)
				puts "Loader.processStatements assignment #{statement.getLValue} #{statement.getOperator}"
				#loaderState.addVariableName(statement.getLValue)
				rValue = nil
				if(statement.getRValue.is_a?(DspConstant))
					rValue = LoaderState.translateDspValue(statement.getRValue)
				end
				expression = processExpression(statement.getRValue, loaderState)
				puts "expression rValue #{expression.getValue}"
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
	
	def processConstant(expression)
		puts "processConstant"
		if(expression.is_a?(DspNumber))
			puts "processConstant DspNumber  #{expression.getValue}"
	#		item = DsiNumberValue.new(expression.getValue)
			item = DspNumber.makeDspNumberFromValue(expression.getValue)
			#item = LoaderState.translateDspValue(expression)
			puts "processConstant DspNumber2 #{item.getValue}"
		elsif(expression.is_a?(DspString))
			puts "processConstant DspString #{expression.getValue}"
	#		item = DsiStringValue.new(expression.getValue)
			item = DspString.new(expression.getValue)
		elsif(expression.is_a?(DspBool))
			puts "processConstant DspBool #{expression.getValue}"
	#		item = DsiBoolValue.new(expression.getValue)
			item = DspBool.new(expression.getValue)
		else
			puts "processConstant constant of unknown type"
		end
		item
	end
	
	def processExpression(expression, loaderState)

		# Expression
		if expression.is_a?(DspOperation)
			puts "processExpression DspOperation"
			firstExpression = processExpression(expression.getFirstExpression, loaderState)
			secondExpression = processExpression(expression.getSecondExpression, loaderState)
			item = DsiOperation.new(firstExpression, expression.getOperator, secondExpression)
		
		elsif expression.is_a?(DspFunctionCall)
			puts "processExpression DspFunctionCall"
			item = processFunctionCall(expression)
			
		elsif expression.is_a?(DspConstant)
			puts "processExpression DspConstant"
			#item = processConstant(expression)
			item = LoaderState.translateDspValue(expression)
			
		elsif expression.is_a?(DspQName)
			item = DsiVariable.new(expression.getName)

		else
			item = nil
		end
		
		item
	end
end

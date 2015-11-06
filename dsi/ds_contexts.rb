require 'set'
require_relative '../dsp/ds_elements'
require_relative 'ds_library'

$logForContexts = false

def logContext text
	puts (". " + text) if $logForContexts
end

$logForState = true

def logState text
	puts (". " + text) if $logForState
end

# Runtime states ####################################################################################################

class DsiRuntimeState
	attr_accessor :returnFlag
	def initialize(currentScopeName, variables, parentState, globalContext)
		@currentScopeName = currentScopeName
		@variables = variables
		@parentState = parentState
		@globalContext = globalContext
		@returnValue = nil # ?
		#logState "DsiRuntimeState.initialize variables.size #{variables.size}"
		logState "DsiRuntimeState.initialize variables=#{variables.to_s}"
		# TODO: deep copy of variables, default values
		@returnFlag = false
		@controlState = Array.new
	end

	def returning?
		@returnSignal ? true : false
	end
	def beginControlledSection
		@controlState.push(DsiControlState.new)
	end
	def endControlledSection
		@controlState.pop
	end
	def setBreak(value)
		return if @controlState.size == 0
		@controlState.last.breakFlag = value
	end
	def setContinue(value)
		return if @controlState.size == 0
		@controlState.last.continueFlag = value
	end
	def testBreak
		return false if @controlState.size == 0
		ret = @controlState.last.breakFlag
		@controlState.last.breakFlag = false
		return ret
	end
	def testContinue
		return false if @controlState.size == 0
		ret = @controlState.last.continueFlag
		@controlState.last.continueFlag = false
		return ret
	end	
	def testShouldLeave?
		return true if (@controlState.last.breakFlag || @controlState.last.continueFlag)
		return false
	end
	
	def getName
		@currentScopeName
	end

	def getGlobalContext
		@globalContext
	end
	
	def getClassContext(name)
		@globalContext.getClassContext(name)
	end
	
	def getFunctionContext(name)
		@globalContext.getFunctionContext(name)
	end	
	
	def getParentState
		@parentState
	end
	
	def getReturnValue
		@returnValue
	end
	def setReturnValue(value)
		@returnValue = value
	end	
	
	def getVariables
		@variables
	end

	def getVariable(name)
		#logState "DSIRUNTIMESTATE.getVariable #{@currentScopeName} :: #{name}"
		var = nil
		@variables.each do |v|
			if v.getName.eql?(name)
				var = v
				#logState "DsiRuntimeState.getVariable found local"
				break
			end
		end
		if var == nil and @parentState != nil
			var = @parentState.getVariable(name)
		end
		#logState "DsiRuntimeState.getVariable end"
		var
	end
	
	def isVariablePresent(variableName)
		found = false
		@variables.each do |v|
			if v.getName.eql?(variableName)
				found = true
			end
		end
		if not found and @parentState != nil
			found = @parentState.isVariablePresent(variableName)
		end
		found
	end
	
	def addVariable(variable)
		if not isVariablePresent(variable.getName)
			@variables.push(variable)
		end
	end
	
	def addVariableByName(variableName)
		if not isVariablePresent(variableName)
			newVariable = DsiVariable.new(variableName, DsiValue.new(nil))
			@variables.push(newVariable)
		end
	end
	
	def replaceVariable(variable)
		@variables.each do |v|
			if v.getName.eql?(variable.getName)
				v.setValue(variable.getValue)
				break
			end
		end
		logState "DsiRuntimeState.replaceVariable #{variable.getName} not found"
	end
	
	def self.cloneDsiValue(dsiValueIn)
		if dsiValueIn == nil
			logState "cloneDsiValue nil"
			return nil
		end
			
		#logState "cloneDsiValue #{dsiValueIn.getName}"
		dsiValueOut = nil
		logState "cloneDsiValue cloning  #{dsiValueIn.getValue}"
		if dsiValueIn.is_a?(DsiNumberValue)
			logState "cloneDsiValue DsiNumberValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiNumberValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiStringValue)
			logState "cloneDsiValue DsiStringValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiStringValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiBoolValue)
			logState "cloneDsiValue DsiBoolValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiBoolValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiEnumValue)
			logState "cloneDsiValue DsiEnumValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiEnumValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiFunctionReferenceValue)
			logState "cloneDsiValue DsiFunctionReferenceValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiFunctionReferenceValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiClassValue)
			logState "cloneDsiValue DsiClassValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiClassValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.is_a?(DsiValue)
			logState "cloneDsiValue DsiValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiValue.new(dsiValueIn.getValue)
		else
			dsiValueOut = nil
		end
		dsiValueOut
	end
	
	def dump
		logState "DsiRuntimeState.dump"
		logState "    CURRENT SCOPE #{@currentScopeName}"
		@variables.each { |v| logState "    VARIABLE #{v.getName} : #{v.getValue}" }
		if not @parentState == nil
			logState "    PARENT STATE"
			@parentState.dump
		end
	end
	
	def isLibraryFunction(name)
		if $libraryFunctions.include?(name)
			puts "LIBRARY FUNCTION DETECTED #{name}"
			return true
		else
			return false
		end
	end
	
end

# Break and continue ####################################################################################################

class DsiControlState
	attr_accessor :breakFlag, :continueFlag
	def initialize
		@breakFlag = false
		@continueFlag = false
	end
end

# DsiRuntimeContext (base class) ####################################################################################################

class DsiRuntimeContext
	def initialize(name, variables)
		logContext "DsiRuntimeContext #{name}, #{variables.size} variables"
		@valid = true
		@name = name
		@variables = variables
		#logContext "DsiRuntimeContext.initialize variables size #{@variables.size}, #{@variables.to_s}"
		@classContexts = nil
		@functionContexts = nil
	end
	
	def getClassContexts
		@classes
	end
	
	def getClassContext(name)
		if @classContexts != nil
			@classContexts.each do |c|
				if f.getName.eql?(name)
					return c
				end
			end
		end
		return nil
	end

	def getFunctionContexts
		@functionContexts
	end
	
	def getFunctionContext(name)
		if @functionContexts != nil
			@functionContexts.each do |f|
				if f.getName.eql?(name)
					return f
				end
			end
		end
		# TODO: Search classes
		return nil
	end
	
	def getName
		@name
	end
	
	def getVariables
		@variables
	end
	
	def isValid
		@valid
	end
	
	def invalidate
		@valid = false
	end
	
	def cloneVariableList(variablesIn) 
		# dsi
		logContext "DsiRuntimeContext.cloneVariableList variables size #{variablesIn.size}, #{variablesIn.to_s}"
		newVariableList = Array.new

		variablesIn.each do |v|
			logState "cloneVariableList cloning #{v.getName} = #{v.getValue}"
			value = DsiRuntimeState.cloneDsiValue(v.getValue)
			if not value == nil
				logState "cloneVariableList cloning #{v.getName} #{value.getValue.to_s}"
				newVariable = DsiVariable.new(v.getName, value)
				logState "cloneVariableList New variable #{newVariable.getName} #{newVariable.getValue.to_s}"
				newVariableList.push(newVariable)
				logState "cloneVariableList newVariableList () size #{newVariableList.size}"
			end
		end
		
		logContext "DsiRuntimeContext.cloneVariableList variables size #{newVariableList.size}, #{newVariableList.to_s}"
		newVariableList
	end

end

# DsiGlobalContext ####################################################################################################

class DsiGlobalContext < DsiRuntimeContext
	# Allowed in the global context are use, variable declaration, enum declaration, class declaration, function declaration
	
	def initialize(variables, enums, classContexts, functionContexts)
		logContext "DsiGlobalContext"
		super("`GlobalContext", variables)
		@enums = Array.new
		@classContexts = classContexts
		@functionContexts = functionContexts
	end
	
	def makeGlobalState
		scopeName = getName
		globalState = DsiRuntimeState.new("`GlobalRuntimeState", @variables, nil, self)
		globalState
	end
	
	def run
		logState "DsiGlobalContext.run"
		mainContext = getFunctionContext("main")
		if not mainContext == nil
			globalState = makeGlobalState
			functionState = mainContext.makeFunctionState(globalState)
			logState "DsiGlobalContext.run - Creating context for main"
			params = Array.new # TODO: Command line parameters
			globalState.dump
			ret = mainContext.invoke(functionState)
		end
	end
	
end

# DsiClassContext ####################################################################################################

class DsiClassContext < DsiRuntimeContext

	def initialize(name, baseClass, variables, functionContexts)
		logContext "DsiClassContext initialize #{name} #{baseClass}"
		super(name, variables)
		@baseClass = baseClass
		@functionContexts = functionContexts
	end
	
	def getName
		@name
	end
	
	def addFunctionContext(functionContext)
		# TODO: Qualify incoming names (classname.functionname)
		existingContext = getFunctionContext(functionContext.getName)
		if existingContext != nil
			@functionContexts.push(functionContext)
		end
	end
end	

# DsiFunctionContext ####################################################################################################

class DsiFunctionContext < DsiRuntimeContext

	def initialize(name, paramNames, variables, instructions)
		logContext "DsiFunctionContext #{name}"
		super(name, variables) # TODO: Scope
		logContext "DsiFunctionContext.initialize variables size #{getVariables.size}, #{getVariables.to_s}"
		@paramNames = paramNames
		@instructions = instructions
		@className = nil
		@returnValue = nil
	end

	def getName
		@name
	end
	
	def getInstructions
		@instructions
	end
	
	def getParamNames
		@paramNames
	end
	
	def setClassName(className)
		@className = className
	end
	
	def dump(state)
		logState "DsiFunctionContext.dump FUNCTION #{getName}"
		state.getVariables.each do |v|
			logState "DsiFunctionContext.dump VARIABLE #{v.getName} : #{v.getValue}"
		end
	end
	
	def makeFunctionState(parentState)
		logState "DsiFunctionContext.makeFunctionState #{getName}"
		scopeName = getName # TODO: Class names
		variables = getVariables
		logState "DsiFunctionContext.makeFunctionState #{scopeName} variables #{variables.size}, #{variables.to_s}"
		functionState = DsiRuntimeState.new(scopeName, variables, parentState, parentState.getGlobalContext)
		functionState
	end
	
	def invoke(functionState)
		logState "DsiFunctionContext.invoke #{getName}"
		functionState.dump
		# Parameters are passed in through the state
		functionState.setReturnValue(nil)
		logState "DsiFunctionContext.invoke NUMBER OF INSTRUCTIONS #{getInstructions.size}"
		getInstructions.each do |i|
			logState "DsiFunctionContext.invoke EVALUATING INSTRUCTION #{i.to_s}"
			i.evaluate(functionState)
		end
		returnValue = functionState.getReturnValue
		functionState.dump
		return returnValue
	end
	
end


require 'set'
require_relative '../dsp/ds_elements'

$logForContexts = true

def logContext text
	puts (". " + text) if $logForContexts
end

$logForState = true

def logState text
	puts (". " + text) if $logForState
end

# Runtime states ####################################################################################################

class DsiRuntimeState
	def initialize(currentScopeName, variables, parentState)
		@currentScopeName = currentScopeName
		@variables = variables
		@parentState= parentState
		@returnValue = nil # ?
		logState "DsiRuntimeState.initialize variables.size #{variables.size}"
		logState "DsiRuntimeState.initialize variables=#{variables.to_s}"
		# TODO: deep copy of variables, default values
		
	end
	def getName
		@currentScopeName
	end
	def getVariables
		@variables
	end
	def getVariable(name)
		var = nil
		@variables.each do |v|
			logState "DsiRuntimeState.getVariable #{v.getName}"
			if v.getName.eql?(name)
				var = v
				break
			end
		end
		if var == nil and not @parentState == nil
			var = @parentState.getVariable(name)
		end
		logState "DsiRuntimeState.getVariable end"
		var
	end
	
	def addVariable(variable)
		found = false
		@variables.each do |v|
			if v.getName.eql?(variable.getName)
				found = false
			end
		end
		if not found
			@variables.push(variable)
		end
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
	
end

# DsiRuntimeContext (base class) ####################################################################################################

class DsiRuntimeContext
	def initialize(name, variables)
		logContext "DsiRuntimeContext #{name}, #{variables.size} variables"
		@valid = true
		@name = name
		@variables = variables
		#logContext "DsiRuntimeContext.initialize variables size #{@variables.size}, #{@variables.to_s}"
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
	
	def getClassContexts
		@classes
	end
	
	def getClassContext(name)
		@classContexts.each do |c|
			if f.getName.eql?(name)
				return c
			end
		end
		return nil
	end

	def getFunctionContexts
		@functionContexts
	end
	
	def getFunctionContext(name)
		@functionContexts.each do |f|
			if f.getName.eql?(name)
				return f
			end
		end
		return nil
	end

	def makeGlobalState
		scopeName = getName
		globalState = DsiRuntimeState.new("`GlobalRuntimeState", @variables, nil)
		globalState
	end
	
	def run
		logState "DsiGlobalContext.run"
		mainContext = getFunctionContext("main")
		if not mainContext == nil
			globalState = makeGlobalState
			logState "DsiGlobalContext.run - Creating context for main"
			params = Array.new # TODO: Command line parameters
			globalState.dump
			ret = mainContext.invoke(globalState)
		end
	end
	
end

# DsiClassContext ####################################################################################################

class DsiClassContext < DsiRuntimeContext

	def initialize(name, baseClass, variables, functionContexts)
		logContext "DsiClassContext #{name} #{baseClass}"
		super(name, variables)
		@baseClass = baseClass
		@functionContexts = functionContexts
	end
	
	def getName
		@name
	end
	
	def addFunction(functionContext)
		# TODO: Qualify incoming names (classname.functionname)
		@functionContexts.each do |f|
			if f.getName.eql?(functionContext.getName)
				return
			end
		end
		@functionContexts.push(functionContext)
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
	end

	def getName
		@name
	end
	
	def getInstructions
		@instructions
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
		# TODO: Param variable names/values need to be added to the state
		scopeName = getName # TODO: Class names
		variables = getVariables
		logState "DsiFunctionContext.makeFunctionState #{scopeName} variables #{variables.size}, #{variables.to_s}"
		functionState = DsiRuntimeState.new(scopeName, variables, parentState)
		functionState
	end
	
	def invoke(parentState)
		logState "DsiFunctionContext.invoke #{getName}"
		
		state = makeFunctionState(parentState)
		
		# Iterate through the statements in the context
		getInstructions.each do |i|
			i.evaluate(state)
		end
		
		state.dump
		#dump(state)
	end
	
end


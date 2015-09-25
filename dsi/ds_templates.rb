require 'set'
require_relative '../dsp/ds_elements'
$verboseTemplate = true

def debugTemplate text
	puts text if $verboseTemplate
end

$verboseState = true

def debugState text
	puts text if $verboseState
end

# Runtime states ####################################################################################################

class DsiRuntimeState
	def initialize(currentScopeName, variables, parentState)
		@currentScopeName = currentScopeName
		@variables = variables
		@parentState= parentState
		@returnValue = nil # ?
		debugState "DsiRuntimeState.initialize variables.size #{variables.size}"
		debugState "DsiRuntimeState.initialize variables=#{variables.to_s}"
		# TODO: deep copy of variables, default values
		
		# TODO: Default values from the template
		#variableNames.each do |v|
		#	@variables.push(DsiVariable.new(v))
		#end
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
			debugState "DsiRuntimeState.getVariable #{v.getName}"
			if v.getName.eql?(name)
				var = v
				break
			end
		end
		if var == nil and not @parentState == nil
			var = @parentState.getVariable(name)
		end
		debugState "DsiRuntimeState.getVariable end"
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
		debugState "cloneDsiValue #{dsiValueIn.getName}"
		dsiValueOut = nil
		debugState "cloneDsiValue cloning  #{dsiValueIn.getValue}"
		if dsiValueIn.getValue.is_a?(DsiNumberValue)
			debugState "cloneDsiValue DsiNumberValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiNumberValue.new(v.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiStringValue)
			debugState "cloneDsiValue DsiStringValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiStringValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiBoolValue)
			debugState "cloneDsiValue DsiBoolValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiBoolValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiEnumValue)
			debugState "cloneDsiValue DsiEnumValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiEnumValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiFunctionReferenceValue)
			debugState "cloneDsiValue DsiFunctionReferenceValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiFunctionReferenceValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiClassValue)
			debugState "cloneDsiValue DsiClassValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiClassValue.new(dsiValueIn.getValue)
		elsif dsiValueIn.getValue.is_a?(DsiValue)
			debugState "cloneDsiValue DsiValue #{dsiValueIn.getValue}"
			dsiValueOut = DsiValue.new(dsiValueIn.getValue)
		else
			dsiValueOut = nil
		end
		dsiValueOut
	end
	
	def dump
		debugState "DsiRuntimeState.dump"
		debugState "    CURRENT SCOPE #{@currentScopeName}"
		@variables.each { |v| debugState "    VARIABLE #{v.getName} : #{v.getValue}" }
		if not @parentState == nil
			debugState "    PARENT STATE"
			@parentState.dump
		end
	end
	
end

# DsiTemplate ####################################################################################################

class DsiContextTemplate
	def initialize(name, variables)
		debugTemplate "DsiTemplate #{name}, #{variables.size} variables"
		@valid = true
		@name = name
		puts "((( DsiContextTemplate.initialize variables size #{variables.size}, #{variables.to_s}"
		@variables = cloneVariableList(variables)
		puts "))) DsiContextTemplate.initialize variables size #{@variables.size}, #{@variables.to_s}"
		#debugTemplate "DsiTemplate #{name}, #{@variables.size} variables"
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
	
	def cloneDspVariableList(variablesIn)
		puts "{{{ DsiContextTemplate.cloneDspVariableList variables size #{variablesIn.size}, #{variablesIn.to_s}"
		newVariableList = Array.new
		variablesIn.each do |v|
			value = LoaderState.translateDspValue
			if not value == nil
				debugState "cloneDspVariableList cloning #{v.getName} #{value.getValue.to_s}"
				newVariable = DsiVariable.new(v.getName, value)
				debugState "cloneDspVariableList New variable #{newVariable.getName} #{newVariable.getValue.to_s}"
				newVariableList.push(newVariable)
				debugState "cloneDspVariableList newVariableList () size #{newVariableList.size}"
			end
		end
		puts "}}} DsiContextTemplate.cloneDspVariableList variables size #{newVariableList.size}, #{newVariableList.to_s}"
		#debugState "cloneDspVariableList newVariableList size #{newVariableList.size}"
		newVariableList
	end
	
	#def cloneDsiVariableList(variablesIn)
	#	puts "{{{ DsiContextTemplate.cloneDsiVariableList variables size #{variablesIn.size}, #{variablesIn.to_s}"
	#	newVariableList = Array.new
	#	variablesIn.each do |v|
	#		value = LoaderState.cloneDsiValue
	#		if not value == nil
	#			debugState "cloneDsiVariableList cloning #{v.getName} #{value.getValue.to_s}"
	#			newVariable = DsiVariable.new(v.getName, value)
	#			debugState "cloneDsiVariableList New variable #{newVariable.getName} #{newVariable.getValue.to_s}"
	#			newVariableList.push(newVariable)
	#			debugState "cloneDsiVariableList newVariableList () size #{newVariableList.size}"
	#		end
	#	end
	#	puts "}}} DsiContextTemplate.cloneDsiVariableList variables size #{newVariableList.size}, #{newVariableList.to_s}"
	#	#debugState "cloneDsiVariableList newVariableList size #{newVariableList.size}"
	#	newVariableList
	#end
	
	def cloneVariableList(variablesIn) 
		# dsi
		puts "{{{ DsiContextTemplate.cloneVariableList variables size #{variablesIn.size}, #{variablesIn.to_s}"
		newVariableList = Array.new

		variablesIn.each do |v|
			value = nil
			debugState "cloneVariableList cloning  #{v.getValue}"
			value = self.class.cloneDsiValue(v.getValue)
			if not value == nil
				debugState "cloneVariableList cloning #{v.getName} #{value.getValue.getValue.to_s}"
				newVariable = DsiVariable.new(v.getName, value)
				debugState "cloneVariableList New variable #{newVariable.getName} #{newVariable.getValue.to_s}"
				newVariableList.push(newVariable)
				debugState "cloneVariableList newVariableList () size #{newVariableList.size}"
			end
		end
		
		puts "}}} DsiContextTemplate.cloneVariableList variables size #{newVariableList.size}, #{newVariableList.to_s}"
		#debugState "cloneVariableList newVariableList size #{newVariableList.size}"
		newVariableList
	end
	
	def cloneDsiVariables(variables)	
	end
end

# DsiGlobalTemplate ####################################################################################################

class DsiGlobalTemplate < DsiContextTemplate
	# Allowed in the global template are use, variable declaration, enum declaration, class declaration, function declaration
	def initialize(variables, enums, classTemplates, functionTemplates)
		debugTemplate "DsiGlobalTemplate"
		super("`GlobalTemplate", variables)
		@enums = Array.new
		@classTemplates = classTemplates
		@functionTemplates = functionTemplates
	end
	
	def getClassTemplates
		@classes
	end
	
	def getClassTemplate(name)
		@classTemplates.each do |c|
			if f.getName.eql?(name)
				return c
			end
		end
		return nil
	end

	def getFunctionTemplates
		@functionTemplates
	end
	
	def getFunctionTemplate(name)
		@functionTemplates.each do |f|
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
		debugState "DsiGlobalContext.run"
		mainTemplate = getFunctionTemplate("main")
		if not mainTemplate == nil
			globalState = makeGlobalState
puts ">>>>>>>makeGlobalState size #{globalState.getVariables.size}"
			debugState "DsiGlobalContext.run - Creating context for main"
			params = Array.new # TODO: Command line parameters
			globalState.dump
			ret = mainTemplate.invoke(globalState)
		end
	end
	
end

# DsiClassTemplate ####################################################################################################

class DsiClassTemplate < DsiContextTemplate
	def initialize(name, baseClass, variables, functionTemplates)
		debugTemplate "DsiClassTemplate #{name} #{baseClass}"
		super(name, variables)
		@baseClass = baseClass
		@functionTemplates = functionTemplates
	end
	
	def getName
		@name
	end
	
	def addFunction(functionTemplate)
		# TODO: Qualify incoming names (classname.functionname)
		@functionTemplates.each do |f|
			if f.getName.eql?(functionTemplate.getName)
				return
			end
		end
		@functionTemplates.push(functionTemplate)
	end
end	

# DsiFunctionTemplate ####################################################################################################

class DsiFunctionTemplate < DsiContextTemplate

	def initialize(name, paramNames, variables, instructions)
		debugTemplate "DsiFunctionTemplate #{name}"
		puts "DsiFunctionTemplate.initialize variables size #{variables.size}, #{variables.to_s}"
		super(name, variables) # TODO: Scope
		puts "DsiFunctionTemplate.initialize variables size #{getVariables.size}, #{getVariables.to_s}"
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
		debugState "DsiFunctionTemplate.dump FUNCTION #{getName}"
		state.getVariables.each do |v|
			debugState "DsiFunctionTemplate.dump VARIABLE #{v.getName} : #{v.getValue}"
		end
	end
	
	def makeFunctionState(parentState)
		debugState "DsiFunctionTemplate.makeFunctionState #{getName}"
		# TODO: Param variable names/values need to be added to the state
		scopeName = getName # TODO: Class names
		variables = getVariables
		debugState "**************DsiFunctionTemplate.makeFunctionState #{scopeName} variables #{variables.getSize}, #{variables.to_s}"
		functionState = DsiRuntimeState.new(scopeName, variables, parentState)
		functionState
	end
	
	def invoke(parentState)
		debugState "DsiFunctionTemplate.invoke #{getName}"
		
		state = makeFunctionState(parentState)
		
		# Iterate through the statements in the template
		getInstructions.each do |i|
			i.evaluate(state)
		end
		
		state.dump
		#dump(state)
	end
	
end


require 'set'

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
		debugState "DsiRuntimeState.initialize scope=#{currentScopeName}"
		@currentScopeName = currentScopeName
		@variables = variables
		@parentState= parentState
		@returnValue = nil # ?
		debugState "DsiRuntimeState.initialize variables=#{@variables.to_s}"
	end
	def getName
		@currentScopeName
	end
	#def getVariables
	#	@variables
	#end
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
		var
		debugState "DsiRuntimeState.getVariable end"
	end
end

# DsiTemplate ####################################################################################################

class DsiStateTemplate
	def initialize(name, variables)
		debugTemplate "DsiTemplate #{name}"
		@valid = true
		@name = name
		@variables = variables
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
		variables = Array.new
		variablesIn.each do |v|
			if v.is_a?(DsiNumberValue)
				debugState "cloneVariableList DsiNumberValue #{v.getName}"
				val = DsiNumberValue.new(v.GetValue)
			elsif v.is_a?(DsiStringValue)
				debugState "cloneVariableList DsiStringValue #{v.getName}"
				val = DsiStringValue.new(v.GetValue)
			elsif v.is_a?(DsiBoolValue)
				val = DsiBoolValue.new(v.GetValue)
			elsif v.is_a?(DsiEnumValue)
				val = DsiEnumValue.new(v.GetValue)
			elsif v.is_a?(DsiFunctionReferenceValue)
				val = DsiFunctionReferenceValue.new(v.GetValue)
			elsif v.is_a?(DsiClassValue)
				val = DsiClassValue.new(v.GetValue)
			elsif v.is_a?(DsiValue)
				val = DsiValue.new(v.GetValue)
			else
				val = nil
			
			end
			if not val == nil
				var = Variable.new(v.getName, val)
				variables.push(var)
			end
		end
		variables
	end
end

# DsiGlobalTemplate ####################################################################################################

class DsiGlobalTemplate < DsiStateTemplate
	# Allowed in the global template are use, variable declaration, enum declaration, class declaration, function declaration
	def initialize(variables, enums, classTemplates, functionTemplates)
		debugTemplate "DsiGlobalTemplate"
		super("0__GlobalTemplate", variables)
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
		variables = cloneVariableList(@variables)
		scopeName = getName
		globalState = DsiRuntimeState.new("0__Global", variables, nil)
		globalState
	end
	
	def run
		debugState "DsiGlobalContext.run"
		mainTemplate = getFunctionTemplate("main")
		if not mainTemplate == nil
			globalState = makeGlobalState
			debugState "DsiGlobalContext.run - Creating context for main"
			params = Array.new # TODO: Command line parameters
			ret = mainTemplate.invoke(globalState)
		end
	end
	
end

# DsiClassTemplate ####################################################################################################

class DsiClassTemplate < DsiStateTemplate
	def initialize(name, baseClass, vars, functionTemplates)
		debugTemplate "DsiClassTemplate #{name} #{baseClass}"
		super(name, vars)
		@baseClass = baseClass
		@functionTemplates = functionTemplates
	end
	
	def getName
		@name
	end
	
	def addVar(name)
		@vars.add(name)
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

class DsiFunctionTemplate < DsiStateTemplate
	def initialize(name, paramNames, vars, instructions)
		debugTemplate "DsiFunctionTemplate #{name}"
		super(name, vars) # TODO: Scope
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
	
	def makeFunctionState(parentState)
		debugState "DsiFunctionTemplate.invoke #{getName}"
		scopeName = getName # TODO: Class names
		variables = cloneVariableList(getVariables)
		# TODO: Param variable names/values need to be added to the state
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
	end
	
end


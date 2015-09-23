require_relative "ds_templates"

$verboseState = true

def debugState text
	puts text if $verboseState
end

# Runtime states ####################################################################################################
# These objects know about the template classes, but the template classes don't know about them.
# The runtime is responsible for its own setup based on the contexts.
# Or is it better for dsc for this code to do the setup work for the template classes after all?

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

# DsiContext ####################################################################################################

class DsiContext
	# Functions for looking up functions and variables in a list of states
	#def initialize(scopeName, variables, parentContext = nil)
	#	#super(scopeName, variables)
	#	@parentContext = parentContext
	#end

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

# DsiGlobalContext ####################################################################################################

class DsiGlobalContext < DsiContext
	def initialize(globalTemplate)
		@globalTemplate = globalTemplate

		variables = Array.new
		globalTemplate.getVariables.each do |v|
			var = DsiVariable.new(v.getName, v.getValue)
		end
		variables = cloneVariableList(@globalTemplate.getVariables)
		
		scopeName = @globalTemplate.getName
		@globalState = DsiRuntimeState.new(scopeName, variables, nil)
		
		# Load variables
	end
	
	def run
		debugState "DsiGlobalContext.run"
		mainTemplate = @globalTemplate.getFunctionTemplate("main")
		if not mainTemplate == nil
			debugState "DsiGlobalContext.run - Creating context for main"
			mainContext = DsiFunctionContext.new(mainTemplate, @globalState, nil)
			params = Array.new # TODO: Command line parameters
			ret = mainContext.evaluate(params)
		end
	end
end

# DsiFunctionContext ####################################################################################################

class DsiFunctionContext < DsiContext
	def initialize(functionTemplate, globalState, classState = nil)
		debugState "DsiFunctionContext.initialize #{functionTemplate.getName}"
		@functionTemplate = functionTemplate
		@globalState = globalState
		@classState = classState
		#@state = nil
		
		variables = Array.new
		functionTemplate.getVariables.each do |v|
			var = DsiVariable.new(v.getName, v.getValue)
		end
		variables = cloneVariableList(@functionTemplate.getVariables)
		
		if @classState == nil
			scopeName = @functionTemplate.getName
			@state = DsiRuntimeState.new(scopeName, variables, @globalState)
		else
			scopeName = "#{@classState.getName}.scopeName"
			@state = DsiRuntimeState.new(scopeName, variables, @classState)
		end
	end
	
	def evaluate(params)
		debugState "DsiFunctionContext.evaluate #{@functionTemplate.getName}"
		# TODO: Param variable names need to be added to the template
		
		# Iterate through the statements in the template
		@functionTemplate.getInstructions.each do |i|
			i.evaluate(@state)
		end
	end
end
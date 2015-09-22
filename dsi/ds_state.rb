$verboseState = true

def debugState text
	puts text if $verboseState
end

require_relative "ds_templates"

# Runtime states ####################################################################################################
# These objects know about the template classes, but the template classes don't know about them.
# The runtime is responsible for its own setup based on the contexts.
# Or is it better for dsc for this code to do the setup work for the template classes after all?

class DsiRuntimeState
	def initialize(currentScopeName, variables)
		@currentScopeName = currentScopeName
		@variables = variables
		@returnValue = nil # ?
	end
	def getName
		@currentScopeName
	end
	def getVariables
		@variables
	end
end

class DsiContext
	# Functions for looking up functions and variables in a list of states
	#def initialize(scopeName, variables, parentContext = nil)
	#	#super(scopeName, variables)
	#	@parentContext = parentContext
	#end
end

class DsiGlobalContext < DsiContext
	def initialize(globalTemplate)
		@globalTemplate = globalTemplate
		variables = Array.new
		
		globalTemplate.getVariables.each do |v|
			var = DsiVariable.new(v.getName, v.getValue)
		end
		
		scopeName = @globalTemplate.getName
		variables = cloneVariableList(@globalTemplate.getVariables)
		@state = DsiRuntimeState.new(scopeName, variables)
		
		# Load variables
	end
	
	def cloneVariableList(variablesIn)
		variables = Array.new
		@globalTemplate.getVariables.each do |v|
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
	
	def run
		debugState "DsiGlobalContext.run"
		main = @globalTemplate.getFunctionTemplate("main")
		if not main == nil
			debugState "DsiGlobalContext.run - calling main"
			params = Array.new
			ret = main.evaluate(params, @state)
		end
	end
end
